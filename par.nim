# parallel work
# par.nim

import threadpool, cpuinfo

{.experimental: "parallel".}
setMaxPoolSize(countProcessors())

proc chunk_range*(size, i, nth: int): Slice[int] =
    let
      chunk_sz = size div nth
      rfrom = i * chunk_sz
      rto = if (i+1) * chunk_sz > size: size else: (i+1) * chunk_sz
    rfrom..<rto

proc par_apply*[T](v:var seq[T], fnc:proc(i:int):T)= # single 'i' index
  proc chunk_apply(fnc:proc(i:int):T, i, n : int, v:var seq[T]) = 
     for i in chunk_range(size=v.len, i, n): 
        v[i] = fnc(i) 

  let nth = countProcessors()

  parallel:
    for i in 0..nth:
      spawn chunk_apply(fnc, i, nth, v)

proc par_apply*[T](v:var seq[T], fnc:proc(t, i:int):T)= # 't' thread number, 'i' index
  proc chunk_apply(fnc:proc(t, i:int):T, i, n : int, v:var seq[T]) = 
     for i in chunk_range(size=v.len, i, n): 
        v[i] = fnc(t, i) 

  let nth = countProcessors()

  parallel:
    for i in 0..nth:
      spawn chunk_apply(fnc, i, nth, v)
