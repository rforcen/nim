# fastsin.nim

import math

type FastSin* = object
  y0,  y1,  y2,  p,  w,  b,  a,  x: float
  n: int

# a: amp, w:freq, b:phase
proc newFastSin*(a: float, w: float, b: float) : FastSin =
  FastSin( a:a,  w:w,   b:b,    x: 0,   y0: (-2 * w + b).sin,    y1: (-w + b).sin,  y2: 0,  p: 2 * w.cos,  n: -1)

proc with_sample_rate*(fs: FastSin, rate: float) : FastSin =
  proc freq2inc(freq: float, samp: float) : float = freq * 2 * PI / samp
  newFastSin(fs.a, freq2inc(fs.w, rate), fs.b)

proc next*(fs: var FastSin) : float =
  fs.n.inc
  fs.x = fs.n.float * fs.w
  fs.y2 = fs.p * fs.y1 - fs.y0
  fs.y0 = fs.y1
  fs.y1 = fs.y2
  fs.a * fs.y2 # mutl by amp.

proc sin*(fs : var FastSin, x: float) : float =
  fs.n.inc
  fs.x = fs.n.float * fs.w
  fs.a * (fs.w * fs.n.float + fs.b + x).sin


when isMainModule:
  import times

  var 
    n = 100_000_000
    fs = newFastSin(1, 440, 0).with_sample_rate(44100)
    s = 0.0
    t0 = now()

  echo "fastsin test"
  for _ in 0..n: s+=fs.next
  echo "lap for ",n," iters:", (now()-t0).inMilliseconds, "ms, res=",s

  s=0.0
  t0=now()
  for i in 0..n: s+=i.float.sin
  echo "lap for ",n," iters:", (now()-t0).inMilliseconds, "ms, res=",s


  