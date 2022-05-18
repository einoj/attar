import streams
import std/strformat
import std/endians

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
    case machine.ram[machine.pc]
      of 0x1000..0x1fff:
        echo fmt"jump_to_addr 0x{machine.ram[machine.pc]:4x}"
      else: discard
    machine.pc += 1

let machine: ref chip8 = new(chip8)
loadrom("pong.rom", machine)
alu(machine)
