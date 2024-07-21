import std/strformat
import ../../attar/opfuncs
import ../../attar/machinedef

let machine: ref chip8 = createChip8()

# Check that sub_vx_vy underflows 
machine.variables[0] = 0
machine.variables[1] = 1
machine.variables[0xf] = 1
let lower: uint16 = 0x014
sub_vx_vy(machine, lower)
assert machine.variables[0] == 255
assert machine.variables[0xf] == 0
# Check VF after no underflow
sub_vx_vy(machine, lower)
assert machine.variables[0] == 254
assert machine.variables[0xf] == 1

# Check that add_vx_vy normally sets VF to 0
machine.variables[0] = 254
machine.variables[1] = 1
machine.variables[0xf] = 1
add_vx_vy(machine, lower)
assert machine.variables[0] == 255
assert machine.variables[0xf] == 0
# Check that add_vx_vy sets VF to 1 on overflow
add_vx_vy(machine, lower)
assert machine.variables[0] == 0
assert machine.variables[0xf] == 1
