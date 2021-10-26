# fir 

import math

const PI2 = PI * 2

type 
  FilterType = enum 
    BANDPASS, DIFFERENTIATOR, HILBERT
 
  Sign = enum 
    NEGATIVE, POSITIVE
 
  remezCoeffCalc = object  # Parks-McClellan algorithm for FIR filter design
    GRIDDENSITY, MAXITERATIONS : int

proc newRemezCoeffCalc() : remezCoeffCalc = 
  remezCoeffCalc( GRIDDENSITY : 16,  MAXITERATIONS : 40 )

proc CreateDenseGrid(rc:remezCoeffCalc, r, numtaps, numband : int, bands : var seq[float], des, weight : seq[float], gridsize : int, Grid, D, W : var seq[float], symmetry:Sign)= 
  var 
      j, k : int 
      delf, lowf, highf : float

  delf = 0.5 / (rc.GRIDDENSITY * r).float 

  #[
    For differentiator, hilbert, symmetry is odd and Grid[0] = max(delf,
    band[0])
   ]#

  if symmetry == NEGATIVE and delf > bands[0]:
    bands[0] = delf 

  j = 0 
  for band in 0..<numband:
    Grid[j] = bands[2 * band] 
    lowf = bands[2 * band] 
    highf = bands[2 * band + 1] 
    k = ((highf - lowf) / delf + 0.5).int  # .5 for rounding 
    for i in 0..<k:
      D[j] = des[band] 
      W[j] = weight[band] 
      Grid[j] = lowf 
      lowf += delf 
      j.inc 
    
    Grid[j - 1] = highf 
  

  #[
   * Similar to above, if odd symmetry, last grid point can't be .5 - but,
   * if there are even taps, leave the last grid point at .5
   ]#
  if symmetry == NEGATIVE and  Grid[gridsize - 1] > (0.5 - delf) and (numtaps %% 2) != 0:
    Grid[gridsize - 1] = 0.5 - delf 
  

proc InitialGuess(r : int, Ext : var seq[int], gridsize : int) =
  for i in 0..r:
    Ext[i] = i * (gridsize - 1) div r 
  

proc CalcParms( r : int, Ext : seq[int], Grid, D, W : seq[float], ad, x, y : var seq[float]) = 
  var 
    ld : int
    sign, xi, delta, denom, numer : float

  # Find x*

  for i in 0..r:
    x[i] = cos(PI2 * Grid[Ext[i]])

  # Calculate ad* - Oppenheim and  Schafer eq 7.132
  ld = (r - 1) div 15 + 1  # Skips around to avoid round errors 
  for i in 0..r:
    denom = 1.0 
    xi = x[i] 
    for j in 0..<ld:
      for k in countup(j, r, ld):
        if k != i:
          denom *= 2.0 * (xi - x[k]) 
    
    if denom.abs < 0.00001:
      denom = 0.00001 
    ad[i] = 1.0 / denom 
  

  # Calculate delta - Oppenheim and  Schafer eq 7.131
   
  numer = 0
  denom = 0 
  sign = 1 
  for i in 0..r:
    numer += ad[i] * D[Ext[i]] 
    denom += sign * ad[i] / W[Ext[i]] 
    sign = -sign 
  
  delta = numer / denom 
  sign = 1 

  # Calculate y* - Oppenheim and  Schafer eq 7.133b
   
  for i in 0..r:
    y[i] = D[Ext[i]] - sign * delta / W[Ext[i]] 
    sign = -sign 
  

proc ComputeA(freq:float, r:int, ad : var seq[float], x,y : seq[float]) : float =
  var xc, c, denom, numer :float

  xc = cos(PI2 * freq)
  
  for i in 0..r:
    c = xc - x[i] 
    if c.abs < 1.0e-7:
      numer = y[i] 
      denom = 1 
      break 
    
    c = ad[i] / c 
    denom += c 
    numer += c * y[i] 
  
  numer / denom 
  

