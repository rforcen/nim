
# gfortran descriptor
type Descriptor* = object 
  base_addr : pointer
  elem_len : int64 # not required as defined in f90
  version: int32 # 1, "
  rank, attribute: int8 # "
  rtype: int16 # "
  dims : array[15, (int,int,int) ] # [lower_bound, extend, sm : int64 ]]

proc newDesc*[T](base_addr : openArray[T]) : Descriptor =
  result = Descriptor(base_addr:base_addr[0].unsafeAddr)
  result.dims[0]=(1, base_addr.len, 1)
  result.dims[1]=(1, base_addr.len, 1)

proc newDesc2d*[T](base_addr : openArray[T], n,m:int) : Descriptor =
  result = Descriptor(base_addr:base_addr[0].unsafeAddr)
  result.dims[0]=(1, n, 1)
  result.dims[2]=(1, n, 1)
  result.dims[1]=(1, n, m)