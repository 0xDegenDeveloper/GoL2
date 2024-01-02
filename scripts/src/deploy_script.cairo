use sncast_std::{
    declare, deploy, invoke, call, DeclareResult, DeployResult, InvokeResult, CallResult, get_nonce
};
use debug::PrintTrait;

/// Command Line Script
// `sncast declare --contract-name GoL2`
// `sncast deploy --class-hash <class_hash_from_above> -c <params>`
// `sncast call --contract-address <contract_address_from_above> -f <function_name> -c <params>
// `sncast invoke`
// ``
// ``
// ``

fn main() {
    'main'.print();
//     let max_fee = 99999999999999999;
//     let salt = 0x3;

//     let declare_result = declare('GoL2', Option::Some(max_fee), Option::None);

//     let nonce = get_nonce('latest');
//     let class_hash = declare_result.class_hash;

//     let params = array!['admin'];

//     let deploy_result = deploy(
//         class_hash, params, Option::Some(salt), true, Option::Some(max_fee), Option::Some(nonce)
//     );
// // 'Deployed contract at'.print();
// deploy_result.contract_address.print();
// let invoke_nonce = get_nonce('pending');
// let invoke_result = invoke(
//     deploy_result.contract_address,
//     'put',
//     array![0x1, 0x2],
//     Option::Some(max_fee),
//     Option::Some(invoke_nonce)
// );

// 'Invoke tx hash is'.print();
// invoke_result.transaction_hash.print();

// let call_result = call(deploy_result.contract_address, 'get', array![0x1]);
// assert(call_result.data == array![0x2], *call_result.data.at(0));
}
