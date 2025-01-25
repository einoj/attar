import std/strformat
import times
import threadpool, std/os
import sdl2, sdl2/mixer
import math

let timeout = 0.1/60 # 60 Hz

sdl2.init(INIT_AUDIO)

# Generate triangle wave samples for audio
const
  sampleRate = 44100       # Standard audio sample rate (samples per second)
  waveFreq = 480           # Frequency of the wave (in Hz)
  waveLength = sampleRate div waveFreq  # Number of samples per cycle
const channel = 1
var waveSamples = newSeq[int16](waveLength)
for i in 0..<waveLength:
  let time = i / sampleRate
  let period = 1/waveFreq
  let cyclepos = floorMod(time,period)
  waveSamples[i] = int16(toInt(32767*(2*abs(2*(cyclepos/period)-1)-1)))

var waveChunk: Chunk
waveChunk.abuf = cast[ptr uint8](waveSamples[0].addr)
waveChunk.alen = 2 * waveLength
waveChunk.volume = MIX_MAX_VOLUME
if mixer.openAudio(sampleRate, MIX_DEFAULT_FORMAT, 2, 4096) != 0:
  quit("SDL_mixer could not initialize! SDL_mixer")

type chip8* = object
  ram*: array[2048, uint8]
  pc*: uint16
  variables*: array[16, uint8]
  stack*: seq[uint16]
  i*: uint16
  framebuf*: array[64*32, uint8]
  dt: uint8
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

var comm_chan*: Channel[uint8]

proc send_st_msg*(st: uint8) =
    comm_chan.send(st)

# Sound timer runs in its own thread
# it counts down at 60 Hz, i.e. period of 16.666... ms
proc tick_st*() =
  var st: uint8 = 0
  while true:
    let msg =  comm_chan.tryRecv()
    if msg.dataAvailable:
      st = msg.msg
    if st > 0:
      st -= 1
      if playChannel(channel, addr waveChunk, -1) == -1:
        echo "Unable to play sound! SDL_mixer Error: ", getError()
      when not defined(release):
        echo fmt"Ticking timer {st}"
    else:
      let _ = haltChannel(channel)
    sleep(16)

proc tick*(machine: ref chip8) =
  let now = cpuTime()
  if now - machine.lasttick > timeout:
    machine.lasttick = now
    if machine.dt > 0:
      machine.dt -= 1
      when not defined(release):
        echo fmt"Ticking timer {machine.dt}"

func createChip8*(): ref chip8 =

  let machine: ref chip8 = new(chip8)
  for i in 0..high(FONT):
    machine.ram[i] = FONT[i]
  machine.pc = 0
  machine.i = 0

  return machine
