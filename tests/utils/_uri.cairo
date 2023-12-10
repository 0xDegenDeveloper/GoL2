use gol2::utils::{
    constants::{
        DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX,
        LAST_COL_CELL_INDEX, LAST_ROW_INDEX
    },
    packing::{unpack_game, pack_game}, svg::{make_svg_array}, uri::{make_uri}
};

use core::byte_array::{ByteArrayTrait};
// use core::to_byte_array::{FormatAsByteArrayTrait::format_as_byte_array};
use core::bytes_31::bytes31_try_from_felt252;
use debug::{PrintTrait, ArrayGenericPrintImpl};
// use alexandria_encoding::base64::{Base64Encoder, Base64Decoder, Base64UrlEncoder, Base64UrlDecoder};
use zeroable::Zeroable;
use alexandria_ascii::ToAsciiTrait;


#[test]
#[available_gas(20000000000)]
fn test_make_uri_array() {
    let mut x = make_uri(1234, 0x1, 1234);
    loop {
        match x.pop_front() {
            Option::Some(el) => { el.print(); },
            Option::None => { break; }
        }
    };
// let mut i = 0;
// loop {
//     match x.at(i) {
//         Option::Some(el) => {
//             el.print();
//             i += 1;
//         },
//         Option::None => { break; }
//     }
// };
}
