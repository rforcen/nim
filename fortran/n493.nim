# rpoly 493.f wrapper
# gfortran -c -Ofast -fdefault-real-8 493.f

import quadmath

{.passL:"493.o -lgfortran -lquadmath -lm".}

converter f128top*(x:var float128):ptr float128=x.unsafeAddr
converter atop*[T](x:var openArray[T]):ptr float128 = x[0].unsafeAddr
converter itop*(x:var cint):ptr cint = x.unsafeAddr

proc rpoly(op:ptr float128, degree:ptr cint, zeror, zeroi:ptr float128, fail:ptr cint) {.importc:"rpoly_".}

when isMainModule:
  var 
    op = @[1.float128, -55, 1320,-18150,157773, -902055,3416930,-8409500,12753576,  -10628640, 3628800] #@[8.float,-8,16,-16,8,-8]
    degree=(op.len-1).cint
    zeror=newSeq[float128](degree)
    zeroi=newSeq[float128](degree)
    fail=1.cint

  rpoly(op.atop, degree, zeror.atop, zeroi.atop, fail)

  echo "roots of poly:", op
  echo "ok:", fail==0
  for r in zeror: write stdout, r,", "
  echo ""
  for r in zeroi: write stdout, r,", "
  echo ""


