import machinedef
import streams
import std/strformat
import std/bitops
import opfuncs
import video

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
    var n: uint16 = bitops.bitor(machine.ram[machine.pc].int shl 8, machine.ram[machine.pc+1].int).uint16
    var lower12bits: uint16 = n
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
        skip_next_instr(machine, lower12bits)
      of 0x7000..0x7fff:
        add_vx(machine, lower12bits)
      of 0xa000..0xafff:
        set_pointer_reg(machine, lower12bits)
      of 0xd000..0xdfff:
        draw(machine, lower12bits)
      of 0xf000..0xffff:
        n.bitslice(0..7)
        case n:
          of 0x07:
            save_delay_timer(machine, lower12bits)
          of 0x15:
            set_delay_timer(machine, lower12bits)
          of 0x29:
            load_font_sprite(machine, lower12bits)
          of 0x33:
            echo fmt "BCD"
          of 0x65:
            reg_load(machine, lower12bits)
          else:
            echo fmt"0xfX{n:x} not implemented"
            break
      else:
        echo fmt"0x{n:4x} not implemented"
        break
    machine.pc += 2
    updategui(machine)
    if quitevent():
      return
  destroygui()

let machine: ref chip8 = createChip8()
loadrom("pong.rom", machine)
initgui()
alu(machine)
