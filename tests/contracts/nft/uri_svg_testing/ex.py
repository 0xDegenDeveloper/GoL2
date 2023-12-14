cairo_output = """

"""

def cairo_output_to_single_ascii_string(cairo_output):
    # Split the input string into lines
    lines = cairo_output.split("\n\n")

    # Filter and extract hex values
    hex_values = []
    for line in lines:
        if 'raw: ' in line and line.split('raw: ')[-1].startswith('0x'):
            hex_values.append(line.split('raw: ')[-1])

    # Convert each hex value to ASCII and concatenate
    ascii_string = ''
    for hex_value in hex_values:
        ascii_chars = bytes.fromhex(hex_value[2:]).decode('ascii')
        ascii_string += ascii_chars

    # Output the ASCII string
    print(ascii_string)

cairo_output_to_single_ascii_string(cairo_output)