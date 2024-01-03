## Running basic tests

`snforge test`

## Running uri/svg tests

### First

Run the python testing script to generate the JSON URI:

`python3 ./tests/contracts/nft/uri/nft_uri_and_svg.py`

### Then

Paste this URI into a browser to view the JSON data. It will look like:

`data:application/json,{"name":"GoL2%20%231","description"...,{"trait_type":"Generation","value":2}]}`

For the image, find the "image" field in this browser JSON data and copy it. Paste this textx into the browser to see the actual image. It should look like:

`data:image/svg+xml,%3Csvg%20xmlns=%22http://www.w3.org...width=%225%22/%3E%3C/g%3E%3C/svg%3E`

> NOTE: This step is crucial because the special characters in the SVG URL are double encoded. When the JSON is resolved in the browser, the first layer of encoding is decoded. Pasting this resolved 'image' property into the browser then decodes the final set of special characters, ensuring the SVG image renders correctly.

## View gas costs & differences

Run

`snforge test gas --ignored`
