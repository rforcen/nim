# st/mt pi calc ratio

import strutils, math, times, strformat
import threadpool, cpuinfo
{.experimental: "parallel".}

# single thread version 
proc term(k: float): float = 4 * math.pow(-1, k) / (2*k + 1)

proc st_pi(n: int): float =
  var ch = newSeq[float](n+1)
  for k in 0..ch.high:  ch[k] = term(float(k))
  for k in 0..ch.high:  result += ch[k]


# mt version

func chunk_range*(size, i, nth: int): Slice[int] =
    let
      chunk_sz = size div nth
      rfrom = i * chunk_sz
      rto = if (i+1) * chunk_sz > size: size else: (i+1) * chunk_sz
    rfrom..<rto

proc mt_pi(n: int): float =
  proc chunk_term(i,nth:int, ch:var seq[float]) = 
    for index in chunk_range(size=ch.len, i, nth):
      ch[index] = term(index.float)
      
  let nth = countProcessors()

  var ch = newSeq[float](n+1)

  parallel:
    for k in 0..nth:
      spawn chunk_term(k, nth, ch)
    
  for k in 0..ch.high: result += ch[k]

proc main()=
  const n = 10000000
  setMaxPoolSize(countProcessors())

  var
    t0 = now()
    piv = st_pi(n)

  let st_lap=(now()-t0).inMilliseconds()
  echo fmt("st lap:{st_lap}ms, pi={piv}")

  t0 = now()
  piv = mt_pi(n)
  let mt_lap=(now()-t0).inMilliseconds()

  echo fmt("mt lap:{mt_lap}ms, pi={piv}")
  echo fmt("st/mt ratio: {st_lap.float / mt_lap.float}")


main()