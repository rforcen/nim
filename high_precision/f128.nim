# f128.nim: c long double  wrapper, c version
# nim c

{.passL: "-lm".} # link with -lm

type f128* {.importc: "long double".} = object
const math_header = "<math.h>"

# wrap
{.push inline.}

proc `+`*(x, y: f128): f128 = {.emit: [result, "=x+y;"].}
proc `-`*(x, y: f128): f128 = {.emit: [result, "=x-y;"].}
proc `-`*(x: f128): f128 = {.emit: [result, "=-x;"].}
proc `*`*(x, y: f128): f128 = {.emit: [result, "=x*y;"].}
proc `/`*(x, y: f128): f128 = {.emit: [result, "=x/y;"].}
proc `^`*(x, y: f128): f128 = {.emit: [result, "=pow(x,y);"].}

proc `+=`*(x: var f128, y: f128) = {.emit: "*x+=y;".}
proc `-=`*(x: var f128, y: f128) = {.emit: "*x-=y;".}
proc `*=`*(x: var f128, y: f128) = {.emit: "*x*=y;".}
proc `/=`*(x: var f128, y: f128) = {.emit: "*x/=y;".}

proc `==`*(x, y: f128): bool = {.emit: [result, "=x==y;"].}
proc `!=`*(x, y: f128): bool = {.emit: [result, "=x!=y;"].}
proc `>=`*(x, y: f128): bool = {.emit: [result, "=x>=y;"].}
proc `<=`*(x, y: f128): bool = {.emit: [result, "=x<=y;"].}
proc `>`*(x, y: f128): bool = {.emit: [result, "=x>y;"].}
proc `<`*(x, y: f128): bool = {.emit: [result, "=x<y;"].}

proc sin*(x: f128): f128 {.importc: "sin", header: math_header.}
proc cos*(x: f128): f128 {.importc: "cos", header: math_header.}
proc tan*(x: f128): f128 {.importc: "tan", header: math_header.}
proc sinh*(x: f128): f128 {.importc: "sinh", header: math_header.}
proc cosh*(x: f128): f128 {.importc: "cosh", header: math_header.}
proc tanh*(x: f128): f128 {.importc: "tanh", header: math_header.}
proc asin*(x: f128): f128 {.importc: "asin", header: math_header.}
proc acos*(x: f128): f128 {.importc: "acos", header: math_header.}
proc atan*(x: f128): f128 {.importc: "atan", header: math_header.}
proc atan2*(x, y: f128): f128 {.importc: "atan2", header: math_header.}

proc pow*(x, y: f128): f128 {.importc: "pow", header: math_header.}
proc exp*(x: f128): f128 {.importc: "exp", header: math_header.}
proc log*(x: f128): f128 {.importc: "log", header: math_header.}
proc log10*(x: f128): f128 {.importc: "log10", header: math_header.}
proc sqrt*(x: f128): f128 {.importc: "sqrt", header: math_header.}

proc floor*(x: f128): f128 {.importc: "floor", header: math_header.}
proc ceil*(x: f128): f128 {.importc: "ceil", header: math_header.}
proc abs*(x: f128): f128 {.importc: "fabs", header: math_header.}

proc lmod*(x: f128): (f128, int) =
  var
    i: float
    fract: f128
  {.emit: "fract=modf(x, &i);".}
  (fract, i.int)

# conversions
converter fto128*(f: float): f128 = # {.emit:[result, "=(long double)f; "].} # this mangles vsc coloring
  var r: f128; {.emit: "r=(long double)f; ".}; r
converter ito128*(i: int): f128 = # {.emit:[result, "=(long double) i;"].}
  var r: f128; {.emit: "r=(long double)i; ".}; r

proc sign*(x: f128): int =
  if x<0: -1
  elif x>0: 1
  else: 0

{.pop.}

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
{.emit:"#include <stdio.h>".}

proc `$`*(x: f128): string =
  var
    conv_buff: array[128, char]
    cl: cint
  {.emit: " cl = sprintf(conv_buff, \"%Le\", x); ".}
  for i in 0..<cl: result.add(conv_buff[i])


# factorial
proc `!`*(n: int): f128 =
  if n > 0: n.f128 * !(n-1) else: 1.0

# test

when isMainModule:
  proc test_f128=
    var f0, f1, f2: f128

    f1 = 123.45
    f2 = 456.78

    echo f1, f2, f1+f2

    # assert comps
    assert f1 != f2
    assert f1 == f1
    assert f2 >= f0
    assert f2 > f1
    assert f1 < f2
    assert f1 <= f2

    # assert algebra
    assert f1+f2 == 123.45.f128 + 456.78.f128, "+ doesn't work"
    assert f1-f2 == 123.45.f128 - 456.78.f128, "- doesn't work"
    assert f1*f2 == 123.45.f128 * 456.78.f128, "* doesn't work"
    assert f1/f2 == 123.45.f128 / 456.78.f128, "/ doesn't work"
    assert f1+f2 != (123.45 + 456.78).f128

    f1+=f2
    echo "+=", f1, "==", 123.45+456.78

    f0 = f1+f2*f1
    echo "f0=f1+f2*f1=", f0, ", f1=", f1, ", f2=", f2
    echo "factorial(900) * 4 = ", !900 * 4
    f1 = f1^(f2/10)
    echo "f1.some func = ", f1.sin.sinh.atan.floor.exp.log
    f2 = 123.456.f128.sqrt
    f0 = -678.89.f128
    echo f0, ", ", f0.abs
    echo 123.456.sqrt, ", ", f2.abs
    echo f2, ", ", f2.lmod

    echo "atan2=", atan2(f1,f2)

    # seq's
    var sf: seq[f128]

    for i in 0..100:
      var f: f128
      case i %% 3:
        of 0: f = f0
        of 1: f = f1
        of 2: f = f2
        else: f = f0
      sf.add(f)
    echo sf[0..10], sf[sf.high-10..sf.high]

  import times, complex, sugar

  proc test_c128=
    var
      c0 = newC128(1, 0)
      z = c0
      zv = newSeq[c128](100)

    # init all items in vect, notice that z=c0 will not work
    for z in zv.mitems: z = c0

    let zzv = collect(newSeq):
      for i in 0..100:
        z
    for zz in zzv: z+=zz
    echo "z=", z
    z = c0

    c0+=123.67
    let n = 4000
    echo "generating c128 ", n*n

    var t0 = now()
    for i in 0..n*n: # simulate mandelbrot fractal generation
      z = c0
      for it in 0..200:
        z = z*z+c0
        if z.abs > 4.0: break
    echo z
    echo "lap c128:", (now()-t0).inMilliseconds, "ms"

    var
      dz = complex64(1, 0)
      dc0 = dz

    dc0 += complex64(123.67, 123.67)

    t0 = now()
    for i in 0..n*n:
      dz = dc0
      for it in 0..200:
        dz = dz*dz+dc0
        if dz.abs > 4.0: break
    echo dz
    echo "lap complex 64:", (now()-t0).inMilliseconds, "ms"

  test_f128()
  test_c128()