
import strutils
import os

# The portaudio DLL is coming from (not most recent, but fairly recent):
#   https://github.com/adfernandes/precompiled-portaudio-windows
# Reference links:
#   http://portaudio.com/docs/v19-doxydocs/api_overview.html
#   https://bitbucket.org/BitPuffin/nim-portaudio/src/d739cb67ab6f2b99ecedf57c664ff5e87d0b0bb5/src/portaudio.nim?at=default&fileviewer=file-view-default
import portaudio as PA

# requires: nimble install oldwinapi
# import windows
# discard MessageBox(0, "Hello World", "Nim", MB_ICONEXCLAMATION or MB_OK)

# the following is inspired by Erik Johansson Andersson example
# https://bitbucket.org/BitPuffin/nim-portaudio/src/761fb0007245e5c3de576e69d4885442c5bf3d49/examples/saw_out.nim?at=default&fileviewer=file-view-default

when defined(windows):
   #proc getch(): cint {.header: "<conio.h>", importc: "_getch".}
   #proc getch(): cint {.importc: "_getch", dynlib: "msvcrt.dll".}
   proc kbhit(): cint {.importc: "_kbhit", dynlib: "msvcrt.dll".}

type
  TPhase = tuple[left, right: float32]

proc streamCallback(inBuf, outBuf: pointer, framesPerBuf: culong, timeInfo: ptr TStreamCallbackTimeInfo,
    statusFlags: TStreamCallbackFlags, userData: pointer): cint {.cdecl.} =

  var
    outBuf = cast[ptr array[0xffffffff, TPhase]](outBuf)
    inBuf = cast[ptr array[0xffffffff, TPhase]](inBuf)
    phase = cast[ptr TPhase](userData)

  if false:
    for i in 0.. <framesPerBuf.int:
      outBuf[i] = phase[]

      # Use a different pitch for each channel.
      phase.left += 0.01
      phase.right += 0.03

      if phase.left >= 1:
        phase.left = -1

      if phase.right >= 1:
        phase.right = -1

    # Lower the amplitude (volume).
    for i in 0.. <framesPerBuf.int:
      outBuf[i].left *= 0.1
      outBuf[i].right *= 0.1
  else:
    for i in 0.. <framesPerBuf.int:
      outBuf[i].left = inBuf[i].left
      outBuf[i].right = inBuf[i].right

  scrContinue.cint

proc check(err: TError|TErrorCode) =
  if cast[TErrorCode](err) != PA.NoError:
    raise newException(Exception, $PA.GetErrorText(err))


var
  phase = (left: 0.cfloat, right: 0.cfloat)
  stream: PStream


check(PA.Initialize())

echo "------------------------------------------------"

let desiredHostApiCond = proc(x: string): bool =
  #x.toLower().contains("wasapi")
  x.toLower().contains("wdm") and x.toLower().contains("ks")
  #x.toLower().contains("mme")
var desiredHostApiIndex = 0

let framesPerBuffer = 64 # PA.FramesPerBufferUnspecified # 256
let latencyFactor = 0.1

let numHostApis = PA.GetHostApiCount()
for i in 0 ..< numHostApis:
  let hostApiInfo = PA.GetHostApiInfo(i.cint)
  echo(" ** Host API number: ", i)
  echo("    Name: ", hostApiInfo.name)
  echo("    Struct version: ", hostApiInfo.structVersion)
  #echo("PaHostApiTypeId: ", hostApiInfo.HostApiTypeId)
  echo("    Device count: ", hostApiInfo.deviceCount)
  echo("    Default input device: ", hostApiInfo.defaultInputDevice)
  echo("    Default output device: ", hostApiInfo.defaultOutputDevice)
  if desiredHostApiCond($hostApiInfo.name):
    echo(" => matches requirements")
    desiredHostApiIndex = i
echo "------------------------------------------------"


let
  deviceCondI = proc(x: string): bool =
    x.toLower.contains("line") and x.toLower.contains("in")
  deviceCondO = proc(x: string): bool = (
    x.toLower.contains("rift") and x.toLower.contains("headphones") or
    x.toLower.contains("headphone") and x.toLower.contains("headphones")
  )

