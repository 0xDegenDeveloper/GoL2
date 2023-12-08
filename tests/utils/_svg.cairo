use gol2::utils::{
    constants::{
        DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX,
        LAST_COL_CELL_INDEX, LAST_ROW_INDEX
    },
    packing::{unpack_game, pack_game}, svg::{make_svg_array}
};

use core::byte_array::{ByteArrayTrait};
// use core::to_byte_array::{FormatAsByteArrayTrait::format_as_byte_array};
use core::bytes_31::bytes31_try_from_felt252;
use debug::{PrintTrait, ArrayGenericPrintImpl};
// use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};
use zeroable::Zeroable;
use alexandria_ascii::ToAsciiTrait;


#[test]
fn test_make_svg_array() {
    let mut svg_array = make_svg_array(3);
    svg_array.print();
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
}

