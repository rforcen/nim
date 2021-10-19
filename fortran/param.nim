#
# quadmath type fortran parameter passing 
# @gfortran -fdefault-real-8 -c param.f 493.f
#

{.passL:"param.o 493.o libalgebra.o paramf90.o -lgfortran -lquadmath -lm".}

import quadmath

# gfortran descriptor
type Descriptor = object 
  base_addr : pointer
  elem_len : int64 # not required as defined in f90
  version: int32 # 1, "
  rank, attribute: int8 # "
  rtype: int16 # "
  dims : array[15, (int,int,int) ] # [lower_bound, extend, sm : int64 ]]

proc newDesc[T](base_addr : openArray[T]) : Descriptor =
  result = Descriptor(base_addr:base_addr[0].unsafeAddr)
  for i in 0..1: result.dims[i]=(1, base_addr.len, 1)
proc newDesc2d[T](base_addr : openArray[T], n,m:int) : Descriptor =
  result = Descriptor(base_addr:base_addr[0].unsafeAddr)
  result.dims[0]=(1, n, 1)
  result.dims[2]=(1, n, 1)
  result.dims[1]=(1, n, m)

proc param (op:ptr float128,degree:ptr cint, zeror, zeroi:ptr float128, fail:ptr cint) {.importc:"param_".}
proc param1(d, r:ptr float128) {.importc:"param1_".}
proc rpoly (op:ptr float128, degree:ptr cint, zeror, zeroi:ptr float128, fail:ptr cint) {.importc:"rpoly_".}
proc cbrt_dp(x:ptr float64) : float64 {.importc:"__lib_algebra_MOD_cbrt_dp".}
proc cbrt_sp(x:ptr float32) : float32 {.importc:"__lib_algebra_MOD_cbrt_sp".}
proc lineq_gausselim_dp(a,b:ptr Descriptor) {.importc:"__lib_algebra_MOD_lineq_gausselim_dp".}

proc vec_1d_2d_param= # test passing 1d & 2d matrix 

  proc pva1d(a:ptr Descriptor)  {.importc:"pva1d_".}
  proc pva2d(a:ptr Descriptor)  {.importc:"pva2d_".}

  const n = 5
  var 
    a=newSeq[float](n*n)
    b=newSeq[float](n)

  for i in 0..a.high: a[i]=i.float
  for i in 0..b.high: b[i]=i.float

  echo "calling pva1d...",  a

  var desc = newDesc(a)
  pva1d(desc.addr)

  echo "values modified...",a

  echo "calling pva2d...",  a
  var desc2d = newDesc2d(a, 5,5)
  pva2d(desc2d.addr)

  echo "values modified...",a

  var descb = newDesc(b)
  lineq_gausselim_dp(desc2d.addr, descb.addr)
  echo a
  echo "result:",b




proc test_no_desc_params=
  var xdp=123.45.float64
  echo "cbrt_dp:", cbrt_dp(xdp.addr)
  var xsp=123.45.float32
  echo "cbrt_sp:", cbrt_sp(xsp.addr)

  var 
    dp=11111.float128
    r=22222.float128

  echo "param1 test, dp, r:", dp, ",",r
  param1(dp.unsafeAddr, r.unsafeAddr)
  echo "values returned from param1:", dp, ",",r

  var 
    degree=10.cint
    op = @[1.float128, -55, 1320,-18150,157773, -902055,3416930,-8409500,12753576,  -10628640, 3628800] #@[8.float,-8,16,-16,8,-8]
    zeror=newSeq[float128](degree)
    zeroi=newSeq[float128](degree)

    fail=1.cint

  param(op[0].unsafeAddr,degree.unsafeAddr, zeror[0].unsafeAddr, zeroi[0].unsafeAddr, fail.unsafeAddr)

  degree=10.cint
  rpoly(op[0].unsafeAddr,degree.unsafeAddr, zeror[0].unsafeAddr, zeroi[0].unsafeAddr, fail.unsafeAddr)

  echo "fail, degree:", fail, ",", degree
  echo zeror
  echo zeroi


vec_1d_2d_param()
test_no_desc_params()