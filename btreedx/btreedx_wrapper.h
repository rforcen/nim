// btreedx nim wrapper
#include "btreedx.h"

extern "C"
{
  void *newBtreeDX()
  {
    return new BtreeDX();
  }
  bool open(void *bt, char *filename)
  {
    return ((BtreeDX *)bt)->open(string(filename));
  }
  bool close(void *bt)
  {
    return ((BtreeDX *)bt)->close();
  }
  bool create(void *bt, char *filename, int keylen, int Unique, int Overlay)
  {
    return ((BtreeDX *)bt)->create(string(filename), keylen, Unique, Overlay);
  }
  bool add(void *bt, char *key, int recno)
  {
    return ((BtreeDX *)bt)->add(key, recno);
  }
  bool find(void *bt, const char *key, int &recNo)
  {
    return ((BtreeDX *)bt)->find(key, recNo);
  }
  bool findEQ(void *bt, const char *key, int &recNo)
  {
    return ((BtreeDX *)bt)->findEQ(key, recNo);
  }
  bool next(void *bt, char *key, int &recNo)
  {
    return ((BtreeDX *)bt)->next(key, recNo);
  }
  bool eraseEQ(void *bt, const char *key)
  {
    return ((BtreeDX *)bt)->eraseEQ(key);
  }
  bool eraseMatch(void *bt, const char *key)
  {
    return ((BtreeDX *)bt)->eraseMatch(key);
  }
}
