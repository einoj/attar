# Functions for running opcodes
import std/strformat
import std/bitops

type chip8* = object
  ram*: array[4096, uint16]
  pc*: uint16
  variables*: array[16, uint8]

proc jump_to_addr*(machine: ref chip8, address: uint16) =
  echo fmt"jump to 0x{address:3x}"
  machine.pc = address

proc set_variable*(machine: ref chip8, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  echo fmt"set variable 0x{variable:x} = 0x{value:x}"
  machine.variables[variable] = value
  
