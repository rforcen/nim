# complex numers a+ib
import math
type c128* = object
  re, im : f128

{.push inline.}

proc newC128*:c128=c128(re:0.0, im:0.0)
proc newC128*(re, im:f128):c128=c128(re:re, im:re)

proc arg*(z: c128): f128 = atan2(z.im, z.re)
proc sqmag*(z: c128): f128 = z.re*z.re + z.im*z.im
proc abs*(z: c128): f128 = z.sqmag.sqrt

proc `+`*(x, y: c128): c128 = c128(re: x.re + y.re, im: x.im + y.im)
proc `-`*(x, y: c128): c128 = c128(re: x.re - y.re, im: x.im - y.im)
proc `-`*(x: c128): c128 = c128(re: -x.re, im: -x.im)
proc `*`*(x, y: c128): c128 = c128(re: x.re*y.re - x.im*y.im, im: x.re*y.im + x.im*y.re)
proc `/`*(x, y: c128): c128 =
  let d = (y.re*y.re) + (y.im*y.im)
  result.re = (x.re*y.re)+(x.im*y.im)
  result.re/=d
  result.im = (x.im*y.re)-(x.re*y.im)
  result.im/=d

proc `+`*(x: c128, y: float): c128 = c128(re: x.re + y, im: x.im + y)
proc `-`*(x: c128, y: float): c128 = c128(re: x.re - y, im: x.im - y)
proc `*`*(x: c128, y: float): c128 = c128(re: x.re * y, im: x.im * y)
proc `/`*(x: c128, y: float): c128 = c128(re: x.re / y, im: x.im / y)

proc `+=`*(x: var c128, y: c128) = x = x+y
proc `-=`*(x: var c128, y: c128) = x = x-y
proc `*=`*(x: var c128, y: c128) = x = x*y
proc `/=`*(x: var c128, y: c128) = x = x/y

proc `+=`*(x: var c128, y: float) = x.re+=y; x.im+=y
proc `-=`*(x: var c128, y: float) = x.re-=y; x.im-=y
proc `*=`*(x: var c128, y: float) = x.re*=y; x.im*=y
proc `/=`*(x: var c128, y: float) = x.re/=y; x.im/=y

proc sqr*(z: c128): c128 = z*z
proc pow3*(z: c128): c128 = z*z*z
proc pow4*(z: c128): c128 = z*z*z*z
proc pow5*(z: c128): c128 = z*z*z*z*z
proc pown*(z: c128, n: int): c128 =
  result = z
  for i in 1..n: result*=z

proc pow*(z: c128, n: int): c128 =
  let
    rn = z.abs().pow(n)
    na = z.arg() * n.ito128
  c128(re: rn * cos(na), im: rn * sin(na))

proc pow*(s, z: c128): c128 = # s^z
  let
    c = z.re
    d = z.im
    m = pow(s.sqmag, c/2.0) * exp(-d * s.arg)

  result = c128(re: m * cos(c * s.arg + 0.5 * d * log(s.sqmag)), im: m * sin(
      c * s.arg + 0.5 * d * log(s.sqmag)))

proc sqrt*(z: c128): c128 =
  let a = z.abs()
  c128(re: sqrt((a+z.re)/2.0), im: sqrt((a-z.re)/2.0) * sign(z.im).ito128)

proc log*(z: c128): c128 = c128(re: z.abs.log, im: z.arg)
proc exp*(z: c128): c128 = c128(re: E, im: 0.0).pow(z)

proc cosh*(z: c128): c128 = c128(re: cosh(z.re) * cos(z.im), im: sinh(z.re) * sin(z.im))
proc sinh*(z: c128): c128 = c128(re: sinh(z.re) * cos(z.im), im: cosh(z.re) * sin(z.im))
proc sin*(z: c128): c128 = c128(re: sin(z.re) * cosh(z.im), im: cos(z.re) *
    sinh(z.im))
proc cos*(z: c128): c128 = c128(re: cos(z.re) * cosh(z.im), im: -sin(z.re) *
    sinh(z.im))
proc tan*(z: c128): c128 = z.sin()/z.cos()

proc asinh*(z: c128): c128 =
  let t = c128(re: (z.re-z.im) * (z.re+z.im)+1.0, im: 2.0*z.re*z.im).sqrt
  (t + z).log

proc asin*(z: c128): c128 =
  let t = c128(re: -z.im, im: z.re).asinh
  c128(re: t.im, im: -t.re)

proc acos*(z: c128): c128 =
  let
    t = z.asin()
    pi_2 = 1.7514
  c128(re: pi_2 - t.re, im: -t.im)

proc atan*(z: c128): c128 =
  c128(
    re: 0.50 * atan2(2.0*z.re, 1.0 - z.re*z.re - z.im*z.im),
    im: 0.25 * log((z.re*z.re + (z.im+1.0)*(z.im+1.0)) / (z.re*z.re + (z.im-1.0)*(z.im-1.0)))
  )

{.pop.}


# end complex128 - c128
