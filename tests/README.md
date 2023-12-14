## Running basic tests

`snforge test`

## Running uri/svg tests

### First

Run

`snforge test --ignored`

### Then,

Copy all of the printed output:

e.g.

```
[DEBUG] data:application/json,{         (raw: 0x646174613a6170706c69636174696f6e2f6a736f6e2c7b

[DEBUG] "name":"GoL2%20%23              (raw: 0x226e616d65223a22476f4c32253230253233

...

[DEBUG] {"trait_type":"Game%20Mode",    (raw: 0x7b2274726169745f74797065223a2247616d652532304d6f6465222c

[DEBUG] "value":"Infinite"}]            (raw: 0x2276616c7565223a22496e66696e697465227d5d

[DEBUG] }                               (raw: 0x7d
```

### Next,

Open [this python script](./contracts/nft/uri_svg_testing/ex.py) and at the top of the file paste in the output:

```
cairo_output = """

<paste in the copied cairo output here>

"""
```

### Next,

Run the script: `python3 tests/contracts/nft/uri_svg_testing/ex.py`. This generate the JSON URI.

To see the JSON data, paste this URI into a browser. It will look like:

`data:application/json,{"name":"GoL2%20%231","description": ... ,{"trait_type":"Game%20Mode","value":"Infinite"}]}`

For the image, find the 'image' property in the JSON and copy it.

Paste this 'image' property into the browser to see the actual image. It should look like:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org ... width=%225%22/%3E%3C/g%3E%3C/svg%3E`

> NOTE: This step is crucial because the SVG images use double encoding for their special characters. When the JSON is resolved in the browser, the first layer of encoding is decoded. Pasting this resolved 'image' property into the browser then decodes the final set of special characters, ensuring the SVG image renders correctly.
