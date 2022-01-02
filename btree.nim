#[ btree
 port from  http://cis.stvincent.edu/html/tutorials/swd/btree/btree.html

 usage:
   vat bt = newBTree(Create, "file.ndx) # create 
   if not bt.add(ItemType(key:toKey($i), data: toData("data" & $i))): break

]#

import streams

type OpenModes* = enum
  ReadWrite # r/w existing file
  Create # create/w/r

const
  MaxKeys = 11  # max number of keys in a node
  MaxKeysPlusOne = MaxKeys + 1
  MinKeys = 5    # min number of keys in a node
  
  NilPtr = -1  
  KeyFieldMax = 12
  DataFieldMax = 36

type 
  KeyFieldType = array[KeyFieldMax, char]
  DataFieldType = array[DataFieldMax, char]

  ItemType = object
    key : KeyFieldType
    data : DataFieldType
  
  NodeType = object
    count : int
    key : array[MaxKeys, ItemType]
    branch : array[MaxKeysPlusOne, int]

  BTree = object 
    dataFile : FileStream
    numItems : int
    openMode : OpenModes

    root, numNodes, nodeSize : int
    currentNode : NodeType

proc cmp(a, b:KeyFieldType):int{.inline.}=
  for i in 0..KeyFieldType.high:
    if a[i]!=b[i]: return a[i].int - b[i].int
  0
  
proc `>=`(a, b:KeyFieldType):bool{.inline.}= cmp(a,b)>=0
proc `<=`(a, b:KeyFieldType):bool{.inline.}= cmp(a,b)<=0
proc `==`(a, b:KeyFieldType):bool{.inline.}= cmp(a,b)==0
proc `!=`(a, b:KeyFieldType):bool{.inline.}= cmp(a,b)!=0
proc `<`(a, b:KeyFieldType):bool{.inline.} = cmp(a,b)<0
proc `>`(a, b:KeyFieldType):bool{.inline.}= cmp(a,b)>0


proc error(msg:string)=
  echo msg
  quit(1)

proc dump*(bt : BTree)=
  for p in 0..bt.numNodes:
  
    bt.dataFile.setPosition p*bt.nodeSize
    discard bt.dataFile.readData(bt.currentNode.unsafeAddr, bt.nodeSize)

    if p==0:
      echo "Node 0 is not part of tree, contains this data:"
      echo "   NumItems = ", bt.currentNode.branch[0]
      echo "   NumNodes = ", bt.currentNode.branch[1]
      echo "   Root = ", bt.currentNode.branch[2] 
    else:
      echo "Dump of node number ", p
      echo "   Count: ", bt.currentNode.count

      write stdout, "   Keys: "

      for k in 0..<bt.currentNode.count:
        write stdout, bt.currentNode.key[k].key, " "
      write stdout, "\n Branches: "
      for k in 0..<bt.currentNode.count:
        write stdout, bt.currentNode.branch[k], " "
      echo ""

proc checkSubtree(bt:BTree, current:int, last: var KeyFieldType)=
  var node: NodeType

  if current == NilPtr: return

  bt.dataFile.setPosition current * bt.nodeSize
  doAssert bt.dataFile.readData(node.unsafeAddr, bt.nodeSize) == bt.nodeSize

  for k in 0..<node.count:
    bt.checkSubtree(node.branch[k], last)
    if last[0] != '*' and last >= node.key[k].key:
      echo "Check has found a problem in node ", current , " index " , k
           , " key " , node.key[k].key
      bt.dump()
      quit(1)    
    last = node.key[k].key  
  bt.checkSubtree(node.branch[node.count], last)

proc check*(bt : BTree)=
  var last : KeyFieldType

  last[0] = '*'
  bt.checkSubtree(bt.root, last)

proc newBtree*(mode:OpenModes, FileName:string) : BTree =

  var fh : File

  result.openMode = mode
  result.nodeSize = sizeof(NodeType)
  
  case mode:
  of ReadWrite:
    if open(fh, FileName, fmReadWriteExisting):
      result.dataFile=newFileStream(fh)

      if result.dataFile.readData(result.currentNode.unsafeAddr, result.nodeSize)==0:
        # assume the Btree is empty if you cannot read from the file
        result.numItems = 0
        result.numNodes = 0
        result.root = NilPtr
      else:  # Node zero is not a normal node, it contains the following:
        result.numItems = result.currentNode.branch[0]
        result.numNodes = result.currentNode.branch[1]
        result.root = result.currentNode.branch[2]
    else:  error "File cannot be opened"
  
  of Create:
    if open(fh, FileName, fmReadWrite):
      result.dataFile=newFileStream(fh)

      result.root = NilPtr
      result.numItems = 0
      result.numNodes = 0  # number does not include the special node zero
      result.currentNode.branch[0] = result.numItems
      result.currentNode.branch[1] = result.numNodes
      result.currentNode.branch[2] = result.root

      result.dataFile.setPosition 0
      result.dataFile.writeData(result.currentNode.unsafeAddr, result.nodeSize)
    else:  error "File cannot be opened"

