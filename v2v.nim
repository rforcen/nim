# v2v.nim

import algorithm, complex, math, sequtils, sugar
import dr_wav, nim_fftw3, formants

proc `+=`(x:var seq[float], y:seq[Complex64]) =
  for i in 0..x.high: 
    x[i] += y[i].re.abs

type Wave = tuple[freq, pwr : float]

proc cmp_pwr(x0, x1 : Wave) : int = 
  if x0.pwr < x1.pwr: 1 else : -1

# aux proc's
proc max_freq(y:seq[float]) : Wave =
  var
    mx=y[0]
    pi=0
  for i in 0..y.high:
    if y[i] > mx:
      mx = y[i]
      pi = i
  (pi.float, mx)

proc index2freq(i, sample_rate:float,  nfft:int) : float =
   i.float * (sample_rate / nfft.float)

proc freq2index(freq, sample_rate : float,  nfft:int) : int =
  freq.int div (sample_rate /  nfft.float / 2).int

proc db(c : Complex) : float = 
  result = 20.0 * ((1.0 / c).abs + 1e-16).log10 # power in db
  if result.classify == fcNaN or result.classify == fcInf:  result = 0

proc peaks(v : seq[float]) : seq[Wave] =
  for i in 1..v.high-1:
    if v[i]>v[i-1] and v[i]>v[i+1]:
      result.add( (i.float, v[i]) )

proc peaks(v : seq[Wave]) : seq[Wave] =
  for i in 1..v.high-1:
    if v[i].pwr > v[i-1].pwr and v[i].pwr > v[i+1].pwr:
      result.add(v[i])

proc v2v(wav_file:string, nfft : int, npeaks : int = 30) : seq[Wave] =
  let wav = read_wav[float](wav_file)
  var 
    fft = fft(nfft)
    y = newSeq[float](nfft)

  for i in countup(0, wav.samples.high, nfft): # acc. fft
    let vto = i+nfft
    if vto > wav.samples.len: break
    fft.exec(wav.samples[i..<vto])
    y += fft.cout
  
  result = y.peaks.peaks
  var # scale. min/max
    max = result[0].pwr
    min = result[0].pwr

  for p in result: 
    min = min(min, p.pwr)
    max = max(max, p.pwr)

  let df = if max!=min: (max-min).abs else: 1.0

  for p in result.mitems: p.pwr = (p.pwr - min) / df

  for p in result.mitems: # set freqs
    p.freq = p.freq.index2freq(wav.sample_rate.float, nfft)

  result = result.filter(x => x.pwr > 0.4 and x.freq < wav.sample_rate / 2).sorted(cmp_pwr)

proc v2v(samples:seq[float], sample_rate:float):seq[Wave]=
  var (formants, freqresp)  = formants(samples, sample_rate)
  formants = formants.sorted(cmp_bw).deduplicate[0..6].sorted(cmp_hz)
  var
    minpwr=formants[0].pwr
    maxpwr=minpwr

  for f in formants:
    maxpwr=max(maxpwr, f.pwr)
    minpwr=min(minpwr, f.pwr)

    result.add((freq : f.hz, pwr : f.pwr))

  for f in result.mitems:
    f.pwr = ((maxpwr - f.pwr + minpwr) - minpwr) / (maxpwr - minpwr)


when isMainModule:
  proc gen_wave(wave: seq[Wave], sample_rate: float,
      n_samples: int): seq[float] =
    result = newSeq[float](n_samples)
    for i, v in result.mpairs:
      var s = 0.0
      for j, w in wave.pairs:
        s += w.pwr * sin(2 * PI * w.freq * i.float / sample_rate)
      v = s / wave.len.float

  proc test_fft_v2v=
    echo "v2v"
    let 
      nfft = 1024*4
      pks = v2v(wav_file = "test.wav", nfft = nfft, npeaks=100)

    for p in pks: 
      echo p

  proc test_fmts_v2v=
    echo "v2v based on formants"
    let wav = read_wav[float]("test.wav")
    let v2v=v2v(wav.samples, wav.sample_rate.float)
    echo v2v
    echo"generating v2v.wav",  write_wav[float]("v2v.wav", 1, 22050, gen_wave(v2v, 22050, 30000))

  
  test_fmts_v2v()