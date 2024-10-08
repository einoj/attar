import std/strformat
import times

let timeout = 0.1/60 # 60 Hz

type chip8* = object
  ram*: array[2048, uint8]
  pc*: uint16
  variables*: array[16, uint8]
  stack*: seq[uint16]
  i*: uint16
  framebuf*: array[64*32, uint8]
  dt: uint8
  st*: uint8
  lasttick: float
  jmpflag*: bool
  input*: array[16, uint8]

const FONT*: array[80, uint8] = [
  # font sprites
  0xf0'u8, 0x90, 0x90, 0x90, 0xf0, # "0"
  0x20, 0x60, 0x20, 0x20, 0x70, # "1"
  0xf0, 0x10, 0xf0, 0x80, 0xf0, # "2"
  0xf0, 0x10, 0xf0, 0x10, 0xf0, # "3"
  0x90, 0x90, 0xf0, 0x10, 0x10, # "4"
  0xf0, 0x80, 0xf0, 0x10, 0xf0, # "5"
  0xf0, 0x80, 0xf0, 0x90, 0xf0, # "6"
  0xf0, 0x10, 0x20, 0x40, 0x40, # "7"
  0xf0, 0x90, 0xf0, 0x90, 0xf0, # "8"
  0xf0, 0x90, 0xf0, 0x10, 0xf0, # "9"
  0xf0, 0x90, 0xf0, 0x90, 0x90, # "A"
  0xe0, 0x90, 0xe0, 0x90, 0xe0, # "B"
  0xf0, 0x80, 0x80, 0x80, 0xf0, # "C"
  0xe0, 0x90, 0x90, 0x90, 0xe0, # "D"
  0xf0, 0x80, 0xf0, 0x80, 0xf0, # "E"
  0xf0, 0x80, 0xf0, 0x80, 0x80, # "F"
]

func getDT*(machine: ref chip8): uint8 =
  return machine.dt

proc setDT*(machine: ref chip8, value: uint8) =
  machine.dt = value
  machine.lasttick = cpuTime()
  when not defined(release):
    echo fmt"Delay Timer set to 0x{machine.dt:x}"

proc tick*(machine: ref chip8) =
  let now = cpuTime()
  if now - machine.lasttick > timeout:
    machine.lasttick = now
    if machine.dt > 0:
      machine.dt -= 1
      when not defined(release):
        echo fmt"Ticking timer {machine.dt}"
    if machine.st > 0:
      machine.st -= 1
      # TODO add beep sound
      when not defined(release):
        echo fmt"Ticking timer {machine.st}"

func createChip8*(): ref chip8 =

  let machine: ref chip8 = new(chip8)
  for i in 0..high(FONT):
    machine.ram[i] = FONT[i]
  machine.pc = 0
  machine.i = 0

  return machine
