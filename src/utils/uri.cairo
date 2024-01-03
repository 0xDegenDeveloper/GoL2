use gol2::utils::{packing::{unpack_game}, svg::make_svg_array};

use alexandria_ascii::ToAsciiTrait;
use alexandria_math::pow;

use debug::PrintTrait;

/// Generates a json url for a token
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
    uri.append('"attributes":');
    let mut attributes = make_attributes(alive_count, token_id, copies, timestamp);
    loop {
        match attributes.pop_front() {
            Option::Some(el) => { uri.append(el); },
            Option::None => { break; }
        }
    };
    uri.append('}');
    uri
}

fn make_attributes(alive: u32, token_id: u256, copies: u256, timestamp: u64) -> Array<felt252> {
    let mut attributes: Array<felt252> = array!['['];
    /// Game Mode 
    attributes.append('{"trait_type":"Game%20Mode",');
    attributes.append('"value":"Infinite"},');
    /// Timestamp 
    attributes.append('{"trait_type":"Timestamp",');
    attributes.append('"value":"');
    attributes.append(timestamp.to_ascii());
    /// Cell Count
    attributes.append('"},{"trait_type":');
    attributes.append('"Cell%20Count",');
    attributes.append('"value":"');
    attributes.append(alive.to_ascii());
    /// Copies
    attributes.append('"},{"trait_type":"Copies",');
    attributes.append('"value":"');
    if copies.high == 0 {
        attributes.append(copies.low.to_ascii());
    } else {
        let mut copies_ascii_array = copies.to_ascii();
        loop {
            match copies_ascii_array.pop_front() {
                Option::Some(el) => { attributes.append(el); },
                Option::None => { break; }
            }
        };
    }
    /// Generation
    attributes.append('"},{"trait_type":"Generation",');
    attributes.append('"value":"');
    if token_id.high == 0 {
        attributes.append(token_id.low.to_ascii());
    } else {
        let mut generation_ascii_array = token_id.to_ascii();
        loop {
            match generation_ascii_array.pop_front() {
                Option::Some(el) => { attributes.append(el); },
                Option::None => { break; }
            }
        };
    }
    attributes.append('"}]');
    attributes
}

