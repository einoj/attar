import machinedef
import sdl2

var
  window: WindowPtr
  render: RendererPtr
  texture: TexturePtr
  runGUI* = true

const W: cint = 64
const H: cint = 32

proc initgui* =
  discard sdl2.init(INIT_EVERYTHING)

  let scale: cint = 4
  window = createWindow("Attar", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, W*scale, H*scale, SDL_WINDOW_RESIZABLE)
  render = createRenderer(window, -1, 1);
  texture = createTexture(render, SDL_PIXELFORMAT_RGB332,
                              SDL_TEXTUREACCESS_STREAMING, W, H);
  discard setLogicalSize(render, W, H);

proc updategui*(machine: ref chip8) =
  clear(render);
  updateTexture(texture, nil, addr machine.framebuf, W * sizeof(uint8));
  copy(render, texture, nil, nil);

  present(render);

proc destroygui* =
  destroy render
  destroy window

proc quitevent*(): bool =
  var
    evt = sdl2.defaultEvent

  while pollEvent(evt):
    if evt.kind == QuitEvent:
      destroygui()
      return true
  return false

