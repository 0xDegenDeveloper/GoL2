use gol2::utils::{
    constants::{
        DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX,
        LAST_COL_CELL_INDEX, LAST_ROW_INDEX
    },
    packing::{unpack_game}
};
use core::to_byte_array::FormatAsByteArrayImpl;
// use alexandria::{ToAsciiTrait};

// create .svg file as felt array (and later on byte array)
fn make_svg_array(game_state: felt252) -> Array<felt252> {
    let mut svg_array = array![
        /// Start svg
        '<svg xmlns=',
        '"http://www.w3.org/2000/svg" ',
        'width="950" height="950" ',
        'viewBox="0 0 950 950">',
        '<g transform="translate(5 5)" ',
        'stroke="#7f8e9b" >',
        /// Background
        '<rect width="900" height="900" ',
        'fill="#1e222b" />',
        /// Grid
        '<g stroke="#5e6266" ',
        'stroke-width="1" >',
    ];

    /// Grid
    let mut i = 1;
    loop {
        if i == 15 {
            break;
        }
        let v = i * 60;
        add_line(ref svg_array, 0, v, 900, v);
        add_line(ref svg_array, v, 0, v, 900);
        i += 1;
    };

    /// Alive cells
    svg_array.append('</g><g fill="#dff17b" ');
    svg_array.append('stroke="#dff17b" ');
    svg_array.append('stroke-width="0.5" >');
    let cells = unpack_game(game_state);
    let mut i = cells.len();
    loop {
        if i == 0 {
            break;
        }
        let cell_idx = 225 - i;
        let is_alive = *cells.at(cell_idx) == 1;
        if is_alive {
            let (row, col) = (cell_idx / (DIM), cell_idx % (DIM));
            add_rect(ref svg_array, 60, 60, col.into() * 60, row.into() * 60);
        }
        i -= 1;
    };
    /// Game Border
    svg_array.append('</g><rect width="900" ');
    svg_array.append('height="900" ');
    svg_array.append('fill="none" ');
    svg_array.append('stroke="#0a0c10" ');
    svg_array.append('stroke-width="5"/>');
    svg_array.append('</g></svg>');
    svg_array
}

fn add_line(ref svg_array: Array<felt252>, x1: felt252, y1: felt252, x2: felt252, y2: felt252) {
    svg_array.append('<line x1="');
    svg_array.append(x1);
    svg_array.append('" y1="');
    svg_array.append(y1);
    svg_array.append('" x2="');
    svg_array.append(x2);
    svg_array.append('" y2="');
    svg_array.append(y2);
    svg_array.append('"/>');
}

fn add_rect(
    ref svg_array: Array<felt252>,
    w: felt252,
    h: felt252,
    translate_x: felt252,
    translate_y: felt252
) {
    svg_array.append('<rect width="');
    svg_array.append(w);
    svg_array.append(' height="');
    svg_array.append(h);
    svg_array.append(' transform="translate(');
    svg_array.append(translate_x);
    svg_array.append(' ');
    svg_array.append(translate_y);
    svg_array.append(')"/>');
}
// translate felt/byte array to u64 or other encoding with browser url front part

// then make json/? for actual token metadata


