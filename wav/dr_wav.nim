# dr_wav.h nim wrapper

{.passL:"dr_wav.o".} # cc -c -O3 dr_wav.c

const 
  dw_header="dr_wav.h"
  
  # Common data formats. 
  DR_WAVE_FORMAT_PCM* = 0x1
  DR_WAVE_FORMAT_ADPCM* = 0x2
  DR_WAVE_FORMAT_IEEE_FLOAT* = 0x3
  DR_WAVE_FORMAT_ALAW* = 0x6
  DR_WAVE_FORMAT_MULAW* = 0x7
  DR_WAVE_FORMAT_DVI_ADPCM* = 0x11
  DR_WAVE_FORMAT_EXTENSIBLE* = 0xFFFE
  #
  DRWAV_TRUE* = 1
  DRWAV_FALSE* = 0

type 
  drwav*  {.header:dw_header, importc:"drwav".} = object

  WavFormat*  {.header:dw_header, importc:"drwav_data_format"} = object
    container, format, channels,  sampleRate,   bitsPerSample : uint32

  wav_def* [T] = tuple[channels, sample_rate : int, samples : seq[T] ]

  drwav_container = enum 
    drwav_container_riff,  drwav_container_w64,  drwav_container_rf64


# dr_wav wrapper
proc drwav_version() : cstring {.header:dw_header, importc:"drwav_version_string".}
# readers(f32, s32, s16)
proc drwav_open_file_and_read_pcm_frames_f32(file_name : cstring, channels, sample_rate:ptr cuint, nframes: ptr uint64, call_back:pointer) : ptr cfloat 
  {.header:dw_header, importc:"drwav_open_file_and_read_pcm_frames_f32".}
proc drwav_open_file_and_read_pcm_frames_s32(file_name : cstring, channels, sample_rate:ptr cuint, nframes: ptr uint64, call_back:pointer) : ptr int32
  {.header:dw_header, importc:"drwav_open_file_and_read_pcm_frames_s32".}
proc drwav_open_file_and_read_pcm_frames_s16(file_name : cstring, channels, sample_rate:ptr cuint, nframes: ptr uint64, call_back:pointer) : ptr int16
  {.header:dw_header, importc:"drwav_open_file_and_read_pcm_frames_s16".}
# writers(init, write, uinit)
proc drwav_init_file_write(wav : ptr drwav, file_name : cstring, format : ptr WavFormat, alloc_cb : pointer) : int32 
  {.header:dw_header, importc:"drwav_init_file_write".}
proc drwav_write_pcm_frames(wav : ptr drwav, framesToWrite : uint64, pData : pointer) : uint64 
  {.header:dw_header, importc:"drwav_write_pcm_frames".}

proc drwav_uninit(pwav : ptr drwav) {.header:dw_header, importc:"drwav_uninit".}
proc drwav_free(p:pointer, cbp:pointer) {.header:dw_header, importc:"drwav_free".}

#nim wrap
proc dw_version*() : string = $drwav_version()

proc read_wav*[T](file_name : string) : wav_def[T] = # let w = read_wav[float32]("test.wav")
  var 
    channels, sample_rate: cuint 
    n_frames : uint64
    samples : seq[T]

  let pSamples = 
    when T is int16: drwav_open_file_and_read_pcm_frames_s16(file_name, channels.addr, sample_rate.addr, n_frames.addr, nil)
    elif T is int32: drwav_open_file_and_read_pcm_frames_s32(file_name, channels.addr, sample_rate.addr, n_frames.addr, nil)
    elif T is float32: drwav_open_file_and_read_pcm_frames_f32(file_name, channels.addr, sample_rate.addr, n_frames.addr, nil)
    else: nil
  
  if pSamples!=nil:
    samples.setLen n_frames * channels
    copyMem(samples[0].addr, pSamples, n_frames.int * T.sizeof * channels.int)
    pSamples.drwav_free nil # once copied, release

  (channels.int, sample_rate.int, samples)

proc write_wav* [T](file_name : string, format: WavFormat, samples: seq[T]) : bool =
  var wav : drwav

  result = drwav_init_file_write(wav.addr, file_name.cstring, format.unsafeAddr, nil) == DRWAV_TRUE
  if result:
    let samples_to_write = samples.len.uint64 div format.channels.uint64
    result = drwav_write_pcm_frames(wav.addr, samples_to_write, samples[0].unsafeAddr) == samples_to_write
    drwav_uninit(wav.addr)

proc samples2secs*(format:WavFormat, samples:int):float=
  samples.float / format.sampleRate.float / format.channels.float

proc print[T](r:wav_def[T])=
  echo "channels   :", r.channels
  echo "sample rate:", r.sample_rate
  echo "n_frames   :", r.samples.len
  if r.samples.len>5:
    echo "samples    :", r.samples[0..5] , r.samples[^5..^1]

when isMainModule:
  import random

  let file_name = "/home/asd/Documents/_voicesync/wav/ah - Roberto.WAV"

  proc test_readwav(file_name:string)=
    let r = read_wav[int16](file_name)
    r.print

  proc test_readrec=
    let
      file_name = "recording.wav"
      r = read_wav[float32](file_name)

    r.print

  proc test_writewavi16=

    var format = WavFormat(container : drwav_container_riff.uint32, format : DR_WAVE_FORMAT_PCM, channels : 1, sampleRate : 22050, bitsPerSample : 16)

    var samples=newSeq[int16](10000)
    for s in samples.mitems: s = (16000 - rand(32000)).int16

    echo "writing samples:", samples[0..10], samples[^10..^1]
    echo "write result:", write_wav[int16]("recording.wav", format, samples)

  proc test_writewavf32=

    var format = WavFormat(container : drwav_container_riff.uint32, format : DR_WAVE_FORMAT_IEEE_FLOAT, channels : 2, sampleRate : 22050, bitsPerSample : 32)
    let n_samples=20000

    var samples=newSeq[float32](n_samples)
    for s in samples.mitems: s = 1 - 2*rand(1.0)
    echo "format   :", format
    echo "n_samples:", samples.len
    echo "seconds  :", format.samples2secs(n_samples)
    echo "writing samples:", samples[0..5], samples[^5..^1]
    echo "write result   :", if write_wav[float32]("recording.wav", format, samples): "ok" else: "fail"
    echo ""

  echo "dw version  :", dw_version()
  # test_readwav(file_name)
  test_writewavf32()
  test_readrec()