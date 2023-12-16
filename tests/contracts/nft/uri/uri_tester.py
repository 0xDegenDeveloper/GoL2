import subprocess

print("Running: snforge `test contracts::nft::uri_svg --ignored`\n")

# Execute snforge test command
command = "snforge test contracts::nft::uri_svg --ignored"
process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
# Decode the process output
cairo_output = process.communicate()[0].decode('utf-8')

print("Copy this output and paste into a browser to view the JSON:\n")

# Extract and convert hex values to ASCII string from command output and print
print(''.join(
    bytes.fromhex(line.split()[1][2:]).decode('ascii', errors='ignore')
    for line in cairo_output.split("\n") if '[DEBUG]' in line and line.split()[1].startswith('0x')
))

print("\n")



