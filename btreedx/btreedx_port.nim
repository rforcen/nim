# on-disk btree(incomplete)


#  Define the following to use inline versions of the respective methods.

const
  bt_NDX_NODE_BASESIZE = 24
  bt_DEFAULT_NDX_NODE_SIZE = 512
  bt_MAX_NDX_NODE_SIZE = 4096
  # bt_NDX_NODE_SIZE = NodeSize
  bt_NDX_NODE_MULTIPLE = 512
  Max_key = 128


type
  BtreeDX = object
    index: ptr BtreeDX
    indexfp: FILE
    IndexStatus: int #  0 = closed, 1 = open
    NodeSize: int

    HeadNode: BtreeDXHeadNode
    LeafNode: BtreeDXLeafNode
    xbNodeLinkCtr: int
    ReusedxbNodeLinks: int
    IndexName: string
    Node: array[bt_MAX_NDX_NODE_SIZE, char]
    NodeChain: ptr BtreeDXNodeLink #  pointer to node chain of index nodes
    FreeNodeChain: ptr BtreeDXNodeLink #  pointer to chain of free index nodes
    CurNode: ptr BtreeDXNodeLink #  pointer to current node
    DeleteChain: ptr BtreeDXNodeLink #  pointer to chain to delete
    CloneChain: ptr BtreeDXNodeLink #  pointer to node chain copy (add dup)
    CurDbfRec: int #  current Dbf record number
    KeyBuf: array[Max_Key, char]  #  work area key buffer
    KeyBuf2: array[Max_Key, char]  #  work area key buffer
    KeyFound: array[Max_Key, char]  #  last key found

  BtreeDXHeadNode = object
    StartNode: int           #  ndx header on disk
    #  header node is node 0
    TotalNodes: int          #  includes header node
    NoOfKeys: int            #  actual count + 1
    KeyLen: int            #  length of key data
    KeysPerNode: int
    KeyType: int           #  00 = Char, 01 = Numeric
    KeySize: int             #  key len + 8 bytes
    Unknown2: char
    Unique: int
    KeyExpression: array[bt_MAX_NDX_NODE_SIZE - 24, char]

  BtreeDXLeafNode  = object
    NoOfKeysThisNode: int    #  ndx node on disk
    KeyRecs: array[bt_MAX_NDX_NODE_SIZE - 4, char]

  BtreeDXNodeLink = object
    PrevNode: ptr BtreeDXNodeLink #  ndx node memory
    NextNode: ptr BtreeDXNodeLink
    CurKeyNo: int            #  0 - KeysPerNode-1
    NodeNo: int
    Leaf: BtreeDXLeafNode

  NodeBufferType = array[bt_MAX_NDX_NODE_SIZE, uint8]


const
  NO_ERROR = 0
  bt_FOUND = 1
  bt_NOT_FOUND = 2
  bt_OPEN = 3
  bt_memory_error = -100
  bt_open_error = -101
  bt_NOT_OPEN = -102
  bt_SEEK_ERROR = -103
  bt_READ_ERROR = -104
  bt_INVALID_NODE_NO = -105
  bt_eof_error = -106
  bt_EOF = -107
  bt_CLOSED = -108
  bt_FILE_EXISTS = -109
  bt_INVALID_KEY = -110
  bt_WRITE_ERROR = -111
  bt_INVALID_NODELINK = -112
  bt_INVALID_RECORD = -113
  bt_NODE_FULL = -114
  bt_KEY_NOT_UNIQUE = -115
  bt_NOT_LEAFNODE = -116

# basics

proc GetHeadNode(bt:var BtreeDX):int=
  if bt.IndexStatus==0:  return bt_NOT_OPEN
  bt.indexfp.setFilePos 0 #  return bt_SEEK_ERROR
  if bt.indexfp.readBuffer(bt.Node.addr, bt.NodeSize)!=bt.NodeSize:
    return bt_READ_ERROR

  copyMem bt.HeadNode.addr, bt.Node.addr, bt.HeadNode.sizeof

  #
  #   Automagically determine the node size.  Note the (2 * sizeof(int))
  #   is taken directly from CreateIndex().
  #

  bt.NodeSize = 2 * sizeof(int) + bt.HeadNode.KeySize * bt.HeadNode.KeysPerNode
  #  printf("NodeSize = %d\n", NodeSize);

  if bt.NodeSize %% bt_NDX_NODE_MULTIPLE != 0:
    bt.NodeSize = ((bt.NodeSize + bt_NDX_NODE_MULTIPLE) div bt_NDX_NODE_MULTIPLE) *
        bt_NDX_NODE_MULTIPLE
  0

