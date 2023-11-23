use starknet::ContractAddress;

#[starknet::interface]
trait IGoL2<TContractState> {
    // read
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    // write 
    fn create(ref self: TContractState, game_state: felt252);
// fn evolve(ref self: TContractState, game_id: felt252);
// fn give_life_to_cell(ref self: TContractState, cell_index: felt252);

}

#[starknet::contract]
mod GoL2 {
    use array::ArrayTrait;
    use starknet::{
        get_block_timestamp, get_caller_address, get_contract_address, contract_address_const,
        ContractAddress, ContractAddressIntoFelt252, Store, storage_address_from_base_and_offset,
        StorageBaseAddress, SyscallResult, storage_read_syscall, storage_write_syscall,
        Felt252TryIntoContractAddress
    };
    use core::integer;
    use option::{Option, OptionTrait};
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use gol2::utils::{
        life_rules::{evaluate_rounds, apply_rounds, get_adjacent}, constants::{constants_component},
        math::{raise_to_power}, packing::{pack_game, unpack_game, revive_cell},
    };

    /// Constants Component
    component!(path: constants_component, storage: constants, event: ConstantsEvent);
    #[abi(embed_v0)]
    impl ConstantsImpl = constants_component::Constants<ContractState>;
    impl ConstantsInternalImpl = constants_component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        /// Game State
        stored_game: LegacyMap<(felt252, felt252), felt252>, // game_id -> generation -> state
        current_generation: LegacyMap<felt252, felt252>, // game_id -> generation
        /// Constants
        #[substorage(v0)]
        constants: constants_component::Storage,
    }

    /// Constructor
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.constants.initializer();
    /// Per old contract 
    // create_new_game(game_state=INFINITE_GAME_GENESIS, user_id=caller);
    // ERC20 initializer
    // Proxy initializer
    }

    /// External functions  
    #[external(v0)]
    impl GoL2Impl of super::IGoL2<ContractState> {
        // fn get_game_state(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
        //     self.s_games.read((game_id, generation))
        // }

        // fn get_cell_array(
        //     self: @ContractState, game_id: felt252, generation: felt252
        // ) -> Array<felt252> {
        //     /// state as int
        //     let state: u256 = self.get_game_state(game_id, generation).into();
        //     /// array to fill with cell states [0,1,0,1]
        //     let mut cell_array = array![];
        //     let mut mask: u256 = 0x1;
        //     let mut i = 0;
        //     loop {
        //         if (i > 225_u256) {
        //             break ();
        //         }
        //         if state & mask > 0 {
        //             cell_array.append(1);
        //         } else {
        //             cell_array.append(0);
        //         }

        //         mask = mask * 2;
        //         i += 1;
        //     };
        //     cell_array
        // }

        /// read
        fn view_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.stored_game.read((game_id, generation))
        }

        fn get_current_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// write 
        fn create(ref self: ContractState, game_state: felt252) {
            // * ensure_user
            assert(!get_caller_address().is_zero(), 'Caller address is zero');
            // * assert_valid_game

            // * pay 
            // * create_new_game
            self.create_new_game(game_state, get_caller_address());
        // let user_id = get_caller_address();
        // let generation = 0;
        // self.s_games.write((game_state, generation), game_state);
        // self.s_generations.write(game_state, generation);
        // self.emit(GameCreated { user_id: user_id, game_id: game_id, state: game_state, });
        }
    }


    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn pay() {}

        fn reward_user() {}

        fn ensure_user() {}

        fn evolve_game() {}

        fn save_game(
            ref self: ContractState, game_id: felt252, generation: felt252, state: felt252
        ) {
            self.stored_game.write((game_id, generation), state);
        }

        fn save_generation_id(ref self: ContractState, game_id: felt252, generation: felt252) {
            self.current_generation.write(game_id, generation);
        }

        fn assert_game_exists(self: @ContractState, game_id: felt252, generation: felt252) {
            assert(self.current_generation.read(game_id) != 0, 'Game does not exist');
            let gen_as_int: u256 = generation.into();
            let current_gen_as_int: u256 = self.current_generation.read(game_id).into();
            assert(gen_as_int <= current_gen_as_int, 'Generation does not exist');
        }

        fn assert_game_does_not_exist(self: @ContractState, game_id: felt252) {
            assert(self.current_generation.read(game_id) == 0, 'Game already exists');
            assert(self.stored_game.read((game_id, 1)) == 0, 'Game already exists');
        }

        fn get_game(self: @ContractState, game_id: felt252, generation: felt252) -> felt252 {
            self.assert_game_exists(game_id, generation);
            self.stored_game.read((game_id, generation))
        }

        fn get_generation(self: @ContractState, game_id: felt252) -> felt252 {
            self.current_generation.read(game_id)
        }

        /// Creator Mode 

        fn assert_valid_new_game(self: @ContractState, game: felt252) { //
        // assert game does not exist
        // split felt into (high, _)
        // assert high bits do not exceed 97

        // assert(game_state < 2 * *225, 'Invalid game state');
        }

        fn create_new_game(ref self: ContractState, game_state: felt252, user_id: ContractAddress) {
            self.save_game(game_state, 1, game_state);
            self.save_generation_id(game_state, 1);
            self.emit(GameCreated { user_id: user_id, game_id: game_state, state: game_state });
        }

        /// Infinite Mode

        fn get_last_state() {}

        fn assert_valid_cell_index() {}

        /// Write 

        fn activate_cell() {}
    }


    /// Events 
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameCreated: GameCreated,
        GameEvolved: GameEvolved,
        CellRevived: CellRevived,
        ConstantsEvent: constants_component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct GameCreated {
        #[key]
        user_id: ContractAddress,
        #[key]
        game_id: felt252,
        state: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct GameEvolved {
        #[key]
        user_id: ContractAddress,
        #[key]
        game_id: felt252,
        state: felt252,
        generation: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct CellRevived {
        #[key]
        user_id: ContractAddress,
        generation: felt252,
        cell_index: felt252,
        state: felt252,
    }
}

