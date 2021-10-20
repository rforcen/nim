# lpc:  linear predictive coding

import math

type LPC = object
  count: int
  delayLine, impulseResponse, coefs: seq[float]

# fwds
proc getOutputSample*(lpc: var LPC, inputSample: float): float
proc init*(lpc: var LPC)
proc getCoefficients*(lpc: var LPC, p: int, x: seq[float]): seq[float]

# methods
proc newLPC*(): LPC = LPC()

proc filter*(lpc: var LPC, y: seq[float], n: int): seq[float] =
  for i in 0..<n: result.add(lpc.getOutputSample(y[i]))

proc eval*(lpc: var LPC, y: seq[float], n: int): seq[float] =
  for i in 0..<n:
    var 
      yp = 0.0
      yy = y[i]
    for j in 0..<lpc.coefs.len:
      yp += lpc.coefs[j] * (yy ^ j)
    result.add(yp)

proc calcCoeff*(lpc: var LPC, p: int, x: seq[float]) =
  lpc.coefs = lpc.getCoefficients(p, x)
  lpc.init()

proc init*(lpc: var LPC) =
  lpc.impulseResponse = lpc.coefs
  lpc.delayLine = newSeq[float](lpc.coefs.len)
  lpc.count = 0

proc getOutputSample*(lpc: var LPC, inputSample: float): float = # evaluate conv
  lpc.delayLine[lpc.count] = inputSample
  result = 0.0
  var index = lpc.count
  for i in 0..<lpc.coefs.len:
    result += lpc.impulseResponse[i] * lpc.delayLine[index]
    index.dec
    if index < 0:
      index = lpc.coefs.len - 1
  lpc.count.inc
  if lpc.count >= lpc.coefs.len: lpc.count = 0

proc getCoefficients*(lpc: var LPC, p: int, x: seq[float]): seq[float] =
  var r = newSeq[float](p+1) # = new double[p + 1] # size = 11
  let N = x.len # size = 256
  for T in 0..<p + 1:
    for t in 0..<N - T:
      r[T] += x[t] * x[t + T]

  var
    e = r[0]
    alpha_new = newSeq[float](p + 1)
    alpha_old = newSeq[float](p + 1)

  alpha_new[0] = 1.0
  alpha_old[0] = 1.0

  var sum = 0.0
  for i in 1..p:
    sum = 0
    for j in 1..i - 1:
      sum += alpha_old[j] * (r[i - j])
    let k = ((r[i]) - sum) / e
    alpha_new[i] = k
    for c in 1..i - 1:
      alpha_new[c] = alpha_old[c] - (k * alpha_old[i - c])
    var e1 = (1 - (k * k)) * e
    for g in 0..i:
      alpha_old[g] = alpha_new[g]
    e = e1

  for a in 1..<p + 1:  alpha_new[a] = -alpha_new[a]

  alpha_new

when isMainModule:
  let xl = 256
  var
    x = newSeq[float](xl)
    lpc = newLPC()

  for i, v in x.mpairs: v = 16000 * sin(2 * PI * 8000 * i.float / 44100)
  let alpha = lpc.getCoefficients(10, x)

  echo "lpc coeff:"
  echo alpha
