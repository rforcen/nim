/*
 * Represents the half-edges that surround each
 * face in a counter-clockwise direction.
 */
#pragma once

#include <string>
using std::string;

class Face;
class Vertex;

class HalfEdge
{
#define null NULL

public:
  /**
   * The vertex associated with the head of this half-edge.
   */
  Vertex *vertex = null;

  /**
   * Triangular face associated with this half-edge.
   */
  Face *face = null;

  /**
   * Next half-edge in the triangle.
   */
  HalfEdge *next = null;

  /**
   * Previous half-edge in the triangle.
   */
  HalfEdge *prev = null;

  /**
   * Half-edge associated with the opposite triangle
   * adjacent to this edge.
   */
  HalfEdge *opposite = null;

  /**
   * Constructs a HalfEdge with head vertex <code>v</code> and
   * left-hand triangular face <code>f</code>.
   *
   * @param v head vertex
   * @param f left-hand triangular face
   */

public:
  HalfEdge(Vertex *v, Face *f);
  HalfEdge();
  void setNext(HalfEdge *edge);
  HalfEdge *getNext();
  void setPrev(HalfEdge *edge);
  HalfEdge *getPrev();
  Face *getFace();
  HalfEdge *getOpposite();
  void setOpposite(HalfEdge *edge);
  Vertex *head();
  Vertex *tail();
  Face *oppositeFace();
  string getVertexString();
  double length();
  double lengthSquared();
};
