use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IGoL2<TContractState> {
    /// Read
    fn is_snapshotter(self: @TContractState, user: ContractAddress) -> bool;
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn view_snapshot(self: @TContractState, generation: felt252) -> GoL2::Snapshot;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    /// Write
    fn create(ref self: TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: usize);
    fn migrate(ref self: TContractState, new_class_hash: ClassHash);
    fn initializer(ref self: TContractState);
    fn set_snapshotter(ref self: TContractState, user: ContractAddress, is_snapshotter: bool);
    fn add_snapshot(
        ref self: TContractState,
        generation: felt252,
        user_id: ContractAddress,
        game_state: felt252,
        timestamp: u64
    ) -> bool;
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
            HIGH_ARRAY_LEN, BOARD_SQUARED
        },
    };
    use alexandria_math::pow;
    use debug::PrintTrait;
    use super::{IGoL2Dispatcher, IGoL2DispatcherTrait};

    /// Components

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    /// (Ownable)
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    /// (Upgradeable)
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;
    /// (ERC20)
    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl SafeAllowanceImpl = ERC20Component::SafeAllowanceImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    /// Contract

    #[storage]
    struct Storage {
        /// Mapping for game_id -> generation -> state.
        stored_game: LegacyMap<(felt252, felt252), felt252>,
        /// Map for game_id -> generation.
        current_generation: LegacyMap<felt252, felt252>,
        /// Has contract been migrated to cairo1 ?
        is_migrated: bool,
        /// Mapping for generations -> Snapshots.
        snapshots: LegacyMap<felt252, Snapshot>,
        /// Mapping for user -> snapshotter status.
        /// @dev Snapshotters are allowed to manually add
        /// snapshots to the contract (intended for the NFT
        /// contract to handle pre-migration generations).
        is_snapshotter: LegacyMap<ContractAddress, bool>,
        /// Number of generations in the infinite game at the time of
        /// migrating from Cairo 0 to Cario 1.
        migration_generation_marker: felt252,
        /// Component storage.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        /// Slot for old proxy admin address, used during migration.
        Proxy_admin: felt252,
    }

    /// @dev Used for testing purposes. In the live version, this will never
    /// be called since the contract is already deployed.
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.erc20.initializer('Game of Life Token', 'GOL');
        self.ownable.initializer(owner);
        self.create_new_game(INFINITE_GAME_GENESIS, get_caller_address());
    }

    /// Events

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

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct Snapshot {
        user_id: ContractAddress,
        game_state: felt252,
        timestamp: u64,
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
        /// Reads

        /// Get if a user is a snapshotter.
        /// @dev A snapshotter is a contract allowed to create snapshots of the infinite game.
        fn is_snapshotter(self: @ContractState, user: ContractAddress) -> bool {
            self.is_snapshotter.read(user)
        }

        /// Get the game state at a given generation.
        fn view_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.stored_game.read((game_id, generation))
        }

        /// Get the snapshot of a generation in the infinite game.
        fn view_snapshot(self: @ContractState, generation: felt252) -> Snapshot {
            self.snapshots.read(generation)
        }

        /// Get the current generation of a game.
        fn get_current_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// Writes

        /// Owner only 

        /// Set a user's snapshotter status.
        /// @dev A snapshotter is a contract allowed to create snapshots for the infinite game.
        /// @dev This allows pre-migration snapshots to be saved in the contract via 3rd party contracts.
        fn set_snapshotter(ref self: ContractState, user: ContractAddress, is_snapshotter: bool) {
            self.ownable.assert_only_owner();
            self.is_snapshotter.write(user, is_snapshotter);
        }

        /// Migrate contract to new class hash (Cairo 0 -> Cairo 1).
        /// @dev Only callable once.
        fn migrate(ref self: ContractState, new_class_hash: ClassHash) {
            let prev_admin = contract_address_try_from_felt252(self.Proxy_admin.read()).unwrap();
            assert(get_caller_address() == prev_admin, 'GoL2: Caller is not prev admin');
            assert(!self.is_migrated.read(), 'GoL2: Contract already migrated');
            /// The contract admin is currently stored in slot `Proxy_admin`, this places it in slot `Ownable_owner`
            self.ownable.initializer(prev_admin);
            /// Save current infinite genesis game state 
            /// Mark the number of generations in the infinite game at the time of migration
            self
                .migration_generation_marker
                .write(self.current_generation.read(INFINITE_GAME_GENESIS));
            /// Toggles function uncallable again
            self.is_migrated.write(true);
            /// Removes proxy setup, switching to single upgradable contract setup
            replace_class_syscall(new_class_hash);
        }

        /// Empty function for interface definition.
        /// @dev Useful for future contract upgrades. This function is 
        /// called by the upgrade function; allowing future upgrades to
        /// perform any necessary initialization in the 1 `upgrade()` txn.
        fn initializer(ref self: ContractState) {}

        /// Snapshotters only

        /// Add a snapshot of a generation to the contract.
        /// @dev Only callable by a snapshotter.
        /// @dev Only callable for generations <= the migration_generation_marker
        /// because post-migration snapshots are stored automatically.
        fn add_snapshot(
            ref self: ContractState,
            generation: felt252,
            user_id: ContractAddress,
            game_state: felt252,
            timestamp: u64
        ) -> bool {
            assert(self.is_snapshotter.read(get_caller_address()), 'GoL2: caller non snapshotter');
            let u_generation: u256 = generation.into();
            assert(
                u_generation <= self.migration_generation_marker.read().into() && u_generation > 0,
                'GoL2: not from pre-migration'
            );
            self.save_snapshot(generation, Snapshot { user_id, game_state, timestamp });
            true
        }

        /// Public

        /// Create a new creator mode game.
        fn create(ref self: ContractState, game_state: felt252) {
            let caller = self.ensure_user();
            self.assert_valid_new_game(game_state);
            self.pay(caller, CREATE_CREDIT_REQUIREMENT);
            self.create_new_game(game_state, caller);
        }

        /// Evolve a game by 1 generation.
        fn evolve(ref self: ContractState, game_id: felt252) {
            let caller = self.ensure_user();
            let (generation, game) = self.evolve_game(game_id, caller);
            self.save_game(game_id, generation, game);
            self.save_generation_id(game_id, generation);
            self.reward_user(caller);
            /// Save a snapshot of this generation if infinite mode
            if game_id == INFINITE_GAME_GENESIS {
                self
                    .save_snapshot(
                        generation,
                        Snapshot {
                            user_id: caller,
                            game_state: game,
                            timestamp: starknet::get_block_timestamp()
                        }
                    );
            }
        }

        /// Revive a cell in the infinite game.
        /// @dev This function fails if the cell is already alive.
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
        /// Get a game at a generation if it exists.
        fn get_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.assert_game_exists(game_id, generation);
            self.stored_game.read((game_id, generation))
        }

        /// Get the current generation of a game.
        fn get_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// Burn a user's gol tokens as payment.
        fn pay(ref self: ContractState, user: ContractAddress, credit_requirement: felt252) {
            self.erc20._burn(user, credit_requirement.into());
        }

        /// Mint a user a gol token as reward.
        fn reward_user(ref self: ContractState, user: ContractAddress) {
            self.erc20._mint(user, 1);
        }

        /// Ensure a user is calling the function and return it.
        /// @dev This was in the Cairo 0 version.
        fn ensure_user(self: @ContractState) -> ContractAddress {
            let caller = get_caller_address();
            assert(caller.is_non_zero(), 'GoL2: User not authenticated');
            caller
        }

        /// Assert that a generation is valid for a game.
        fn assert_game_exists(self: @ContractState, game_id: felt252, generation: felt252) {
            assert(self.current_generation.read(game_id) != 0, 'GoL2: Zero generation');
            let current_generation: u256 = self.current_generation.read(game_id).into();
            assert(generation.into() <= current_generation, 'GoL2: Generation > current');
        }

        /// Evolve a game by 1 generation and return the new generation and game state.
        fn evolve_game(
            ref self: ContractState, game_id: felt252, user: ContractAddress
        ) -> (felt252, felt252) {
            let prev_generation = self.current_generation.read(game_id);
            self.assert_game_exists(game_id, prev_generation);

            let new_generation = prev_generation + 1;
            /// Unpack game 
            let game_state = self.stored_game.read((game_id, prev_generation));
            let cell_states = unpack_game(game_state);
            /// Evolve game by 1 generation    
            let new_cell_states = evaluate_rounds(1, cell_states);
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

        /// Save the state of a game at a generation.
        fn save_game(
            ref self: ContractState, game_id: felt252, generation: felt252, packed_game: felt252
        ) {
            self.stored_game.write((game_id, generation), packed_game);
        }

        /// Save the current generation of a game.
        fn save_generation_id(ref self: ContractState, game_id: felt252, generation: felt252) {
            self.current_generation.write(game_id, generation);
        }

        /// Save a snapshot of a generation if it has not been stored yet.
        /// A snapshot is a record of the game_state upon a generation being evolved, e.g.
        ///     - Alice evolves the game to generation 10 with state: S_a.
        ///     - Bob revives a cell, keeping the generation at 10 but making the state: S_b.
        ///     - Charlie evolves the game to generation 11 with state: S_c.
        ///     Snapshot 10 is recorded with state: S_a, Alice's address, and her timestamp,
        ///     Snapshot 11 is recorded with state: S_c, Charlie's address, and his timestamp.
        ///     Bob does not own a snapshot because he did not 'evolve' the game to any state.
        fn save_snapshot(ref self: ContractState, generation: felt252, snapshot: Snapshot,) {
            let s_snapshot: Snapshot = self.snapshots.read(generation);
            let user_id: felt252 = s_snapshot.user_id.into();
            assert(
                user_id.into()
                    + s_snapshot.game_state.into()
                    + s_snapshot.timestamp.into() == 0_u256,
                'GoL2: Snapshot already exists'
            );
            self.snapshots.write(generation, snapshot);
        }

        /// Assert that a game does not exist.
        fn assert_game_does_not_exist(self: @ContractState, game_id: felt252) {
            assert(
                self.stored_game.read((game_id, 1)) + self.current_generation.read(game_id) == 0,
                'Game already exists'
            );
        }

        /// Assert that a game is valid for creation.
        fn assert_valid_new_game(self: @ContractState, game: felt252) {
            self.assert_game_does_not_exist(game);
            let game_int: u256 = game.into();
            /// @dev This is the max game size that can be create
            assert(game_int.high < (pow(2, HIGH_ARRAY_LEN.into())), 'Game size too big');
        }

        /// Create a new game.
        fn create_new_game(ref self: ContractState, game_state: felt252, user_id: ContractAddress) {
            self.save_game(game_state, 1, game_state);
            self.save_generation_id(game_state, 1);
            self.emit(GameCreated { user_id: user_id, game_id: game_state, state: game_state });
        }

        /// Get the last state of the infinite game.
        fn get_last_state(self: @ContractState) -> (felt252, felt252) {
            let generation = self.current_generation.read(INFINITE_GAME_GENESIS);
            let game_state = self.stored_game.read((INFINITE_GAME_GENESIS, generation));
            (generation, game_state)
        }

        /// Assert that a cell index is valid.
        /// @dev A cell index is valid if it is in the range [0, BOARD_SQUARED).
        fn assert_valid_cell_index(self: @ContractState, cell_index: usize) {
            assert(cell_index < BOARD_SQUARED, 'Cell index out of range');
        }

        /// Activate a cell in the infinite game if the cell is dead.
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

