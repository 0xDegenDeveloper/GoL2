use gol2::utils::{constants::DIM, packing::{unpack_game}};
use alexandria_ascii::ToAsciiTrait;

/// Create an SVG string for a cell array.
/// Returns the SVG string (Array<felt252>) and the number of alive cells in the array.
/// @dev URI special chars are encoded like so:
/// % -> %25, space -> %20, " -> %22, # -> %23, < -> %3C, > -> %3E.
/// @dev SVG special chars are double encoded so that 
/// when browsers replace special chars, the SVG is not broken.
/// i.e. %2525 -> %25 -> %, %2523 -> %23 -> #, %253C -> %3C -> <, %253E -> %3E -> >
fn make_svg_array(cell_array: Array<felt252>) -> (Array<felt252>, u32) {
    let mut svg_u8_array: Array<u8> = array![];
    let mut svg_array: Array<felt252> = array![
        /// Start SVG file
        'data:image/svg+xml,', //data:image/svg+xml,
        '%253Csvg%2520xmlns=%2522', ///<svg xmlns="
        'http://www.w3.org/2000/svg%2522', //http://www.w3.org/2000/svg"
        '%2520width=%2522910%2522', // width="910"
        '%2520height=%2522910%2522', // height="910"
        '%2520viewBox=%25220%25200', // viewBox="0 0
        '%2520910%2520910%2522%253E', // 910 910">
        /// Board (translated to center border)
        '%253Cg%2520transform=', //<g transform=
        '%2522translate(5%25205)', //"translate(5 5)
        '%2522%253E', //">
        /// Grid background
        '%253Crect%2520width=', //<rect width=
        '%2522900%2522', //"900"
        '%2520height=%2522900%2522', // height="900"
        '%2520fill=%2522%25231e222b', // fill="#1e222b"
        '%2522/%253E', // />
        /// Grid lines group
        '%253Cg%2520stroke=%2522', //<g stroke="
        '%25235e6266%2522', //#5e6266"
        '%2520stroke-width=%25221%2522', // stroke-width="1"
        '%253E', //>
    ];

    /// Grid lines
    let mut i = 1;
    loop {
        if i == DIM {
            break;
        }
        let v = (i * 60).into();
        add_line(ref svg_array, 0, v, 900, v);
        add_line(ref svg_array, v, 0, v, 900);
        i += 1;
    };

    /// Alive cells group
    svg_array.append('%253C/g%253E%253Cg%2520fill='); //</g><g fill=
    svg_array.append('%2522%2523dff17b'); //"#dff17b
    svg_array.append('%2522'); //"
    svg_array.append('%2520stroke=%2522%2523'); // stroke="#
    svg_array.append('dff17b%2522'); //dff17b"
    svg_array.append('%2520stroke-width=%2522'); // stroke-width="
    svg_array.append('0.5%2522%253E'); //0.5">

    /// Alive cells
    let stop = cell_array.len();
    let mut i = 0;
    loop {
        if i == stop {
            break;
        }
        let cell_idx = i;
        if *cell_array.at(cell_idx) == 1 {
            let (row, col) = (cell_idx / (DIM), cell_idx % (DIM));
            add_rect(ref svg_array, 60, 60, col.into() * 60, row.into() * 60);
        }
        i += 1;
    };

    /// Game border
    svg_array.append('%253C/g%253E%253Crect%2520'); ///</g><rect' '
    svg_array.append('width=%2522900%2522'); ///width="900"
    svg_array.append('%2520height=%2522900%2522'); /// height="900"
    svg_array.append('%2520fill=%2522none%2522'); /// fill="none"
    svg_array.append('%2520stroke=%2522%2523'); /// stroke="#
    svg_array.append('0a0c10%2522'); ///0a0c10"
    svg_array.append('%2520stroke-width=%2522'); /// stroke-width="
    svg_array.append('5%2522/%253E'); ///5"/>
    svg_array.append('%253C/g%253E%253C/svg%253E'); ///</g></svg>

    (svg_array, i)
}

/// Add a line shape to the SVG array
fn add_line(ref svg_array: Array<felt252>, x1: felt252, y1: felt252, x2: felt252, y2: felt252) {
    let x1_int: u32 = x1.try_into().unwrap();
    let y1_int: u32 = y1.try_into().unwrap();
    let x2_int: u32 = x2.try_into().unwrap();
    let y2_int: u32 = y2.try_into().unwrap();

    svg_array.append('%253Cline%2520x1=%2522'); ///<line x1="
    svg_array.append(x1_int.to_ascii());
    svg_array.append('%2522%2520y1=%2522'); /// y1="
    svg_array.append(y1_int.to_ascii());
    svg_array.append('%2522%2520x2=%2522'); /// x2="
    svg_array.append(x2_int.to_ascii());
    svg_array.append('%2522%2520y2=%2522'); /// y2="
    svg_array.append(y2_int.to_ascii());
    svg_array.append('%2522/%253E'); ///"/>
}

/// Add a rectangle shape to the SVG array
fn add_rect(
    ref svg_array: Array<felt252>,
    w: felt252,
    h: felt252,
    translate_x: felt252,
    translate_y: felt252
) {
    let w_int: u32 = w.try_into().unwrap();
    let h_int: u32 = h.try_into().unwrap();
    let translate_x_int: u32 = translate_x.try_into().unwrap();
    let translate_y_int: u32 = translate_y.try_into().unwrap();

    svg_array.append('%253Crect'); //<rect
    svg_array.append('%2520width=%2522'); // width="
    svg_array.append(w_int.to_ascii());
    svg_array.append('%2522%2520height=%2522'); //" height="
    svg_array.append(h_int.to_ascii());
    svg_array.append('%2522%2520transform=%2522'); //" transform="
    svg_array.append('translate('); //translate(
    svg_array.append(translate_x_int.to_ascii());
    svg_array.append('%2520'); // (space)
    svg_array.append(translate_y_int.to_ascii());
    svg_array.append(')%2522/%253E'); //)"/>
}