proc `=destroy`(bt: var BTree) = 
  if bt.openMode == Create: #  Be sure to write out the updated node zero:
    bt.currentNode.branch[0] = bt.numItems
    bt.currentNode.branch[1] = bt.numNodes
    bt.currentNode.branch[2] = bt.root

    bt.dataFile.setPosition 0
    bt.dataFile.writeData(bt.currentNode.unsafeAddr, bt.nodeSize)

  bt.dataFile.flush
  bt.dataFile.close

proc empty*(bt:BTree):bool = bt.root == NilPtr

proc searchNode(bt:BTree, target:KeyFieldType , location: var int) : bool =
  var found = false

  if target < bt.currentNode.key[0].key: location = -1
  else:  # do a sequential search, right to left:
    location = bt.currentNode.count - 1
    while target < bt.currentNode.key[location].key and location > 0:
      location.dec

    if  target == bt.currentNode.key[location].key: found = true
  found

proc addItem(newItem: ItemType, newRight:int,  node:var NodeType, location:int) =
  var j = node.count
  while j > location: 
    node.key[j] = node.key[j - 1]
    node.branch[j + 1] = node.branch[j]
    j.dec
  
  node.key[location] = newItem
  node.branch[location + 1] = newRight
  inc node.count

proc split(bt: var BTree, currentItem:ItemType, currentRight, currentRoot, location: int, 
  newItem:var ItemType, newRight:var int) =
  var
     median:int
     rightNode:NodeType

  if location < MinKeys:  median = MinKeys
  else:   median = MinKeys + 1

  bt.dataFile.setPosition currentRoot * bt.nodeSize
  doAssert bt.dataFile.readData(bt.currentNode.unsafeAddr, bt.nodeSize) == bt.nodeSize

  for j in median ..< MaxKeys: # move half of the items to the RightNode
    rightNode.key[j - median] = bt.currentNode.key[j]
    rightNode.branch[j - median + 1] = bt.currentNode.branch[j + 1]
  

  rightNode.count = MaxKeys - median
  bt.currentNode.count = median  # is then incremented by AddItem

  # put CurrentItem in place
  if location < MinKeys: addItem(currentItem, currentRight, bt.currentNode, location + 1)
  else:    addItem(currentItem, currentRight, rightNode, location - median + 1)

  newItem = bt.currentNode.key[bt.currentNode.count - 1]
  rightNode.branch[0] = bt.currentNode.branch[bt.currentNode.count]
  bt.currentNode.count.dec

  bt.dataFile.setPosition currentRoot * bt.nodeSize
  bt.dataFile.writeData(bt.currentNode.unsafeAddr, bt.nodeSize)

  bt.numNodes.inc
  newRight = bt.numNodes
  bt.dataFile.setPosition newRight * bt.nodeSize
  bt.dataFile.writeData rightNode.addr, bt.nodeSize

proc pushDown(bt:var BTree,  currentItem:ItemType, currentRoot:int,
                            moveUp:var bool, newItem:var ItemType, newRight:var int) =
  var location=0


  if currentRoot == NilPtr:  # stopping case, cannot insert into empty tree
    moveUp = true
    newItem = currentItem
    newRight = NilPtr
  else:  # recursive case
  
    bt.dataFile.setPosition currentRoot * bt.nodeSize
    doAssert bt.dataFile.readData(bt.currentNode.unsafeAddr, bt.nodeSize)==bt.nodeSize


    if bt.searchNode(currentItem.key, location):
      error("Error: attempt to put a duplicate into B-tree")

    bt.pushDown(currentItem, bt.currentNode.branch[location + 1], moveUp, newItem, newRight)

    if moveUp:
      bt.dataFile.setPosition currentRoot * bt.nodeSize
      doAssert bt.dataFile.readData(bt.currentNode.unsafeAddr, bt.nodeSize) == bt.nodeSize


      if bt.currentNode.count < MaxKeys:
        moveUp = false
        addItem(newItem, newRight, bt.currentNode, location + 1)
        bt.dataFile.setPosition currentRoot * bt.nodeSize
        bt.dataFile.writeData(bt.currentNode.unsafeAddr, bt.nodeSize)

      else:
        moveUp = true
        bt.split(newItem, newRight, currentRoot, location, newItem, newRight)
      
proc add*(bt:var BTree, item: ItemType) : bool =
  var
    MoveUp:bool
    NewRight:int
    NewItem:ItemType

  bt.pushDown(item, bt.root, MoveUp, NewItem, NewRight)

  if MoveUp:  # create a new root node
    bt.currentNode.count = 1
    bt.currentNode.key[0] = NewItem
    bt.currentNode.branch[0] = bt.root
    bt.currentNode.branch[1] = NewRight
    bt.numNodes.inc
    bt.root = bt.numNodes
    bt.dataFile.setPosition bt.numNodes * bt.nodeSize
    bt.dataFile.writeData(bt.currentNode.unsafeAddr, bt.nodeSize)

  bt.numItems.inc   # fixed 12/21/2001
  true  # no reason not to assume success

