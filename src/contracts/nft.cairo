use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IGoLNFT<TContractState> {
    /// Read 
    fn get_whitelist_root(self: @TContractState) -> felt252;
    /// Write 
    fn set_whitelist_root(ref self: TContractState, root: felt252);
}


#[starknet::contract]
mod GoL2NFT {
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ClassHash,
        replace_class_syscall, contract_address_try_from_felt252
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, introspection::src5::SRC5Component,
        upgrades::{UpgradeableComponent, interface::IUpgradeable},
        token::erc721::{ERC721Component, interface::IERC721Metadata},
    };
    use gol2::utils::{
        life_rules::evaluate_rounds, math::raise_to_power,
        packing::{pack_game, unpack_game, revive_cell},
        constants::{
            INFINITE_GAME_GENESIS, DIM, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT,
            INITIAL_ADMIN
        }
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);


    /// Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    /// ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    /// SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;


    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        whitelist_root: felt252
    ) {
        self.ownable.initializer(owner);
        self.erc721.initializer(name, symbol);
        self.whitelist_root.write(whitelist_root);
    }


    #[storage]
    struct Storage {
        /// Merkle root for whitelist mints 
        whitelist_root: felt252,
        /// Component Storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        WhitelistRootChanged: WhitelistRootChanged,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct WhitelistRootChanged {
        old_root: felt252,
        new_roow: felt252,
    }

    /// External Functions
    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[external(v0)]
    impl ERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc721.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc721.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 { //
            // todo: on chain metadata + svg images
            token_id.try_into().unwrap()
        }
    }

    #[external(v0)]
    impl GoL2NFTImpl of super::IGoLNFT<ContractState> {
        /// Read
        fn get_whitelist_root(self: @ContractState) -> felt252 {
            self.whitelist_root.read()
        }

        /// Write
        fn set_whitelist_root(ref self: ContractState, root: felt252) {
            self.ownable.assert_only_owner();
            self.whitelist_root.write(root);
        }
    }
/// Internal Functions
// #[generate_trait]
// impl HelperImpl of HelperTrait {
//     fn pay(ref self: ContractState, user: ContractAddress, credit_requirement: felt252) {
//         self.erc20._burn(user, credit_requirement.into());
//     }

//     fn reward_user(ref self: ContractState, user: ContractAddress) {
//         self.erc20._mint(user, 1);
//     }

//     fn ensure_user(self: @ContractState) -> ContractAddress {
//         let caller = get_caller_address();
//         assert(caller.is_non_zero(), 'User not authenticated');
//         caller
//     }

//     fn evolve_game(
//         ref self: ContractState, game_id: felt252, user: ContractAddress
//     ) -> (felt252, felt252) {
//         let prev_generation = self.current_generation.read(game_id);

//         self.assert_game_exists(game_id, prev_generation);

//         let new_generation = prev_generation + 1;
//         /// Unpack game 
//         let game_state = self.stored_game.read((game_id, prev_generation));
//         let cells = unpack_game(game_state);
//         /// Evolve game by # of generations     
//         let new_cell_states = evaluate_rounds(1, cells);
//         let packed_game = pack_game(new_cell_states);

//         self
//             .emit(
//                 GameEvolved {
//                     user_id: user,
//                     game_id: game_id,
//                     generation: new_generation,
//                     state: packed_game
//                 }
//             );
//         (new_generation, packed_game)
//     }

//     fn save_game(
//         ref self: ContractState, game_id: felt252, generation: felt252, packed_game: felt252
//     ) {
//         self.stored_game.write((game_id, generation), packed_game);
//     }

//     fn save_generation_id(ref self: ContractState, game_id: felt252, generation: felt252) {
//         self.current_generation.write(game_id, generation);
//     }

//     fn assert_game_exists(self: @ContractState, game_id: felt252, generation: felt252) {
//         assert(self.current_generation.read(game_id) != 0, 'Game has not been started');
//         let current_generation: u256 = self.current_generation.read(game_id).into();
//         assert(generation.into() <= current_generation, 'Generation does not exist yet');
//     }

//     fn assert_game_does_not_exist(self: @ContractState, game_id: felt252) {
//         assert(
//             self.stored_game.read((game_id, 1)) + self.current_generation.read(game_id) == 0,
//             'Game already exists'
//         );
//     }

//     fn get_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
//         self.assert_game_exists(game_id, generation);
//         self.stored_game.read((game_id, generation))
//     }

//     fn get_generation(self: @ContractState, game_id: felt252) -> felt252 {
//         self.current_generation.read(game_id)
//     }

//     /// Creator Mode
//     fn assert_valid_new_game(self: @ContractState, game: felt252) {
//         self.assert_game_does_not_exist(game);
//         /// max game => 225 bits all 1s => 2^225 - 1
//         assert(game.into() < (raise_to_power(2, (DIM * DIM).into())), 'Game size too big');
//     }

//     fn create_new_game(ref self: ContractState, game_state: felt252, user_id: ContractAddress) {
//         self.save_game(game_state, 1, game_state);
//         self.save_generation_id(game_state, 1);
//         self.emit(GameCreated { user_id: user_id, game_id: game_state, state: game_state });
//     }

//     /// Infinite Mode
//     fn get_last_state(self: @ContractState) -> (felt252, felt252) {
//         let generation = self.current_generation.read(INFINITE_GAME_GENESIS);
//         let game_state = self.stored_game.read((INFINITE_GAME_GENESIS, generation));
//         (generation, game_state)
//     }

//     fn assert_valid_cell_index(self: @ContractState, cell_index: felt252) {
//         assert(cell_index.try_into().unwrap() < DIM * DIM, 'Cell index out of range');
//     }

//     fn activate_cell(
//         ref self: ContractState,
//         generation: felt252,
//         caller: ContractAddress,
//         cell_index: felt252,
//         current_state: felt252
//     ) {
//         self.assert_valid_cell_index(cell_index);
//         let packed_game = revive_cell(cell_index, current_state);

//         assert(packed_game != current_state, 'No changes made to game');

//         /// Generation does not increment when cell is activated
//         self.save_game(INFINITE_GAME_GENESIS, generation, packed_game);

//         self
//             .emit(
//                 CellRevived {
//                     user_id: caller,
//                     generation: generation,
//                     cell_index: cell_index,
//                     state: packed_game
//                 }
//             );
//     }
// }
}