var
  deviceI = -1
  deviceO = -1

let numDevices = PA.GetDeviceCount()
for i in 0 ..< numDevices:
  let deviceInfo = PA.GetDeviceInfo(i.cint)
  echo(" ** Device number: ", i)
  echo("    Name: ", deviceInfo.name)
  echo("    Host API: ", deviceInfo.hostApi)
  echo("    maxInputChannels: ", deviceInfo.maxInputChannels)
  echo("    maxOutputChannels: ", deviceInfo.maxOutputChannels)
  echo("    defaultLowInputLatency: ", deviceInfo.defaultLowInputLatency)
  echo("    defaultLowOutputLatency: ", deviceInfo.defaultLowOutputLatency)
  echo("    defaultHighInputLatency: ", deviceInfo.defaultHighInputLatency)
  echo("    defaultHighOutputLatency: ", deviceInfo.defaultHighOutputLatency)
  echo("    defaultSampleRate: ", deviceInfo.defaultSampleRate)
  if deviceInfo.hostApi == desiredHostApiIndex:
    if deviceCondI($deviceInfo.name) and deviceInfo.maxInputChannels > 0:
      echo(" => matches input device condition")
      deviceI = i
    if deviceCondO($deviceInfo.name) and deviceInfo.maxOutputChannels > 0:
      echo(" => matches output device condition")
      deviceO = i

echo "------------------------------------------------"

if deviceI == -1:
  deviceI = PA.GetDefaultInputDevice()
  echo("No input device matches device condition; using default device ", deviceI)
if deviceO == -1:
  deviceO = PA.GetDefaultOutputDevice()
  echo("No output device matches device condition; using default device ", deviceO)


echo("Using input device ", deviceI, " and output device ", deviceO)

var
  paramsI = PA.TStreamParameters(
    device: deviceI.TDeviceIndex,
    channelCount: 2,
    hostApiSpecificStreamInfo: nil,
    sampleFormat: PA.TSampleFormat.sfFloat32,
    suggestedLatency: PA.GetDeviceInfo(deviceI.TDeviceIndex).defaultLowInputLatency * latencyFactor,
  )
  paramsO = PA.TStreamParameters(
    device: deviceO.TDeviceIndex,
    channelCount: 2,
    hostApiSpecificStreamInfo: nil,
    sampleFormat: PA.TSampleFormat.sfFloat32,
    suggestedLatency: PA.GetDeviceInfo(deviceO.TDeviceIndex).defaultLowOutputLatency * latencyFactor,
  )

#[
check(PA.OpenDefaultStream(cast[PStream](stream.addr),
                           numInputChannels = 2,
                           numOutputChannels = 2,
                           sampleFormat = sfFloat32,
                           sampleRate = 44_100,
                           framesPerBuffer = 256,
                           streamCallback = streamCallback,
                           userData = cast[pointer](phase.addr)))
]#

let sampleRateI =  PA.GetDeviceInfo(deviceI.TDeviceIndex).defaultSampleRate
let sampleRateO =  PA.GetDeviceInfo(deviceO.TDeviceIndex).defaultSampleRate
if sampleRateI != sampleRateO:
  echo("Warning input/output sample rates do not match: ", sampleRateI, " != ", sampleRateO)
let sampleRate = sampleRateO

var callback = streamCallback

check(PA.OpenStream(
  cast[PStream](stream.addr),
  paramsI.addr,
  paramsO.addr,
  sampleRate = sampleRate,
  framesPerBuffer = framesPerBuffer.cuLong, # 256, # PA.FramesPerBufferUnspecified, # 256
  PA.NoFlag,
  streamCallback = cast[ptr TStreamCallback](callback),
  userData = cast[pointer](phase.addr))
)

check(PA.StartStream(stream))

var c = 0
while c == 0:
  sleep(1000)
  let streamInfo = PA.GetStreamInfo(stream)
  echo("Stream latency: input = ", streamInfo.inputLatency, ", output = ", streamInfo.outputLatency)
  c = kbhit()

check(PA.StopStream(stream))
check(PA.CloseStream(stream))
check(PA.Terminate())