proc OpenIndex(bt:var BtreeDX, filename:string) : int =
  var rc: int

  bt.IndexName = filename
  
  #  open the file
  let res_open=bt.indexfp.open(filename)

  if not res_open: return bt_open_error
  
  bt.IndexStatus = bt_OPEN
  rc = bt.GetHeadNode()
  if rc!=0:
    close(bt.indexfp)
    return rc

  rc

proc CloseIndex(bt:var BtreeDX):int=
  if bt.IndexStatus == bt_OPEN: close(bt.indexfp)
  bt.IndexStatus = 0
  NO_ERROR

proc PutHeadNode(bt:var BtreeDX, Head:var BtreeDXHeadNode, f:var FILE, UpdateOnly:int):int=
  
  template writeField(fld:untyped)=
    if bt.indexfp.writeBuffer(fld.addr, fld.sizeof)!=fld.sizeof: return bt_WRITE_ERROR

  bt.indexfp.setFilePos 0 #  return bt_SEEK_ERROR
  
  writeField(Head.StartNode)
  writeField(Head.TotalNodes)
  writeField(Head.NoOfKeys)
  
  if UpdateOnly!=0: return NO_ERROR

  writeField(Head.KeyLen)
  writeField(Head.KeysPerNode)
  writeField(Head.KeyType)
  writeField(Head.KeySize)
  writeField(Head.Unknown2)
  writeField(Head.KeyExpression)

  NO_ERROR

proc CreateIndex(bt:var BtreeDX, IxName:string,  KeyLen:int,  Unique:int, Overlay:int) :int=

  bt.IndexStatus = bt_CLOSED

  # Get the index file name and store it in the class 
  bt.IndexName = IxName

  # check if the file already exists 
  let ex = bt.indexfp.open(IxName, fmReadWriteExisting)
  if ex and Overlay==0:
    close(bt.indexfp)
    return bt_FILE_EXISTS
  
  if ex: close(bt.indexfp)
  if not bt.indexfp.open(IxName, fmReadWrite): return bt_open_error

  # build the header record 
  # memset(&bt.HeadNode, 0x00, sizeof(BtreeDXHeadNode))
  bt.HeadNode.StartNode = 1
  bt.HeadNode.TotalNodes = 2
  bt.HeadNode.NoOfKeys = 1

  if KeyLen == 0 or KeyLen > 100: # 100 byte key length limit     
    return bt_INVALID_KEY
  else:
    bt.HeadNode.KeyType = 0 # character key 
    bt.HeadNode.KeyLen = KeyLen
  

  bt.HeadNode.KeySize = bt.HeadNode.KeyLen + 8
  while (bt.HeadNode.KeySize %% 4) != 0: bt.HeadNode.KeySize.inc # multiple of 4

  bt.HeadNode.KeysPerNode = (bt.NodeSize - 2 * sizeof(int)) div bt.HeadNode.KeySize
  bt.HeadNode.Unique = Unique

  let rc = bt.PutHeadNode(bt.HeadNode, bt.indexfp, 0)
  if rc != 0:  return rc
  
  # write node #1 all 0x00 
  var buff:NodeBufferType

  if bt.indexfp.writeBytes(buff, 0, bt.NodeSize)!=bt.NodeSize:
      close(bt.indexfp)
      return bt_WRITE_ERROR
  
  bt.IndexStatus = bt_OPEN

  NO_ERROR

