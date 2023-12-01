use gol2::utils::constants::{
    DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX, LAST_COL_CELL_INDEX,
    LAST_ROW_INDEX
};

/// Evaluates an amount of games and returns the final state.
fn evaluate_rounds(mut rounds: usize, mut cells: Array<felt252>) -> Array<felt252> {
    let mut i = 0;
    loop {
        if rounds == 0 {
            break cells.clone();
        }
        cells = apply_rules(cells.clone());
        rounds -= 1;
    }
}

/// Apply the Game of Life rules (wrapping on edges).
fn apply_rules(cell_states: Array<felt252>) -> Array<felt252> {
    let mut evolution = array![];
    let mut i = 0;
    let end = cell_states.len();

    loop {
        if i == end {
            break ();
        } else {
            let cell_idx: usize = i;
            let (L, R, U, D, LU, RU, LD, RD) = get_adjacent(cell_idx);

            /// How many neighbours are alive?
            let score = *cell_states[L]
                + *cell_states[R]
                + *cell_states[D]
                + *cell_states[U]
                + *cell_states[LU]
                + *cell_states[RU]
                + *cell_states[LD]
                + *cell_states[RD];

            /// Game logic to determine next state of cell.
            evolution
                .append(
                    /// If alive
                    if *cell_states[cell_idx] == 1 {
                        if (score - 2) * (score - 3) == 0 {
                            /// Remain alive.
                            1
                        } else {
                            /// Die.
                            0
                        }
                    } else {
                        if score == 3 {
                            /// Become alive.
                            1
                        } else {
                            /// Remain dead.
                            0
                        }
                    }
                );
        }
        i += 1;
    };
    evolution
}

/// Gets the 8 neighbours of a cell (wrapping on edges).
fn get_adjacent(cell_idx: usize) -> (usize, usize, usize, usize, usize, usize, usize, usize) {
    /// Cell Array: 
    ///         Row 0               Row 1              Row 2
    ///  <-------DIM-------> <-------DIM-------> <-------DIM------->
    /// [0,0,0,0,1,...,1,0,1,0,1,1,0,...,1,0,0,1,1,1,0,1...,0,0,1,0...]
    ///  ^col_0      col_14^ ^col_0      col_14^ ^col_0
    let (row, col) = (cell_idx / (DIM), cell_idx % (DIM));

    /// LU U RU
    /// L  .  R
    /// LD D RD
    let (mut L, mut R, mut U, mut D, mut LU, mut RU, mut LD, mut RD) = (
        225, 225, 225, 225, 225, 225, 225, 225
    );

    L = if col == FIRST_COL_INDEX {
        /// Cell is on left, and needs to wrap.
        cell_idx + LAST_COL_CELL_INDEX
    } else {
        cell_idx - 1
    };

    R = if col == LAST_COL_INDEX {
        /// Cell is on right, and needs to wrap.
        cell_idx - LAST_COL_CELL_INDEX
    } else {
        cell_idx + 1
    };

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
        L != 226
            && R != 226
            && U != 226
            && D != 226
            && LU != 226
            && RU != 226
            && LD != 226
            && RD != 226,
        'Invalid neighbor calculations'
    );

    (L, R, U, D, LU, RU, LD, RD)
}
