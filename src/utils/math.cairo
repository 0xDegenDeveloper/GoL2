// todo: replace with alexandria library
/// Raises base to the power of exponent
fn raise_to_power(base: u128, mut exponent: u128) -> u256 {
    let mut result: u256 = 1;
    loop {
        if exponent == 0 {
            break result;
        }
        result *= base.into();
        exponent -= 1;
    }
}
