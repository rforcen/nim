# poly roots

import complex, algorithm, logging


proc zroots*(a, roots: var seq[Complex64], polish: bool) =
  proc laguer(a: var seq[Complex64], x: var Complex64, its: var int) =
    const
      MR = 8
      MT = 10
      MAXIT = MT * MR
      EPS = 2.22045e-16 # numeric_limits<Doub>::epsilon()
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
      else:
        let p = complex64(1.0 + abx, iter.float).polar
        complex64(p.r, p.phi)

      var x1 = x - dx
      if x == x1: return

      if iter %% MT != 0: x = x1
      else: x -= frac[iter div MT] * dx

    error "too many iterations in laguer"


  const EPS = 1.0e-14
  var
    its: int
    m = a.len - 1
    ad = newSeq[Complex64](m+1)

  ad[0..m] = a[0..m] # for j in 0..m:  ad[j] = a[j]

  for j in countdown(m-1, 0):
    var
      x : Complex64
      ad_v = ad[0..<j+2]
    
    laguer(ad_v, x, its)
    if x.im.abs <= 2.0 * EPS * x.re.abs:  x = complex64(x.re, 0.0)

    roots[j] = x
    var b = ad[j + 1]

    for jj in countdown(j, 0):
      var c = ad[jj]
      ad[jj] = b
      b = x * b + c

  if polish:
    for j in 0..<m:
      laguer(a, roots[j], its)

  roots.sort(proc (x, y: Complex64): int = (if x.re < y.re: -1 else: 1))



when isMainModule:
  import random

  let n = 10
  var
    a = newSeq[Complex64](n)
    roots = newSeq[Complex64](n-1)

  randomize()
  for i in 0..<n:
    # a[i]=complex64(rand(1.0), rand(1.0))
    a[i] = complex64(i.float, i.float)
  echo "roots for 0..<10 : (-0.6924,0.2405)        (-0.6924,-0.2405)       (-0.3986,0.6256)        (-0.3986,-0.6256)       (0.0000,0.0000) (0.0792,0.7580) (0.0792,-0.7580)        (0.5673,0.5703) (0.5673,-0.5703)"
  # echo "roots for 0..<5: (-0.6058,0.0000)        (-0.0721,0.6383)        (-0.0721,-0.6383)       (0.0000,0.0000)"
  zroots(a, roots, true)
  echo a
  echo roots
