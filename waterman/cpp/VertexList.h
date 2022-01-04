/**
 * Maintains a double-linked list of vertices for use by QuickHull3D
 */

#pragma once

#include <stdio.h>

class Vertex;

class VertexList
{

#define null NULL

  Vertex *head = null;
  Vertex *tail = null;

  /**
   * Clears this list.
   */
public:
  VertexList();

  void clear();

  /**
   * Adds a vertex to the end of this list.
   */
  void add(Vertex *vtx);
  /**
   * Adds a chain of vertices to the end of this list.
   */
  void addAll(Vertex *vtx);

  /**
   * Deletes a vertex from this list.
   */
  void del(Vertex *vtx);

  /**
   * Deletes a chain of vertices from this list.
   */
  void del(Vertex *vtx1, Vertex *vtx2);

  /**
   * Inserts a vertex into this list before another
   * specificed vertex.
   */
  void insertBefore(Vertex *vtx, Vertex *next);

  /**
   * Returns the first element in this list.
   */
  Vertex *first();

  /**
   * Returns true if this list is empty.
   */
  bool isEmpty();
};
