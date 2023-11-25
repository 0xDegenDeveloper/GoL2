use starknet::ContractAddress;

#[starknet::interface]
trait IGoL2<TContractState> {
    // read
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    // write 
    fn create(ref self: TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: felt252);
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
        life_rules::{evaluate_rounds, apply_rules, get_adjacent}, math::{raise_to_power},
        packing::{pack_game, unpack_game, revive_cell},
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, SHIFT, LOW_ARRAY_LEN,
            HIGH_ARRAY_LEN, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT
        }
    };

    #[storage]
    struct Storage {
        /// Game State
        stored_game: LegacyMap<(felt252, felt252), felt252>, // game_id -> generation -> state
        current_generation: LegacyMap<felt252, felt252>, // game_id -> generation
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

        /// done
        fn evolve(ref self: ContractState, game_id: felt252) {
            let caller = self.ensure_user();
            let (generation, game) = self.evolve_game(game_id, caller);
            self.save_game(game_id, generation, game);
            self.save_generation_id(game_id, generation);
            self.reward_user(caller);
        }

        /// done
        fn give_life_to_cell(ref self: ContractState, cell_index: felt252) {
            let caller = self.ensure_user();
            let (generation, current_game_state) = self.get_last_state();
            self.assert_valid_cell_index(cell_index);
            self.pay(caller, GIVE_LIFE_CREDIT_REQUIREMENT);
            self.activate_cell(generation, caller, cell_index, current_game_state)
        }
    }


    #[generate_trait]
    impl HelperImpl of HelperTrait {
        /// todo 
        fn pay(self: @ContractState, user: ContractAddress, credit_requirement: felt252) { ///
        /// ERC20._burn(user, credit_requirement_u256);
        }

        /// todo 
        fn reward_user(self: @ContractState, user: ContractAddress) { ///
        /// ERC20._mint(user, 1_u256);
        }

        /// done
        fn ensure_user(self: @ContractState) -> ContractAddress {
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'User not authenticated');
            caller
        }

        /// todo 
        fn evolve_game(
            ref self: ContractState, game_id: felt252, user: ContractAddress
        ) -> (felt252, felt252) {
            let generations = 1;
            let prev_generation = self.current_generation.read(game_id);

            self.assert_game_exists(game_id, prev_generation);

            let new_generation = prev_generation + generations;
            /// Unpack game 
            let game_state = self.stored_game.read((game_id, prev_generation));
            let cells = unpack_game(game_state);
            /// Evolve game by # of generations     
            let new_cell_states = array!['todo']; //evaluate_rounds(generations, cells);
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

        /// done
        fn save_game(
            ref self: ContractState, game_id: felt252, generation: felt252, packed_game: felt252
        ) {
            self.stored_game.write((game_id, generation), packed_game);
        }

        /// done
        fn save_generation_id(ref self: ContractState, game_id: felt252, generation: felt252) {
            self.current_generation.write(game_id, generation);
        }

        /// done
        fn assert_game_exists(self: @ContractState, game_id: felt252, generation: felt252) {
            assert(self.current_generation.read(game_id) != 0, 'Game does not exist');
            let current_generation: u256 = self.current_generation.read(game_id).into();
            assert(generation.into() <= current_generation, 'Generation does not exist');
        }

        /// done 
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

        /// * done (check this against div_mod in og)
        fn assert_valid_new_game(self: @ContractState, game: felt252) { //
            self.assert_game_does_not_exist(game);
            let game_as_int: u256 = game.into();
            let high = game_as_int.high;

            assert(
                game_as_int < raise_to_power(2, (DIM * DIM).into()), 'Invalid game'
            ); /// max game is 225 bits all 1s => 2^225 - 1

            assert(
                high.into() < raise_to_power(2, HIGH_ARRAY_LEN.into()), 'Invalid game2'
            ); /// max game (high bits) is 97 bits all 1s => 2^97 - 1
            assert(
                game.into() < (raise_to_power(2, (DIM * DIM).into())), 'Invalid game3'
            ); /// max game is 225 bits all 1s => 2^225 - 1
        }

        /// done
        fn create_new_game(ref self: ContractState, game_state: felt252, user_id: ContractAddress) {
            self.save_game(game_state, 1, game_state);
            self.save_generation_id(game_state, 1);
            self.emit(GameCreated { user_id: user_id, game_id: game_state, state: game_state });
        }

        /// Infinite Mode

        /// done
        fn get_last_state(self: @ContractState) -> (felt252, felt252) {
            let generation = self.current_generation.read(INFINITE_GAME_GENESIS);
            let game_id = self.stored_game.read((INFINITE_GAME_GENESIS, generation));
            (generation, game_id)
        }

        /// done
        fn assert_valid_cell_index(self: @ContractState, cell_index: felt252) {
            assert(cell_index.try_into().unwrap() < DIM * DIM, 'Cell index out of range');
        }

        /// Write 
        fn activate_cell(
            ref self: ContractState,
            generation: felt252,
            caller: ContractAddress,
            cell_index: felt252,
            current_state: felt252
        ) {
            self.assert_valid_cell_index(cell_index);
            let packed_game = revive_cell(cell_index, current_state);

            assert(packed_game != current_state, 'No changes made to game');

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


    /// Events 
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameCreated: GameCreated,
        GameEvolved: GameEvolved,
        CellRevived: CellRevived,
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

