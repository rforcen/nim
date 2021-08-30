#include "btreedx.h"

#define USE_BSEARCH

short BtreeDX::CloneNodeChain() {
  BtreeDXNodeLink *TempNodeS;
  BtreeDXNodeLink *TempNodeT;
  BtreeDXNodeLink *TempNodeT2;

  if (CloneChain) ReleaseNodeMemory(CloneChain);
  CloneChain = NULL;

  if (!NodeChain) return NO_ERROR;
  TempNodeS = NodeChain;
  TempNodeT2 = NULL;

  while (TempNodeS) {
    if ((TempNodeT = GetNodeMemory()) == NULL) {
      return bt_memory_error;
    }
    memcpy(TempNodeT, TempNodeS, sizeof(struct BtreeDXNodeLink));
    TempNodeT->NextNode = NULL;
    TempNodeT->PrevNode = TempNodeT2;
    if (!CloneChain) {
      TempNodeT2 = TempNodeT;
      CloneChain = TempNodeT;
    } else {
      TempNodeT2->NextNode = TempNodeT;
      TempNodeT2 = TempNodeT2->NextNode;
    }
    TempNodeS = TempNodeS->NextNode;
  }
  return NO_ERROR;
}

short BtreeDX::UncloneNodeChain() {
  if (NodeChain) ReleaseNodeMemory(NodeChain);
  NodeChain = CloneChain;
  CloneChain = NULL;
  CurNode = NodeChain;
  while (CurNode->NextNode) CurNode = CurNode->NextNode;
  return NO_ERROR;
}

/* This routine dumps the node chain to stdout                         */
#ifdef XBASE_DEBUG
void BtreeDX::DumpNodeChain() {
  BtreeDXNodeLink *n;
  cout << "\n*************************\n";
  cout << "xbNodeLinkCtr = " << xbNodeLinkCtr;
  cout << "\nReused      = " << ReusedxbNodeLinks << "\n";

  n = NodeChain;
  while (n) {
    cout << "xbNodeLink Chain" << n->NodeNo << "\n";
    n = n->NextNode;
  }
  n = FreeNodeChain;
  while (n) {
    cout << "FreexbNodeLink Chain" << n->NodeNo << "\n";
    n = n->NextNode;
  }
  n = DeleteChain;
  while (n) {
    cout << "DeleteLink Chain" << n->NodeNo << "\n";
    n = n->NextNode;
  }
}
#endif

/* This routine returns a chain of one or more index nodes back to the */
/* free node chain                                                     */

void BtreeDX::ReleaseNodeMemory(BtreeDXNodeLink *n) {
  BtreeDXNodeLink *temp;

  if (!FreeNodeChain)
    FreeNodeChain = n;
  else /* put this list at the end */
  {
    temp = FreeNodeChain;
    while (temp->NextNode) temp = temp->NextNode;
    temp->NextNode = n;
  }
  return;
}

/*!
 */
/* This routine returns a node from the free chain if available,       */
/* otherwise it allocates new memory for the requested node             */

BtreeDX::BtreeDXNodeLink *BtreeDX::GetNodeMemory(void) {
  BtreeDXNodeLink *temp;
  if (FreeNodeChain) {
    temp = FreeNodeChain;
    FreeNodeChain = temp->NextNode;
    ReusedxbNodeLinks++;
  } else {
    temp = (BtreeDXNodeLink *)malloc(sizeof(BtreeDXNodeLink));
    xbNodeLinkCtr++;
  }
  memset(temp, 0x00, sizeof(BtreeDXNodeLink));
  return temp;
}
void BtreeDX::DumpHdrNode() {
  cout << "\nStart node    = " << HeadNode.StartNode;
  cout << "\nTotal nodes   = " << HeadNode.TotalNodes;
  cout << "\nNo of keys    = " << HeadNode.NoOfKeys;
  cout << "\nKey Length    = " << HeadNode.KeyLen;
  cout << "\nKeys Per Node = " << HeadNode.KeysPerNode;
  cout << "\nKey type      = " << HeadNode.KeyType;
  cout << "\nKey size      = " << HeadNode.KeySize;
  cout << "\nUnknown 2     = " << HeadNode.Unknown2;
  cout << "\nUnique        = " << HeadNode.Unique;
  cout << "\nKeyExpression = " << HeadNode.KeyExpression;
  cout << "\n";

#if 0
   FILE * log;
   if(( log = fopen( "xbase.log", "a+t" )) == NULL ) return;
   fprintf( log, "\n-------------------" );
   fprintf( log, "\nStart node    =%ld ",  HeadNode.StartNode );
   fprintf( log, "\nTotal nodes   =%ld ",  HeadNode.TotalNodes );
   fprintf( log, "\nNo of keys    =%ld ",  HeadNode.NoOfKeys );
   fprintf( log, "\nKey Length    =%d ",   HeadNode.KeyLen );
   fprintf( log, "\nKeys Per Node =%d ",   HeadNode.KeysPerNode );
   fprintf( log, "\nKey type      =%d ",   HeadNode.KeyType );
   fprintf( log, "\nKey size      =%ld ",  HeadNode.KeySize );
   fprintf( log, "\nUnknown 2     =%d ",   HeadNode.Unknown2 );
   fprintf( log, "\nUnique        =%d ",   HeadNode.Unique );
   fprintf( log, "\nKeyExpression =%s \n", HeadNode.KeyExpression );
   fclose( log );
#endif
}

BtreeDX::BtreeDX() {
  memset(Node, 0x00, bt_MAX_NDX_NODE_SIZE);
  memset(&HeadNode, 0x00, sizeof(BtreeDXHeadNode));
  NodeChain = NULL;
  CloneChain = NULL;
  FreeNodeChain = NULL;
  DeleteChain = NULL;
  CurNode = NULL;
  xbNodeLinkCtr = 0L;
  ReusedxbNodeLinks = 0L;
  NodeSize = bt_DEFAULT_NDX_NODE_SIZE;
  KeyBuf = KeyBuf2 = KeyFound = NULL;
}

short BtreeDX::OpenIndex(const char *FileName) {
  int NameLen, rc;

  NameLen = strlen(FileName) + 1;
  IndexName = FileName;

  /* open the file */
  if ((indexfp = fopen(FileName, "r+b")) == NULL) return bt_open_error;

  IndexStatus = bt_OPEN;
  if ((rc = GetHeadNode()) != 0) {
    fclose(indexfp);
    return rc;
  }

  freeKeyBuff();

  KeyBuf = (char *)malloc(HeadNode.KeyLen + 1);
  KeyBuf2 = (char *)malloc(HeadNode.KeyLen + 1);
  KeyFound = (char *)malloc(HeadNode.KeyLen + 1);
  memset(KeyBuf, 0, HeadNode.KeyLen + 1);
  memset(KeyBuf2, 0, HeadNode.KeyLen + 1);
  memset(KeyFound, 0, HeadNode.KeyLen + 1);

  return rc;
}

short BtreeDX::CloseIndex(void) {
  freeKeyBuff();

  if (indexfp && IndexStatus == bt_OPEN) fclose(indexfp);
  IndexStatus = 0;
  return NO_ERROR;
}

