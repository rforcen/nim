# complex_std.nim
# nim wrapper to std::complex

# {.checks: off, optimization: speed.}

import strformat
# import f128

# {.passC:"-std=gnu++2a".}


# f128
type f128* {.importcpp: "long double".} = object

converter fto128*(f: float): f128 = # {.emit:[result, "=(long double)f; "].} # this mangles vsc coloring
  var r: f128; {.emit: "r=(long double)f; ".}; r
converter ito128*(i: int): f128 = # {.emit:[result, "=(long double) i;"].}
  var r: f128; {.emit: "r=(long double)i; ".}; r
proc `$`*(x: f128): string =
  var
    conv_buff: array[128, char]
    cl: cint = conv_buff.high
  {.emit: " cl = snprintf(conv_buff, cl, \"%Le\", x); ".}
  for i in 0..<cl: result.add(conv_buff[i])
#

type Complex[T] {.header:"<complex>", importcpp: "std::complex<'0>".} = object 
  re, im : T

proc complex*[T](re, im:T):Complex[T] {.importcpp: "'0 (@)".}

proc `+`*[T](a,b:Complex[T]):Complex[T] {.importcpp:"# + #".}
proc `-`*[T](a,b:Complex[T]):Complex[T] {.importcpp:"# - #".}
proc `-`*[T](a:Complex[T]):Complex[T] {.importcpp:"-#".}
proc `*`*[T](a,b:Complex[T]):Complex[T] {.importcpp:"# * #".}
proc `/`*[T](a,b:Complex[T]):Complex[T] {.importcpp:"# / #".}

proc `+=`*[T](a,b:Complex[T]) {.importcpp:"# += #".}
proc `-=`*[T](a,b:Complex[T]) {.importcpp:"# -= #".}
proc `*=`*[T](a,b:Complex[T]) {.importcpp:"# *= #".}
proc `/=`*[T](a,b:Complex[T]) {.importcpp:"# /= #".}

proc `==`*[T](a,b:Complex[T]):bool {.importcpp:"# == #".}
proc `!=`*[T](a,b:Complex[T]):bool {.importcpp:"# != #".}

proc real*[T](z:Complex[T]):T {.importcpp: "#.real()".}
proc imag*[T](z:Complex[T]):T {.importcpp: "#.imag()".}
proc abs*[T](z:Complex[T]):T {.importcpp: "abs(#)".}
proc arg*[T](z:Complex[T]):T {.importcpp: "std::arg(#)".}
proc norm*[T](z:Complex[T]):T {.importcpp: "std::norm(#)".}
proc conj*[T](z:Complex[T]):Complex[T] {.importcpp: "std::conj(#)".}
proc proj*[T](z:Complex[T]):Complex[T] {.importcpp: "std::proj(#)".}
proc polar*[T](r, theta:T):Complex[T] {.importcpp: "std::polar(@)".}

proc exp*[T](z:Complex[T]):Complex[T] {.importcpp: "std::exp(#)".}
proc log*[T](z:Complex[T]):Complex[T] {.importcpp: "std::log(#)".}
proc log10*[T](z:Complex[T]):Complex[T] {.importcpp: "std::log10(#)".}

proc pow*[T](z,y:Complex[T]):Complex[T] {.importcpp: "std::pow(@)".}

proc sin*[T](z:Complex[T]):Complex[T] {.importcpp: "std::sin(#)".}
proc cos*[T](z:Complex[T]):Complex[T] {.importcpp: "std::cos(#)".}
proc tan*[T](z:Complex[T]):Complex[T] {.importcpp: "std::tan(#)".}
proc asin*[T](z:Complex[T]):Complex[T] {.importcpp: "std::asin(#)".}
proc acos*[T](z:Complex[T]):Complex[T] {.importcpp: "std::acos(#)".}
proc atan*[T](z:Complex[T]):Complex[T] {.importcpp: "std::atan(#)".}

proc sinh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::sinh(#)".}
proc cosh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::cosh(#)".}
proc tanh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::tanh(#)".}
proc asinh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::asinh(#)".}
proc acosh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::acosh(#)".}
proc atanh*[T](z:Complex[T]):Complex[T] {.importcpp: "std::atanh(#)".}

# proc `$`*[T](z:Complex[T]):string = "(" & $(z.real()) & ", " & $(z.imag()) & ")"

when isMainModule:
  var 
    z = complex[f128](3,4)
    z1 = complex[f128](5,6)

  # echo "z=", z #, z.abs={z.abs}, z.arg={z.arg}"
  # echo fmt "z+z={z+z}"
  # z+=z1
  # echo fmt "z1={z1}, z+=z1={z}, -z={-z}, z==z1:{z==z1}, z!=z1:{z!=z1}"
  # echo fmt "polar(1,2)={polar(1.fto128,1.6.fto128)}"
  # echo "z.allfunc=", z.exp.log.sin.cos.tan.asin.acos.atan.sinh.cosh.tanh.asinh.acosh.atanh