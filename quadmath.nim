# quadmath.nim, __float128 wrapper
# doc: https://gcc.gnu.org/onlinedocs/libquadmath

{.passL: "-lm -lquadmath".}

type float128* {.importc: "__float128".} = object
const math_header = "<quadmath.h>"

# wrap
{.push inline.}

proc `+`*(x, y: float128): float128 = {.emit: [result, "=x+y;"].}
proc `-`*(x, y: float128): float128 = {.emit: [result, "=x-y;"].}
proc `-`*(x: float128): float128 = {.emit: [result, "=-x;"].}
proc `*`*(x, y: float128): float128 = {.emit: [result, "=x*y;"].}
proc `/`*(x, y: float128): float128 = {.emit: [result, "=x/y;"].}
proc `^`*(x, y: float128): float128 = {.emit: [result, "=pow(x,y);"].}

proc `+=`*(x: var float128, y: float128) = {.emit: "*x+=y;".}
proc `-=`*(x: var float128, y: float128) = {.emit: "*x-=y;".}
proc `*=`*(x: var float128, y: float128) = {.emit: "*x*=y;".}
proc `/=`*(x: var float128, y: float128) = {.emit: "*x/=y;".}

proc `==`*(x, y: float128): bool = {.emit: [result, "=x==y;"].}
proc `!=`*(x, y: float128): bool = {.emit: [result, "=x!=y;"].}
proc `>=`*(x, y: float128): bool = {.emit: [result, "=x>=y;"].}
proc `<=`*(x, y: float128): bool = {.emit: [result, "=x<=y;"].}
proc `>`*(x, y: float128): bool = {.emit: [result, "=x>y;"].}
proc `<`*(x, y: float128): bool = {.emit: [result, "=x<y;"].}

proc sin*(x: float128): float128 {.importc: "sinq", header: math_header.}
proc cos*(x: float128): float128 {.importc: "cosq", header: math_header.}
proc tan*(x: float128): float128 {.importc: "tanq", header: math_header.}
proc sinh*(x: float128): float128 {.importc: "sinhq", header: math_header.}
proc cosh*(x: float128): float128 {.importc: "coshq", header: math_header.}
proc tanh*(x: float128): float128 {.importc: "tanhq", header: math_header.}
proc asin*(x: float128): float128 {.importc: "asinq", header: math_header.}
proc acos*(x: float128): float128 {.importc: "acosq", header: math_header.}
proc atan*(x: float128): float128 {.importc: "atanq", header: math_header.}
proc atan2*(x, y: float128): float128 {.importc: "atan2q", header: math_header.}

proc pow*(x, y: float128): float128 {.importc: "powq", header: math_header.}
proc exp*(x: float128): float128 {.importc: "expq", header: math_header.}
proc log*(x: float128): float128 {.importc: "logq", header: math_header.}
proc log10*(x: float128): float128 {.importc: "log10q", header: math_header.}
proc sqrt*(x: float128): float128 {.importc: "sqrtq", header: math_header.}

proc floor*(x: float128): float128 {.importc: "floorq", header: math_header.}
proc ceil*(x: float128): float128 {.importc: "ceilq", header: math_header.}
proc abs*(x: float128): float128 {.importc: "fabsq", header: math_header.}


# conversions
converter fto128*(f: float): float128 = # {.emit:[result, "=(__float128)f; "].} # this mangles vsc coloring
  var r: float128; {.emit: "r=(__float128)f; ".}; r
converter ito128*(i: int): float128 = # {.emit:[result, "=(__float128) i;"].}
  var r: float128; {.emit: "r=(__float128)i; ".}; r
converter f128toi*(f: float128): int = 
  var r: cint; {.emit: "r=(int)f; ".}; r.int

converter sto128*(s:cstring): float128 = {.emit:[result, "=strtoflt128 (s, NULL);"].}
converter sto128*(s:string): float128 = s.cstring.sto128

