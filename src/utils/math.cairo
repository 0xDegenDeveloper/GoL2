/// Raises base to the power of exponent
fn raise_to_power(base: u128, exponent: u128) -> u256 {
    let mut i = 0;
    let mut result: u256 = 1;
    loop {
        if i >= exponent {
            break result;
        }
        result *= base.into();
        i = i + 1;
    }
}
