type chip8* = object
  ram*: array[4096, uint8]
  pc*: uint16
  variables*: array[16, uint8]
  stack*: seq[uint16]
  i*: uint16
  framebuf*: array[64*32, uint8]
  dt*: uint8

const FONT: array[80, uint8] = [
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

func createChip8*(): ref chip8 =

  let machine: ref chip8 = new(chip8)
  for i in 0..high(FONT):
    machine.ram[i] = FONT[i]
  machine.pc = 0
  machine.i = 0

  return machine