let # constants
  FLT128_MAX* = "1.18973149535723176508575932662800702e4932Q".float128
  FLT128_MIN* = "3.36210314311209350626267781732175260e-4932Q".float128
  FLT128_EPSILON* = "1.92592994438723585305597794258492732e-34Q".float128
  FLT128_DENORM_MIN* = "6.475175119438025110924438958227646552e-4966Q".float128
  M_Eq* = "2.718281828459045235360287471352662498Q"  # e 
  M_LOG2Eq* = "1.442695040888963407359924681001892137Q"  # log_2 e 
  M_LOG10Eq* = "0.434294481903251827651128918916605082Q"  # log_10 e 
  M_LN2q* = "0.693147180559945309417232121458176568Q"  # log_e 2 
  M_LN10q* = "2.302585092994045684017991454684364208Q"  # log_e 10 
  M_PIq* = "3.141592653589793238462643383279502884Q"  # pi 
  M_PI_2q* = "1.570796326794896619231321691639751442Q"  # pi/2 
  M_PI_4q* = "0.785398163397448309615660845819875721Q"  # pi/4 
  M_1_PIq* = "0.318309886183790671537767526745028724Q"  # 1/pi 
  M_2_PIq* = "0.636619772367581343075535053490057448Q"  # 2/pi 
  M_2_SQRTPIq* = "1.128379167095512573896158903121545172Q"  # 2/sqrt(pi) 
  M_SQRT2q* = "1.414213562373095048801688724209698079Q"  # sqrt(2) 
  M_SQRT1_2q* = "0.707106781186547524400844362104849039Q"  # 1/sqrt(2)   

proc sign*(x: float128): int =
  if x<0: -1
  elif x>0: 1
  else: 0

proc lmod*(x: float128): (float128, int) =
  var
    i: float128
    fract: float128
  {.emit: "fract=modfq(x, &i);".}
  (fract, i.int)

{.pop.}

# complex numers a+ib
import math
type Complex128* = object
  re, im : float128

{.push inline.}
proc complex128*:Complex128=Complex128(re:0.0, im:0.0)
proc complex128*(re, im:float128):Complex128=Complex128(re:re, im:re)

proc arg*(z: Complex128): float128 = atan2(z.im, z.re)
proc sqmag*(z: Complex128): float128 = z.re*z.re + z.im*z.im
proc abs*(z: Complex128): float128 = z.sqmag.sqrt

proc `+`*(x, y: Complex128): Complex128 = Complex128(re: x.re + y.re, im: x.im + y.im)
proc `-`*(x, y: Complex128): Complex128 = Complex128(re: x.re - y.re, im: x.im - y.im)
proc `-`*(x: Complex128): Complex128 = Complex128(re: -x.re, im: -x.im)
proc `*`*(x, y: Complex128): Complex128 = Complex128(re: x.re*y.re - x.im*y.im, im: x.re*y.im + x.im*y.re)
proc `/`*(x, y: Complex128): Complex128 =
  let d = (y.re*y.re) + (y.im*y.im)
  result.re = (x.re*y.re)+(x.im*y.im)
  result.re/=d
  result.im = (x.im*y.re)-(x.re*y.im)
  result.im/=d

proc `+`*(x: Complex128, y: float): Complex128 = Complex128(re: x.re + y, im: x.im + y)
proc `-`*(x: Complex128, y: float): Complex128 = Complex128(re: x.re - y, im: x.im - y)
proc `*`*(x: Complex128, y: float): Complex128 = Complex128(re: x.re * y, im: x.im * y)
proc `/`*(x: Complex128, y: float): Complex128 = Complex128(re: x.re / y, im: x.im / y)

proc `+=`*(x: var Complex128, y: Complex128) = x = x+y
proc `-=`*(x: var Complex128, y: Complex128) = x = x-y
proc `*=`*(x: var Complex128, y: Complex128) = x = x*y
proc `/=`*(x: var Complex128, y: Complex128) = x = x/y

proc `+=`*(x: var Complex128, y: float) = x.re+=y; x.im+=y
proc `-=`*(x: var Complex128, y: float) = x.re-=y; x.im-=y
proc `*=`*(x: var Complex128, y: float) = x.re*=y; x.im*=y
proc `/=`*(x: var Complex128, y: float) = x.re/=y; x.im/=y

proc sqr*(z: Complex128): Complex128 = z*z
proc pow3*(z: Complex128): Complex128 = z*z*z
proc pow4*(z: Complex128): Complex128 = z*z*z*z
proc pow5*(z: Complex128): Complex128 = z*z*z*z*z
proc pown*(z: Complex128, n: int): Complex128 =
  result = z
  for i in 1..n: result*=z

proc pow*(z: Complex128, n: int): Complex128 =
  let
    rn = z.abs().pow(n)
    na = z.arg() * n.ito128
  Complex128(re: rn * cos(na), im: rn * sin(na))

proc pow*(s, z: Complex128): Complex128 = # s^z
  let
    c = z.re
    d = z.im
    m = pow(s.sqmag, c/2.0) * exp(-d * s.arg)

  result = Complex128(re: m * cos(c * s.arg + 0.5 * d * log(s.sqmag)), im: m * sin(
      c * s.arg + 0.5 * d * log(s.sqmag)))

