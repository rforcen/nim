#[
   basic unsafe vec ptr based with len(int) at p[0]
   usage:
     var v=vec[float](100)

     for i, vi in v.mpairs:  vi=i.float 
     for vi in v: echo vi
     v.free

]#

import sugar

type Vec*[t] = ptr t

{.push checks: off, line_dir: off, stack_trace: off, debugger: off, inline: on.}


# access data item p + int.size + i*t.size
proc data*[t](p: ptr t, i:int): ptr t = cast[ptr t](cast[int](p) + int.sizeof + i*t.sizeof)

# indexers
proc `[]`*[t](p: ptr t, i: int): t = p.data(i)[]

proc `[]`*[t](p: ptr t, s: Slice[int]): seq[t] = # [a..b]
    collect(newSeq):
        for i in s: p[i]

proc `[]=`*[t](p: ptr t, i: int, val: t) = cast[ptr t](cast[int](p) + int.sizeof + i*t.sizeof)[] = val

# address of len, i.e. p[0]
proc ptr_n[t](p: ptr t): ptr int = cast[ptr int](p)

proc set_len[t](p: ptr t, n: int) = ptr_n(p)[] = n

# constructor
proc vec*[t](n: int): ptr t =
  var p = cast[ptr t](alloc0(n*t.sizeof+int.sizeof))
  p.set_len n
  p

proc len*[t](p: ptr t): int = ptr_n(p)[].int

proc low*[t](p: ptr t): int = 0

proc high*[t](p: ptr t): int =
  if p.len==0: 0 else: p.len-1

proc mid*[t](p: ptr t): int = p.len div 2

proc first*[t](p: ptr t, n: int): seq[t] =
  collect(newSeq):
      for i in 0..<n: p[i]

proc last*[t](p: ptr t, n: int): seq[t] =
  collect(newSeq):
      for i in p.high-n..p.high: p[i]

proc toseq*[t](p: ptr t): seq[t] =
  collect(newSeq):
      for i in 0..p.high: p[i]

proc free*[t](p: var ptr t) =
  if p != nil and p.len != 0:
    p.setlen 0
    dealloc(p)
    p = nil

# iterators

iterator items*[t](v: Vec[t]): t =
  var i = 0
  while i <= v.high:
      yield v[i]
      inc i

iterator mitems*[t](a: Vec[t]): var t =
  ## Iterates over each item of `a` so that you can modify the yielded value.
  var i = 0
  while i < len(a):
      yield a.data(i)[]
      inc(i)

iterator pairs*[t](v: Vec): tuple[a: int, b: t] =
  var i = 0
  while i <= v.high:
      yield (i, v[i])
      inc i

iterator mpairs*[t](v: Vec[t]): tuple[a: int, b: var t] =
  var i = 0
  while i <= v.high:
      yield (i, v.data(i)[])
      inc i

{.pop.}


when isMainModule:
    proc test_miniv =
        var
            v = vec[float](1000)
            v1, v2: Vec[float]

        v1 = v # shallow copy
        v2 = v1

        for i, vi in v.mpairs:  vi=i.float

        let ni=5
        echo v.first ni, v[v.mid..v.mid+ni], v.last ni
        echo v1.first ni, v1[v.mid..v.mid+ni], v1.last ni
        echo v2.first ni, v2[v.mid..v.mid+ni], v2.last ni

        v.free
        v1.free
        v2.free

        var v3=vec[float](10)

        for i, vi in v3.mpairs:  vi=i.float 
        for vi in v3: echo vi
        v.free

    test_miniv()