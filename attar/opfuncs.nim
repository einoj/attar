# Functions for running opcodes
import std/strformat
import std/bitops
import std/random
import machinedef

proc store_bcd_rep*(machine: ref, lower: uint16) =
  var j = lower shr 8
  var hundreds: uint8 = 0
  var tens: uint8 = 0
  var ones: uint8 = 0

  while j > 100:
    j -= 100
    hundreds += 1
  while j > 10:
    j -= 10
    tens += 1
  while j > 0:
    j -= 1
    ones += 1

  machine.ram[machine.i] = hundreds
  machine.ram[machine.i+1] = tens
  machine.ram[machine.i+2] = ones
  when not defined(release):
    echo fmt """Store BCD {lower shr 8 } {hundreds} hundreds in I=0x{machine.i:x},
    {tens} tens in I=0x{machine.i+1:x}, {ones} ones in I=0x{machine.i+2:x}"""

proc skip_next_instr(machine: ref) =
    machine.pc += 2
    when not defined(release):
      echo "Skipping next instruction"

proc skip_next_instr_equal*(machine: ref, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  if machine.variables[variable] == value:
      skip_next_instr(machine)

proc skip_next_instr_not_equal*(machine: ref, lower: uint16) =
  var variable = lower
  variable.bitslice(8..11)
  var value = uint8(lower)
  if machine.variables[variable] != value:
      skip_next_instr(machine)

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
  if machine.variables[variable] > 0xf:
    echo "ERROR: digit {machine.variables[variable]} font not supported"
    return
  machine.i = 5*machine.variables[variable]
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

proc and_vx_vy*(machine: ref chip8, lower: uint16) =
  var x = lower
  x.bitslice(8..11)
  var y = lower
  y.bitslice(4..7)
  when not defined(release):
    echo fmt"set V{x:x} = V{x:x} and V{y:x}"
  machine.variables[x] = bitand(machine.variables[x], machine.variables[y])

proc add_vx_vy*(machine: ref chip8, lower: uint16) =
  var x = lower
  x.bitslice(8..11)
  var y = lower
  y.bitslice(4..7)
  when not defined(release):
    echo fmt"set V{x:x} = V{x:x} + V{y:x}"
  machine.variables[x] = machine.variables[x] + machine.variables[y]
  machine.variables[0xf] = 0
  if machine.variables[x] < machine.variables[y]:
    echo fmt"V{x:x} overflow"
    machine.variables[0xf] = 1

proc set_vx_vy*(machine: ref chip8, lower: uint16) =
  var x = lower
  x.bitslice(8..11)
  var y = lower
  y.bitslice(4..7)
  when not defined(release):
    echo fmt"set V{x:x} = V{y:x}"
  machine.variables[x] = machine.variables[y]

proc sub_vx_vy*(machine: ref chip8, lower: uint16) =
  var x = lower
  x.bitslice(8..11)
  var y = lower
  y.bitslice(4..7)
  when not defined(release):
    echo fmt"set V{x:x} = V{x:x} - V{y:x}"
  machine.variables[0xf] = 1
  if machine.variables[y] > machine.variables[x]:
    machine.variables[0xf] = 0
    when not defined(release):
      echo fmt"V{x:x} underflow, VF set to 0"
  machine.variables[x] = machine.variables[x] - machine.variables[y]

proc jump_to_addr*(machine: ref chip8, address: uint16) =
  when not defined(release):
    echo fmt"jump to 0x{address:3x}"
  machine.pc = address
  machine.jmpflag = true
  echo fmt"RAM at PC({machine.pc:x}) = {bitops.bitor(machine.ram[machine.pc].int shl 8, machine.ram[machine.pc+1].int).uint16:x}"


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
    echo fmt"draw 8 wide {N} high sprite starting from {xcoordinate},{ycoordinate}"
  for row in ycoordinate..ycoordinate+N-1:
    idx = uint16(row)
    if idx > 31:
        idx -= 31
    sprite = machine.ram[machine.i+sprite_index]
    sprite_index += 1
    pixel_index = 0
    # Sprites are 8 pixels wide
    for col in xcoordinate-1..xcoordinate+7:
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
  var machine_i = machine.i
  for i in 0..int(Vlast):
      machine.variables[i] = machine.ram[machine_i]
      machine_i += 1

proc random*(machine: ref chip8, lower: uint16) =
  var Vx = lower
  var k = lower
  Vx.bitslice(8..11)
  k.bitslice(0..7)
  randomize()
  let num = rand(255)
  let result = bitand(int(k), num)
  when not defined(release):
    echo fmt"Random: Store bitand({k}, {num}) = {result} in V{Vx} "

proc set_st*(machine: ref chip8, lower: uint16) =
  var x = lower
  x.bitslice(8..11)
  machine.st = uint8(x)

proc skip_not_pressed*(machine: ref chip8, lower: uint16) =
  #TODO IMPLEMENT ME
  return

proc skip_pressed*(machine: ref chip8, lower: uint16) =
  #TODO IMPLEMENT ME
  return
