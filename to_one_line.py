input = './init_command.sh'
output = './all_in_one.sh'

result = open(output, 'w')
one_line_command = ''

with open(input, 'r') as file:
    for line in file:
        if line.startswith('#'): continue
        if line.startswith('set'): continue
        if line.startswith('\n'): continue
        one_line_command += line

one_line_command = one_line_command.replace('\\\n', ' ')
one_line_command = ' && '.join(one_line_command.split('\n'))
one_line_command = ' '.join(one_line_command.split())
result.write(one_line_command)