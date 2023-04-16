# Functions for running opcodes
import std/strformat
import std/bitops
import machinedef

proc store_bcd_rep*(machine: ref, lower: uint16) =
  var j = lower shr 8
  var hundreds: uint8 = 0
  var tens: uint8 = 0
  var ones: uint8 = 0

  while j > 100:
    echo fmt"100 j = {j}"
    j -= 100
    hundreds += 1
  while j > 10:
    echo fmt"10 j = {j}"
    j -= 10
    tens += 1
  while j > 0:
    echo fmt"1 j = {j}"
    j -= 1
    ones += 1

  machine.ram[machine.i] = hundreds
  machine.ram[machine.i+1] = tens
  machine.ram[machine.i+2] = ones
  when not defined(release):
    echo fmt "Store BCD {hundreds} in I={machine.i}, {tens} in I={machine.i+1}, {ones} in I={machine.i+2}"


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
  machine.variables[variable] = machine.getDT()
  when not defined(release):
    echo fmt"Delay Timer saved V[{variable}] = {machine.variables[variable]:x}"

proc set_delay_timer*(machine: ref, lower: uint16) =
  let variable = lower shr 8
  machine.setDT(machine.variables[variable])

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
  const screenW = 64
  const width = 8
  var Vx = lower
  var Vy = lower
  var N:uint16 = lower
  Vx.bitslice(8..11)
  Vy.bitslice(4..7)
  var sprite: uint8  = 0
  var sprite_index: uint16 = 0
  var pixel: uint8 = 0
  var pixel_index: uint8 = 7
  let xcoordinate: uint16 = machine.variables[Vx]
  let ycoordinate: uint16 = machine.variables[Vy]
  var idx: uint16 = 0 
  var jdx: uint16 = 0
  var framebuf_i: uint16 = 0
  N.bitslice(0..3)
  when not defined(release):
    echo fmt"draw {N} sprites starting from {xcoordinate},{ycoordinate}"
    for i in machine.i..machine.i+N-1:
      echo fmt"Drawing 0b{machine.ram[i]:08b}"
  for row in ycoordinate..ycoordinate+4:
    idx = uint16(row)
    if idx > 31:
        idx -= 31
    sprite = machine.ram[machine.i+sprite_index]
    sprite_index += 1
    pixel_index = 0
    for col in xcoordinate..xcoordinate+7:
      jdx = uint16(col)
      if jdx > 63:
          jdx -= 63
      pixel = (sprite shr (8-pixel_index)) and 1
      pixel_index += 1
      framebuf_i = idx*screenW+jdx
      if pixel == 1:
        machine.framebuf[framebuf_i] = machine.framebuf[framebuf_i] xor (uint8 0xff)
      else:
        machine.framebuf[framebuf_i] = machine.framebuf[framebuf_i] xor (uint8 0x00)

proc reg_load*(machine: ref chip8, lower: uint16) =
  var Vlast = lower
  Vlast.bitslice(8..11)
  when not defined(release):
    echo fmt"reg_load V0 to V{Vlast} starting from I = 0x{machine.i:x}"
  for i in 0..int(Vlast):
      machine.variables[i] = machine.ram[machine.i]
      machine.i += 1
