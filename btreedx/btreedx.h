#ifndef BTREEDX_H
#define BTREEDX_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <memory.h>

using std::string;
using std::cout;

// BtreeDX class

class BtreeDX {
// Define the following to use inline versions of the respective methods.
#define bt_INLINE_COMPAREKEY
#define bt_INLINE_GETDBFNO

#define bt_NDX_NODE_BASESIZE 24  // size of base header data

#define bt_DEFAULT_NDX_NODE_SIZE 512
#define bt_MAX_NDX_NODE_SIZE 4096
#define bt_NDX_NODE_SIZE NodeSize
#define bt_NDX_NODE_MULTIPLE 512

  // BtreeDXHeadnode struct
  struct BtreeDXHeadNode { /* ndx header on disk */
    int StartNode;         /* header node is node 0 */
    int TotalNodes;        /* includes header node */
    int NoOfKeys;          /* actual count + 1 */
    short KeyLen;          /* length of key data */
    short KeysPerNode;
    short KeyType; /* 00 = Char, 01 = Numeric */
    int KeySize;   /* key len + 8 bytes */
    char Unknown2;
    char Unique;
    char KeyExpression[bt_MAX_NDX_NODE_SIZE - 24];
  };
  struct BtreeDXLeafNode { /* ndx node on disk */
    int NoOfKeysThisNode;
    char KeyRecs[bt_MAX_NDX_NODE_SIZE - 4];
  };

  // BtreeDXNodeLink struct
  struct BtreeDXNodeLink { /* ndx node memory */
    BtreeDXNodeLink *PrevNode;
    BtreeDXNodeLink *NextNode;
    int CurKeyNo; /* 0 - KeysPerNode-1 */
    int NodeNo;
    struct BtreeDXLeafNode Leaf;
  };

 public:
  enum {
    NO_ERROR = 0,
    bt_FOUND = 1,
    bt_NOT_FOUND = 2,
    bt_OPEN = 3,

    bt_memory_error = -100,
    bt_open_error = -101,

    bt_NOT_OPEN = -102,
    bt_SEEK_ERROR = -103,
    bt_READ_ERROR = -104,
    bt_INVALID_NODE_NO = -105,
    bt_eof_error = -106,
    bt_EOF = -107,
    bt_CLOSED = -108,
    bt_FILE_EXISTS = -109,
    bt_INVALID_KEY = -110,
    bt_WRITE_ERROR = -111,
    bt_INVALID_NODELINK = -112,
    bt_INVALID_RECORD = -113,
    bt_NODE_FULL = -114,
    bt_KEY_NOT_UNIQUE = -115,
    bt_NOT_LEAFNODE = -116
  };

  BtreeDX();
  ~BtreeDX() { CloseIndex(); }

  bool open(string fileName) { return OpenIndex(fileName.c_str()) == NO_ERROR; }
  bool close() { return CloseIndex() == NO_ERROR; }
  bool create(string fileName, int keylen, short Unique = 1,
              short OverLay = 1) {
    return CreateIndex(fileName.c_str(), keylen, Unique, OverLay) == NO_ERROR;
  }
  bool add(const char *key, const int recNo) {
    return AddKey(key, recNo) == NO_ERROR;
  }
  bool findEQ(const char *key, int &recNo) {  // exact match
    auto rv = FindKey(key);
    auto res = (rv == bt_FOUND && strcpy(KeyFound, key) == 0);
    if (res) recNo = getRecNo();
    return res;
  }
  bool find(const char *key, int &recNo) {  // first match
    auto rv = FindKey(key);
    auto res = (rv == bt_FOUND);
    if (res) recNo = getRecNo();
    return res;
  }
  bool next(char *key, int &recNo) {
    auto res = (GetNextKey() == NO_ERROR);
    if (res) {
      recNo = getRecNo();
      strcpy(key, KeyFound);
    }
    return res;
  }
  bool eraseEQ(const char *key) {  // exact match key erase
    return DeleteKey(key) == NO_ERROR;
  }
  int eraseMatch(
      const char *key) {  //  erase ALL partial match -> return # keys deleted
    int nkd = 0;
    while (DeleteKey(key, false) == NO_ERROR) {
      nkd++;
    }
    return nkd;
  }
  short find(const char *Tkey, char *keyFound,
             int &recNo) {  // use a char keyFound[keylen+1]
    auto rv = FindKey(Tkey) == bt_FOUND;
    if (rv) {
      strncpy(keyFound, getKey(), HeadNode.KeyLen);
      keyFound[HeadNode.KeyLen] = 0;
      recNo = getRecNo();
    }
    return rv;
  }
  const char *getFileName() { return IndexName.c_str(); }
  char *getKey() { return KeyFound; }
  int getRecNo() { return CurDbfRec; }  // after key search
  int getNnodes() { return GetTotalNodes(); }
  bool match(const char *key) {  // key vs. KeyFound
    return (strncmp(key, KeyFound, strlen(key)) == 0);
  }

 private:
  short OpenIndex(const char *FileName);
  short CloseIndex();
  short CreateIndex(const char *IxName, int KeyLen, short Unique = 1,
                    short OverLay = 1);
  int GetTotalNodes();
  int GetCurDbfRec() { return CurDbfRec; }

  short AddKey(const char *key, int);
  short UniqueIndex() { return HeadNode.Unique; }
  short DeleteKey(const char *key, bool exact = true);
  short FindKey(const char *Key);
  short FindKey();

