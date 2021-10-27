# multidimensional sparse matrix
import algorithm, sugar

type 
  Hash = uint64
  Recno = uint32
  HashRecno = tuple[hash:Hash, recno:Recno]

  SparseField* = tuple[name:string, nitems:int]

  Sparse* = object
    schema*:seq[SparseField]
    nfields*:int
    nbits*:int

    bitseq*:seq[Slice[int]]
    nshl, nshr:seq[int]
    mask: seq[Hash]

    pool*:seq[HashRecno]
    data*:ref RootObj

const BAD_RECNO* : Recno = 0xffffffff'u32

# aux proc's
proc nbits(n:int):int= # nbits required to store 'n' value
  var nb=n
  while nb!=0: result.inc; nb=nb.shr 1

proc allbits1(n:int):Hash =  (1.Hash.shl n) - 1

proc sparse*(schema:varargs[SparseField]) : Sparse = 
  var 
    nb=0
    bitseq : seq[Slice[int]]
    nshl, nshr : seq[int]
    mask:seq[Hash]

  for f in schema: 
    bitseq.add((nb..<nb+f.nitems.nbits))
    nb += f.nitems.nbits
    mask.add(allbits1(f.nitems.nbits))
    nshr.add(f.nitems.nbits)

  for i in 1..bitseq.high: nshl.add(bitseq[i].len)
  nshl.add(0)
  
  assert nb <= Hash.sizeof * 8

  Sparse(schema : @schema, nbits : nb, bitseq : bitseq, nfields:schema.len, nshl:nshl, nshr:nshr, mask:mask)

proc sparse*(s: Sparse) : Sparse = # s.all_except_pool = ns.all_except_pool
  Sparse(schema:s.schema, nfields:s.nfields, nbits:s.nbits, bitseq:s.bitseq, nshl:s.nshl, nshr:s.nshr, mask:s.mask)

proc check_args*(s:Sparse, ix:varargs[int]):bool=
  result = ix.len == s.nfields
  if result:
    for index, i in ix: result = result and i<s.bitseq[index].len

proc hash*(s:Sparse, ix:varargs[int]):Hash=
  for i in 0..ix.high:
    result = (result or ix[i].Hash).shl s.nshl[i]

proc unhash*(s:Sparse, hash:Hash) : seq[int] =
  var h:Hash=hash
  for i in countdown(s.nfields-1, 0):
    result.add((h and s.mask[i]).int)
    h = h shr s.nshr[i]
  result.reversed
 
proc find*(s:Sparse, ix:varargs[int]):Recno = # linear search
  assert ix.len == s.nfields
  let h = s.hash ix
  for p in s.pool:
    if p.hash==h: return p.recno
  BAD_RECNO

proc `[]`*(s:Sparse, ix:varargs[int]) : Recno = # binary seach
  assert ix.len == s.nfields
  let f = s.pool.binarySearch(s.hash(ix), proc(x:HashRecno, k:Hash) : int = cmp(x.hash, k))
  if f != -1: s.pool[f].recno else: BAD_RECNO

proc `[]=`*(s:var Sparse, ix:varargs[int], recno:Recno) = 
  assert ix.len == s.nfields
  s.pool.add((s.hash ix, recno))

proc add*(s:var Sparse, ix:openArray[int], recno:Recno) = 
  assert ix.len == s.nfields
  s.pool.add((s.hash ix, recno))

proc sort*(s:var Sparse) = s.pool = s.pool.sortedByIt(it.hash)

proc clear*(s:var Sparse) = s.pool.setLen(0)

proc copy*(s:var Sparse, ns:Sparse)=
  s.schema = ns.schema
  s.bitseq = ns.bitseq
  s.nshl = ns.nshl
  s.nshr = ns.nshr
  s.mask = ns.mask
  s.nfields=ns.nfields
  s.nbits=ns.nbits

proc find_name(s:Sparse, name:string):int= # find ss in schema
  for i, nn in s.schema:
    if nn.name == name: return i
  assert false, name & " -> bad field name"


proc rearrange*(s:var Sparse, newsch:varargs[string]) = # change schema order
  
  assert newsch.len == s.nfields

  let nseq = collect(newSeq): # new schema seq
    for ss in newsch:
      s.find_name(ss)

  # rearrange with ns
  var ns :Sparse # new sparse = s, avoid coping pool
  ns.copy s # ns=s (except pool & data)

  for i, n in nseq: # create exchanged seq's
    ns.schema[i] = s.schema[n]
    ns.bitseq[i] = ns.bitseq[n]
    ns.nshl[i] = ns.nshl[n]
    ns.nshr[i] = ns.nshr[n]
    ns.mask[i] = ns.mask[n]

  # rehash pool
  var nuh = newSeq[int](s.nfields)

  for p in s.pool.mitems:
    var uh = s.unhash(p.hash)
    for i, n in nseq: nuh[i] = uh[n]
    p = (ns.hash(nuh), p.recno)

  s.sort # sort rehashed pool

  s.copy ns # s=ns


when isMainModule:
  import strutils, times

  proc test_ins_find=
    var s = sparse(("country", 218), ("station", 105395), ("element", 207), ("year", 238), ("month", 12))
    echo s
    let h = s.hash(12, 1344, 34, 238-1, 2)
    echo "(12, 1344, 34, 237, 2): hash:",h.toHex, ", unhash:", s.unhash(h), ", rehash:", s.unhash(s.hash(12, 1344, 34, 238-1, 2))

    let ns = 105395-2
    for st in 0..<ns: s[218-1, st, 207-1, 238-1, 12-1] = st.Recno
    s.sort

    for st in 0..<ns:
      if s[218-1, st, 207-1, 238-1, 12-1] != st.Recno: echo s[218-1, st, 207-1, 238-1, 12-1], "=", st

    let nc=218-1
    for c in 0..<ns: s[c, 105395-1, 207-1, 238-1, 12-1] = c.Recno
    s.sort
    for c in 0..<nc:
      if s[c, 105395-1, 207-1, 238-1, 12-1] != c.Recno: echo s[c, 105395-1, 207-1, 238-1, 12-1]

    echo s[0,0,0,0,0]==BAD_RECNO

    echo "range check, generation..."
    s.clear

    var recno:Recno=0
    let nco=6
    
    for c in 0..<nco:
      echo "generating...", c 
      let t0=now()
      for st in 0..<105395:
        for el in 0..<207:
          s[c, st, el, 0,0] = recno
          recno.inc

      recno=0
      s.sort

      echo "access test...", c
      for st in 0..<105395:
        for el in 0..<207:
          assert s[c, st, el, 0,0] == recno
          recno.inc

      s.clear
      recno=0

      echo "lap:", (now()-t0).inMilliseconds

    echo "ok"

  proc test_rearrange=
    var s = sparse(("country", 218), ("station", 105395), ("element", 207), ("year", 238), ("month", 12))
    echo s

    echo "adding ", 105395*207 ," items..."
    var t0 = now()
    var recno:Recno = 0
    for st in 0..<105395:
      for el in 0..<207:
        s[0, st, el, 0,0] = recno
        recno.inc

    s.sort
    var sold = s

    echo "rearrange..."
    s.rearrange("station","element", "country", "year", "month")

    echo "checking..."
    for st in 0..<105395:
      for el in 0..<207:
        assert sold[0, st, el, 0,0] == s[st, el, 0, 0, 0]
   

    echo "ok, lap:", (now()-t0).inMilliseconds, "ms"

  test_rearrange()
  
  
