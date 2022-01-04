/**
 * Maintains a single-linked list of faces for use by QuickHull3D
 */

#pragma once

#include <stdio.h>

class Face;

class FaceList
{
#define null NULL

  Face *head = null;
  Face *tail = null;

public:
  FaceList();

  void clear();
  void add(Face *vtx);
  Face *first();
  bool isEmpty();
};