  void DumpHdrNode();
  void DumpNodeRec(int NodeNo);
  void DumpNodeChain();
  short CheckIndexIntegrity(const short Option);
  short KeyExists(const char *Key) { return FindKey(Key, strlen(Key)); }

  virtual void SetNodeSize(short size);

  int GetLong(const char *p) { return (int)(*(int *)p); }
  short GetShort(const char *p) { return (short)(*(short *)p); }
  void PutLong(const char *p, int i) { *((int *)p) = i; }
  void copyKey(const char *key) {
    memset(KeyBuf, 0x00, HeadNode.KeyLen + 1);
    strncpy(KeyBuf, key,
            std::min<int>(HeadNode.KeyLen, strlen(key)));  // KeyBuf=key
  }
  void freeKeyBuff() {
    if (KeyBuf) {
      free(KeyBuf);
      KeyBuf = NULL;
    }
    if (KeyBuf2) {
      free(KeyBuf2);
      KeyBuf2 = NULL;
    }
    if (KeyFound) {
      delete[] KeyFound;
      KeyFound = NULL;
    }
  }

  BtreeDX *index;
  FILE *indexfp = 0;
  int IndexStatus; /* 0 = closed, 1 = open */
  short NodeSize;

  short GetFirstKey();
  short GetNextKey();

 protected:
  BtreeDXHeadNode HeadNode;
  BtreeDXLeafNode LeafNode;
  int xbNodeLinkCtr;
  int ReusedxbNodeLinks;
  string IndexName;
  char Node[bt_MAX_NDX_NODE_SIZE];

  BtreeDXNodeLink *NodeChain;      // pointer to node chain of index nodes
  BtreeDXNodeLink *FreeNodeChain;  // pointer to chain of free index nodes
  BtreeDXNodeLink *CurNode;        // pointer to current node
  BtreeDXNodeLink *DeleteChain;    // pointer to chain to delete
  BtreeDXNodeLink *CloneChain;     // pointer to node chain copy (add dup)
  int CurDbfRec;                   // current Dbf record number
  char *KeyBuf = 0;                // work area key buffer
  char *KeyBuf2 = 0;               // work area key buffer
  char *KeyFound = 0;              // last key found

  /* private functions */
  int GetLeftNodeNo(short, BtreeDXNodeLink *);
  inline short CompareKey(const char *Key1, const char *Key2, short Klen) {
    int c;

    if (!(Key1 && Key2)) return -1;

    if (Klen > HeadNode.KeyLen) Klen = HeadNode.KeyLen;

    if (HeadNode.KeyType == 0) {
      c = memcmp(Key1, Key2, Klen);
      if (c < 0)
        return 2;
      else if (c > 0)
        return 1;
      return 0;
    }
    return 0;
  }
  inline int GetDbfNo(short RecNo, BtreeDXNodeLink *n) {
    BtreeDXLeafNode *temp;
    char *p;
    if (!n) return 0L;
    temp = &n->Leaf;
    if (RecNo < 0 || RecNo > (temp->NoOfKeysThisNode - 1)) return 0L;
    p = temp->KeyRecs + 4;
    p += RecNo * (8 + HeadNode.KeyLen);
    return (int)(*((int *)p));
  }

  char *GetKeyData(short, BtreeDXNodeLink *);
  short GetKeysPerNode();
  short GetHeadNode();
  short GetLeafNode(int, short);
  BtreeDXNodeLink *GetNodeMemory();
  void ReleaseNodeMemory(BtreeDXNodeLink *);
  short BSearchNode(const char *key, short klen, const BtreeDXNodeLink *node,
                    short *comp);
  int GetLeafFromInteriorNode(const char *Tkey, short Klen);
  short PutKeyData(short, BtreeDXNodeLink *);
  short PutLeftNodeNo(short, BtreeDXNodeLink *, int);
  short PutLeafNode(int, BtreeDXNodeLink *);
  short PutHeadNode(BtreeDXHeadNode *, FILE *, short);
  short PutDbfNo(short, BtreeDXNodeLink *, int);
  short PutKeyInNode(BtreeDXNodeLink *, short, int, int, short);
  short SplitLeafNode(BtreeDXNodeLink *, BtreeDXNodeLink *, short, int);
  short SplitINode(BtreeDXNodeLink *, BtreeDXNodeLink *, int);
  short AddToIxList();
  short RemoveFromIxList();
  short RemoveKeyFromNode(short, BtreeDXNodeLink *);
  short FindKey(const char *Tkey, short Klen);

  short UpdateParentKey(BtreeDXNodeLink *);

  short GetLastKey(int);
  short GetPrevKey();
  void UpdateDeleteList(BtreeDXNodeLink *);
  void ProcessDeleteList();
  BtreeDXNodeLink *LeftSiblingHasSpace(BtreeDXNodeLink *);
  BtreeDXNodeLink *RightSiblingHasSpace(BtreeDXNodeLink *);
  short DeleteSibling(BtreeDXNodeLink *);
  short MoveToLeftNode(BtreeDXNodeLink *, BtreeDXNodeLink *);
  short MoveToRightNode(BtreeDXNodeLink *, BtreeDXNodeLink *);

  short CloneNodeChain();
  short UncloneNodeChain();
};

#endif  // BTREEDX_H