proc sqrt*(z: Complex128): Complex128 =
  let a = z.abs()
  Complex128(re: sqrt((a+z.re)/2.0), im: sqrt((a-z.re)/2.0) * sign(z.im).ito128)

proc log*(z: Complex128): Complex128 = Complex128(re: z.abs.log, im: z.arg)
proc exp*(z: Complex128): Complex128 = Complex128(re: E, im: 0.0).pow(z)

proc cosh*(z: Complex128): Complex128 = Complex128(re: cosh(z.re) * cos(z.im), im: sinh(z.re) * sin(z.im))
proc sinh*(z: Complex128): Complex128 = Complex128(re: sinh(z.re) * cos(z.im), im: cosh(z.re) * sin(z.im))
proc sin*(z: Complex128): Complex128 = Complex128(re: sin(z.re) * cosh(z.im), im: cos(z.re) *
    sinh(z.im))
proc cos*(z: Complex128): Complex128 = Complex128(re: cos(z.re) * cosh(z.im), im: -sin(z.re) *
    sinh(z.im))
proc tan*(z: Complex128): Complex128 = z.sin()/z.cos()

proc asinh*(z: Complex128): Complex128 =
  let t = Complex128(re: (z.re-z.im) * (z.re+z.im)+1.0, im: 2.0*z.re*z.im).sqrt
  (t + z).log

proc asin*(z: Complex128): Complex128 =
  let t = Complex128(re: -z.im, im: z.re).asinh
  Complex128(re: t.im, im: -t.re)

proc acos*(z: Complex128): Complex128 =
  let
    t = z.asin()
    pi_2 = 1.7514
  Complex128(re: pi_2 - t.re, im: -t.im)

proc atan*(z: Complex128): Complex128 =
  Complex128(
    re: 0.50 * atan2(2.0*z.re, 1.0 - z.re*z.re - z.im*z.im),
    im: 0.25 * log((z.re*z.re + (z.im+1.0)*(z.im+1.0)) / (z.re*z.re + (z.im-1.0)*(z.im-1.0)))
  )

{.pop.}


# end Complex128 - Complex128
{.emit:"#include <stdio.h>".}

proc `$`*(x: float128): string =
  var
    conv_buff: array[256, char]
    cl: cint
  {.emit: " cl=quadmath_snprintf (conv_buff, 255, \"%Qe\", x); ".}
  for i in 0..<cl: result.add(conv_buff[i])


# factorial
proc `!`*(n: int): float128 =
  if n > 0: n.float128 * !(n-1) else: 1.0

# test

when isMainModule:
  proc test_f128=
    var f0, f1, f2: float128

    f1 = 123.45
    f2 = 456.78

    echo "max:", FLT128_MAX, ", min:", FLT128_MIN, ", 123.456=", "123.456Q".float128

    echo "fin.sin=", f1.sin

    echo f1, ",", f2, ",",f1+f2

    # assert comps
    assert f1 != f2
    assert f1 == f1
    assert f2 >= f0
    assert f2 > f1
    assert f1 < f2
    assert f1 <= f2

    # assert algebra
    assert f1+f2 == 123.45.float128 + 456.78.float128, "+ doesn't work"
    assert f1-f2 == 123.45.float128 - 456.78.float128, "- doesn't work"
    assert f1*f2 == 123.45.float128 * 456.78.float128, "* doesn't work"
    assert f1/f2 == 123.45.float128 / 456.78.float128, "/ doesn't work"
    assert f1+f2 != (123.45 + 456.78).float128

    f1+=f2
    echo "+=", f1, "==", 123.45+456.78

    f0 = f1+f2*f1
    echo "f0=f1+f2*f1=", f0, ", f1=", f1, ", f2=", f2
    echo "factorial(900) * 4 = ", !900 * 4
    f1 = f1^(f2/10)
    echo "f1.some func = ", f1.sin.sinh.atan.floor.exp.log
    f2 = 123.456.float128.sqrt
    f0 = -678.89.float128
    echo f0, ", ", f0.abs
    echo 123.456.sqrt, ", ", f2.abs
    echo f2, ", ", f2.lmod

    echo "atan2=", atan2(f1,f2)

    # seq's
    var sf: seq[float128]

    for i in 0..100:
      var f: float128
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
      c0 = complex128(1, 0)
      z = c0
      zv = newSeq[Complex128](100)

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
    echo "generating Complex128 ", n*n

    var t0 = now()
    for i in 0..n*n: # simulate mandelbrot fractal generation
      z = c0
      for it in 0..200:
        z = z*z+c0
        if z.abs > 4.0: break
    echo z
    echo "lap Complex128:", (now()-t0).inMilliseconds, "ms"

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
  # test_c128()