short BtreeDX::GetHeadNode(void) {
  char *p;

  if (!IndexStatus) return bt_NOT_OPEN;
  if (fseek(indexfp, 0, SEEK_SET)) return bt_SEEK_ERROR;
  if ((fread(Node, bt_NDX_NODE_SIZE, 1, indexfp)) != 1) return bt_READ_ERROR;

  /* load the head node structure */
  p = Node;
  HeadNode.StartNode = GetLong(p);
  p += 4;
  HeadNode.TotalNodes = GetLong(p);
  p += 4;
  HeadNode.NoOfKeys = GetLong(p);
  p += 4;
  HeadNode.KeyLen = GetShort(p);
  p += 2;
  HeadNode.KeysPerNode = GetShort(p);
  p += 2;
  HeadNode.KeyType = GetShort(p);
  p += 2;
  HeadNode.KeySize = GetLong(p);
  p += 4;
  HeadNode.Unknown2 = *p++;
  HeadNode.Unique = *p++;

  //
  //  Automagically determine the node size.  Note the (2 * sizeof(int))
  //  is taken directly from CreateIndex().
  //
  NodeSize = (2 * sizeof(int)) + HeadNode.KeySize * HeadNode.KeysPerNode;
  // printf("NodeSize = %d\n", NodeSize);
  if (NodeSize % bt_NDX_NODE_MULTIPLE)
    NodeSize = ((NodeSize + bt_NDX_NODE_MULTIPLE) / bt_NDX_NODE_MULTIPLE) *
               bt_NDX_NODE_MULTIPLE;
  // printf("NodeSize = %d\n", NodeSize);

  return 0;
}

/* This routine reads a leaf node from disk                            */
/*                                                                     */
/*  If SetNodeChain 2, then the node is not appended to the node chain */
/*                     but the CurNode pointer points to the node read */
/*  If SetNodeChain 1, then the node is appended to the node chain     */
/*  If SetNodeChain 0, then record is only read to Node memory         */

short BtreeDX::GetLeafNode(int NodeNo, short SetNodeChain) {
  BtreeDXNodeLink *n;

  if (!IndexStatus) return bt_NOT_OPEN;

  if (fseek(indexfp, NodeNo * bt_NDX_NODE_SIZE, SEEK_SET)) return bt_SEEK_ERROR;

  if ((fread(Node, bt_NDX_NODE_SIZE, 1, indexfp)) != 1) return bt_READ_ERROR;

  if (!SetNodeChain) return 0;

  if ((n = GetNodeMemory()) == NULL) return bt_memory_error;

  n->NodeNo = NodeNo;
  n->CurKeyNo = 0L;
  n->NextNode = NULL;
  n->Leaf.NoOfKeysThisNode = GetLong(Node);
  memcpy(n->Leaf.KeyRecs, Node + 4, bt_NDX_NODE_SIZE - 4);

  /* put the node in the chain */
  if (SetNodeChain == 1) {
    if (NodeChain == NULL) /* first one ? */
    {
      NodeChain = n;
      CurNode = n;
      CurNode->PrevNode = NULL;
    } else {
      n->PrevNode = CurNode;
      CurNode->NextNode = n;
      CurNode = n;
    }
  } else
    CurNode = n;
  return 0;
}

/*!
  \param n
*/
#ifdef XBASE_DEBUG
void BtreeDX::DumpNodeRec(int n) {
  char *p;
  int NoOfKeys, LeftBranch, RecNo;
  short i, j;
  FILE *log;

  if ((log = fopen("xbase.log", "a+t")) == NULL) return;
  GetLeafNode(n, 0);
  NoOfKeys = GetLong(Node);
  p = Node + 4; /* go past no of keys */

  fprintf(log, "\n--------------------------------------------------------");
  fprintf(log, "\nNode # %ld", n);
  fprintf(log, "\nNumber of keys = %ld", NoOfKeys);
  fprintf(log, "\n Key     Left     Rec     Key");
  fprintf(log, "\nNumber  Branch   Number   Data");

  for (i = 0; i < GetKeysPerNode() /*NoOfKeys*/; i++) {
    LeftBranch = GetLong(p);
    p += 4;
    RecNo = GetLong(p);
    p += 4;

    fprintf(log, "\n  %d       %ld       %ld         ", i, LeftBranch, RecNo);

    if (!HeadNode.KeyType)
      for (j = 0; j < HeadNode.KeyLen; j++) fputc(*p++, log);
    else {
      fprintf(log, "??????" /*, GetDouble( p )*/);
      p += 8;
    }
  }
  fclose(log);
}
#endif

#ifndef bt_INLINE_GETDBFNO
int BtreeDX::GetDbfNo(short RecNo, BtreeDXNodeLink *n) {
  BtreeDXLeafNode *temp;
  char *p;
  if (!n) return 0L;
  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > (temp->NoOfKeysThisNode - 1)) return 0L;
  p = temp->KeyRecs + 4;
  p += RecNo * (8 + HeadNode.KeyLen);
  return (GetLong(p));
}
#endif

/*!
  \param RecNo
  \param n
*/
int BtreeDX::GetLeftNodeNo(short RecNo, BtreeDXNodeLink *n) {
  BtreeDXLeafNode *temp;
  char *p;
  if (!n) return 0L;
  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > temp->NoOfKeysThisNode) return 0L;
  p = temp->KeyRecs;
  p += RecNo * (8 + HeadNode.KeyLen);
  return (GetLong(p));
}

/*!
  \param RecNo
  \param n
*/
char *BtreeDX::GetKeyData(short RecNo, BtreeDXNodeLink *n) {
  BtreeDXLeafNode *temp;
  char *p;
  if (!n) return 0L;
  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > (temp->NoOfKeysThisNode - 1)) return 0L;
  p = temp->KeyRecs + 8;
  p += RecNo * (8 + HeadNode.KeyLen);
  return (p);
}

/*!
 */
int BtreeDX::GetTotalNodes(void) { return HeadNode.TotalNodes; }

/*!
 */
short BtreeDX::GetKeysPerNode(void) { return HeadNode.KeysPerNode; }

/*!
  \param RetrieveSw
*/
short BtreeDX::GetFirstKey() {
  /* This routine returns 0 on success and sets CurDbfRec to the record  */
  /* corresponding to the first index pointer                            */

  int TempNodeNo;
  short rc;

  /* initialize the node chain */
  if (NodeChain) {
    ReleaseNodeMemory(NodeChain);
    NodeChain = NULL;
  }

  if ((rc = GetHeadNode()) != 0) {
    CurDbfRec = 0L;
    return rc;
  }

  /* get a node and add it to the link */

  if ((rc = GetLeafNode(HeadNode.StartNode, 1)) != 0) {
    return rc;
  }

  /* traverse down the left side of the tree */
  while (GetLeftNodeNo(0, CurNode)) {
    TempNodeNo = GetLeftNodeNo(0, CurNode);
    if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;
    }
    CurNode->CurKeyNo = 0;
  }
  CurDbfRec = GetDbfNo(0, CurNode);

  return NO_ERROR;
}

/*!
  \param RetrieveSw
*/
short BtreeDX::GetNextKey() {
  /* This routine returns 0 on success and sets CurDbfRec to the record  */
  /* corresponding to the next index pointer                             */

  BtreeDXNodeLink *TempxbNodeLink;

  int TempNodeNo;
  short rc = 0;

  if (!IndexStatus) {
    CurDbfRec = 0L;
    return (bt_NOT_OPEN);
  }

  if (!CurNode) {
    rc = GetFirstKey();
    return rc;
  }

  /* more keys on this node ? */
  if ((CurNode->Leaf.NoOfKeysThisNode - 1) > CurNode->CurKeyNo) {
    CurNode->CurKeyNo++;
    CurDbfRec = GetDbfNo(CurNode->CurKeyNo, CurNode);
    char *d = GetKeyData(CurNode->CurKeyNo, CurNode);
    if (d) strncpy(KeyFound, d, HeadNode.KeyLen);  // save current key
    return NO_ERROR;
  }

  /* if head node we are at eof */
  if (CurNode->NodeNo == HeadNode.StartNode) {
    return bt_eof_error;
  }

  /* this logic assumes that interior nodes have n+1 left node no's where */
  /* n is the number of keys in the node                                  */

  /* pop up one node to the interior node level & free the leaf node      */

  TempxbNodeLink = CurNode;
  CurNode = CurNode->PrevNode;
  CurNode->NextNode = NULL;
  ReleaseNodeMemory(TempxbNodeLink);

  /* while no more right keys && not head node, pop up one node */
  while ((CurNode->CurKeyNo >= CurNode->Leaf.NoOfKeysThisNode) &&
         (CurNode->NodeNo != HeadNode.StartNode)) {
    TempxbNodeLink = CurNode;
    CurNode = CurNode->PrevNode;
    CurNode->NextNode = NULL;
    ReleaseNodeMemory(TempxbNodeLink);
  }

  /* if head node && right most key, return end-of-file */
  if ((HeadNode.StartNode == CurNode->NodeNo) &&
      (CurNode->CurKeyNo >= CurNode->Leaf.NoOfKeysThisNode)) {
    return bt_eof_error;
  }

  /* move one to the right */
  CurNode->CurKeyNo++;
  TempNodeNo = GetLeftNodeNo(CurNode->CurKeyNo, CurNode);

  if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
    return rc;  // error
  }

  /* traverse down the left side of the tree */
  while (GetLeftNodeNo(0, CurNode)) {
    TempNodeNo = GetLeftNodeNo(0, CurNode);
    if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;  // error
    }
    CurNode->CurKeyNo = 0;
  }

  CurDbfRec = GetDbfNo(0, CurNode);
  char *d = GetKeyData(CurNode->CurKeyNo, CurNode);
  if (d) strncpy(KeyFound, d, HeadNode.KeyLen);  // save current key

  return NO_ERROR;
}

