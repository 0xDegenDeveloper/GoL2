use gol2::utils::math::raise_to_power;

#[test]
fn test_raise_to_power() {
    assert(raise_to_power(0, 0) == 1, 'Invalid math 0');
    assert(raise_to_power(0, 1) == 0, 'Invalid math 1');
    assert(raise_to_power(1, 0) == 1, 'Invalid math 2');
    assert(raise_to_power(1, 1) == 1, 'Invalid math 3');
    assert(raise_to_power(2, 0) == 1, 'Invalid math 4');
    assert(raise_to_power(2, 1) == 2, 'Invalid math 5');
    assert(raise_to_power(2, 2) == 4, 'Invalid math 6');
    assert(raise_to_power(2, 3) == 8, 'Invalid math 7');
    assert(raise_to_power(2, 4) == 16, 'Invalid math 8');
    assert(raise_to_power(2, 5) == 32, 'Invalid math 9');
    assert(raise_to_power(2, 6) == 64, 'Invalid math 10');
    assert(raise_to_power(2, 7) == 128, 'Invalid math 11');
    assert(raise_to_power(2, 10) == 1024, 'Invalid math 12');
}
