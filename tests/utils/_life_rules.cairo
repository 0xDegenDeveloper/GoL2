use gol2::utils::life_rules::{get_adjacent, evaluate_rounds};
use debug::PrintTrait;

#[test]
fn test_get_adjacent() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(16);
    assert(l == 15, 'Invalid L');
    assert(r == 17, 'Invalid R');
    assert(u == 1, 'Invalid U');
    assert(d == 31, 'Invalid D');
    assert(lu == 0, 'Invalid LU');
    assert(ru == 2, 'Invalid RU');
    assert(ld == 30, 'Invalid LD');
    assert(rd == 32, 'Invalid RD');
}

#[test]
fn test_get_adjacent_wrapped_ul() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(0);
    assert(l == 14, 'Invalid L');
    assert(r == 1, 'Invalid R');
    assert(u == 210, 'Invalid U');
    assert(d == 15, 'Invalid D');
    assert(lu == 224, 'Invalid LU');
    assert(ru == 211, 'Invalid RU');
    assert(ld == 29, 'Invalid LD');
    assert(rd == 16, 'Invalid RD');
}

#[test]
fn test_get_adjacent_wrapped_dl() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(210);
    assert(l == 224, 'Invalid L');
    assert(r == 211, 'Invalid R');
    assert(u == 195, 'Invalid U');
    assert(d == 0, 'Invalid D');
    assert(lu == 209, 'Invalid LU');
    assert(ru == 196, 'Invalid RU');
    assert(ld == 14, 'Invalid LD');
    assert(rd == 1, 'Invalid RD');
}

#[test]
fn test_get_adjacent_wrapped_ur() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(14);
    assert(l == 13, 'Invalid L');
    assert(r == 0, 'Invalid R');
    assert(u == 224, 'Invalid U');
    assert(d == 29, 'Invalid D');
    assert(lu == 223, 'Invalid LU');
    assert(ru == 210, 'Invalid RU');
    assert(ld == 28, 'Invalid LD');
    assert(rd == 15, 'Invalid RD');
}

#[test]
fn test_get_adjacent_wrapped_dr() {
    let (l, r, u, d, lu, ru, ld, rd) = get_adjacent(224);
    assert(l == 223, 'Invalid L');
    assert(r == 210, 'Invalid R');
    assert(u == 209, 'Invalid U');
    assert(d == 14, 'Invalid D');
    assert(lu == 208, 'Invalid LU');
    assert(ru == 195, 'Invalid RU');
    assert(ld == 13, 'Invalid LD');
    assert(rd == 0, 'Invalid RD');
}

#[test]
fn test_evaluate_rounds() {
    let mut acorn = array![];
    let mut expected_evolution = array![];
    let mut i = 0;
    let mut j = 0;
    loop {
        if i >= 225_u32 {
            break ();
        }
        if i == 99 || i == 116 || i == 128 || i == 129 || i == 132 || i == 133 || i == 134 {
            acorn.append(1);
        } else {
            acorn.append(0);
        }
        if j == 113
            || j == 114
            || j == 115
            || j == 117
            || j == 118
            || j == 132
            || j == 133
            || j == 148 {
            expected_evolution.append(1);
        } else {
            expected_evolution.append(0);
        }

        i += 1;
        j += 1;
    };

    let evolved = evaluate_rounds(1, acorn.clone());

    assert(evolved == expected_evolution, 'Invalid acorn evolution');
}

#[test]
fn test_evaluate_rounds_spinner() {
    let mut spinner = array![];
    let mut i = 225;
    loop {
        if i == 0 {
            break ();
        }
        if i == 1 || i == 2 || i == 3 {
            spinner.append(1);
        } else {
            spinner.append(0);
        }
        i -= 1;
    };

    let evolved = evaluate_rounds(2, spinner.clone());

    assert(evolved == spinner, 'Invalid spinner evolution');
}