/*!
  \param NodeNo
  \param RetrieveSw
*/
short BtreeDX::GetLastKey(int NodeNo) {
  /* This routine returns 0 on success and sets CurDbfRec to the record  */
  /* corresponding to the last index pointer                             */

  /* If NodeNo = 0, start at head node, otherwise start at NodeNo        */

  int TempNodeNo;
  short rc;

  if (NodeNo < 0 || NodeNo > HeadNode.TotalNodes) return (bt_INVALID_NODE_NO);

  /* initialize the node chain */
  if (NodeChain) {
    ReleaseNodeMemory(NodeChain);
    NodeChain = NULL;
  }
  if (NodeNo == 0L)
    if ((rc = GetHeadNode()) != 0) {
      CurDbfRec = 0L;
      return rc;
    }

  /* get a node and add it to the link */

  if (NodeNo == 0L) {
    if ((rc = GetLeafNode(HeadNode.StartNode, 1)) != 0) {
      CurDbfRec = 0L;

      return rc;
    }
  } else {
    if ((rc = GetLeafNode(NodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;
    }
  }
  CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode;

  /* traverse down the right side of the tree */
  while (GetLeftNodeNo(CurNode->Leaf.NoOfKeysThisNode, CurNode)) {
    TempNodeNo = GetLeftNodeNo(CurNode->Leaf.NoOfKeysThisNode, CurNode);
    if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;
    }
    CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode;
  }
  CurNode->CurKeyNo--; /* leaf node has one fewer ix recs */
  CurDbfRec = GetDbfNo(CurNode->Leaf.NoOfKeysThisNode - 1, CurNode);

  return NO_ERROR;
}

/*!
  \param RetrieveSw
*/
short BtreeDX::GetPrevKey() {
  /* This routine returns 0 on success and sets CurDbfRec to the record  */
  /* corresponding to the previous index pointer                         */

  BtreeDXNodeLink *TempxbNodeLink;

  int TempNodeNo;
  short rc = 0;

  if (!IndexStatus) {
    CurDbfRec = 0L;
    return (bt_NOT_OPEN);
  }

  if (!CurNode) {
    CurDbfRec = 0L;
    return GetFirstKey();
  }

  /* more keys on this node ? */
  if (CurNode->CurKeyNo > 0) {
    CurNode->CurKeyNo--;
    CurDbfRec = GetDbfNo(CurNode->CurKeyNo, CurNode);

    return NO_ERROR;
  }

  /* this logic assumes that interior nodes have n+1 left node no's where */
  /* n is the number of keys in the node                                  */

  /* pop up one node to the interior node level & free the leaf node      */

  if (!CurNode->PrevNode) { /* michael - make sure prev node exists */
    return bt_eof_error;
  }

  TempxbNodeLink = CurNode;
  CurNode = CurNode->PrevNode;
  CurNode->NextNode = NULL;
  ReleaseNodeMemory(TempxbNodeLink);

  /* while no more left keys && not head node, pop up one node */
  while ((CurNode->CurKeyNo == 0) && (CurNode->NodeNo != HeadNode.StartNode)) {
    TempxbNodeLink = CurNode;
    CurNode = CurNode->PrevNode;
    CurNode->NextNode = NULL;
    ReleaseNodeMemory(TempxbNodeLink);
  }

  /* if head node && left most key, return end-of-file */
  if ((HeadNode.StartNode == CurNode->NodeNo) && (CurNode->CurKeyNo == 0)) {
#ifdef bt_LOCKING_ON
    if (dbf->GetAutoLock()) LockIndex(F_SETLKW, F_UNLCK);
#endif
    return bt_eof_error;
  }

  /* move one to the left */
  CurNode->CurKeyNo--;
  TempNodeNo = GetLeftNodeNo(CurNode->CurKeyNo, CurNode);

  if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
#ifdef bt_LOCKING_ON
    if (dbf->GetAutoLock()) LockIndex(F_SETLKW, F_UNLCK);
#endif
    return rc;
  }

  if (GetLeftNodeNo(0, CurNode)) /* if interior node */
    CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode;
  else /* leaf node */
    CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode - 1;

  /* traverse down the right side of the tree */
  while (GetLeftNodeNo(0, CurNode)) /* while interior node */
  {
    TempNodeNo = GetLeftNodeNo(CurNode->Leaf.NoOfKeysThisNode, CurNode);
    if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;
    }
    if (GetLeftNodeNo(0, CurNode)) /* if interior node */
      CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode;
    else /* leaf node */
      CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode - 1;
  }
  CurDbfRec = GetDbfNo(CurNode->Leaf.NoOfKeysThisNode - 1, CurNode);

  return NO_ERROR;
}

#ifndef bt_INLINE_COMPAREKEY

/*!
  \param Key1
  \param Key2
  \param Klen
*/
short BtreeDX::CompareKey(const char *Key1, const char *Key2, short Klen) {
  /*   if key1 = key2  --> return 0      */
  /*   if key1 > key2  --> return 1      */
  /*   if key1 < key2  --> return 2      */

  const char *k1, *k2;
  short i;
  double d1, d2;
  int c;

  if (!(Key1 && Key2)) return -1;

  if (Klen > HeadNode.KeyLen) Klen = HeadNode.KeyLen;

  if (HeadNode.KeyType == 0) {
#if 0
      k1 = Key1;
      k2 = Key2;
      for( i = 0; i < Klen; i++ )
      {
         if( *k1 > *k2 ) return 1;
         if( *k1 < *k2 ) return 2;
         k1++;
         k2++;
      }
      return 0;
#else
    // printf("comparing '%s' to '%s'\n", Key1, Key2);
    c = memcmp(Key1, Key2, Klen);
    if (c < 0)
      return 2;
    else if (c > 0)
      return 1;
    return 0;
#endif
  } else /* key is numeric */
  {
    d1 = GetDouble(Key1);
    d2 = GetDouble(Key2);
    if (d1 == d2)
      return 0;
    else if (d1 > d2)
      return 1;
    else
      return 2;
  }
}
#endif

/**************************************************************************/

/*!
  \param key
  \param klen
  \param node
  \param comp
*/
/*
**  This is a pretty basic binary search with two exceptions:  1) it will
**  find the first of duplicate key values and 2) will return the index
**  and the value of the last comparision even if it doesn't find a
**  match.
*/
short BtreeDX::BSearchNode(const char *key, short klen,
                           const BtreeDXNodeLink *node, short *comp) {
  short c = 1, p = -1, start = 0, end = node->Leaf.NoOfKeysThisNode - 1;

  if (start > end) {
    *comp = 2;
    return 0;
  }

  do {
    p = (start + end) / 2;
    c = CompareKey(key, GetKeyData(p, (BtreeDXNodeLink *)node), klen);
    switch (c) {
      case 1: /* greater than */
        start = p + 1;
        break;

      case 2: /* less than */
        end = p - 1;
        break;
    }
  } while (start <= end && c);

  if (c == 1)
    while (p < node->Leaf.NoOfKeysThisNode &&
           (c = CompareKey(key, GetKeyData(p, (BtreeDXNodeLink *)node),
                           klen)) == 1)
      p++;

  *comp = c;

  if (!c)
    while (p > 0 &&
           !CompareKey(key, GetKeyData(p - 1, (BtreeDXNodeLink *)node), klen))
      p--;

  return p;
}

