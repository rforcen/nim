# signal window nim

import math

type WindowType* = enum
  RECTANGULAR, BARTLETT, HANNING, HAMMING, BLACKMAN

proc signal_window*( windowType : WindowType = HAMMING, nSamples : int) : seq[float] =
# generate nSamples window function values
# for index values 0 .. nSamples - 1
  let m = nSamples div 2
  var r : float

  result = newSeq[float](nSamples)

  case windowType:

  of BARTLETT: # Bartlett (triangular) window
    for n in 0..<nSamples:
      result[n] = 1.0 - (n - m).abs.float / m.float

  of HANNING: # Hanning window
    r = PI / (m + 1).float
    for n in -m..<m:
      result[m + n] = 0.5 + 0.5 * (n.float * r).cos
      
  of HAMMING: # Hamming window
    r = PI / m.float
    for n in -m..<m:
      result[m + n] = 0.54 + 0.46 * (n.float * r).cos
      
  of BLACKMAN: # Blackman window
    r = PI / m.float
    for n in -m..<m:
      result[m + n] = 0.42 + 0.5 * (n.float * r).cos + 0.08 * (2 * n.float * r).cos
      
  else: # Rectangular window function
    for n in 0..<nSamples:
      result[n] = 1.0
    