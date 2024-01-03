use gol2::utils::{packing::{unpack_game}, svg::make_svg_array};

use alexandria_ascii::ToAsciiTrait;
use alexandria_math::pow;

use debug::PrintTrait;

/// Create a JSON URL for a token.
/// @dev URI special chars are encoded like so:
/// (space) -> %20, # -> %23
fn make_uri_array(
    token_id: u256, gamestate: felt252, cell_array: Array<felt252>, copies: u256, timestamp: u64
) -> Array<felt252> {
    let gamestate_int: u256 = gamestate.into();

    /// Url prefix
    let mut uri: Array<felt252> = array!['data:application/json,{'];
    uri.append('"name":"GoL2%20%23');
    if token_id.high != 0 {
        uri.append(token_id.high.to_ascii());
    }
    uri.append(token_id.low.to_ascii());
    /// Description
    uri.append('","description":"Snapshot');
    uri.append('%20of%20GoL2%20Game');
    uri.append('%20at%20Generation%20%23');
    if token_id.high == 0 {
        uri.append(token_id.low.to_ascii());
    } else {
        let mut generation_ascii_array = token_id.to_ascii();
        loop {
            match generation_ascii_array.pop_front() {
                Option::Some(el) => { uri.append(el); },
                Option::None => { break; }
            }
        };
    }
    /// Image
    uri.append('","image":"');
    let (mut image_path, alive_count) = make_svg_array(cell_array);
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
    make_attributes(ref uri, alive_count, token_id, copies, timestamp);
    uri.append('}');
    uri
}

/// Add the attributes to the token URI
fn make_attributes(
    ref uri: Array<felt252>, alive: u32, token_id: u256, copies: u256, timestamp: u64
) {
    uri.append('"attributes": [');
    /// Game Mode 
    uri.append('{"trait_type":"Game%20Mode",');
    uri.append('"value":"Infinite"},');
    /// Timestamp 
    uri.append('{"trait_type":"Timestamp",');
    uri.append('"value":"');
    uri.append(timestamp.to_ascii());
    /// Cell Count
    uri.append('"},{"trait_type":');
    uri.append('"Cell%20Count",');
    uri.append('"value":"');
    uri.append(alive.to_ascii());
    /// Copies
    uri.append('"},{"trait_type":"Copies",');
    uri.append('"value":"');
    if copies.high == 0 {
        uri.append(copies.low.to_ascii());
    } else {
        let mut copies_ascii_array = copies.to_ascii();
        loop {
            match copies_ascii_array.pop_front() {
                Option::Some(el) => { uri.append(el); },
                Option::None => { break; }
            }
        };
    }
    /// Generation
    uri.append('"},{"trait_type":"Generation",');
    uri.append('"value":"');
    if token_id.high == 0 {
        uri.append(token_id.low.to_ascii());
    } else {
        let mut generation_ascii_array = token_id.to_ascii();
        loop {
            match generation_ascii_array.pop_front() {
                Option::Some(el) => { uri.append(el); },
                Option::None => { break; }
            }
        };
    }
    uri.append('"}]');
}

