# polyroot uses the Durand-Kerner method to find all roots (real and complex) of a polynomial of the form:
# f(x) = pow(x, n) + a1*pow(x, n - 1) + a2*pow(x, n - 2) + . . . + a(n - 2)*x*x + a(n - 1)*x + a(n)
# where the vector A = a1, a2, a3, . . . , a(n - 2), a(n - 1), a(n)

import complex, algorithm

proc eval_poly*(coeff:seq[float], x : Complex64) : Complex64 =
  let n = coeff.high
  var p = x
  result = complex64(coeff[n],0)
  for i in 1..n:
    result += coeff[n - i] * p
    p *= x
  
proc roots*(A : seq[float]) : seq[Complex64] =
  proc poly(A : seq[float],  x : Complex64) : Complex64 =
    let n = A.len
    var p = complex64(1,0)
    result = complex64(0,0)
    for i in 0..<n:
      result += A[n - i - 1] * p
      p *= x
    result += p

  let 
    n = A.high
    iterations = 100
    z = complex(0.4, 0.9)
    a0 = A[0]
    
  result = newSeq[Complex64](n)

  var a=newSeq[float](n)
  for i in 0..<n: # normalize
    a[i] = A[i + 1] / (if a0!=0: a0 else: 1)

  var zz = complex64(1,0)
  for i in 0..<n:
    result[i] = zz # pow(z, i)
    zz *= z

  for i in 0..<iterations:    
    for j in 0..<n:      
      var B = poly(a, result[j])
      for k in 0..<n:        
        if k != j:    B /= result[j] - result[k]
      
      result[j] -= B
    
  
  result.sort(proc (x, y: Complex64): int = (if x.re < y.re: -1 else: 1))
  
when isMainModule:
  proc test_roots(op: seq[float]) =
    echo "roots of ", op, ", degree:", op.len-1

    var s = 0.0
    for i, r in op.roots:
      s += op.eval_poly(r).abs2
      # echo i, ":", r, ", err:", op.eval_poly(r).abs
    echo "avg err:", s/op.high.float

  test_roots @[8.0, -8.0, 16.0, -16.0, 8.0, -8.0]
  test_roots @[1.0, -55.0, 1320.0, -18150.0, 157773.0, -902055.0, 3416930.0, -8409500.0, 12753576.0, -10628640.0, 3628800.0]
