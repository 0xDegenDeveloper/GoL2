use gol2::utils::{packing::{unpack_game}, svg::make_svg_array};

use alexandria_ascii::ToAsciiTrait;
use alexandria_math::pow;

use debug::PrintTrait;

/// todo: can probably rm 
/// Breaks a felt252 into an array of u8s (bytes)
fn felt_to_u8_array(f: felt252) -> Array<u8> {
    let f_int: u256 = f.into();
    assert(f_int.high < core::integer::BoundedInt::max(), 'Converting felt is > bytes31');
    let mut u8_array: Array<u8> = array![];
    let mut bytes: u8 = 1; /// how many bytes does the felt span ?

    let is_big = f_int.high != 0;

    /// Which part of the felt are we counting the bytes for?
    let part = if is_big {
        f_int.high
    } else {
        f_int.low
    };

    loop {
        /// If part fills all 16 bytes, this prevents u128_mul_overflow in pow()
        if bytes == 15 {
            bytes += 1;
            break;
        }
        if part < pow(2, bytes.into() * 8) {
            break;
        }
        bytes += 1;
    };

    /// Big felts have all lower 16 bytes filled
    if is_big {
        bytes += 16;
    }

    /// Append each byte of the felt to the array
    let mut b31: bytes31 = f.try_into().unwrap();
    let mut i: usize = 0;
    loop {
        if i == bytes.into() {
            break;
        }
        let byte = b31.at(bytes.into() - 1 - i); // reverses byte order
        u8_array.append(byte);

        i += 1;
    };
    u8_array
}

/// todo: can probably rm
/// Appends a felt252 to an array of u8s (bytes)
fn append_array(ref array: Array<u8>, to_add: felt252) {
    let mut u8_array = felt_to_u8_array(to_add);
    loop {
        match u8_array.pop_front() {
            Option::Some(el) => { array.append(el); },
            Option::None => { break; }
        }
    };
}

/// Generates a json url for a token
fn make_uri_array(token_id: u256, gamestate: felt252, generation: felt252) -> Array<felt252> {
    let generation_int: u256 = generation.into();
    let gamestate_int: u256 = gamestate.into();

    /// Url prefix
    let mut uri: Array<felt252> = array!['data:application/json,{'];
    /// Name todo: token_id|generation|gamestate
    uri.append('"name":"GoL2%20%23');
    if token_id.high != 0 {
        uri.append(token_id.high.to_ascii());
    }
    uri.append(token_id.low.to_ascii());
    /// Description
    uri.append('","description":"Snapshot');
    uri.append('%20of%20GoL2%20Game');
    uri.append('%20at%20generation%20');
    if generation_int.high != 0 {
        let mut generation_ascii_array = generation_int.to_ascii();
        loop {
            match generation_ascii_array.pop_front() {
                Option::Some(el) => { uri.append(el); },
                Option::None => { break; }
            }
        };
    } else {
        uri.append(generation_int.low.to_ascii());
    }
    /// Image
    uri.append('","image":"');
    let mut image_path = make_svg_array(gamestate);
    loop {
        match image_path.pop_front() {
            Option::Some(el) => { uri.append(el); },
            Option::None => { break; }
        }
    };
    /// External url
    uri.append('","external_url":');
    uri.append('"https://gol2.io",'); // todo: specific url for token ? 
    /// Attributes
    uri.append('"attributes":');
    let mut attributes = make_attributes(gamestate, generation);
    loop {
        match attributes.pop_front() {
            Option::Some(el) => { uri.append(el); },
            Option::None => { break; }
        }
    };
    uri.append('}');
    uri
}

fn make_attributes(gamestate: felt252, generation: felt252) -> Array<felt252> {
    let generation_int: u256 = generation.into();
    let mut attributes: Array<felt252> = array!['['];
    /// Generation
    attributes.append('{"trait_type":"Generation",');
    attributes.append('"value":"');
    if generation_int.high != 0 {
        let mut generation_ascii_array = generation_int.to_ascii();
        loop {
            match generation_ascii_array.pop_front() {
                Option::Some(el) => { attributes.append(el); },
                Option::None => { break; }
            }
        };
    } else {
        attributes.append(generation_int.low.to_ascii());
    }

    attributes.append('"},');
    /// Cell count
    let mut cell_array = unpack_game(gamestate);
    let mut alive: usize = 0;
    loop {
        match cell_array.pop_front() {
            Option::Some(el) => { if el == 1 {
                alive += 1;
            } },
            Option::None => { break; }
        }
    };
    attributes.append('{"trait_type":"Cell%20Count",');
    attributes.append('"value":"');
    attributes.append(alive.to_ascii());
    attributes.append('"},');
    /// Game mode 
    attributes.append('{"trait_type":"Game%20Mode",');
    attributes.append('"value":"Infinite"}]');
    attributes
}

