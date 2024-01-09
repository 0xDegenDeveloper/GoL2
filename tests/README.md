## Table of contents

1. [Basic Tests](#basic)
2. [URI/SVG Tests](#uri)
3. [Gas Tests](#gas)

## Run basic tests: <a name="basic"></a>

`snforge test`

## Run uri/svg tests: <a name="uri"></a>

Run the python testing script to generate the JSON URI:

`npm run test_uri`.

_**This command runs `python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py`. You may need to use a different python command other than `python3` to run the script depending on your machine.**_

`Test passed!` means the test matches the expected output; to view it for yourself see below:

### Step 1:

Paste the URI into your browser to view the JSON data as marketplaces _**should**_; it will look like this:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`.

### Step 2:

To see the image, find the "image" field in this browser JSON and copy the data. Paste this text into the browser to see the image. It should look like this:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`.

> NOTE: This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved by the browser, the first layer of encoding is decoded. Pasting this resolved 'image' data into the browser then decodes the second set of special characters, ensuring the SVG renders correctly.

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

where `0x1a734` is the Cairo 0 `evolve` function's gas usage, and `0x73a0` is the Cairo 1 function's gas usage.
