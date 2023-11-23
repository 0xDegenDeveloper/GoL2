use starknet::ContractAddress;

#[starknet::interface]
trait IGoL2<TContractState> {
    // Constants 
    fn DIM(self: @TContractState) -> u32;
    fn FIRST_ROW_INDEX(self: @TContractState) -> u32; //0
    fn LAST_ROW_INDEX(self: @TContractState) -> u32; //14
    fn LAST_ROW_CELL_INDEX(self: @TContractState) -> u32; //210 (DIM^2 - DIM) (bottom left corner)
    fn FIRST_COL_INDEX(self: @TContractState) -> u32; //0
    fn LAST_COL_INDEX(self: @TContractState) -> u32; //14
    fn LAST_COL_CELL_INDEX(self: @TContractState) -> u32; //14 (DIM - 1) (top right corner)
    fn SHIFT(self: @TContractState) -> u256; //2^128
    fn LOW_ARRAY_LEN(self: @TContractState) -> u32; //128
    fn HIGH_ARRAY_LEN(self: @TContractState) -> u32; //97 

    /// ****************** ///

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
        life_rules::{evaluate_rounds, apply_rounds, get_adjacent}, math::{raise_to_power},
        packing::{pack_game, unpack_game, revive_cell},
    };

    /// Constants Component
    // component!(path: constants_component, storage: constants, event: ConstantsEvent);
    // #[abi(embed_v0)]
    // impl ConstantsImpl = constants_component::Constants<ContractState>;
    // impl ConstantsInternalImpl = constants_component::InternalImpl<ContractState>;

    const DIM: u32 = 15;
    const FIRST_ROW_INDEX: u32 = 0;
    const LAST_ROW_INDEX: u32 = 14; // DIM - 1
    const LAST_ROW_CELL_INDEX: u32 = 210; // DIM^2 - 1
    const FIRST_COL_INDEX: u32 = 0;
    const LAST_COL_INDEX: u32 = 14;
    const LAST_COL_CELL_INDEX: u32 = 14;
    const SHIFT: u256 = 0x100000000000000000000000000000000; // 2^128
    const LOW_ARRAY_LEN: u32 = 128;
    const HIGH_ARRAY_LEN: u32 = 97;


    #[storage]
    struct Storage {
        /// Game State
        stored_game: LegacyMap<(felt252, felt252), felt252>, // game_id -> generation -> state
        current_generation: LegacyMap<felt252, felt252>, // game_id -> generation
    /// Constants
    // #[substorage(v0)]
    // constants: constants_component::Storage,
    }

    /// Constructor
    #[constructor]
    fn constructor(ref self: ContractState) { // self.constants.initializer();
    /// Per old contract 
    // create_new_game(game_state=INFINITE_GAME_GENESIS, user_id=caller);
    // ERC20 initializer
    // Proxy initializer
    }

    /// External functions  
    #[external(v0)]
    impl GoL2Impl of super::IGoL2<ContractState> {
        /// Constants
        fn DIM(self: @ContractState) -> u32 {
            DIM
        }
        fn FIRST_ROW_INDEX(self: @ContractState) -> u32 {
            FIRST_ROW_INDEX
        }
        fn LAST_ROW_INDEX(self: @ContractState) -> u32 {
            LAST_ROW_INDEX
        }
        fn LAST_ROW_CELL_INDEX(self: @ContractState) -> u32 {
            LAST_ROW_CELL_INDEX
        }
        fn FIRST_COL_INDEX(self: @ContractState) -> u32 {
            FIRST_COL_INDEX
        }
        fn LAST_COL_INDEX(self: @ContractState) -> u32 {
            LAST_COL_INDEX
        }
        fn LAST_COL_CELL_INDEX(self: @ContractState) -> u32 {
            LAST_COL_CELL_INDEX
        }
        fn SHIFT(self: @ContractState) -> u256 {
            SHIFT
        }
        fn LOW_ARRAY_LEN(self: @ContractState) -> u32 {
            LOW_ARRAY_LEN
        }
        fn HIGH_ARRAY_LEN(self: @ContractState) -> u32 {
            HIGH_ARRAY_LEN
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
    // ConstantsEvent: constants_component::Event,
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