proc CalcError(r : int, ad, x, y : var seq[float], gridsize : int, Grid, D, W : seq[float], E : var seq[float]) = 
  for i in 0..<gridsize:
    let A = ComputeA(Grid[i], r, ad, x, y) 
    E[i] = W[i] * (D[i] - A) 
  
  

proc Search(r : int, Ext : var seq[int], gridsize : int, E : seq[float]) = 
  var
    j, k, l, extra : int # Counters 
    up, alt :int
    foundExt = newSeq[int](2*r+1)  # Array of found extremals 

  k = 0 

  #   * Check for extremum at 0.
   
  if ((E[0] > 0.0) and (E[0] > E[1])) or ((E[0] < 0.0) and (E[0] < E[1])):
      foundExt[k] = 0
      k.inc

  
  # Check for extrema inside dense grid
   
  for i in 1..<gridsize - 1:
    if ((E[i] >= E[i - 1]) and (E[i] > E[i + 1]) and (E[i] > 0.0)) or ((E[i] <= E[i - 1]) and (E[i] < E[i + 1]) and (E[i] < 0.0)):
      foundExt[k] = i
      k.inc

  # * Check for extremum at 0.5
  j = gridsize - 1 
  if ((E[j] > 0.0) and (E[j] > E[j - 1])) or ((E[j] < 0.0) and (E[j] < E[j - 1])):
    foundExt[k] = j
    k.inc
   
   
  extra = k - (r + 1) 

  while extra > 0:
    if E[foundExt[0]] > 0.0:
      up = 1  # first one is a maxima 
    else:
      up = 0  # first one is a minima 

    l = 0 
    alt = 1 
    for j in 1..<k:
      if E[foundExt[j]].abs < E[foundExt[l]].abs:
        l = j  # new smallest error. 
      if up != 0 and  E[foundExt[j]] < 0.0:
        up = 0  # switch to a minima 
      elif up == 0 and  E[foundExt[j]] > 0.0:
        up = 1  # switch to a maxima 
      else:
        alt = 0 
        break  # Ooops, found two non-alternating 

     # extrema. Delete smallest of them 
     # if the loop finishes, all extrema are alternating 

    #[   * If there's only one extremal and all are alternating, delete the
     * smallest of the first/last extremals.]#
     
    if alt != 0 and  extra == 1:
      if E[foundExt[k - 1]].abs < E[foundExt[0]].abs:
        l = foundExt[k - 1]  # Delete last extremal 
      else:
        l = foundExt[0]  # Delete first extremal 
    

    for j in l..<k: # Loop that does the deletion  
      foundExt[j] = foundExt[j + 1] 
    
    k.dec 
    extra.dec 

  for i in 0..r:
    Ext[i] = foundExt[i]  # Copy found extremals to Ext* 
  

proc FreqSample(N : int, A, h : var seq[float], symm : Sign) = 
  var  x, val, M : float

  M = (N.float - 1.0) / 2.0 

  if symm == POSITIVE:
    if N %% 2 != 0:
      for n in 0..<N:
        val = A[0] 
        x = PI2 * (n.float - M) / N.float 
        for k in 1..M.int:
          val += 2.0 * A[k] * cos(x * k.float)
        h[n] = val / N.float
    else:
      for n in 0..<N:
        val = A[0] 
        x = PI2 * (n.float - M) / N.float
        for k in 1..(N div 2 - 1):
          val += 2.0 * A[k] * cos(x * k.float)
        h[n] = val / N.float
  else:
    if N %% 2 != 0:
      for n in 0..<N:
        val = 0 
        x = PI2 * (n.float - M) / N.float 
        for k in 1..M.int:
          val += 2.0 * A[k] * sin(x * k.float) 
        h[n] = val / N.float
    else:
      for n in 0..<N:
        val = A[N div 2] * sin(PI * (n.float - M))
        x = PI2 * (n.float - M) / N.float 
        for k in 1..(N div 2 - 1):
          val += 2.0 * A[k] * sin(x * k.float) 
        h[n] = val / N.float
        
