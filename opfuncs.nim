# Functions for running opcodes
import std/strformat
import std/bitops

type chip8* = object
  ram*: array[4096, uint16]
  pc*: uint16
  variables*: array[16, uint8]
  stack: seq[uint16]
  i: uint16
  framebuff: array[64, array[32, uint16]]

proc jump_to_addr*(machine: ref chip8, address: uint16) =
  echo fmt"jump to 0x{address:3x}"
  machine.pc = address

proc set_variable*(machine: ref chip8, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  echo fmt"set variable 0x{variable:x} = 0x{value:x}"
  machine.variables[variable] = value

proc call_subroutine*(machine: ref chip8, address: uint16) =
  machine.stack.add(machine.pc)
  jump_to_addr(machine, address)

proc return_subroutine*(machine: ref chip8) =
  machine.pc =  machine.stack.pop

proc set_pointer_reg*(machine: ref chip8, address: uint16) =
  machine.i = address

proc draw*(machine: ref chip8, lower: uint16) =
  var vx = lower
  var vy = lower
  var n = lower
  vx.bitslice(8..11)
  vy.bitslice(4..7)
  n.bitslice(0..3)
  var pointr = machine.i
  for row in machine.variables[vx]..8:
    for col in machine.variables[vy]..n:
      machine.framebuff[row][col] = machine.framebuff[row][col] xor machine.ram[pointr]
      pointr += 1
    
