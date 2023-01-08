# Functions for running opcodes
import std/strformat
import std/bitops
import machinedef

proc skip_next_instr*(machine: ref, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  if machine.variables[variable] == value:
    machine.pc += 2
    when not defined(release):
      echo "Skipping next instruction"

proc save_delay_timer*(machine: ref, lower: uint16) =
  let variable = lower shr 8
  machine.variables[variable] = machine.dt
  when not defined(release):
    echo fmt"Delay Timer saved to V[{variable}] {machine.variables[variable]:x}"

proc set_delay_timer*(machine: ref, lower: uint16) =
  let variable = lower shr 8
  machine.dt = machine.variables[variable]
  when not defined(release):
    echo fmt"Delay Timer set to {machine.dt:x}"


proc load_font_sprite*(machine: ref chip8, lower: uint16) =
  let variable = lower shr 8
  case machine.variables[variable]:
    of 0x0:
      machine.i = 0x0
    of 0x1:
      machine.i = 0x5
    of 0x2:
      machine.i = 0xa
    of 0x3:
      machine.i = 0xf
    of 0x4:
      machine.i = 0x14
    of 0x5:
      machine.i = 0x19
    of 0x6:
      machine.i = 0x1e
    of 0x7:
      machine.i = 0x23
    of 0x8:
      machine.i = 0x28
    of 0x9:
      machine.i = 0x2d
    of 0xa:
      machine.i = 0x32
    of 0xb:
      machine.i = 0x37
    of 0xc:
      machine.i = 0x3c
    of 0xd:
      machine.i = 0x41
    of 0xe:
      machine.i = 0x46
    of 0xf:
      machine.i = 0x4b
    else:
      echo "ERROR: digit {machine.variables[variable]} font not supported"
  when not defined(release):
    echo fmt"Set I = {machine.i:x}, address of font depicting {machine.variables[variable]:x}"

proc add_vx*(machine: ref chip8, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  when not defined(release):
    echo fmt"Add {value:x} to variable 0x{variable:x}"
  machine.variables[variable] += value
  echo fmt"New variable 0x{machine.variables[variable]:x}"

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
