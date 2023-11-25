use debug::PrintTrait;


use gol2::utils::constants::{
    DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX, LAST_COL_CELL_INDEX,
    LAST_ROW_INDEX
};

fn evaluate_rounds(rounds: usize, cells: Array<felt252>) -> Array<felt252> {
    let mut i = 0;
    let mut pending_states = cells.clone(); // omit clone ?
    loop {
        if i >= rounds {
            break ();
        } else {
            pending_states = apply_rules(pending_states.clone());
        }
        i += 1;
    };

    pending_states
}

fn apply_rules(cell_states: Array<felt252>) -> Array<felt252> {
    let mut pending_states = array![];
    let mut i = cell_states.len();
    let end = cell_states.len();

    loop {
        if i == 0 {
            break ();
        } else {
            let cell_idx: usize = end - i;
            let (L, R, U, D, LU, RU, LD, RD) = get_adjacent(cell_idx);

            let score = *cell_states[L]
                + *cell_states[R]
                + *cell_states[D]
                + *cell_states[U]
                + *cell_states[LU]
                + *cell_states[RU]
                + *cell_states[LD]
                + *cell_states[RD];

            /// Final outcome
            /// If alive
            if *cell_states[cell_idx] == 1 {
                /// With good neighbours
                if (score - 2) * (score - 3) == 0 {
                    /// Live
                    pending_states.append(1);
                } else {
                    pending_states.append(0);
                }
            } else {
                if score == 3 {
                    pending_states.append(1);
                } else {
                    pending_states.append(0);
                }
            }
        }
        i -= 1;
    };

    array![]
}

fn get_adjacent(cell_idx: usize) -> (usize, usize, usize, usize, usize, usize, usize, usize) {
    /// cell_states and pending_states structure:
    ///         Row 0               Row 1              Row 2
    ///  <-------DIM-------> <-------DIM-------> <-------DIM------->
    /// [0,0,0,0,1,...,1,0,1,0,1,1,0,...,1,0,0,1,1,1,0,1...,0,0,1,0...]
    ///  ^col_0     col_DIM^ ^col_0     col_DIM^ ^col_0
    // let cell_idx: usize = cell_idx.try_into().unwrap();
    let row: usize = cell_idx / (DIM);
    let col: usize = cell_idx % (DIM);

    /// LU U RU
    /// L  .  R
    /// LD D RD
    let mut L = '_';
    let mut R = '_';
    let mut U = '_';
    let mut D = '_';
    let mut LU = '_';
    let mut RU = '_';
    let mut LD = '_';
    let mut RD = '_';

    if col == FIRST_COL_INDEX {
        /// Cell is on left, and needs to wrap.
        L = cell_idx + LAST_COL_CELL_INDEX;
    } else {
        L = cell_idx - 1;
    }

    if col == LAST_COL_INDEX {
        /// Cell is on right, and needs to wrap.
        R = cell_idx - LAST_COL_CELL_INDEX;
    } else {
        R = cell_idx + 1;
    }

    /// Bottom neighbours: D, LD, RD
    if row == LAST_ROW_INDEX {
        /// Lower neighbour cells are on top, and need to wrap.
        D = cell_idx - LAST_ROW_CELL_INDEX;
        LD = L - LAST_ROW_CELL_INDEX;
        RD = R - LAST_ROW_CELL_INDEX;
    } else {
        /// Lower neighbour cells are not top row, don't wrap.
        D = cell_idx + DIM;
        LD = L + DIM;
        RD = R + DIM;
    }

    /// Top neighbours: U, LU, RU
    if row == FIRST_ROW_INDEX {
        /// Upper neighbour cells are on top, and need to wrap.
        U = cell_idx + LAST_ROW_CELL_INDEX;
        LU = L + LAST_ROW_CELL_INDEX;
        RU = R + LAST_ROW_CELL_INDEX;
    } else {
        /// Upper neighbour cells are not top row, don't wrap.
        U = cell_idx - DIM;
        LU = L - DIM;
        RU = R - DIM;
    }

    assert(
        L != '_'
            && R != '_'
            && U != '_'
            && D != '_'
            && LU != '_'
            && RU != '_'
            && LD != '_'
            && RD != '_',
        'Invalid neighbor calculations'
    );

    (L, R, U, D, LU, RU, LD, RD)
}
