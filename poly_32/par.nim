# parallel work
# par.nim

import threadpool, cpuinfo

{.experimental: "parallel".}
setMaxPoolSize(countProcessors())

# adapted from distribute
proc par_ranges*(size, n : int32):seq[Slice[int32]]= # Create the result and calculate the stride size and the remainder if any.
    var
        stride = size div n
        first :int32= 0
        last :int32= 0
        extra = size mod n
  
    result = newSeq[Slice[int32]](n)# Use an undercounting algorithm which *adds* the remainder each iteration.

    for i in 0 ..< n:
        last = first + stride
        if extra > 0:
            dec extra
            inc last
        result[i] = first ..< last
        first = last

proc par_ranges*[T](v:seq[T]):seq[Slice[int32]]= # seq[from..to]
  par_ranges(v.len.int32, countProcessors().int32)
proc par_ranges*(l:int32):seq[Slice[int32]]= # seq[from..to]
  par_ranges(l, countProcessors().int32)

template par_exec(chunk_apply, fnc, v) =
    let 
      nth = countProcessors()
      chunks = par_ranges(v.len.int32, nth)

    parallel:
        for chunk in chunks:
          spawn chunk_apply(fnc, chunk, v)

proc par_apply*[T](v:var seq[T], fnc:proc(i:int32):T)= # single 'i' index
  proc chunk_apply(fnc:proc(i:int32):T, chunk:Slice[int32], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(index) 
  par_exec(chunk_apply, fnc, v)

proc par_apply*[T](v:var seq[T], fnc:proc(t, i:int32):T)= # 't' thread number, 'i' index
  proc chunk_apply(fnc:proc(t, i:int32):T, chunk:Slice[int32], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(t, index) 
  par_exec(chunk_apply, fnc, v)

proc par_iter*[T](v:var seq[T], fnc:proc(v:var seq[T], r:Slice[int32]))= # 't' thread number, 'i' index
  proc chunk_apply(fnc:proc(v:var seq[T], r:Slice[int32]), chunk:Slice[int32], v:var seq[T]) = 
     fnc(v, r) 
  par_exec(chunk_apply, fnc, v)

