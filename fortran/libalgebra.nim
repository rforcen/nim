# libalgebra.f90 wrapper using fortran descriptors

import for_desc

{.passL:"libalgebra.o -lgfortran -lm".}

# sp = float32

proc cbrt_sp*(x:ptr float32) : float32 {.importc:"__lib_algebra_MOD_cbrt_sp".}
proc quadratic_reduced_sp*(b,c,x1,x2 : ptr float32) {.importc:"__lib_algebra_MOD_quadratic_reduced_sp".}
proc quadratic_sp*(a,b,c,x1,x2 : ptr float32) {.importc:"__lib_algebra_MOD_quadratic_sp".}
proc quadratic_pascal_sp*(a,b,c,x1,x2 : ptr float32) {.importc:"__lib_algebra_MOD_quadratic_pascal_sp".}
proc quadratic_pascal_reduced_sp*(b,c,x1,x2 : ptr float32) {.importc:"__lib_algebra_MOD_quadratic_pascal_reduced_sp".}
proc lineq_gausselim_sp*(a,b:ptr Descriptor) {.importc:"__lib_algebra_MOD_lineq_gausselim_sp".}

# dp = float

proc cbrt_dp*(x:ptr float64) : float64 {.importc:"__lib_algebra_MOD_cbrt_dp".}
proc quadratic_reduced_dp*(b,c,x1,x2 : ptr float) {.importc:"__lib_algebra_MOD_quadratic_reduced_dp".}
proc quadratic_dp*(a,b,c,x1,x2 : ptr float) {.importc:"__lib_algebra_MOD_quadratic_dp".}
proc quadratic_pascal_dp*(a,b,c,x1,x2 : ptr float) {.importc:"__lib_algebra_MOD_quadratic_pascal_dp".}
proc quadratic_pascal_reduced_dp*(b,c,x1,x2 : ptr float) {.importc:"__lib_algebra_MOD_quadratic_pascal_reduced_dp".}
proc lineq_gausselim_dp*(a,b:ptr Descriptor) {.importc:"__lib_algebra_MOD_lineq_gausselim_dp".}

# to ptr converters

converter f32top*(x:var float32):ptr float32=x.unsafeAddr
converter f64top*(x:var float64):ptr float64=x.unsafeAddr
converter desctop*(x:var Descriptor):ptr Descriptor=x.unsafeAddr

when isMainModule:
  import random

  proc test_sp=
    var x = 10.float32
    echo "cbrt_sp: ", cbrt_sp(x)
    var 
      a = 34'f32
      b = 123'f32
      c = 34'f32
      x1,x2 : float32
    
    quadratic_reduced_sp(b, c, x1, x2)
    echo "quadratic_reduced_sp: ", b,", ",c,", ",", ", x1, ", ", x2
    quadratic_sp(a, b, c, x1, x2)
    echo "quadratic_sp: ", a, ", ", b,", ",c,", ",", ", x1, ", ", x2  
    quadratic_pascal_sp(a, b, c, x1, x2)
    echo "quadratic_pascal_sp: ", a, ", ", b,", ",c,", ",", ", x1, ", ", x2
    quadratic_pascal_reduced_sp(b, c, x1, x2)
    echo "quadratic_pascal_reduced_sp: ", b,", ",c,", ",", ", x1, ", ", x2

    const n = 10
    var 
      A=newSeq[float32](n*n)
      B=newSeq[float32](n)
      descA = newDesc2d(A, n,n)
      descB = newDEsc(B)

    randomize()
    for i in 0..A.high: A[i]=rand(1.0)
    for i in 0..B.high: B[i]=rand(1.0)

    lineq_gausselim_sp(descA, descB)

    echo "A=", A
    echo "B=", B

  proc test_dp=
    var x = 10.float
    echo "cbrt_dp: ", cbrt_dp(x)
    var 
      a = 34'f64
      b = 123'f64
      c = 34'f64
      x1,x2 : float
    
    quadratic_reduced_dp(b, c, x1, x2)
    echo "quadratic_reduced_dp: ", b,", ",c,", ",", ", x1, ", ", x2
    quadratic_dp(a, b, c, x1, x2)
    echo "quadratic_dp: ", a, ", ", b,", ",c,", ",", ", x1, ", ", x2  
    quadratic_pascal_dp(a, b, c, x1, x2)
    echo "quadratic_pascal_dp: ", a, ", ", b,", ",c,", ",", ", x1, ", ", x2
    quadratic_pascal_reduced_dp(b, c, x1, x2)
    echo "quadratic_pascal_reduced_dp: ", b,", ",c,", ",", ", x1, ", ", x2

    const n = 10
    var 
      A=newSeq[float](n*n)
      B=newSeq[float](n)
      descA = newDesc2d(A, n,n)
      descB = newDEsc(B)

    randomize()
    for i in 0..A.high: A[i]=rand(1.0)
    for i in 0..B.high: B[i]=rand(1.0)

    lineq_gausselim_dp(descA, descB)

    echo "A=", A
    echo "B=", B
  
  test_sp()
  test_dp()