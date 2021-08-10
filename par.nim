# parallel work
# par.nim

import threadpool, cpuinfo

{.experimental: "parallel".}
setMaxPoolSize(countProcessors())

# adapted from distribute
proc chunk_ranges*(size, n : int):seq[Slice[int]]= # Create the result and calculate the stride size and the remainder if any.
    var
        stride = size div n
        first = 0
        last = 0
        extra = size mod n
  
    result = newSeq[Slice[int]](n)# Use an undercounting algorithm which *adds* the remainder each iteration.

    for i in 0 ..< n:
        last = first + stride
        if extra > 0:
            dec extra
            inc last
        result[i] = first ..< last
        first = last

proc par_apply*[T](v:var seq[T], fnc:proc(i:int):T)= # single 'i' index
  proc chunk_apply(fnc:proc(i:int):T, chunk:Slice[int], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(index) 
  
  let 
      nth = countProcessors()
      chunks = chunk_ranges(v.len, nth)

  parallel:
    for i in 0..<nth:
      spawn chunk_apply(fnc, chunks[i], v)

proc par_apply*[T](v:var seq[T], fnc:proc(t, i:int):T)= # 't' thread number, 'i' index

  proc chunk_apply(fnc:proc(t, i:int):T, chunk:Slice[int], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(t, index) 

  let 
      nth = countProcessors()
      chunks = chunk_ranges(v.len, nth)

  parallel:
    for i in 0..<nth:
      spawn chunk_apply(fnc, chunks[i], v)

when isMainModule:
    for r in chunk_ranges(7, 3):
        echo r, " ", r.len