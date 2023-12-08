use gol2::utils::constants::{
    DIM, FIRST_ROW_INDEX, FIRST_COL_INDEX, LAST_COL_INDEX, LAST_ROW_CELL_INDEX, LAST_COL_CELL_INDEX,
    LAST_ROW_INDEX
};

/// Evaluates an amount of games and returns the final state.
fn evaluate_rounds(mut rounds: usize, mut cells: Array<felt252>) -> Array<felt252> {
    loop {
        if rounds == 0 {
            break;
        }
        cells = apply_rules(cells);
        rounds -= 1;
    };
    cells
}

/// Apply the Game of Life rules (wrapping on edges).
fn apply_rules(cell_states: Array<felt252>) -> Array<felt252> {
    let mut evolution = array![];
    let mut i = 0;
    let stop = cell_states.len();
    loop {
        if i == stop {
            break;
        }
        let (L, R, U, D, LU, RU, LD, RD) = get_adjacent(i);

        /// How many neighbours are alive?
        let score = *cell_states[L]
            + *cell_states[R]
            + *cell_states[D]
            + *cell_states[U]
            + *cell_states[LU]
            + *cell_states[RU]
            + *cell_states[LD]
            + *cell_states[RD];

        evolution
            .append(
                /// If alive
                if *cell_states[i] == 1 {
                    /// Remain alive.
                    if (score - 2) * (score - 3) == 0 {
                        1
                    } /// Die.
                    else {
                        0
                    }
                } /// If dead
                else {
                    /// Become alive.
                    if score == 3 {
                        1
                    } /// Remain dead.
                    else {
                        0
                    }
                }
            );
        i += 1;
    };
    evolution
}

/// Gets the 8 neighbours of a cell (wrapping on edges).
fn get_adjacent(cell_idx: usize) -> (usize, usize, usize, usize, usize, usize, usize, usize) {
    ///  Cell Array: 
    ///        Row 0               Row 1                Row 2
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

    if row == LAST_ROW_INDEX {
        /// Cell is on bottom, and needs to wrap.
        D = cell_idx - LAST_ROW_CELL_INDEX;
        LD = L - LAST_ROW_CELL_INDEX;
        RD = R - LAST_ROW_CELL_INDEX;
    } else {
        D = cell_idx + DIM;
        LD = L + DIM;
        RD = R + DIM;
    }

    if row == FIRST_ROW_INDEX {
        /// Cell is on top, and needs to wrap.
        U = cell_idx + LAST_ROW_CELL_INDEX;
        LU = L + LAST_ROW_CELL_INDEX;
        RU = R + LAST_ROW_CELL_INDEX;
    } else {
        U = cell_idx - DIM;
        LU = L - DIM;
        RU = R - DIM;
    }

    (L, R, U, D, LU, RU, LD, RD)
}
