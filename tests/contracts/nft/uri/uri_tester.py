import subprocess

command = 'snforge test contracts::nft::uri_svg --ignored'
print('\nRunning: `' + command + '`, parsing output, and converting to ASCII...\n')

# Execute snforge test command
process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
# Decode the process output
cairo_output = process.communicate()[0].decode('utf-8')

print("Copy this output and paste into a browser to view the JSON:\n\n" + ''.join(bytes.fromhex(line.split('raw: ')[1][2:]).decode('ascii', errors='ignore') for line in cairo_output.split('\n') if 'raw' in line), '\n')