/*!
  \param Tkey
  \param Klen
*/
int BtreeDX::GetLeafFromInteriorNode(const char *Tkey, short Klen) {
  /* This function scans an interior node for a key and returns the   */
  /* correct interior leaf node no                                    */

  short p, c;

  /* if Tkey > any keys in node, return right most key */
  p = CurNode->Leaf.NoOfKeysThisNode - 1;
  if (CompareKey(Tkey, GetKeyData(p, CurNode), Klen) == 1) {
    CurNode->CurKeyNo = CurNode->Leaf.NoOfKeysThisNode;
    return GetLeftNodeNo(CurNode->Leaf.NoOfKeysThisNode, CurNode);
  }

  p = BSearchNode(Tkey, Klen, CurNode, &c);

  CurNode->CurKeyNo = p;
  return GetLeftNodeNo(p, CurNode);
}

/*!
  \param Key
*/
short BtreeDX::FindKey(const char *Key) { return FindKey(Key, strlen(Key)); }

/*!
  \param Tkey
  \param DbfRec
*/

/*!
 */
short BtreeDX::FindKey(void) {
  /* if no paramaters given, use KeyBuf */
  return (FindKey(KeyBuf, HeadNode.KeyLen));
}

/*!
  \param Tkey
  \param Klen
  \param RetrieveSw
*/
short BtreeDX::FindKey(const char *Tkey, short Klen) {
  /* This routine sets the current key to the found key */

  /* if RetrieveSw is true, the method positions the dbf record */
  short rc, i;
  int TempNodeNo;

  if (NodeChain) {
    ReleaseNodeMemory(NodeChain);
    NodeChain = NULL;
  }

  if ((rc = GetHeadNode()) != 0) {
    CurDbfRec = 0L;
    return rc;
  }

  /* load first node */
  if ((rc = GetLeafNode(HeadNode.StartNode, 1)) != 0) {
    CurDbfRec = 0L;
    return rc;
  }

  /* traverse down the tree until it hits a leaf */
  while (GetLeftNodeNo(0, CurNode)) /* while interior node */
  {
    TempNodeNo = GetLeafFromInteriorNode(Tkey, Klen);
    if ((rc = GetLeafNode(TempNodeNo, 1)) != 0) {
      CurDbfRec = 0L;
      return rc;
    }
  }

  /* leaf level */

  i = BSearchNode(Tkey, Klen, CurNode, &rc);
  switch (rc) {
    case 0: { /* found! */
      CurNode->CurKeyNo = i;
      CurDbfRec = GetDbfNo(i, CurNode);
      char *d = GetKeyData(CurNode->CurKeyNo, CurNode);
      if (d) strncpy(KeyFound, d, HeadNode.KeyLen);  // save current key
      return bt_FOUND;
    }
    case 1: /* less than */
      break;

    case 2: /* greater than */
      CurNode->CurKeyNo = i;
      CurDbfRec = GetDbfNo(i, CurNode);
      return bt_NOT_FOUND;
  }

  CurNode->CurKeyNo = i;
  if (i >= CurNode->Leaf.NoOfKeysThisNode) {
    CurDbfRec = 0;
    return bt_EOF;
  }

  CurDbfRec = GetDbfNo(i, CurNode);
  return bt_NOT_FOUND;
}

short BtreeDX::CreateIndex(const char *IxName, int KeyLen, short Unique,
                           short Overlay) {
  short i, NameLen, rc;

  IndexStatus = bt_CLOSED;

  /* Get the index file name and store it in the class */
  NameLen = strlen(IxName) + 1;
  IndexName = IxName;

  /* check if the file already exists */
  if (((indexfp = fopen(IxName, "r")) != NULL) && !Overlay) {
    fclose(indexfp);
    return bt_FILE_EXISTS;
  }

  if (indexfp) fclose(indexfp);

  if ((indexfp = fopen(IxName, "w+b")) == NULL) return bt_open_error;

  /* build the header record */
  memset(&HeadNode, 0x00, sizeof(BtreeDXHeadNode));
  HeadNode.StartNode = 1L;
  HeadNode.TotalNodes = 2L;
  HeadNode.NoOfKeys = 1L;

  if (KeyLen == 0 || KeyLen > 100) /* 100 byte key length limit */
    return bt_INVALID_KEY;
  else {
    HeadNode.KeyType = 0; /* character key */
    HeadNode.KeyLen = KeyLen;
  }

  HeadNode.KeySize = HeadNode.KeyLen + 8;
  while ((HeadNode.KeySize % 4) != 0) HeadNode.KeySize++; /* multiple of 4*/

  HeadNode.KeysPerNode =
      (short)(bt_NDX_NODE_SIZE - (2 * sizeof(int))) / HeadNode.KeySize;

  HeadNode.Unique = Unique;

  freeKeyBuff();

  KeyBuf = (char *)malloc(HeadNode.KeyLen + 1);
  KeyBuf2 = (char *)malloc(HeadNode.KeyLen + 1);
  KeyFound = (char *)malloc(HeadNode.KeyLen + 1);
  memset(KeyBuf, 0, HeadNode.KeyLen + 1);
  memset(KeyBuf2, 0, HeadNode.KeyLen + 1);
  memset(KeyFound, 0, HeadNode.KeyLen + 1);

  if ((rc = PutHeadNode(&HeadNode, indexfp, 0)) != 0) {
    return rc;
  }
  /* write node #1 all 0x00 */
  for (i = 0; i < bt_NDX_NODE_SIZE; i++) {
    if ((fwrite("\x00", 1, 1, indexfp)) != 1) {
      fclose(indexfp);
      return bt_WRITE_ERROR;
    }
  }
  IndexStatus = bt_OPEN;

  return NO_ERROR;
}

/*!
  \param RecNo
  \param n
  \param NodeNo
*/
short BtreeDX::PutLeftNodeNo(short RecNo, BtreeDXNodeLink *n, int NodeNo) {
  /* This routine sets n node's leftnode number */
  BtreeDXLeafNode *temp;
  char *p;
  if (!n) return (bt_INVALID_NODELINK);

  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > HeadNode.KeysPerNode) return (bt_INVALID_KEY);

  p = temp->KeyRecs;
  p += RecNo * (8 + HeadNode.KeyLen);
  PutLong(p, NodeNo);
  return NO_ERROR;
}

/*!
  \param RecNo
  \param n
  \param DbfNo
*/
short BtreeDX::PutDbfNo(short RecNo, BtreeDXNodeLink *n, int DbfNo) {
  /* This routine sets n node's dbf number */

  BtreeDXLeafNode *temp;
  char *p;
  if (!n) return (bt_INVALID_NODELINK);

  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > (HeadNode.KeysPerNode - 1)) return (bt_INVALID_KEY);

  p = temp->KeyRecs + 4;
  p += RecNo * (8 + HeadNode.KeyLen);
  PutLong(p, DbfNo);
  return NO_ERROR;
}
/************************************************************************/

/*!
  \param l
  \param n
*/
short BtreeDX::PutLeafNode(int l, BtreeDXNodeLink *n) {
  if ((fseek(indexfp, l * bt_NDX_NODE_SIZE, SEEK_SET)) != 0) {
    fclose(indexfp);
    return bt_SEEK_ERROR;
  }
  PutLong(Node, n->Leaf.NoOfKeysThisNode);

  if ((fwrite(Node, 4, 1, indexfp)) != 1) {
    fclose(indexfp);
    return bt_WRITE_ERROR;
  }
  if ((fwrite(&n->Leaf.KeyRecs, bt_NDX_NODE_SIZE - 4, 1, indexfp)) != 1) {
    fclose(indexfp);
    return bt_WRITE_ERROR;
  }
  return 0;
}
/************************************************************************/