proc AddKey(bt: var BtreeDX, key:string,  DbfRec:int):int=

  bt.KeyBuf = key

  var rc = bt.FindKey(KeyBuf, bt.HeadNode.KeyLen) # find node key belongs in 
  if rc == bt_FOUND and bt.HeadNode.Unique: return bt_KEY_NOT_UNIQUE

  if bt.CurNode.Leaf.NoOfKeysThisNode > 0 and rc == bt_FOUND: 
    rc = 0
    while rc == 0:
      p = bt.GetKeyData(bt.CurNode.CurKeyNo, bt.CurNode)
      if p == nil:
        rc = -1
      else:
        rc = bt.CompareKey(KeyBuf, p, bt.HeadNode.KeyLen)
        if rc == 0 and DbfRec >= bt.GetDbfNo(bt.CurNode.CurKeyNo, bt.CurNode): 
          rc = GetNextKey()
          if rc == bt_EOF:
            rc = GetLastKey(0)
            if rc != NO_ERROR: return rc
            bt.CurNode.CurKeyNo.inc
        else:
          rc = -1
  
  # update header node 
  bt.HeadNode.NoOfKeys.inc

  # section A - if room in node, add key to node 

  if bt.CurNode.Leaf.NoOfKeysThisNode < bt.HeadNode.KeysPerNode: 
    rc = PutKeyInNode(bt.CurNode, bt.CurNode.CurKeyNo, DbfRec, 0L, 1)
    if rc != 0: return rc
    rc = PutHeadNode(bt.HeadNode, bt.indexfp, 1)
    if rc != 0: return rc
    return NO_ERROR

  # section B - split leaf node if full and put key in correct position 

  var TempNode:BtreeDXNodeLink # = bt.GetNodeMemory()
  bt.HeadNode.TotalNodes.inc
  TempNode.NodeNo = bt.HeadNode.TotalNodes

  rc = bt.SplitLeafNode(CurNode, TempNode, CurNode.CurKeyNo, DbfRec)
  if rc!=0: return rc
  

  var TempNodeNo = TempNode.NodeNo

  # section C go up tree splitting nodes as necessary 

  var Tparent = CurNode.PrevNode.addr

  while Tparent!=nil and Tparent.Leaf.NoOfKeysThisNode >= bt.HeadNode.KeysPerNode):
    var TempNode:BtreeDXNodeLink # = GetNodeMemory()

    rc = SplitINode(Tparent, TempNode, TempNodeNo)
    if rc!=0: return rc

    TempNodeNo = TempNode.NodeNo
    CurNode = Tparent
    CurNode.NextNode = nil
    Tparent = CurNode.PrevNode
  

  # Section D  if CurNode is split root, create new root     

  #[ at this point
      CurNode = The node that was just split
      TempNodeNo = The new node split off from CurNode ]#

  if CurNode.NodeNo == HeadNode.StartNode:

    var SaveNodeChain = NodeChain
    NodeChain = nil
    SaveCurNode = CurNode
    bt.GetLastKey(CurNode.NodeNo)
    memcpy(KeyBuf, GetKeyData(CurNode.CurKeyNo, CurNode), HeadNode.KeyLen)

    NodeChain = SaveNodeChain
    CurNode = SaveCurNode

    bt.PutKeyData(0, TempNode)
    bt.PutLeftNodeNo(0, TempNode, CurNode.NodeNo)
    bt.PutLeftNodeNo(1, TempNode, TempNodeNo)
    TempNode.NodeNo = HeadNode.TotalNodes.inc
    TempNode.Leaf.NoOfKeysThisNode.inc
    HeadNode.StartNode = TempNode.NodeNo
    rc = bt.PutLeafNode(TempNode.NodeNo, TempNode)
    if rc: return rc
    rc = PutHeadNode(&HeadNode, indexfp, 1)
    if rc: return rc
    return NO_ERROR
  
  # Section E  make room in parent 
  for (i = Tparent.Leaf.NoOfKeysThisNode i > Tparent.CurKeyNo i--) 
    memcpy(KeyBuf, GetKeyData(i - 1, Tparent), HeadNode.KeyLen)
    PutKeyData(i, Tparent)
    PutLeftNodeNo(i + 1, Tparent, GetLeftNodeNo(i, Tparent))
  

  # put key in parent 

  SaveNodeChain = NodeChain
  NodeChain = nil
  SaveCurNode = CurNode
  GetLastKey(CurNode.NodeNo)

  memcpy(KeyBuf, GetKeyData(CurNode.CurKeyNo, CurNode), HeadNode.KeyLen)

  ReleaseNodeMemory(NodeChain)
  NodeChain = SaveNodeChain
  CurNode = SaveCurNode

  PutKeyData(i, Tparent)
  PutLeftNodeNo(i + 1, Tparent, TempNodeNo)
  Tparent.Leaf.NoOfKeysThisNode.inc
  rc = PutLeafNode(Tparent.NodeNo, Tparent)
  if (rc) return rc
  rc = PutHeadNode(&HeadNode, indexfp, 1)
  if (rc) return rc

  return NO_ERROR



proc newBtreeDX*():BtreeDX=BtreeDX()

proc open*(bt:var BTreeDX, filename:string):bool=
  bt.OpenIndex(filename) == NO_ERROR

proc create*(bt:var BtreeDX,  fileName:string,  keylen:int,  Unique:int = 1, OverLay:int = 1) : bool =
    bt.CreateIndex(fileName, keylen, Unique, OverLay) == NO_ERROR

proc close*(bt:var BtreeDX) : bool = bt.CloseIndex() == NO_ERROR

proc add(bt:var BtreeDX, key:string, recno:var int):bool=
  bt.AddKey(key, recno) == NO_ERROR

when isMainModule:
  var bt = newBtreeDX()
  echo bt.create("bt.ndx", 8)
