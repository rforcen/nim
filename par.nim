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

template par_exec() =
    let 
      nth = countProcessors()
      chunks = chunk_ranges(v.len, nth)

    parallel:
        for i in 0..<nth:
          spawn chunk_apply(fnc, chunks[i], v)

proc par_apply*[T](v:var seq[T], fnc:proc(i:int):T)= # single 'i' index

  proc chunk_apply(fnc:proc(i:int):T, chunk:Slice[int], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(index) 

  par_exec()

proc par_apply*[T](v:var seq[T], fnc:proc(t, i:int):T)= # 't' thread number, 'i' index

  proc chunk_apply(fnc:proc(t, i:int):T, chunk:Slice[int], v:var seq[T]) = 
     for index in chunk: 
        v[index] = fnc(t, index) 

  par_exec()

when isMainModule:
    for r in chunk_ranges(7, 3):
        echo r, " ", r.len

    # par closure sample
    const n=100000
    var v=newSeq[int](n)

    par_apply(v, proc(i:int):int=i) # set all to i
    echo v[0..5], v[^5..^1]
    
    assert v[0..3] == @[0,1,2,3] and v[^1]==n-1

    v.par_apply(proc(i:int):int=i*2) # set all to i*2
    echo v[0..5], v[^5..^1]
    