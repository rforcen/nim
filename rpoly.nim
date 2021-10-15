#[
  polynomial roots, 493.f nim wrapper

	@gfortran -Ofast -c -fdefault-real-8 -fdefault-double-8 493

  generates symbol rpoly_

  SUBROUTINE rpoly(op, degree, zeror, zeroi, fail)

]#
import complex, algorithm

{.passL: "493.o -lgfortran -lm -lquadmath".}

proc poly_root*(op: openArray[float], zeros: var seq[Complex64]): bool =
  proc poly_root_f(op: ptr cdouble, degree: ptr cint, zeror, zeroi: ptr cdouble,
      fail: ptr cint) {.importc: "rpoly_".}

  var
    degree = op.len.cint-1
    zeror = newSeq[float64](degree)
    zeroi = newSeq[float64](degree)
    fail = 0.cint

  poly_root_f(cast[ptr cdouble](op[0].unsafeAddr), cast[ptr cint](degree.addr),
      cast[ptr cdouble](zeror[0].addr), cast[ptr cdouble](zeroi[0].addr), cast[
      ptr cint](fail.addr))

  result = fail == 0
  zeros = @[]

  if result: # fill return zeros
    for i in 0..<degree:
      zeros.add(complex64(zeror[i], zeroi[i]))

proc eval_poly*(coeff: seq[float], x: Complex64): Complex64 =
  let c = coeff.reversed
  result = complex64(c[0], 0.0)
  var p = x
  for i in 1..c.high:
    result += p * c[i]
    p*=x

when isMainModule:
  proc test_roots(op: seq[float]) =
    var roots: seq[Complex64]
    echo "roots of ", op, ", degree:", op.len-1
    if poly_root(op, roots):
      var s = 0.0
      for i, r in roots.pairs:
        s += op.eval_poly(r).abs2
        # echo i, ":", r, ", err:", op.eval_poly(r).abs
      echo "avg err:", s/roots.len.float
    else: echo "fail, no roots found"

  test_roots @[8.0, -8.0, 16.0, -16.0, 8.0, -8.0]
  test_roots @[1.0, -55.0, 1320.0, -18150.0, 157773.0, -902055.0, 3416930.0,
        -8409500.0, 12753576.0, -10628640.0, 3628800.0]
  test_roots @[1.0, 1, -1, -2, 1, 1, 1, 1]
