use gol2::utils::{
    constants::{
        DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX,
        LAST_COL_CELL_INDEX, LAST_ROW_INDEX
    },
    packing::{unpack_game, pack_game}, svg::{make_svg_array},
    uri::{make_uri_array, felt_to_u8_array, append_array}
};

use core::byte_array::{ByteArrayTrait};
// use core::to_byte_array::{FormatAsByteArrayTrait::format_as_byte_array};
use core::bytes_31::bytes31_try_from_felt252;
use debug::{PrintTrait};
// use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};
use zeroable::Zeroable;
use alexandria_ascii::ToAsciiTrait;

#[test]
#[available_gas(20000000000000)]
fn test_svg_to_base64() {
    let acorn = 39132555273291485155644251043342963441664;
    let evo = 0x100030006e0000000000000000000000000000;
    // let mut svg_array = make_svg_array(0x1);
    let mut svg_array = make_uri_array(12345678912345678999, 'gamestate', 12345678912345678999);
    // let mut x: Array<u8> = array![];
    loop {
        match svg_array.pop_front() {
            Option::Some(byte) => { byte.print(); },
            Option::None => { break; },
        }
    };
}
// #[test]
// fn test_make_svg_array() {
// let mut svg_array = make_uri(123, 0x1, 123);
// svg_array.print();
// let x: ByteArray = 'testing'.format_as_byte_array(64);
// let b = bytes31_try_from_felt252('test').unwrap();
// let bb: u8 = b.into();
// let encoded = Base64Encoder::encode(array![bb]);
// let mut i = svg_array.len();
// i.print();
// loop {
//     let el = svg_array.pop_front();
//     match el { 
//         Option::Some(el) => {
//             let str: felt252 = el;
//             str.print();
//         },
//         Option::None => { break; }
//     }
// };
// }