proc find*(bt:var BTree,  searchKey:KeyFieldType, item:var ItemType) : bool =
  var
    currentRoot = bt.root
    location = 0
    found = false

  while currentRoot != NilPtr and not found: 
    bt.dataFile.setPosition currentRoot * bt.nodeSize
    doAssert bt.dataFile.readData(bt.currentNode.unsafeAddr, bt.nodeSize) == bt.nodeSize

    if bt.searchNode(searchKey, location):
      found = true
      item = bt.currentNode.key[location]
    else:
      currentRoot = bt.currentNode.branch[location + 1]
  
  found

# int, string to Key/Data conversion
proc toKey*(i:int):KeyFieldType=cast[KeyFieldType](i)
proc toKey*(s:string):KeyFieldType=
  for i in 0..min(KeyFieldType.high, s.high):
    result[i]=s[i]
proc toData*(i:int):DataFieldType=cast[DataFieldType](i)
proc toData*(s:string):DataFieldType=
  for i in 0..min(DataFieldType.high, s.high):
    result[i]=s[i]

when isMainModule:
  import random, times, sequtils

  const  n = 400_000

  proc test_ins_find_random*()=
    var bt = newBtree(Create, "btree.ndx")

    var rl = (0..n).toSeq() # random list
    rl.shuffle

    echo "inserting random list..."
    
    for i in 0..n:
      if not bt.add(ItemType(key:toKey($rl[i]), data: toData("data" & $rl[i]))): break
      if i %% (n div 10) == 0: write stdout, "\r", i;   stdout.flushFile

    bt.check

    echo "\nok\nfind random list..."

    var ok=true
    for i in 0..n:
      var item : ItemType
      if not bt.find(toKey($rl[i]), item): 
        ok=false
        break
      else:
        doAssert item.key == toKey($rl[i])
        doAssert item.data == toData("data" & $rl[i])
      if i %% (n div 10) == 0: 
        write stdout, i, "\r";   stdout.flushFile
  
    # bt.Dump
    echo ""
    echo if ok: "ok" else: "find failed!"

  proc test_ins_find*()=
    var bt = newBtree(Create, "btree.ndx")

    echo "inserting..."
    for i in 0..n:
      if not bt.add(ItemType(key:toKey($i), data: toData("data" & $i))): break
      if i %% (n div 10) == 0: write stdout, "\r", i;   stdout.flushFile

    bt.check

    echo "\nok\nfind..."
    var ok=true
    for i in 0..n:
      var item : ItemType
      if not bt.find(toKey($i), item): 
        ok=false
        break
      else:
        doAssert item.key == toKey($i)
        doAssert item.data == toData("data" & $i)
      if i %% (n div 10) == 0: 
        write stdout, i, "\r";   stdout.flushFile
  
    # bt.Dump
    echo ""
    echo if ok: "ok" else: "retrieve fail"

  proc test_find*()=
    var bt = newBtree(ReadWrite, "btree.ndx")

    bt.check

    echo "\nfind..."
    var ok=true

    for i in 0..n:
      var item : ItemType
      if not bt.find(toKey($i), item): 
        echo "key not found:", i, item
        ok=false
        break
      else:
        doAssert item.key == toKey($i)
        doAssert item.data == toData("data" & $i)
      if i %% (n div 10) == 0: 
        write stdout, i, "\r";   stdout.flushFile
  
    # bt.Dump
    echo ""
    echo if ok: "ok" else: "find fail"

  proc test_random_find=
    var bt = newBtree(ReadWrite, "btree.ndx")

    bt.check

    echo "\nrandom find..."
    var ok=true

    let 
      t0=now()
      niters=n*10

    for i in 0..niters:
      var item : ItemType
      let 
        r = $rand(n)
        key=toKey(r)
      if not bt.find(key, item): 
        echo "key not found:", i, item
        ok=false
        break
      else:
        doAssert item.key == key
        doAssert item.data == toData("data" & r)
      if i %% (n div 10) == 0: 
        write stdout, "\r", i;   stdout.flushFile
  
    # bt.Dump
    echo "\nlap:", (now()-t0).inMicroseconds.float / niters.float, " us/search"
    echo if ok: "ok" else: "retrieve fail"

  proc test_key_cmp=
    doAssert 10.toKey < 11.toKey
    doAssert 12.toKey > 10.toKey
    doAssert 10.toKey >= 10.toKey
    doAssert 8.toKey <= 68.toKey
    doAssert 10.toKey == 10.toKey
    doAssert 10.toKey != 11.toKey
    
    doAssert "10".toKey < "11".toKey
    doAssert "7".toKey > "10".toKey
    doAssert "10".toKey >= "10".toKey
    doAssert "6".toKey <= "68".toKey
    doAssert "10".toKey == "10".toKey
    doAssert "10".toKey != "11".toKey
    echo "key cmp ok!"
  
  randomize()

  test_ins_find_random()
  # test_key_cmp()
  # test_ins_find()
  # test_find()
  # test_random_find()
