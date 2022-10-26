# Functions for running opcodes
import std/strformat
import std/bitops

type chip8* = object
  ram*: array[4096, uint16]
  pc*: uint16
  variables*: array[16, uint8]
  stack: seq[uint16]
  i: uint16
  framebuf*: array[64*32, uint8]

proc jump_to_addr*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"jump to 0x{address:3x}"
  machine.pc = address

proc set_variable*(machine: ref chip8, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  when not defined(release):
    echo fmt"set variable 0x{variable:x} = 0x{value:x}"
  machine.variables[variable] = value

proc call_subroutine*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"return_subroutine"
  machine.stack.add(machine.pc)
  jump_to_addr(machine, address)

proc return_subroutine*(machine: ref chip8) =
  when not defined(release):
    echo fmt"return_subroutine"
  machine.pc =  machine.stack.pop

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
  var Vx = lower
  var Vy = lower
  var N = lower
  Vx.bitslice(8..11)
  Vy.bitslice(4..7)
  N.bitslice(0..3)
  when not defined(release):
    echo fmt"draw {N} pixels from {Vx},{Vy}"
