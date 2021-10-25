# formants lpc method

import math, complex, algorithm
import lpc, poly_roots_laguerre, nim_fftw3, sig_wind

type Formant* = object
  hz*, bw*, pwr*: float # freq, bandwidth, power

proc cmp_hz*(x, y: Formant): int =
  if x.hz > y.hz: 1
  else:
    if x.hz < y.hz: -1
    else: 0

proc cmp_pwr*(x, y: Formant): int =
  if x.pwr > y.pwr: 1
  else:
    if x.pwr < y.pwr: -1
    else: 0

proc cmp_bw*(x, y: Formant): int =
  if x.bw > y.bw: 1
  else:
    if x.bw < y.bw: -1
    else: 0

proc cmp_db*(x, y: Formant): int =
  - (x.cmp_pwr y)

proc index2freq*(i:int, sample_rate:float,  nfft:int) : float =
   i.float * (sample_rate / nfft.float)

proc freq2index*(freq, sample_rate : float,  nfft:int) : int =
  freq.int div (sample_rate /  nfft.float).int

proc db*(c : Complex) : float = 
  result = 10.0 * (c.abs / 1e-12 ).log10 
  if result.classify == fcNaN or result.classify == fcInf:  result = 0
  
proc `*`(x,y:seq[float]) : seq[float] =
  result = newSeq[float](x.len)
  for i in 0..x.high: result[i]=x[i]*y[i]

proc formants*(samples: seq[float],  sample_rate: float): (seq[Formant], seq[Complex64]) =
  var
    lpc = newLPC()
    roots: seq[Complex64]

  let # filter samples w/hamming window
    n_coeff = (2 + sample_rate / 100).int.power_2 # lpc coeff
    coeff = lpc.getCoefficients(n_coeff, samples * signal_window(HAMMING, samples.len))
    srpi2 = sample_rate / (PI * 2)
    srpi = sample_rate / PI

  zroots(coeff, roots, true)

  var formants : seq[Formant]

  for root in roots:
    if root.im > 0.01:
      let
        hz = srpi2 * root.im.arctan2(root.re)
        bw = srpi * root.abs.ln

      if hz > 0 and bw < 400: # formant frequencies should be greater than 0 Hz with bandwidths less than 10 Hz
        formants.add(Formant(hz: hz.ceil, bw: bw, pwr: 0))

  formants.sort(cmp_hz)


  # freq. response & calc. power
  var 
    nfft = coeff.len.power_2 # sample_rate.int.power_2.shr 2 # closer power of 2 (log2)
    freqresp : seq[Complex64]
    fft = fft(nfft)

  fft.set(coeff)
  fft.exec()

  for i in 0..<nfft div 2: 
    freqresp.add( complex(i.index2freq(sample_rate, nfft).float, fft.cout[i].db ) )

  for f in formants.mitems:
    f.pwr = fft.cout[f.hz.freq2index(sample_rate, nfft) %% fft.cout.len].db

  formants.sort(cmp_bw)

  (formants, freqresp)
  

when isMainModule:
  import sugar, sequtils, dr_wav

  proc gen_wave(amps, freqs: seq[float], sample_rate: float,
      n_samples: int): seq[float] =
    result = newSeq[float](n_samples)
    for i, v in result.mpairs:
      var s = 0.0
      for j, f in freqs.pairs:
        s += amps[j] * sin(2 * PI * f * i.float / sample_rate)
      v = s / amps.len.float

  proc test_formants_gen_wave=
    var
      sample_rate = 44100.0
      freqs = @[8000.0, 1234, 645, 3456, 5678, 2300]
      amps =  @[10.0  ,    3,   9,    5,    6,    8]

    let 
      n_samples = (sample_rate * 3).int
      samples = gen_wave(amps, freqs, sample_rate, n_samples)

    let (formats, freqresp) = formants(samples = samples,  sample_rate = sample_rate)

    echo "wave:"
    echo amps
    echo freqs
    echo "formants:"
    for f in formats.filter(x => x.bw < 1).sorted(cmp_pwr): echo f

  
  proc test_formants_wav_file=
    let 
      file_name = "test.wav"
      wav = read_wav[float](file_name)

    echo "formants"
    echo "file       :", file_name
    echo "sample rate:", wav.sample_rate

    var (formats, freqresp) = formants(samples = wav.samples, sample_rate = wav.sample_rate.float)
    
    formats = formats.sorted(cmp_bw).deduplicate
    echo "formants:", formats.len
    for f in formats[0..6].sorted(cmp_hz): echo f
    # for fr in freqresp:  echo fr.re," ", fr.im

  test_formants_wav_file()
  