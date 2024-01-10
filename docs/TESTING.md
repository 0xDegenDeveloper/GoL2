# Testing

## Run Basic Tests: <a name="basic"></a>

`snforge test`

## View Gas Differences: <a name="gas"></a>

`snforge test gas --ignored`

The output will be similar to:

```
[DEBUG] evolve                          (raw: 0x65766f6c7665

[DEBUG] old                             (raw: 0x6f6c64

[DEBUG]                                 (raw: 0x1a734

[DEBUG] new                             (raw: 0x6e6577

[DEBUG]                                 (raw: 0x73a0
```

where `0x1a734` is the Cairo 0 `evolve` function's gas usage, and `0x73a0` is the Cairo 1 `evolve` function's gas usage.
