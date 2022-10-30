# Functions for running opcodes
import std/strformat
import std/bitops
import machinedef

proc jump_to_addr*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"jump to 0x{address:3x}"
  machine.pc = address
  echo fmt"RAM at PC = {machine.ram[machine.pc]}"

proc set_variable*(machine: ref chip8, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  when not defined(release):
    echo fmt"set variable 0x{variable:x} = 0x{value:x}"
  machine.variables[variable] = value

proc call_subroutine*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"call subroutine"
  machine.stack.add(machine.pc)
  jump_to_addr(machine, address)

proc return_subroutine*(machine: ref chip8) =
  machine.pc =  machine.stack.pop
  when not defined(release):
    echo "return_subroutine"
    echo fmt"pc set to {machine.pc}"

proc set_pointer_reg*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"set_pointer_reg to 0x{address:3x}"
  machine.i = address

proc display_clear*(machine: ref chip8) =
  when not defined(release):
    echo fmt"display_clear"
  for pixel in machine.framebuf.mitems:
    pixel = 0

proc draw*(machine: ref chip8, lower: uint16) =
  const W = 64
  const width = 8
  var Vx = lower
  var Vy = lower
  var N = lower
  Vx.bitslice(8..11)
  Vy.bitslice(4..7)
  N.bitslice(0..3)
  when not defined(release):
    echo fmt"draw {N} pixels from {Vx},{Vy}"
  for i in Vx..Vx+width-1:
    for j in Vy..Vy+N-1:
      machine.framebuf[i+W*j] = machine.framebuf[i+W*j] xor uint8 0x55

proc reg_load*(machine: ref chip8, lower: uint16) =
  var Vlast = lower
  Vlast.bitslice(8..11)
  when not defined(release):
    echo fmt"reg_load V0 to V{Vlast} starting from I = 0x{machine.i:x}"
  for i in 0..int(Vlast):
      machine.variables[i] = machine.ram[machine.i]
      machine.i += 1
