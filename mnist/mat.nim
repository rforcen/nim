# mat, perceptron linear algebra support

import sequtils, random, math

type 
  real* = float32
  vec* = seq[real]
  vvec* = seq[vec]
  mat* = vvec
  vmat* = seq[vvec]


# vec, mat

# := is values copy
proc `:=`*(t : var vec,f:vec)= # t=f a := b is a=b (values)
  assert f.len==t.len
  for i in 0..f.high: t[i]=f[i]
proc `:=`*(t : var mat,f:mat)= # t=f a := b is a=b (values)
  assert f.len==t.len
  for i in 0..f.high: t[i]:=f[i]
proc `:=`*(t : var vmat,f:vmat)= # t=f a := b is a=b (values)
  assert f.len==t.len
  for i in 0..f.high: t[i]:=f[i]

proc zero*(m:var vec) =
  for r in m.mitems: r = 0.0

proc zero*(m:var mat) =
  for r in m.mitems: r.zero

proc zero*(m:var vmat) =
  for r in m.mitems: r.zero

proc rand_vec*(sz : int) : vec = # uniform rand avg=0.0
  result = newSeq[real](sz)
  for r in result.mitems: r = rand(-1.0..1.0) # -1..1

proc rand_mat*(sz1, sz : int) : mat =
  result = newSeqWith(sz1, newSeq[real](sz))
  for r in result.mitems:
    r = rand_vec(r.len)

proc `+=`*(m:var vec, a:vec) =
  for i, r in m.mpairs: r+=a[i] 
proc `+=`*(m:var mat, a:mat) =
  for i, r in m.mpairs: r+=a[i]
proc `+=`*(m:var vmat, a:vmat) =
  for i, r in m.mpairs: r+=a[i]

proc `/=`*(m:var vec, f:real) =
  for i, r in m.mpairs: r/=f
proc `/=`*(m:var mat, f:real) =
  for i, r in m.mpairs: r/=f
proc `/=`*(m:var vmat, f:real) =
  for i, r in m.mpairs: r/=f

proc `*=`*(m:var vec, f:real) =
  for i, r in m.mpairs: r*=f
proc `*=`*(m:var mat, f:real) =
  for i, r in m.mpairs: r*=f
proc `*=`*(m:var vmat, f:real) =
  for i, r in m.mpairs: r*=f

proc `+`*(m,a: mat) : mat =
  result=m
  for i, ai in a.pairs: result[i]+=ai

proc `-=`*(m:var vec, a:vec)
proc `-`*(m,a: mat) : mat =
  result=m
  for i, ai in a.pairs: result[i]-=ai

proc `-=`*(m:var vec, a:vec) =
  for i, r in m.mpairs: r-=a[i] 
proc `-=`*(m:var mat, a:mat) =
  for i, r in m.mpairs: r-=a[i]
proc `-=`*(m:var vmat, a:vmat) =
  for i, r in m.mpairs: r-=a[i]

proc `+`*(a,b:vec):vec=
  assert a.len == b.len
  result = a
  for i in 0..b.high:
    result[i] += b[i]

proc `*`*(a,b:vec):vec # coeff wise prod
proc `+`*(a:mat,b:vec):mat=
  for v in a:
    result.add(v*b)

proc `-`*(a,b:vec):vec=
  assert a.len == b.len
  result = newSeq[real](a.len)
  for i in 0..a.high:
    result[i] = a[i]-b[i]

proc `*`*(a,b:vec):vec= # coeff wise prod
  assert a.len == b.len
  result = a
  for i in 0..b.high:
    result[i] *= b[i]

proc `*`*(m:mat, b:vec) : mat =
  for r in m:  result.add(r*b)

proc `*`*(a:vec, f:real):vec=
  result=a
  for i in 0..a.high: result[i]*=f

proc `*`*(a:mat, f:real):mat=
  result=a
  for i in 0..a.high: result[i]=a[i]*f

proc `*`*(a:vmat, f:real):vmat=
  result=a
  for i in 0..a.high: result[i]=a[i]*f

proc transpose*(a:mat):mat=
  result=newSeqWith(a[0].len, newSeq[real](a.len))
  for i in 0..a.high:
    for j in 0..a[0].high:
      result[j][i]=a[i][j]

proc `.**`*(a,b:vec):mat=
  for ai in a:
    result.add( b * ai )

proc `.*`*(a,b:vec):real= # dot prod
  assert a.len == b.len
  for i in 0..a.high:
    result += a[i] * b[i]

proc `.*`*(a:mat, b:vec):vec= 
  for aa in a:
    result.add( aa .* b )

proc wab*(w:mat, a,b:vec):vec= # (w.dot a)  + b
  for i, aa in w.pairs:
    result.add((aa .* a) + b[i])

proc sum*(t:vec):real=
  for i in t: result+=i
proc sum*(t:mat):real=
  for i in t: result+=i.sum
proc sum*(t:vmat):real=
  for i in t: result+=i.sum

proc from_shape*(v:vvec):vvec=
  result=v
  result.zero
proc from_shape*(v:vmat):vmat=
  result=v
  result.zero

func sigmoid*(z:real):real = 1 / (1 + (-z).exp)
proc sigmoid*(z:vec):vec = 
  result=z
  result.apply(sigmoid)

func sigmoid_prime*(z:real):real = z.sigmoid * (1 - z.sigmoid)
proc sigmoid_prime*(z:vec):vec =
  result=z
  result.apply(sigmoid_prime)

when isMainModule:
  proc test1=
    var
      a:vec= @[1'f32, 2,3,4]
      b:mat= @[a,a]
    
    echo "a=",a
    echo "b=",b
    a= @[3'f32, 4,5,6]
    echo "b=",b
    echo "a=",a
    echo "a*a=",a*a
    b=b*4.0
    echo "b=b*4:", b
    echo "b*a=", b*a
    echo "b .* a", b .* a
    b-=b
    echo "b-=b",b

    var 
      rv = rand_vec(4)
      rm = rand_mat(3,4)
      rm1=rm
      rmm = @[ rm, rm, rm]
      rmm1 = rmm

    echo "rv=", rv
    echo "rm=", rm
    echo "rm1=", rm1
    echo "sum(rmm, rmm1):", (rmm*2).sum,", ", rmm1.sum*2

  proc test2=
    var
      a : vec = @[0'f32,1,2,3,4,5]
      b=a
      dt=a .** b
    echo dt
    let ddt = dt .* a
    echo ddt
    let wwab=dt.wab(a,b)
    echo "wwab=", wwab
    
  test2()
