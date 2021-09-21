# btreedx nim wrapper
# g++ -c btreedx.cpp
# nim cpp -d:release -d:danger btreedx_wrapper.nim

{.passL:"btreedx.o".}
{.passC:"-std=c++11".}

# ffi
type BtreeDX*{.importcpp:"BtreeDX", header:"btreedx.h".}= object
proc newBtreeDX*() : ptr BtreeDX  {.importcpp:"new BtreeDX()",  header: "btreedx.h".}
proc open*(bt:ptr BtreeDX, fileName:cstring) : bool  {.importcpp:"#.open(@)", header: "btreedx.h".}
proc close*(bt:ptr BtreeDX) : bool  {.importcpp:"#.close()",  header: "btreedx.h".}
proc create*(bt:ptr BtreeDX, fileName:cstring, keylen:cint, unique:cint=1, overlay:cint=1) : bool  {.importcpp:"#.create(@)",  header: "btreedx.h".}
proc add*(bt:ptr BtreeDX, key:cstring, recno:cint) : bool  {.importcpp:"#.add(@)",  header: "btreedx.h".}
proc find*(bt:ptr BtreeDX, key:cstring, recno:var cint) : bool  {.importcpp:"#.find(@)",  header: "btreedx.h".}
proc findEQ*(bt:ptr BtreeDX, key:cstring, recno:var cint) : bool  {.importcpp:"#.findEQ(@)",  header: "btreedx.h".}
proc next*(bt:ptr BtreeDX, key:cstring, recno:var cint) : bool  {.importcpp:"#.next(@)",  header: "btreedx.h".}
proc eraseEQ*(bt:ptr BtreeDX, key:cstring) : bool  {.importcpp:"#.eraseEQ(@)",  header: "btreedx.h".}
proc eraseMatch*(bt:ptr BtreeDX, key:cstring) : bool  {.importcpp:"#.eraseMatch(@)",  header: "btreedx.h".}

# wrapper
proc open*(bt:ptr BtreeDX, fileName:string) : bool = bt.open(fileName.cstring)

proc create*(bt:ptr BtreeDX, fileName:string, keylen:int, unique:int=1, overlay:int=1) : bool=
  bt.create(fileName.cstring, keylen.cint, unique.cint, overlay.cint)

proc add*(bt:ptr BtreeDX, key:string, recno:int) : bool =  bt.add(key.cstring, recno.cint)

proc find*(bt:ptr BtreeDX, key:string, recno:var int) : bool  =
  var ci = recno.cint
  result=bt.find(key.cstring, ci)
  recno=ci.int

proc next*(bt:ptr BtreeDX, key:var string, recno:var int) : bool =
  var ci = recno.cint
  result=bt.next(key.cstring, ci)
  recno=ci.int

# test

when isMainModule:

  const 
    n=1000
    filename="test.ndx"

  proc create_ins_find* =

    var bt = newBtreeDX()

    if bt.create(filename, 8):
      echo "created, inserting ",n," keys..."
      for i in 0..n:
        let key = $i
        if not bt.add(key, i):
          echo i,","

      echo "finding..."
      for i in 0..n:
        let key = $i
        var recno=0
        if not bt.find(key, recno):
          echo "nf",i,","

      var 
        key="100"
        recno=0

      echo "next from ", key

      if bt.find(key, recno):
        for i in 0..10:
          echo key, ":",recno
          discard bt.next(key, recno)

      if bt.close():
        echo "closed, ok"

  proc open_find* =
    var bt = newBtreeDX()
    if bt.open(filename):
      var 
        part_key="45"
        key=part_key
        recno=0

      echo "partial match:", key
      if bt.find(key, recno):
        while true:
          stdout.write key, ":",recno, " | "
          if not bt.next(key, recno) or key[0..part_key.high]!=part_key: break

      discard bt.close
    echo ""

  create_ins_find()
  open_find()