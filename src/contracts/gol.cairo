use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IGoL2<TContractState> {
    /// Read
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    /// Write
    fn create(ref self: TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: usize);
    /// .
    fn initializer(ref self: TContractState);
    fn migrate(ref self: TContractState, new_class_hash: ClassHash);
}


#[starknet::contract]
mod GoL2 {
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ClassHash,
        replace_class_syscall, contract_address_try_from_felt252
    };
    use openzeppelin::{
        access::ownable::OwnableComponent,
        upgrades::{UpgradeableComponent, interface::IUpgradeable},
        token::erc20::{ERC20Component, interface::IERC20Metadata}
    };
    use gol2::utils::{
        life_rules::evaluate_rounds, packing::{pack_game, unpack_game, revive_cell},
        constants::{
            INFINITE_GAME_GENESIS, DIM, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT,
            HIGH_ARRAY_LEN, BOARD_SQUARED, INITIAL_ADMIN
        }
    };
    use alexandria_math::pow;
    use debug::PrintTrait;
    use super::{IGoL2Dispatcher, IGoL2DispatcherTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    /// Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    /// ERC20
    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl SafeAllowanceImpl = ERC20Component::SafeAllowanceImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.create_new_game(INFINITE_GAME_GENESIS, get_caller_address());
        self.ownable.initializer(owner);
    }

    #[storage]
    struct Storage {
        /// Mapping for game_id -> generation -> state
        stored_game: LegacyMap<(felt252, felt252), felt252>,
        /// Map for game_id -> generation
        current_generation: LegacyMap<felt252, felt252>,
        /// Has contract been migrated to cairo1
        is_migrated: bool,
        /// Component Storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        /// Slot of old proxy admin address, used for migration to ownable/upgradable components
        Proxy_admin: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameCreated: GameCreated,
        GameEvolved: GameEvolved,
        CellRevived: CellRevived,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct GameCreated {
        #[key]
        user_id: ContractAddress,
        game_id: felt252,
        state: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct GameEvolved {
        #[key]
        user_id: ContractAddress,
        #[key]
        game_id: felt252,
        generation: felt252,
        state: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct CellRevived {
        #[key]
        user_id: ContractAddress,
        generation: felt252,
        cell_index: usize,
        state: felt252,
    }

    /// External Functions
    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        /// Write
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
            IGoL2Dispatcher { contract_address: starknet::get_contract_address() }.initializer();
        }
    }

    #[external(v0)]
    impl ERC20MetadataImpl of IERC20Metadata<ContractState> {
        fn decimals(self: @ContractState) -> u8 {
            0
        }

        fn name(self: @ContractState) -> felt252 {
            self.erc20.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc20.symbol()
        }
    }

    #[external(v0)]
    impl GoL2Impl of super::IGoL2<ContractState> {
        /// Empty function, used for interface definition if future upgrades to the contract
        fn initializer(ref self: ContractState) {}

        fn migrate(ref self: ContractState, new_class_hash: ClassHash) {
            let prev_admin = contract_address_try_from_felt252(self.Proxy_admin.read()).unwrap();
            assert(get_caller_address() == prev_admin, 'Caller is not prev admin');
            assert(!self.is_migrated.read(), 'Contract already migrated');
            /// The contract admin is currently stored in slot `Proxy_admin`, this places it in slot `Ownable_owner`
            self.ownable.initializer(prev_admin);
            /// Toggles function uncallable again
            self.is_migrated.write(true);
            /// Removes proxy setup, switching to single upgradable contract setup
            replace_class_syscall(new_class_hash);
        }

        /// Read
        fn view_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.stored_game.read((game_id, generation))
        }

        fn get_current_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// Write 
        fn create(ref self: ContractState, game_state: felt252) {
            let caller = self.ensure_user();
            self.assert_valid_new_game(game_state);
            self.pay(caller, CREATE_CREDIT_REQUIREMENT);
            self.create_new_game(game_state, caller);
        }

        fn evolve(ref self: ContractState, game_id: felt252) {
            let caller = self.ensure_user();
            let (generation, game) = self.evolve_game(game_id, caller);
            self.save_game(game_id, generation, game);
            self.save_generation_id(game_id, generation);
            self.reward_user(caller);
        }

        fn give_life_to_cell(ref self: ContractState, cell_index: usize) {
            let caller = self.ensure_user();
            let (generation, current_game_state) = self.get_last_state();
            self.assert_valid_cell_index(cell_index);
            self.pay(caller, GIVE_LIFE_CREDIT_REQUIREMENT);
            self.activate_cell(generation, caller, cell_index, current_game_state)
        }
    }

    /// Internal Functions
    #[generate_trait]
    impl GoL2Internals of GoL2InternalTrait {
        fn pay(ref self: ContractState, user: ContractAddress, credit_requirement: felt252) {
            self.erc20._burn(user, credit_requirement.into());
        }

        fn reward_user(ref self: ContractState, user: ContractAddress) {
            self.erc20._mint(user, 1);
        }

        fn ensure_user(self: @ContractState) -> ContractAddress {
            let caller = get_caller_address();
            assert(caller.is_non_zero(), 'User not authenticated');
            caller
        }

        fn evolve_game(
            ref self: ContractState, game_id: felt252, user: ContractAddress
        ) -> (felt252, felt252) {
            let prev_generation = self.current_generation.read(game_id);
            self.assert_game_exists(game_id, prev_generation);

            let new_generation = prev_generation + 1;
            /// Unpack game 
            let game_state = self.stored_game.read((game_id, prev_generation));
            let cells = unpack_game(game_state);
            /// Evolve game by # of generations     
            let new_cell_states = evaluate_rounds(1, cells);
            let packed_game = pack_game(new_cell_states);

            self
                .emit(
                    GameEvolved {
                        user_id: user,
                        game_id: game_id,
                        generation: new_generation,
                        state: packed_game
                    }
                );
            (new_generation, packed_game)
        }

        fn save_game(
            ref self: ContractState, game_id: felt252, generation: felt252, packed_game: felt252
        ) {
            self.stored_game.write((game_id, generation), packed_game);
        }

        fn save_generation_id(ref self: ContractState, game_id: felt252, generation: felt252) {
            self.current_generation.write(game_id, generation);
        }

        fn assert_game_exists(self: @ContractState, game_id: felt252, generation: felt252) {
            assert(self.current_generation.read(game_id) != 0, 'Game has not been started');
            let current_generation: u256 = self.current_generation.read(game_id).into();
            assert(generation.into() <= current_generation, 'Generation does not exist yet');
        }

        fn assert_game_does_not_exist(self: @ContractState, game_id: felt252) {
            assert(
                self.stored_game.read((game_id, 1)) + self.current_generation.read(game_id) == 0,
                'Game already exists'
            );
        }

        fn get_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.assert_game_exists(game_id, generation);
            self.stored_game.read((game_id, generation))
        }

        fn get_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// Creator Mode
        fn assert_valid_new_game(self: @ContractState, game: felt252) {
            self.assert_game_does_not_exist(game);
            /// max game => 225 bits all 1s => 2^225 - 1
            let game_int: u256 = game.into();
            assert(game_int.high < (pow(2, HIGH_ARRAY_LEN.into())), 'Game size too big');
        }

        fn create_new_game(ref self: ContractState, game_state: felt252, user_id: ContractAddress) {
            self.save_game(game_state, 1, game_state);
            self.save_generation_id(game_state, 1);
            self.emit(GameCreated { user_id: user_id, game_id: game_state, state: game_state });
        }

        /// Infinite Mode
        fn get_last_state(self: @ContractState) -> (felt252, felt252) {
            let generation = self.current_generation.read(INFINITE_GAME_GENESIS);
            let game_state = self.stored_game.read((INFINITE_GAME_GENESIS, generation));
            (generation, game_state)
        }

        fn assert_valid_cell_index(self: @ContractState, cell_index: usize) {
            assert(cell_index < BOARD_SQUARED, 'Cell index out of range');
        }

        fn activate_cell(
            ref self: ContractState,
            generation: felt252,
            caller: ContractAddress,
            cell_index: usize,
            current_state: felt252
        ) {
            self.assert_valid_cell_index(cell_index);
            let packed_game = revive_cell(cell_index, current_state);

            assert(packed_game != current_state, 'No changes made to game');

            /// Generation does not increment when cell is activated
            self.save_game(INFINITE_GAME_GENESIS, generation, packed_game);

            self
                .emit(
                    CellRevived {
                        user_id: caller,
                        generation: generation,
                        cell_index: cell_index,
                        state: packed_game
                    }
                );
        }
    }
}

