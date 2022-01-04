/**
 * Represents vertices of the hull, as well as the points from
 * which it is formed.
 *
 */

#pragma once

class Face;
class Point3d;

class Vertex
{
public:
  /**
   * Spatial point associated with this vertex.
   */
  Point3d *pnt = null;

  /**
   * Back index into an array.
   */
  int index;

  /**
   * List forward link.
   */
  Vertex *prev = null;

  /**
   * List backward link.
   */
  Vertex *next = null;

  /**
   * Current face that this vertex is outside of.
   */
  Face *face = null;

  /**
   * Constructs a vertex and sets its coordinates to 0.
   */
public:
  Vertex();
  ~Vertex();

  /**
   * Constructs a vertex with the specified coordinates
   * and index.
   */
  Vertex(double x, double y, double z, int idx);
};
