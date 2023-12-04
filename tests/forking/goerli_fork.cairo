use starknet::{contract_address_const, ClassHash};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash
};
use gol2::{
    contracts::gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2},
    utils::{
        math::raise_to_power,
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT
        },
    }
};
use openzeppelin::{
    access::ownable::{OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}},
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
    },
    token::erc20::{ERC20Component, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
};
use debug::PrintTrait;

/// Setup
fn deploy_contract(name: felt252) -> IGoL2Dispatcher {
    let contract = declare(name);
    let contract_address = contract.deploy(@array!['admin']).unwrap();
    IGoL2Dispatcher { contract_address }
}

#[starknet::interface]
trait IOldGol<TContractState> {
    /// Read
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn totalSupply(self: @TContractState) -> u256;
    fn decimals(self: @TContractState) -> u8;
    fn balanceOf(self: @TContractState, owner: felt252) -> u256;
    fn allowance(self: @TContractState, owner: felt252, spender: felt252) -> u256;
    fn view_game(self: @TContractState, game_id: felt252, generation: felt252) -> felt252;
    fn get_current_generation(self: @TContractState, game_id: felt252) -> felt252;
    /// Write
    fn transfer(self: @TContractState, to: felt252, value: u256);
    fn transferFrom(self: @TContractState, from: felt252, to: felt252, value: u256);
    fn approve(self: @TContractState, spender: felt252, value: u256);
    fn increaseAllowance(self: @TContractState, spender: felt252, added_value: u256);
    fn decreaseAllowance(self: @TContractState, spender: felt252, subtracted_value: u256);
    // fn init
    fn upgrade(self: @TContractState, new_contract: felt252);
    fn create(self: @TContractState, game_state: felt252);
    fn evolve(ref self: TContractState, game_id: felt252);
    fn give_life_to_cell(ref self: TContractState, cell_index: felt252);
}

// #[test]
// #[fork("GOERLI")]
// fn test_upgraded_class_hash() {
//     let old_gol_address = contract_address_const::<
//         0x06dc4bd1212e67fd05b456a34b24a060c45aad08ab95843c42af31f86c7bd093
//     >();
//     let OldGol = IOldGolDispatcher { contract_address: old_gol_address };
//     let Upgrade = IUpgradeableDispatcher { contract_address: old_gol_address };
//     let new_contract = declare('GoL2');

//     let old_hash: ClassHash = get_class_hash(OldGol.contract_address);
//     let f: felt252 = old_hash.into();
//     f.print();
//     /// Upgrade contract as og admin
//     start_prank(
//         CheatTarget::All(()),
//         contract_address_const::<
//             0x020f8c63faff27a0c5fe8a25dc1635c40c971bf67b8c35c6089a998649dfdfcb
//         >()
//     );
//     let new_contract_class: ClassHash = new_contract.class_hash;
//     let f: felt252 = new_contract_class.into();
//     f.print();

//     Upgrade.upgrade(new_contract_class);
//     stop_prank(CheatTarget::All(()));

//     let current_hash = get_class_hash(OldGol.contract_address);
//     let f: felt252 = current_hash.into();
//     f.print();
// // assert(old_hash != new_hash, 'class hash should be different');
// // assert(get_class_hash(old_gol_address) == new_contract_class, 'class hash upgraded wrong');
// }

#[test]
#[fork("GOERLI")]
fn test_upgraded_state() {
    let user = contract_address_const::<'user'>();
    let old_gol_address = contract_address_const::<
        0x06dc4bd1212e67fd05b456a34b24a060c45aad08ab95843c42af31f86c7bd093
    >();
    /// Old contract
    let OldGol = IOldGolDispatcher { contract_address: old_gol_address };
    let OldUpgrade = IUpgradeableDispatcher { contract_address: old_gol_address };
    let old_hash = get_class_hash(OldGol.contract_address);

    /// Give user some tokens
    let mut i = 100;
    start_prank(CheatTarget::All(()), user);
    loop {
        if i == 0 {
            break ();
        }
        OldGol.evolve(INFINITE_GAME_GENESIS);
        i -= 1;
    };

    /// Set fake allowances
    let user2 = contract_address_const::<'user2'>();
    let fake_allowance = 100;
    OldGol.approve(user2.into(), fake_allowance);
    stop_prank(CheatTarget::All(()));

    /// ERC20
    let old_name = OldGol.name();
    let old_symbol = OldGol.symbol();
    let old_total_supply = OldGol.totalSupply();
    let old_decimals = OldGol.decimals();
    let old_balance = OldGol.balanceOf(user.into());
    let old_allowance = OldGol.allowance(user.into(), user2.into()); // owner, spender
    /// Game
    let old_generation = OldGol.get_current_generation(INFINITE_GAME_GENESIS);
    let old_view_game = OldGol.view_game(INFINITE_GAME_GENESIS, old_generation);

    /// Upgrade contract 
    let admin = contract_address_const::<
        0x020f8c63faff27a0c5fe8a25dc1635c40c971bf67b8c35c6089a998649dfdfcb
    >();
    start_prank(CheatTarget::All(()), admin);
    let new_contract_hash_felt: felt252 = declare('GoL2').class_hash.into();
    OldGol.upgrade(new_contract_hash_felt);
    // OldUpgrade.upgrade(new_contract_hash_felt);
    stop_prank(CheatTarget::All(()));

    let new_hash = get_class_hash(OldUpgrade.contract_address);

    let f: felt252 = old_hash.into();
    f.print();
    let f: felt252 = new_hash.into();
    f.print();

    let NewGol = IGoL2Dispatcher { contract_address: old_gol_address };
    let NewERC20 = ERC20ABIDispatcher { contract_address: old_gol_address };

    /// ERC20
    let new_name = NewERC20.name();
    let new_symbol = NewERC20.symbol();
// let new_total_supply = NewERC20.total_supply();
// let new_decimals = NewERC20.decimals();
// let new_balance = NewERC20.balance_of(user.into());
// let new_allowance = NewERC20.allowance(user.into(), user2.into());
/// Game
// let new_generation = NewGol.get_current_generation(INFINITE_GAME_GENESIS);
// let new_view_game = NewGol.view_game(INFINITE_GAME_GENESIS, new_generation);
// assert(old_name == new_name, 'name should be the same');
// assert(old_symbol == new_symbol, 'symbol should be the same');
// assert(old_total_supply == new_total_supply, 'total supply should be the same');
// assert(old_decimals == new_decimals, 'decimals should be the same');
// assert(old_balance == new_balance, 'balance should be the same');
// assert(old_generation == new_generation, 'generation should be the same');
// assert(old_view_game == new_view_game, 'view game should be the same');
// assert(old_allowance == new_allowance, 'allowance should be the same');
}