proc isDone(r : int, Ext : seq[int], E : seq[float]) : int =
  var min, max : float

  max = E[Ext[0]].abs
  min = max

  for i in 1..r:
    max = max.max E[Ext[i]].abs
    min = min.min E[Ext[i]].abs
  
  if ((max - min) / max) < 0.0001: 1 
  else:  0 
  
proc remez*(rc:remezCoeffCalc, h : var seq[float], numtaps, numband : int, bands, des, weight : var seq[float], filter_type : FilterType) =
  var
    Grid, W, D, E : seq[float] 
    iter, gridsize, r : int
    Ext : seq[int]
    taps : seq[float]
    c : float
    x, y, ad : seq[float] 
    symmetry : Sign

  if filter_type == BANDPASS:
    symmetry = POSITIVE 
  else:
    symmetry = NEGATIVE 

  r = numtaps div 2  # number of extrema 
  if numtaps %% 2 != 0 and  symmetry == POSITIVE:
    r.inc 

  #[* Predict dense grid size in advance for memory allocation .5 is so we
    * round up, not truncate ]#
   
  gridsize = 0 
  for i in 0..<numband:
    gridsize += (2.0 * r.float * rc.GRIDDENSITY.float * (bands[2 * i + 1] - bands[2 * i]) + 0.5).int

  if symmetry == NEGATIVE:
    gridsize.dec 
  

  #* Dynamically allocate memory for arrays with proper sizes
   
  Grid = newSeq[float](gridsize) 
  D = newSeq[float](gridsize)
  W = newSeq[float](gridsize) 
  E = newSeq[float](gridsize) 
  Ext = newSeq[int](r + 1)
  taps = newSeq[float](r + 1)
  x = newSeq[float](r + 1)
  y = newSeq[float](r + 1) 
  ad = newSeq[float](r + 1) 

  #* Create dense frequency grid
   
  rc.CreateDenseGrid(r, numtaps, numband, bands, des, weight, gridsize, Grid, D, W, symmetry) 
  InitialGuess(r, Ext, gridsize) 

  # * For Differentiator: (fix grid)
   
  if filter_type == DIFFERENTIATOR:
    for i in 0..<gridsize:
      D[i] = D[i]*Grid[i]  
      if D[i] > 0.0001:
        W[i] /= Grid[i]   

  #[
   * For odd or Negative symmetry filters, alter the D* and W* according
   * to Parks McClellan ]#
   
  if symmetry == POSITIVE: 
    if numtaps %% 2 == 0:
      for i in 0..<gridsize:
        c = cos(PI * Grid[i]) 
        D[i] /= c 
        W[i] *= c 
  else:
    if numtaps %% 2 != 0:
      for i in 0..<gridsize:
        c = sin(PI2 * Grid[i]) 
        D[i] /= c 
        W[i] *= c 
    else:
      for i in 0..<gridsize:
        c = sin(PI * Grid[i]) 
        D[i] /= c 
        W[i] *= c 
  

  #  * Perform the Remez Exchange algorithm
   
  for i in 0..<rc.MAXITERATIONS:
    iter=i
    CalcParms(r, Ext, Grid, D, W, ad, x, y) 
    CalcError(r, ad, x, y, gridsize, Grid, D, W, E) 
    Search(r, Ext, gridsize, E) 
    if isDone(r, Ext, E) != 0:
      break 
  
  if iter == rc.MAXITERATIONS:
    echo "Reached maximum iteration count.\nResults may be bad.\n"
  

  CalcParms(r, Ext, Grid, D, W, ad, x, y) 

  #[
   * Find the 'taps' of the filter for use with Frequency Sampling. If odd
   * or Negative symmetry, fix the taps according to Parks McClellan ]#
   
  for i in 0..numtaps div 2:
    if symmetry == POSITIVE:
      if numtaps %% 2 != 0:
        c = 1 
      else:
        c = cos(PI * i.float / numtaps.float)
    
    else:
      if numtaps %% 2 != 0:
        c = sin(PI2 * (i / numtaps))
      else:
        c = sin(PI * (i / numtaps))
    
    taps[i] = ComputeA(i / numtaps, r, ad, x, y) * c 
  

  #   * Frequency sampling design with calculated taps
   
  FreqSample(numtaps, taps, h, symmetry) 

