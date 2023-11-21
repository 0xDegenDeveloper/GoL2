use starknet::ContractAddress;

#[starknet::interface]
trait IGoL2<TContractState> {
    /// read
    fn get_game_state(self: @TContractState, game_id: felt252, generation: u256) -> felt252;
    fn get_cell_array(self: @TContractState, game_id: felt252, generation: u256) -> Array<felt252>;
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
    use gol2::utils::constants::constants_component;

    /// Constants Component
    component!(path: constants_component, storage: constants, event: ConstantsEvent);
    #[abi(embed_v0)]
    impl ConstantsImpl = constants_component::Constants<ContractState>;
    impl ConstantsInternalImpl = constants_component::InternalImpl<ContractState>;

    /// Constructor
    #[constructor]
    fn constructor(ref self: ContractState, game_state: felt252) {
        self.constants.initializer();
        self.s_games.write((game_state, 0), game_state);
    }

    /// External functions  
    #[external(v0)]
    impl GoL2Impl of super::IGoL2<ContractState> {
        // fn DIM(self: @ContractState) -> u8 {
        //     self.s_DIM.read()
        // }

        fn get_game_state(self: @ContractState, game_id: felt252, generation: u256) -> felt252 {
            self.s_games.read((game_id, generation))
        }

        fn get_cell_array(
            self: @ContractState, game_id: felt252, generation: u256
        ) -> Array<felt252> {
            /// state as int
            let state: u256 = self.get_game_state(game_id, generation).into();
            /// array to fill with cell states [0,1,0,1]
            let mut cell_array = array![];
            let mut mask: u256 = 0x1;
            let mut i = 0;
            loop {
                if (i > 225_u256) {
                    break ();
                }
                if state & mask > 0 {
                    cell_array.append(1);
                } else {
                    cell_array.append(0);
                }

                mask = mask * 2;
                i += 1;
            };
            cell_array
        }
    }


    #[storage]
    struct Storage {
        /// Game Board
        // grid
        // s_DIM: u8, // 15
        s_FIRST_ROW_INDEX: u8, // 0
        s_LAST_ROW_INDEX: u8, // 14
        s_FIRST_COL_INDEX: u8, // 0 
        s_LAST_COL_INDEX: u8, // 14
        // cells
        s_LAST_ROW_CELL_INDEX: u8, // 210 (dim^2 - dim)
        s_LAST_COL_CELL_INDEX: u8, // 14 
        // game states ? 
        s_games: LegacyMap<(felt252, u256), felt252>, // (game_id, generation) -> state
        s_generations: LegacyMap<felt252, u256>, // game_id -> generation
        #[substorage(v0)]
        constants: constants_component::Storage,
    }


    #[derive(Serde, Copy, Drop, starknet::Store)]
    struct GameState {
        generation: u256,
        state: felt252, // felt representation of the game state (felt252 -> u256 -> bit array for cell map) <0,0,0,0,g,a,m,e,s,t,a,t,e>
    }

    trait GameStateTrait {
        fn into_cell_array(self: GameState) -> Array<bool>;
    }


    impl GameStateImpl of GameStateTrait {
        fn into_cell_array(self: GameState) -> Array<bool> {
            let state_as_int: u256 = self.state.into();
            let bit = state_as_int > 0x1;
            let mut cell_array = array![];
            // let state_as_int: u256 = state_as_int.into();
            cell_array
        }
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        EventStruct: EventStruct,
        ConstantsEvent: constants_component::Event
    }

    #[derive(Drop, starknet::Event)]
    struct EventStruct {
        #[key]
        x: ContractAddress,
        y: bool,
    }
}
