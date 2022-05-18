import streams
import std/strformat
import std/endians
import std/bitops

type chip8 = object
  ram: array[4096, uint16]
  pc: uint16
  variables: array[16, uint8]

proc loadrom(romname: string, machine: ref chip8) =
  var stream = newFileStream(romname, fmRead)
  var i: int = 0x200
  while not stream.atEnd:
    var element = stream.readUint16
    var bigend: uint16
    bigEndian16(addr bigend, addr element)
    machine.ram[i] = bigend
    i += 1
  stream.close()

proc alu(machine: ref chip8) =
  while machine.pc<4096:
    var n: uint16 = machine.ram[machine.pc]
    case n:
      of 0x00E0:
        echo fmt"display_clear"
      of 0x00EE:
        echo fmt"return"
      of 0x1000..0x1fff:
        echo fmt"jump_to_addr 0x{machine.ram[machine.pc]:4x}"
      of 0xf000..0xffff:
        var v = 0x00ff'u16
        n.mask(v)
        case n:
          of 0x33:
            echo fmt "BCD"
          else: discard
      else: discard
    machine.pc += 1

let machine: ref chip8 = new(chip8)
loadrom("pong.rom", machine)
alu(machine)