type FIR = object 
  delayLine, impulseResponse : seq[float]
  count, nCoeff : int

proc coeffSetAVG(numCoeff:int) : seq[float] =
# avg filter, works fine for high freq signals -> good fft anti smearing filter
  result = newSeq[float](numCoeff)
  for i in 0..<numCoeff:
    result[i] = i / (i + 1)

proc calcCoeff*(numCoeff, numband : int, bands, desired, weights : var seq[float], filter_type : FilterType) : seq[float] =
  let rc = newremezCoeffCalc()
  result = newSeq[float](numCoeff)
  rc.remez(result, numCoeff, numband, bands, desired, weights, filter_type)

proc setCoeff*(fir:var FIR, coefs : seq[float], nCoeff : int) =
  fir.nCoeff = nCoeff
  fir.impulseResponse = coefs
  fir.delayLine = newSeq[float](nCoeff)

proc newFIR*():FIR=
  FIR(nCoeff:30, impulseResponse:coeffSetAVG(30), delayLine:newSeq[float](30))

proc newFir*(coeff:seq[float]):FIR=
  FIR(nCoeff:coeff.len, impulseResponse:coeff, delayLine:newSeq[float](coeff.len))

proc newFIR*(nCoeff:int):FIR=
  FIR(nCoeff:nCoeff, impulseResponse:coeffSetAVG(nCoeff), delayLine:newSeq[float](nCoeff))

proc getOutputSample(fir: var FIR, inputSample : float ) : float =
  # evaluate conv
  fir.delayLine[fir.count] = inputSample
  result = 0.0
  var index = fir.count
  for i in 0..<fir.nCoeff:  
    result += fir.impulseResponse[i] * fir.delayLine[index]
    index.dec
    if index < 0:
      index = fir.nCoeff - 1

  fir.count.inc
  if fir.count >= fir.nCoeff:
    fir.count = 0

proc filter*(fir: var FIR, y : var seq[float], n : int) =
  for i in 0..<n:
    y[i] = fir.getOutputSample(y[i])

when isMainModule:
  
  proc test() = # remezCoeff test
    let 
      numtaps = 7

    var 
      h : seq[float]
      rc = newremezCoeffCalc()
    var 
      desired = @[0.float, 1, 0, 1, 0] # band responses [numband]
      weights = @[10.float, 1, 3, 1, 20] # error weights [numband]
      bands = @[0.0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5]   # User-specified band edges [2 * numband]

      expected = @[0.002695, -0.069610, 0.026097, 0.145518, 0.026097, -0.069610, 0.002695]
    h = newSeq[float](numtaps)

    rc.remez(h, numtaps, bands.len div 2, bands, desired, weights, BANDPASS) 
    echo h[0..6]
    echo expected
  
  proc coeffSet01() : seq[float] =
    let numCoeff = 9
    var 
      desired = @[0.0, 0, 0, 1, 1]                                   # band responses [numband]
      weights = @[10.0, 1, 10, 1, 3]                                    # error weights [numband]
      bands = @[0.0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5] # 0..1 range User-specified band edges [2 * numband]

    calcCoeff(numCoeff, bands.len div 2, bands, desired, weights, BANDPASS)

  proc coeffSet02() : seq[float] =
    let numCoeff = 7
    var 
      desired = @[0.0, 1, 0, 1, 0]                                   # band responses [numband]
      weights = @[10.0, 1, 3, 1, 20]                                 # error weights [numband]
      bands = @[0.0, 0.05, 0.1, 0.15, 0.18, 0.25, 0.3, 0.36, 0.41, 0.5] # 0..1 range User-specified band edges [2 * numband]

    calcCoeff(numCoeff, bands.len div 2, bands, desired, weights, BANDPASS)
  
  test()
  echo coeffSet01()
  echo coeffSet02()