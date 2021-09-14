# c long double  wrapper

# link with -lm, --passL:"-lm"

{.passL: "-lm".}

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
proc ata2n*(x, y: f128): f128 {.importc: "atan2", header: math_header.}

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

{.pop.}

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
