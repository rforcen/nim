# poly roots laguerre method, float coeff, complex roots

import complex, algorithm, sequtils, sugar

const EPS = 2.22045e-16 # numeric_limits<Doub>::epsilon()

converter ftoc(f: float): Complex64 = complex64(f, 0.0)
proc polarc(p:Complex64): Complex64 = 
  let pp = p.polar
  complex64(pp.r, pp.phi)

# real coeff
proc zroots*(a: seq[float], roots: var seq[Complex64], polish: bool) =
  proc laguer(a: seq[Complex64], x: var Complex64, its: var int) =
    const
      MR = 8
      MT = 10
      MAXIT = MT * MR
      frac = [0.0, 0.5, 0.25, 0.75, 0.13, 0.38, 0.62, 0.88, 1.0]

    let m = a.len - 1

    for iter in 1..MAXIT:
      its = iter

      var 
        b = a[m]
        err = b.abs
        d, f : Complex64
        abx = x.abs

      for j in countdown(m - 1, 0):
        f = x * f + d
        d = x * d + b
        b = x * b + a[j]
        err = b.abs + abx * err

      err *= EPS
      if b.abs <= err: return

      var 
        g = d / b
        g2 = g * g
        h = g2 - 2.0 * f / b
        sq = ((m - 1).float * (m.float * h - g2)).sqrt
        gp = g + sq
        gm = g - sq

        abp = gp.abs
        abm = gm.abs

      if abp < abm: gp = gm

      var dx = if max(abp, abm) > 0.0: m.float / gp
      else: complex64(1.0 + abx, iter.float).polarc

      var x1 = x - dx
      if x == x1: return

      if iter %% MT != 0: x = x1
      else: x -= frac[iter div MT] * dx

    raise newException(ArithmeticDefect, "roots not found, too many iterations in laguer")


  var
    its: int
    m = a.len - 1
    ad = newSeq[Complex64](m+1)
    ac = a.map(x => x.ftoc)

  for j in 0..m: ad[j] = a[j]

  for j in countdown(m-1, 0):
    var
      x : Complex64
      ad_v = ad[0..<j+2]
    
    laguer(ad_v, x, its)

    if x.im.abs <= 2.0 * EPS * x.re.abs:  x = x.re

    roots[j] = x

    var b = ad[j + 1]
    for jj in countdown(j, 0):
      var c = ad[jj]
      ad[jj] = b
      b = x * b + c

  if polish:
    for r in roots.mitems:
      laguer(ac, r, its)

  # sort by re
  roots.sort(proc (x, y: Complex64): int = (if x.re < y.re: -1 else: 1))

proc eval_poly*(c:seq[float], x:Complex64) : Complex64 =
  result = complex64(c[0],0)
  var p = x
  for i in 1..c.high:
    result += p * c[i] 
    p*=x

proc eval_poly*(c:seq[Complex64], x:Complex64) : Complex64 =
  result = c[0]
  var p = x
  for i in 1..c.high:
    result += p * c[i] 
    p*=x

when isMainModule:
  import random

  randomize()

  var
    ar = @[-1.float,1,1,1,2,3,4,5,-6]
    roots = newSeq[Complex64](ar.len-1)

  zroots(ar, roots, true)

  echo "check roots poly order...", ar.len

  var s=0.0
  for r in roots: 
    echo r
    s+=eval_poly(ar, r).abs
  echo "avg. error:",s/roots.len.float
