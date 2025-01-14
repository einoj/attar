import machinedef
import streams
import std/strformat
import std/bitops
import opfuncs
import video
import os

proc loadrom(romname: string, machine: ref chip8) =
  var stream = newFileStream(romname, fmRead)
  var i: uint16 = 0x200
  machine.pc = i
  var echocnt: int = 0
  while not stream.atEnd:
    machine.ram[i] = stream.readUint8
    when not defined(release):
      stdout.write fmt"[0x{i:3x}]=0x{machine.ram[i]:2x} "
      echocnt += 1
      if echocnt == 8:
        echocnt = 0
        echo " "
    i += 1
  stream.close()

proc alu(machine: ref chip8) =
  while machine.pc<0x1000:
    machine.tick()
    var n: uint16 = bitops.bitor(machine.ram[machine.pc].int shl 8, machine.ram[machine.pc+1].int).uint16
    echo fmt"instruction = {n:x}" 
    var lower12bits: uint16 = n
    var firstbyte: uint16 = n
    firstbyte.bitslice(0..7)
    lower12bits.bitslice(0..11)
    case n:
      of 0:
        discard
      of 0x00E0:
        display_clear(machine)
      of 0x00EE:
        return_subroutine(machine)
      of 0x1000..0x1fff:
        jump_to_addr(machine, lower12bits)
      of 0x6000..0x6fff:
        set_variable(machine, lower12bits)
      of 0x2000..0x2fff:
        call_subroutine(machine, lower12bits)
        continue # continue so we do not increment the program counter
      of 0x3000..0x3fff:
        skip_next_instr_equal(machine, lower12bits)
      of 0x4000..0x4fff:
        skip_next_instr_not_equal(machine, lower12bits)
      of 0x7000..0x7fff:
        add_vx(machine, lower12bits)
      of 0x8000..0x8fff:
        n.bitslice(0..3)
        case n:
          of 0x0:
            set_vx_vy(machine, lower12bits)
          of 0x1:
            echo fmt"0x8xy{n:x} not implemented"
          of 0x2:
            and_vx_vy(machine, lower12bits)
          of 0x3:
            echo fmt"0x8xy{n:x} not implemented"
          of 0x4:
            add_vx_vy(machine, lower12bits)
          of 0x5:
            sub_vx_vy(machine, lower12bits)
          of 0x6:
            echo fmt"0x8xy{n:x} not implemented"
          of 0x7:
            echo fmt"0x8xy{n:x} not implemented"
          of 0xE:
            echo fmt"0x8xy{n:x} not implemented"
          else:
            echo fmt"0x8xy{n:x} not implemented"
      of 0xa000..0xafff:
        set_pointer_reg(machine, lower12bits)
      of 0xd000..0xdfff:
        draw(machine, lower12bits)
        updategui(machine)
      of 0xe000..0xefa1:
        case firstbyte:
          of 0xa1:
            skip_not_pressed(machine, lower12bits)
          of 0x9e:
            skip_pressed(machine, lower12bits)
          else:
            echo fmt"0xefa1 0x{n:4x} not implemented"
      of 0xc000..0xcfff:
        random(machine, lower12bits)
        updategui(machine)
      of 0xf000..0xffff:
        case firstbyte:
          of 0x07:
            save_delay_timer(machine, lower12bits)
          of 0x15:
            set_delay_timer(machine, lower12bits)
          of 0x29:
            load_font_sprite(machine, lower12bits)
          of 0x33:
            store_bcd_rep(machine, lower12bits)
          of 0x65:
            reg_load(machine, lower12bits)
          of 0x18:
            set_st(machine, lower12bits)
          else:
            echo fmt"0xfX{n:x} not implemented"
            break
      else:
        echo fmt"0x{n:4x} not implemented"
        break
    if not machine.jmpflag:
      machine.pc += 2
    else:
      machine.jmpflag = false
    updategui(machine)
    if quitevent():
      return
  destroygui()

let machine: ref chip8 = createChip8()
loadrom(paramStr(1), machine)
initgui()
alu(machine)
