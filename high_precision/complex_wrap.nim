# complex.h wrapper
# https://github.com/nim-lang/Nim/blob/6fb372d96bade748aa6cb3484fef2118b4585f26/doc/nimc.txt#L599

import f128

type float128=f128
type SomeReal* = float32 | float64 | float128

type Complex[T] {.header:"complex.h", importcpp: "Complex<'0>", nodecl.} = object 
  re, im : T

proc newComplex*[T]() : Complex[T] {.importcpp: "Complex<'*0>()", nodecl.}
proc newComplex*[T](re, im:T) : Complex[T] {.importcpp: "Complex<'*0>(@)", nodecl.}
proc newComplex*[T](re:T) : Complex[T] {.importcpp: "Complex<'*0>(@,0)", nodecl.}

proc sqmag*[T : SomeReal] (z:Complex[T]) : T {.importcpp:"#.sqmag()"}
proc arg*[T : SomeReal] (z:Complex[T]) : T {.importcpp:"#.arg()"}
proc abs*[T : SomeReal] (z:Complex[T]) : T {.importcpp:"#.abs()"}

proc `+`*[T : SomeReal] (a,b:Complex[T]) : Complex[T] {.importcpp:"# + #"} 
proc `-`*[T : SomeReal] (a,b:Complex[T]) : Complex[T] {.importcpp:"# - #"} 
proc `*`*[T : SomeReal] (a,b:Complex[T]) : Complex[T] {.importcpp:"# * #"} 
proc `/`*[T : SomeReal] (a,b:Complex[T]) : Complex[T] {.importcpp:"# / #"} 

import strformat
proc `$`*[T](z:Complex[T]):string = fmt "({z.re}, {z.im})"

when isMainModule:
  echo "complex# test..."
  var 
    z32:Complex[float32]=newComplex[float32](3,4)
    z64:Complex[float64]=newComplex[float64](3,4)
    z128:Complex[float128]=newComplex[float128](3,4)

  echo "z=", z32, ", sqmag=", z32.sqmag, ", arg=", z32.arg
  echo "z=", z64, ", sqmag=", z64.sqmag, ", arg=", z64.arg
  echo "z=", z128, ", sqmag=", z128.sqmag, ", arg=", z128.arg, ", abs=", z128.abs

  z128 = (z128+z128) / z128
  echo "z=", z128, ", sqmag=", z128.sqmag, ", arg=", z128.arg, ", abs=", z128.abs
  z128 = z128 * z128
  echo "z=", z128, ", sqmag=", z128.sqmag, ", arg=", z128.arg, ", abs=", z128.abs
  z128 = z128 + z128
  echo "z=", z128, ", sqmag=", z128.sqmag, ", arg=", z128.arg, ", abs=", z128.abs
  z128 = z128 - z128
  echo "z=", z128, ", sqmag=", z128.sqmag, ", arg=", z128.arg, ", abs=", z128.abs
