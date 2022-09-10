import streams
import std/strformat
import std/endians
import std/bitops
import opfuncs
import sdl2
import sdl2/ttf

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
    var lower12bits: uint16 = machine.ram[machine.pc]
    lower12bits.bitslice(0..11)
    case n:
      of 0:
        discard
      of 0x00E0:
        echo fmt"display_clear"
      of 0x00EE:
        return_subroutine(machine)
      of 0x1000..0x1fff:
        jump_to_addr(machine, lower12bits)
      of 0x6000..0x6fff:
        set_variable(machine, lower12bits)
      of 0x2000..0x2fff:
        call_subroutine(machine, lower12bits)
      of 0xa000..0xafff:
        set_pointer_reg(machine, lower12bits)
      of 0xf000..0xffff:
        n.bitslice(0..7)
        case n:
          of 0x33:
            echo fmt "BCD"
          else:
            echo fmt"0xfX{n:x} not implemented"
      else:
        echo fmt"0x{n:4x} not implemented"
    machine.pc += 1

#let machine: ref chip8 = new(chip8)
#loadrom("pong.rom", machine)
#alu(machine)

proc gui =
  discard sdl2.init(INIT_EVERYTHING)

  const W: cint = 64
  const H: cint = 32

  var
    window: WindowPtr
    render: RendererPtr
    surface: SurfacePtr
    framebuf: array[64*32, uint8]

  window = createWindow("Attar", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, W, H, SDL_WINDOW_RESIZABLE)
  render = createRenderer(window, -1, 1);
  var texture = createTexture(render, SDL_PIXELFORMAT_RGB332,
                              SDL_TEXTUREACCESS_STREAMING, W, H);
  discard setLogicalSize(render, W, H);

  var
    evt = sdl2.defaultEvent
    runGame = true

  while runGame:
    while pollEvent(evt):
      if evt.kind == QuitEvent:
        runGame = false
        break
    for i in 0..W*H-1:
      framebuf[i] = uint8 0x55

    clear(render);
    updateTexture(texture, nil, addr framebuf, W * sizeof(uint8));
    copy(render, texture, nil, nil);

    present(render);

  destroy render
  destroy window

gui()
