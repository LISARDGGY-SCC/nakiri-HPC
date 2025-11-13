input = './init_command.sh'
output = './test.sh'

result = open(output, 'w')
one_line_command = ''

with open(input, 'r') as file:
    for line in file:
        if line.startswith('#'): continue
        if line.startswith('\n'): continue
        line = line.split('\n\\')
        one_line_command += line[0]

result.write(one_line_command)