/*!
  \param Head
  \param f
  \param UpdateOnly
*/
short BtreeDX::PutHeadNode(BtreeDXHeadNode *Head, FILE *f, short UpdateOnly) {
  char buf[4];

  if ((fseek(f, 0L, SEEK_SET)) != 0) {
    fclose(f);
    return (bt_SEEK_ERROR);
  }

  memset(buf, 0x00, 4);
  PutLong(buf, Head->StartNode);
  if ((fwrite(&buf, 4, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  memset(buf, 0x00, 4);
  PutLong(buf, Head->TotalNodes);
  if ((fwrite(&buf, 4, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  memset(buf, 0x00, 4);
  PutLong(buf, Head->NoOfKeys);
  if ((fwrite(&buf, 4, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  if (UpdateOnly) return NO_ERROR;
  memset(buf, 0x00, 2);
  PutLong(buf, Head->KeyLen);
  if ((fwrite(&buf, 2, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  memset(buf, 0x00, 2);
  PutLong(buf, Head->KeysPerNode);
  if ((fwrite(&buf, 2, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  memset(buf, 0x00, 2);
  PutLong(buf, Head->KeyType);
  if ((fwrite(&buf, 2, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  memset(buf, 0x00, 4);
  PutLong(buf, Head->KeySize);
  if ((fwrite(&buf, 4, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  if ((fwrite(&Head->Unknown2, bt_NDX_NODE_SIZE - 22, 1, f)) != 1) {
    fclose(f);
    return bt_WRITE_ERROR;
  }
  return 0;
}
/************************************************************************/

/*!
  \param RecNo
  \param n
*/
short BtreeDX::PutKeyData(short RecNo, BtreeDXNodeLink *n) {
  /* This routine copies the KeyBuf data into BtreeDXNodeLink n */
  BtreeDXLeafNode *temp;
  char *p;
  short i;
  if (!n) return (bt_INVALID_NODELINK);

  temp = &n->Leaf;
  if (RecNo < 0 || RecNo > (HeadNode.KeysPerNode - 1)) return (bt_INVALID_KEY);

  p = temp->KeyRecs + 8;
  p += RecNo * (8 + HeadNode.KeyLen);
  for (i = 0; i < HeadNode.KeyLen; i++) {
    *p = KeyBuf[i];
    p++;
  }
  return NO_ERROR;
}
/************************************************************************/

/*!
  \param n
  \param pos
  \param d
  \param l
  \param w
*/
short BtreeDX::PutKeyInNode(BtreeDXNodeLink *n, short pos, int d, int l,
                            short w) {
  short i;

  /* check the node */
  if (!n) return (bt_INVALID_NODELINK);

  if (pos < 0 || pos > HeadNode.KeysPerNode) return (bt_INVALID_RECORD);

  if (n->Leaf.NoOfKeysThisNode >= HeadNode.KeysPerNode) return (bt_NODE_FULL);

  /* if key movement, save the original key */
  if (pos < n->Leaf.NoOfKeysThisNode)
    memcpy(KeyBuf2, KeyBuf, HeadNode.KeyLen + 1);

  /* if interior node, handle the right most left node no */
  if (GetLeftNodeNo(0, n))
    PutLeftNodeNo(n->Leaf.NoOfKeysThisNode + 1, n,
                  GetLeftNodeNo(n->Leaf.NoOfKeysThisNode, n));

  for (i = n->Leaf.NoOfKeysThisNode; i > pos; i--) {
    memcpy(KeyBuf, GetKeyData(i - 1, n), HeadNode.KeyLen);
    PutKeyData(i, n);
    PutDbfNo(i, n, GetDbfNo(i - 1, n));
    PutLeftNodeNo(i, n, GetLeftNodeNo(i - 1, n));
  }
  /* put new key in node */

  if (pos < n->Leaf.NoOfKeysThisNode)
    memcpy(KeyBuf, KeyBuf2, HeadNode.KeyLen + 1);

  PutKeyData(pos, n);
  PutDbfNo(pos, n, d);
  PutLeftNodeNo(pos, n, l);
  n->Leaf.NoOfKeysThisNode++;
  if (w)
    return PutLeafNode(n->NodeNo, n);
  else
    return 0;
}
/************************************************************************/

/*!
  \param n1
  \param n2
  \param pos
  \param d
*/
short BtreeDX::SplitLeafNode(BtreeDXNodeLink *n1, BtreeDXNodeLink *n2,
                             short pos, int d) {
  short i, j, rc;

  if (!n1 || !n2) return (bt_INVALID_NODELINK);

  if (pos < 0 || pos > HeadNode.KeysPerNode) return (bt_INVALID_NODELINK);

  if (pos < HeadNode.KeysPerNode) /* if it belongs in node */
  {
    /* save the original key */
    memcpy(KeyBuf2, KeyBuf, HeadNode.KeyLen + 1);
    PutKeyData(HeadNode.KeysPerNode, n2);
    for (j = 0, i = pos; i < n1->Leaf.NoOfKeysThisNode; j++, i++) {
      memcpy(KeyBuf, GetKeyData(i, n1), HeadNode.KeyLen);
      PutKeyData(j, n2);
      PutDbfNo(j, n2, GetDbfNo(i, n1));
      n2->Leaf.NoOfKeysThisNode++;
    }

    /* restore original key */
    memcpy(KeyBuf, KeyBuf2, HeadNode.KeyLen + 1);

    /* update original leaf */
    PutKeyData(pos, n1);
    PutDbfNo(pos, n1, d);
    n1->Leaf.NoOfKeysThisNode = pos + 1;
  } else /* put the key in a new node because it doesn't fit in the CurNode*/
  {
    PutKeyData(0, n2);
    PutDbfNo(0, n2, d);
    n2->Leaf.NoOfKeysThisNode++;
  }
  if ((rc = PutLeafNode(n1->NodeNo, n1)) != 0) return rc;
  if ((rc = PutLeafNode(n2->NodeNo, n2)) != 0) return rc;
  return 0;
}
/************************************************************************/

/*!
  \param n1
  \param n2
  \param t
*/
short BtreeDX::SplitINode(BtreeDXNodeLink *n1, BtreeDXNodeLink *n2, int t)
/* parent, tempnode, tempnodeno */
{
  short i, j, rc;
  BtreeDXNodeLink *SaveNodeChain;
  BtreeDXNodeLink *SaveCurNode;

  /* if not at the end of the node shift everthing to the right */
  if (n1->CurKeyNo + 1 < HeadNode.KeysPerNode) /* this clause appears to work */
  {
    if (CurNode->NodeNo == HeadNode.StartNode) cout << "\nHead node ";

    for (j = 0, i = n1->CurKeyNo + 1; i < n1->Leaf.NoOfKeysThisNode; i++, j++) {
      memcpy(KeyBuf, GetKeyData(i, n1), HeadNode.KeyLen);
      PutKeyData(j, n2);
      PutLeftNodeNo(j, n2, GetLeftNodeNo(i, n1));
    }
    PutLeftNodeNo(j, n2, GetLeftNodeNo(i, n1));

    n2->Leaf.NoOfKeysThisNode = n1->Leaf.NoOfKeysThisNode - n1->CurKeyNo - 1;
    n1->Leaf.NoOfKeysThisNode =
        n1->Leaf.NoOfKeysThisNode - n2->Leaf.NoOfKeysThisNode;

    /* attach the new leaf to the original parent */
    SaveNodeChain = NodeChain;
    NodeChain = NULL;
    SaveCurNode = CurNode;
    GetLastKey(CurNode->NodeNo);
    memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
    ReleaseNodeMemory(NodeChain);
    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;
    PutKeyData(n1->CurKeyNo, n1);
    PutLeftNodeNo(n1->CurKeyNo + 1, n1, t);
  } else if (n1->CurKeyNo + 1 == HeadNode.KeysPerNode) {
    SaveNodeChain = NodeChain;
    NodeChain = NULL;
    SaveCurNode = CurNode;
    GetLastKey(t);
    memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
    PutKeyData(0, n2);
    PutLeftNodeNo(0, n2, t);
    PutLeftNodeNo(1, n2, GetLeftNodeNo(n1->Leaf.NoOfKeysThisNode, n1));
    ReleaseNodeMemory(NodeChain);
    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;
    n2->Leaf.NoOfKeysThisNode = 1;
    n1->Leaf.NoOfKeysThisNode--;
  } else /* pos = HeadNode.KeysPerNode */
  {
    SaveNodeChain = NodeChain;
    NodeChain = NULL;
    SaveCurNode = CurNode;
    GetLastKey(CurNode->NodeNo);
    memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
    ReleaseNodeMemory(NodeChain);
    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;

    PutKeyData(0, n2);
    PutLeftNodeNo(0, n2, CurNode->NodeNo);
    PutLeftNodeNo(1, n2, t);
    n2->Leaf.NoOfKeysThisNode = 1;
    n1->Leaf.NoOfKeysThisNode--;
  }
  n2->NodeNo = HeadNode.TotalNodes++;
  if ((rc = PutLeafNode(n1->NodeNo, n1)) != 0) return rc;
  if ((rc = PutLeafNode(n2->NodeNo, n2)) != 0) return rc;
  return 0;
}

/************************************************************************/

/*!
  \param DbfRec
*/
short BtreeDX::AddKey(const char *key, int DbfRec) {
  char *p;
  short i, rc;
  BtreeDXNodeLink *TempNode;
  BtreeDXNodeLink *Tparent;
  int TempNodeNo = 0L; /* new, unattached leaf node no */
  BtreeDXNodeLink *SaveNodeChain;
  BtreeDXNodeLink *SaveCurNode;

  if (!key) return bt_NOT_FOUND;

  memset(KeyBuf, 0x00, HeadNode.KeyLen + 1);
  strncpy(KeyBuf, key,
          std::min<int>(HeadNode.KeyLen, strlen(key)));  // KeyBuf=key

  rc = FindKey(KeyBuf, HeadNode.KeyLen); /* find node key belongs in */
  if (rc == bt_FOUND && HeadNode.Unique) return (bt_KEY_NOT_UNIQUE);

  if (CurNode->Leaf.NoOfKeysThisNode > 0 && rc == bt_FOUND) {
    rc = 0;
    while (rc == 0) {
      if ((p = GetKeyData(CurNode->CurKeyNo, CurNode)) == NULL)
        rc = -1;
      else {
        rc = CompareKey(KeyBuf, p, HeadNode.KeyLen);
        if (rc == 0 && DbfRec >= GetDbfNo(CurNode->CurKeyNo, CurNode)) {
          if ((rc = GetNextKey()) == bt_EOF) {
            if ((rc = GetLastKey(0)) != NO_ERROR) return rc;
            CurNode->CurKeyNo++;
          }
        } else
          rc = -1;
      }
    }
  }

  /* update header node */
  HeadNode.NoOfKeys++;
  /************************************************/
  /* section A - if room in node, add key to node */
  /************************************************/

  if (CurNode->Leaf.NoOfKeysThisNode < HeadNode.KeysPerNode) {
    if ((rc = PutKeyInNode(CurNode, CurNode->CurKeyNo, DbfRec, 0L, 1)) != 0) {
      return rc;
    }
    if ((rc = PutHeadNode(&HeadNode, indexfp, 1)) != 0) {
      return rc;
    }
    return NO_ERROR;
  }

  /* section B - split leaf node if full and put key in correct position */

  TempNode = GetNodeMemory();
  TempNode->NodeNo = HeadNode.TotalNodes++;

  rc = SplitLeafNode(CurNode, TempNode, CurNode->CurKeyNo, DbfRec);
  if (rc) {
    return rc;
  }

  TempNodeNo = TempNode->NodeNo;
  ReleaseNodeMemory(TempNode);

  /*****************************************************/
  /* section C go up tree splitting nodes as necessary */
  /*****************************************************/
  Tparent = CurNode->PrevNode;

  while (Tparent && Tparent->Leaf.NoOfKeysThisNode >= HeadNode.KeysPerNode) {
    TempNode = GetNodeMemory();
    if (!TempNode) {
      return bt_memory_error;
    }

    rc = SplitINode(Tparent, TempNode, TempNodeNo);
    if (rc) return rc;

    TempNodeNo = TempNode->NodeNo;
    ReleaseNodeMemory(TempNode);
    ReleaseNodeMemory(CurNode);
    CurNode = Tparent;
    CurNode->NextNode = NULL;
    Tparent = CurNode->PrevNode;
  }

  /************************************************************/
  /* Section D  if CurNode is split root, create new root     */
  /************************************************************/

  /* at this point
      CurNode = The node that was just split
      TempNodeNo = The new node split off from CurNode */

  if (CurNode->NodeNo == HeadNode.StartNode) {
    TempNode = GetNodeMemory();
    if (!TempNode) {
      return bt_memory_error;
    }

    SaveNodeChain = NodeChain;
    NodeChain = NULL;
    SaveCurNode = CurNode;
    GetLastKey(CurNode->NodeNo);
    memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);

    ReleaseNodeMemory(NodeChain);
    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;

    PutKeyData(0, TempNode);
    PutLeftNodeNo(0, TempNode, CurNode->NodeNo);
    PutLeftNodeNo(1, TempNode, TempNodeNo);
    TempNode->NodeNo = HeadNode.TotalNodes++;
    TempNode->Leaf.NoOfKeysThisNode++;
    HeadNode.StartNode = TempNode->NodeNo;
    rc = PutLeafNode(TempNode->NodeNo, TempNode);
    if (rc) return rc;
    rc = PutHeadNode(&HeadNode, indexfp, 1);
    if (rc) return rc;
    ReleaseNodeMemory(TempNode);
    return NO_ERROR;
  }
  /**********************************/
  /* Section E  make room in parent */
  /**********************************/
  for (i = Tparent->Leaf.NoOfKeysThisNode; i > Tparent->CurKeyNo; i--) {
    memcpy(KeyBuf, GetKeyData(i - 1, Tparent), HeadNode.KeyLen);
    PutKeyData(i, Tparent);
    PutLeftNodeNo(i + 1, Tparent, GetLeftNodeNo(i, Tparent));
  }

  /* put key in parent */

  SaveNodeChain = NodeChain;
  NodeChain = NULL;
  SaveCurNode = CurNode;
  GetLastKey(CurNode->NodeNo);

  memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);

  ReleaseNodeMemory(NodeChain);
  NodeChain = SaveNodeChain;
  CurNode = SaveCurNode;

  PutKeyData(i, Tparent);
  PutLeftNodeNo(i + 1, Tparent, TempNodeNo);
  Tparent->Leaf.NoOfKeysThisNode++;
  rc = PutLeafNode(Tparent->NodeNo, Tparent);
  if (rc) return rc;
  rc = PutHeadNode(&HeadNode, indexfp, 1);
  if (rc) return rc;

  return NO_ERROR;
}

/*!
  \param pos
  \param n
*/
short BtreeDX::RemoveKeyFromNode(short pos, BtreeDXNodeLink *n) {
  short i;

  /* check the node */
  if (!n) return (bt_INVALID_NODELINK);

  if (pos < 0 || pos > HeadNode.KeysPerNode) return (bt_INVALID_KEY);

  for (i = pos; i < n->Leaf.NoOfKeysThisNode - 1; i++) {
    memcpy(KeyBuf, GetKeyData(i + 1, n), HeadNode.KeyLen);

    PutKeyData(i, n);
    PutDbfNo(i, n, GetDbfNo(i + 1, n));
    PutLeftNodeNo(i, n, GetLeftNodeNo(i + 1, n));
  }
  PutLeftNodeNo(i, n, GetLeftNodeNo(i + 1, n));
  n->Leaf.NoOfKeysThisNode--;
  /* if last key was deleted, decrement CurKeyNo */
  if (n->CurKeyNo > n->Leaf.NoOfKeysThisNode) n->CurKeyNo--;
  return PutLeafNode(n->NodeNo, n);
}

/*!
  \param n
*/
short BtreeDX::UpdateParentKey(BtreeDXNodeLink *n) {
  /* this routine goes backwards thru the node chain looking for a parent
     node to update */

  BtreeDXNodeLink *TempNode;

  if (!n) return (bt_INVALID_NODELINK);

  if (!GetDbfNo(0, n)) return (bt_NOT_LEAFNODE);

  TempNode = n->PrevNode;
  while (TempNode) {
    if (TempNode->CurKeyNo < TempNode->Leaf.NoOfKeysThisNode) {
      memcpy(KeyBuf, GetKeyData(n->Leaf.NoOfKeysThisNode - 1, n),
             HeadNode.KeyLen);
      PutKeyData(TempNode->CurKeyNo, TempNode);
      return PutLeafNode(TempNode->NodeNo, TempNode);
    }
    TempNode = TempNode->PrevNode;
  }
  return NO_ERROR;
}

/*!
  \param n
*/
/* This routine queues up a list of nodes which have been emptied      */
void BtreeDX::UpdateDeleteList(BtreeDXNodeLink *n) {
  n->NextNode = DeleteChain;
  DeleteChain = n;
}

/*!
 */
/* Delete nodes from the node list - for now we leave the empty nodes  */
/* dangling in the file. Eventually we will remove nodes from the file */

void BtreeDX::ProcessDeleteList(void) {
  if (DeleteChain) {
    ReleaseNodeMemory(DeleteChain);
    DeleteChain = NULL;
  }
}

/*!
  \param n
*/
BtreeDX::BtreeDXNodeLink *BtreeDX::LeftSiblingHasSpace(BtreeDXNodeLink *n) {
  BtreeDXNodeLink *TempNode;
  BtreeDXNodeLink *SaveCurNode;

  /* returns a Nodelink to BtreeDXNodeLink n's left sibling if it has space */

  /* if left most node in parent return NULL */
  if (n->PrevNode->CurKeyNo == 0) return NULL;

  SaveCurNode = CurNode;
  GetLeafNode(GetLeftNodeNo(n->PrevNode->CurKeyNo - 1, n->PrevNode), 2);
  if (CurNode->Leaf.NoOfKeysThisNode < HeadNode.KeysPerNode) {
    TempNode = CurNode;
    CurNode = SaveCurNode;
    TempNode->PrevNode = n->PrevNode;
    return TempNode;
  } else /* node is already full */
  {
    ReleaseNodeMemory(CurNode);
    CurNode = SaveCurNode;
    return NULL;
  }
}

/*!
  \param n
*/
BtreeDX::BtreeDXNodeLink *BtreeDX::RightSiblingHasSpace(BtreeDXNodeLink *n) {
  /* returns a Nodelink to BtreeDXNodeLink n's right sibling if it has space */

  BtreeDXNodeLink *TempNode;
  BtreeDXNodeLink *SaveCurNode;

  /* if left most node in parent return NULL */
  if (n->PrevNode->CurKeyNo >= n->PrevNode->Leaf.NoOfKeysThisNode) return NULL;

  SaveCurNode = CurNode;
  /* point curnode to right sib*/
  GetLeafNode(GetLeftNodeNo(n->PrevNode->CurKeyNo + 1, n->PrevNode), 2);

  if (CurNode->Leaf.NoOfKeysThisNode < HeadNode.KeysPerNode) {
    TempNode = CurNode;
    CurNode = SaveCurNode;
    TempNode->PrevNode = n->PrevNode;
    return TempNode;
  } else /* node is already full */
  {
    ReleaseNodeMemory(CurNode);
    CurNode = SaveCurNode;
    return NULL;
  }
}
/*************************************************************************/

/*!
  \param n
  \param Right
*/
short BtreeDX::MoveToRightNode(BtreeDXNodeLink *n, BtreeDXNodeLink *Right) {
  short j;
  BtreeDXNodeLink *TempNode;
  BtreeDXNodeLink *SaveCurNode;
  BtreeDXNodeLink *SaveNodeChain;

  if (n->CurKeyNo == 0) {
    j = 1;
    SaveNodeChain = NodeChain;
    SaveCurNode = CurNode;
    NodeChain = NULL;
    GetLastKey(n->NodeNo);
    memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
    ReleaseNodeMemory(NodeChain);
    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;
  } else {
    j = 0;
    memcpy(KeyBuf, GetKeyData(j, n), HeadNode.KeyLen);
  }
  PutKeyInNode(Right, 0, 0L, GetLeftNodeNo(j, n), 1);
  ReleaseNodeMemory(Right);
  TempNode = n;
  CurNode = n->PrevNode;
  n = n->PrevNode;
  n->NextNode = NULL;
  UpdateDeleteList(TempNode);
  DeleteSibling(n);
  return NO_ERROR;
}

/*!
  \param n
  \param Left
*/
short BtreeDX::MoveToLeftNode(BtreeDXNodeLink *n, BtreeDXNodeLink *Left) {
  short j, rc;
  BtreeDXNodeLink *SaveNodeChain;
  BtreeDXNodeLink *TempNode;

  if (n->CurKeyNo == 0)
    j = 1;
  else
    j = 0;

  /* save the original node chain */
  SaveNodeChain = NodeChain;
  NodeChain = NULL;

  /* determine new right most key for left node */
  GetLastKey(Left->NodeNo);
  memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
  ReleaseNodeMemory(NodeChain);
  NodeChain = NULL; /* for next GetLastKey */
  PutKeyData(Left->Leaf.NoOfKeysThisNode, Left);
  PutLeftNodeNo(Left->Leaf.NoOfKeysThisNode + 1, Left, GetLeftNodeNo(j, n));
  Left->Leaf.NoOfKeysThisNode++;
  Left->CurKeyNo = Left->Leaf.NoOfKeysThisNode;
  if ((rc = PutLeafNode(Left->NodeNo, Left)) != 0) return rc;

  n->PrevNode->NextNode = NULL;
  UpdateDeleteList(n);

  /* get the new right most key for left to update parents */
  GetLastKey(Left->NodeNo);

  /* assemble the chain */
  TempNode = Left->PrevNode;
  TempNode->CurKeyNo--;
  NodeChain->PrevNode = Left->PrevNode;
  UpdateParentKey(CurNode);
  ReleaseNodeMemory(NodeChain);
  ReleaseNodeMemory(Left);
  CurNode = TempNode;
  NodeChain = SaveNodeChain;
  TempNode->CurKeyNo++;
  DeleteSibling(TempNode);
  return NO_ERROR;
}

/*!
  \param n
*/
short BtreeDX::DeleteSibling(BtreeDXNodeLink *n) {
  BtreeDXNodeLink *Left;
  BtreeDXNodeLink *Right;
  BtreeDXNodeLink *SaveCurNode;
  BtreeDXNodeLink *SaveNodeChain;
  BtreeDXNodeLink *TempNode;
  short rc;

  /* this routine deletes sibling CurRecNo out of xbNodeLink n */
  if (n->Leaf.NoOfKeysThisNode > 1) {
    RemoveKeyFromNode(n->CurKeyNo, n);
    if (n->CurKeyNo == n->Leaf.NoOfKeysThisNode) {
      SaveNodeChain = NodeChain;
      SaveCurNode = CurNode;
      NodeChain = NULL;
      GetLastKey(n->NodeNo);
      /* assemble the node chain */
      TempNode = NodeChain->NextNode;
      NodeChain->NextNode = NULL;
      ReleaseNodeMemory(NodeChain);
      TempNode->PrevNode = n;
      UpdateParentKey(CurNode);
      /* take it back apart */
      ReleaseNodeMemory(TempNode);
      NodeChain = SaveNodeChain;
      CurNode = SaveCurNode;
    }
  } else if (n->NodeNo == HeadNode.StartNode) {
    /* get here if root node and only one child remains */
    /* make remaining node the new root */
    if (n->CurKeyNo == 0)
      HeadNode.StartNode = GetLeftNodeNo(1, n);
    else
      HeadNode.StartNode = GetLeftNodeNo(0, n);
    UpdateDeleteList(n);
    NodeChain = NULL;
    CurNode = NULL;
  } else if ((Left = LeftSiblingHasSpace(n)) != NULL) {
    return MoveToLeftNode(n, Left);
  } else if ((Right = RightSiblingHasSpace(n)) != NULL) {
    return MoveToRightNode(n, Right);
  }
  /* else if left sibling exists */
  else if (n->PrevNode->CurKeyNo > 0) {
    /* move right branch from left sibling to this node */
    SaveCurNode = CurNode;
    SaveNodeChain = NodeChain;
    NodeChain = NULL;
    GetLeafNode(GetLeftNodeNo(n->PrevNode->CurKeyNo - 1, n->PrevNode), 2);
    Left = CurNode;
    Left->PrevNode = SaveCurNode->PrevNode;
    GetLastKey(Left->NodeNo);

    strncpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
    if (n->CurKeyNo == 1) PutLeftNodeNo(1, n, GetLeftNodeNo(0, n));
    PutKeyData(0, n);
    PutLeftNodeNo(0, n, GetLeftNodeNo(Left->Leaf.NoOfKeysThisNode, Left));
    if ((rc = PutLeafNode(n->NodeNo, n)) != NO_ERROR) return rc;
    SaveCurNode = n->PrevNode;
    SaveCurNode->NextNode = NULL;
    ReleaseNodeMemory(n);
    Left->Leaf.NoOfKeysThisNode--;
    if ((rc = PutLeafNode(Left->NodeNo, Left)) != NO_ERROR) return rc;
    /* rebuild left side of tree */
    GetLastKey(Left->NodeNo);
    NodeChain->PrevNode = SaveCurNode;
    SaveCurNode->CurKeyNo--;
    UpdateParentKey(CurNode);
    ReleaseNodeMemory(NodeChain);
    ReleaseNodeMemory(Left);
    CurNode = SaveCurNode;
    NodeChain = SaveNodeChain;
  }
  /* right sibling must exist */
  else if (n->PrevNode->CurKeyNo <= n->PrevNode->Leaf.NoOfKeysThisNode) {
    /* move left branch from left sibling to this node */
    SaveCurNode = CurNode;
    SaveNodeChain = NodeChain;
    NodeChain = NULL;

    /* move the left node number one to the left if necessary */
    if (n->CurKeyNo == 0) {
      PutLeftNodeNo(0, n, GetLeftNodeNo(1, n));
      GetLastKey(GetLeftNodeNo(0, n));
      memcpy(KeyBuf, GetKeyData(CurNode->CurKeyNo, CurNode), HeadNode.KeyLen);
      PutKeyData(0, n);
      ReleaseNodeMemory(NodeChain);
      NodeChain = NULL;
    }
    GetLeafNode(GetLeftNodeNo(n->PrevNode->CurKeyNo + 1, n->PrevNode), 2);

    /* put leftmost node number from right node in this node */
    PutLeftNodeNo(1, n, GetLeftNodeNo(0, CurNode));
    if ((rc = PutLeafNode(n->NodeNo, n)) != NO_ERROR) return rc;

    /* remove the key from the right node */
    RemoveKeyFromNode(0, CurNode);
    if ((rc = PutLeafNode(CurNode->NodeNo, CurNode)) != NO_ERROR) return rc;
    ReleaseNodeMemory(CurNode);

    /* update new parent key value */
    GetLastKey(n->NodeNo);
    NodeChain->PrevNode = n->PrevNode;
    UpdateParentKey(CurNode);
    ReleaseNodeMemory(NodeChain);

    NodeChain = SaveNodeChain;
    CurNode = SaveCurNode;
  } else {
    /* this should never be true-but could be if 100 byte limit is ignored*/
    cout << "Fatal index error\n";
    exit(0);
  }
  return NO_ERROR;
}

short BtreeDX::DeleteKey(const char *key, bool exact) {
  BtreeDXNodeLink *TempNode;
  short rc;

  copyKey(key);  // KeyBuf = key

  if ((rc = FindKey(KeyBuf)) != bt_FOUND) return rc;
  strncpy(KeyFound, GetKeyData(CurNode->CurKeyNo, CurNode),
          HeadNode.KeyLen);  // save current key
  if (exact && strcmp(key, KeyFound) != 0)
    return bt_NOT_FOUND;  // only delete w/exact match

  /* found the record to delete at this point */
  HeadNode.NoOfKeys--;

  /* delete the key from the node                                    */
  if ((rc = RemoveKeyFromNode(CurNode->CurKeyNo, CurNode)) != 0) return rc;

  /* if root node, we are done */
  if (!(CurNode->NodeNo == HeadNode.StartNode)) {
    /* if leaf node now empty */
    if (CurNode->Leaf.NoOfKeysThisNode == 0) {
      TempNode = CurNode->PrevNode;
      TempNode->NextNode = NULL;
      UpdateDeleteList(CurNode);
      CurNode = TempNode;
      DeleteSibling(CurNode);
      ProcessDeleteList();
    }

    /* if last key of leaf updated, update key in parent node */
    /* this logic updates the correct parent key              */

    else if (CurNode->CurKeyNo == CurNode->Leaf.NoOfKeysThisNode) {
      UpdateParentKey(CurNode);
    }
  }

  if (CurNode) {
    CurDbfRec = GetDbfNo(CurNode->CurKeyNo, CurNode);
    char *d = GetKeyData(CurNode->CurKeyNo, CurNode);
    if (d) strncpy(KeyFound, d, HeadNode.KeyLen);  // save current key
  } else
    CurDbfRec = 0;

  if ((rc = PutHeadNode(&HeadNode, indexfp, 1)) != 0) return rc;
  return NO_ERROR;
}
#ifdef XBASE_DEBUG
short BtreeDX::CheckIndexIntegrity(const short option) {
  /* if option = 1, print out some stats */

  short rc;
  int ctr = 1L;

  rc = dbf->GetRecord(ctr);
  while (ctr < dbf->NoOfRecords()) {
    ctr++;
    if (option) cout << "\nChecking Record " << ctr;
    if (!dbf->RecordDeleted()) {
      CreateKey(0, 0);
      rc = FindKey(KeyBuf, dbf->GetCurRecNo());
      if (rc != bt_FOUND) {
        if (option) {
          cout << "\nRecord number " << dbf->GetCurRecNo() << " Not Found\n";
          cout << "Key = " << KeyBuf << "\n";
        }
        return rc;
      }
    }
    if ((rc = dbf->GetRecord(ctr)) != NO_ERROR) return rc;
  }
  if (option) {
    cout << "\nTotal records checked = " << ctr << "\n";
    cout << "Exiting with rc = " << rc << "\n";
  }

  return NO_ERROR;
}
#endif

void BtreeDX::SetNodeSize(short size) {
  if (size >= bt_DEFAULT_NDX_NODE_SIZE) {
    if (size % bt_NDX_NODE_MULTIPLE)
      NodeSize = ((size + bt_NDX_NODE_MULTIPLE) / bt_NDX_NODE_MULTIPLE) *
                 bt_NDX_NODE_MULTIPLE;
    else
      NodeSize = size;
  } else
    NodeSize = bt_DEFAULT_NDX_NODE_SIZE;
}
