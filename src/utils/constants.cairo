const INFINITE_GAME_GENESIS: felt252 = 39132555273291485155644251043342963441664;
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

const CREATE_CREDIT_REQUIREMENT: felt252 = 10;
const GIVE_LIFE_CREDIT_REQUIREMENT: felt252 = 1;
// #[starknet::interface]
// trait IConstants<TContractState> {
//     fn DIM(self: @TContractState) -> u8;
//     fn FIRST_ROW_INDEX(self: @TContractState) -> u8; //0
//     fn LAST_ROW_INDEX(self: @TContractState) -> u8; //14
//     fn LAST_ROW_CELL_INDEX(self: @TContractState) -> u8; //210 (DIM^2 - DIM) (bottom left corner)
//     fn FIRST_COL_INDEX(self: @TContractState) -> u8; //0
//     fn LAST_COL_INDEX(self: @TContractState) -> u8; //14
//     fn LAST_COL_CELL_INDEX(self: @TContractState) -> u8; //14 (DIM - 1) (top right corner)
//     fn SHIFT(self: @TContractState) -> u256; //2^128
//     fn LOW_ARRAY_LEN(self: @TContractState) -> u8; //128
//     fn HIGH_ARRAY_LEN(self: @TContractState) -> u8; //97 
// }

// #[starknet::component]
// mod constants_component {
//     use starknet::{ContractAddress, get_caller_address};
//     use gol2::utils::math::raise_to_power;

//     #[storage]
//     struct Storage {
//         s_DIM: u8,
//         s_FIRST_ROW_INDEX: u8, //0
//         s_LAST_ROW_INDEX: u8, //14
//         s_LAST_ROW_CELL_INDEX: u8, //210 (DIM^2 - DIM) (bottom left corner)
//         s_FIRST_COL_INDEX: u8, //0
//         s_LAST_COL_INDEX: u8, //14
//         s_LAST_COL_CELL_INDEX: u8, //14 (DIM - 1) (top right corner)
//         s_SHIFT: u256, //2^128
//         s_LOW_ARRAY_LEN: u8, //128
//         s_HIGH_ARRAY_LEN: u8, //97
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     enum Event {
//         ConstantsInitialized: ConstantsInitialized
//     }

//     /// needed ? 
//     #[derive(Drop, starknet::Event)]
//     struct ConstantsInitialized {
//         DIM: u8,
//     }

//     #[embeddable_as(Constants)]
//     impl ConstantsImpl<
//         TContractState, +HasComponent<TContractState>
//     > of super::IConstants<ComponentState<TContractState>> {
//         // read
//         fn DIM(self: @ComponentState<TContractState>) -> u8 {
//             self.s_DIM.read()
//         }

//         fn FIRST_ROW_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_FIRST_ROW_INDEX.read()
//         }

//         fn LAST_ROW_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_LAST_ROW_INDEX.read()
//         }

//         fn LAST_ROW_CELL_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_LAST_ROW_CELL_INDEX.read()
//         }

//         fn FIRST_COL_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_FIRST_COL_INDEX.read()
//         }

//         fn LAST_COL_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_LAST_COL_INDEX.read()
//         }

//         fn LAST_COL_CELL_INDEX(self: @ComponentState<TContractState>) -> u8 {
//             self.s_LAST_COL_CELL_INDEX.read()
//         }

//         fn SHIFT(self: @ComponentState<TContractState>) -> u256 {
//             self.s_SHIFT.read()
//         }

//         fn LOW_ARRAY_LEN(self: @ComponentState<TContractState>) -> u8 {
//             self.s_LOW_ARRAY_LEN.read()
//         }

//         fn HIGH_ARRAY_LEN(self: @ComponentState<TContractState>) -> u8 {
//             self.s_HIGH_ARRAY_LEN.read()
//         }
//     }

//     #[generate_trait]
//     impl InternalImpl<
//         TContractState, +HasComponent<TContractState>
//     > of InternalTrait<TContractState> {
//         fn initializer(ref self: ComponentState<TContractState>) {
//             self.s_DIM.write(15);
//             self.s_FIRST_ROW_INDEX.write(0);
//             self.s_LAST_ROW_INDEX.write(14);
//             self.s_LAST_ROW_CELL_INDEX.write(210);
//             self.s_FIRST_COL_INDEX.write(0);
//             self.s_LAST_COL_INDEX.write(14);
//             self.s_LAST_COL_CELL_INDEX.write(14);
//             let shift = raise_to_power(2, 128);
//             assert(shift == 0x100000000000000000000000000000000, 'Invalid 2^128');
//             self.s_SHIFT.write(shift); //2^128
//             self.s_LOW_ARRAY_LEN.write(128);
//             self.s_HIGH_ARRAY_LEN.write(97);
//         // self.emit(ConstantsInitialized { DIM: 15, x: x });
//         }
//     }
// }


