type chip8* = object
  ram*: array[4096, uint16]
  pc*: uint16
  variables*: array[16, uint8]
  stack*: seq[uint16]
  i*: uint16
  framebuf*: array[64*32, uint8]
