
/**
 * Computes the convex hull of a set of three dimensional points.
 *
 * <p>The algorithm is a three dimensional implementation of Quickhull, as
 * described in Barber, Dobkin, and Huhdanpaa, <a
 * href=http://citeseer.ist.psu.edu/barber96quickhull.html> ``The Quickhull
 * Algorithm for Convex Hulls''</a> (ACM Transactions on Mathematical Software,
 * Vol. 22, No. 4, December 1996), and has a complexity of O(n log(n)) with
 * respect to the number of points. A well-known C implementation of Quickhull
 * that works for arbitrary dimensions is provided by <a
 * href=http://www.qhull.org>qhull</a>.
 *
 * <p>A hull is constructed by providing a set of points
 * to either a constructor or a
 * {@link #build(Point3d[]) build} method. After
 * the hull is built, its vertices and faces can be retrieved
 * using {@link #getVertices()
 * getVertices} and {@link #getFaces() getFaces}.
 * A typical usage might look like this:
 * <pre>
 *   // x y z coordinates of 6 points
 *   Point3d[] points = new Point3d[]
 *    { new Point3d (0.0,  0.0,  0.0),
 *      new Point3d (1.0,  0.5,  0.0),
 *      new Point3d (2.0,  0.0,  0.0),
 *      new Point3d (0.5,  0.5,  0.5),
 *      new Point3d (0.0,  0.0,  2.0),
 *      new Point3d (0.1,  0.2,  0.3),
 *      new Point3d (0.0,  2.0,  0.0),
 *    };
 *
 *   QuickHull3D hull = new QuickHull3D();
 *   hull.build (points);
 *
 *   System.out.println ("Vertices:");
 *   Point3d[] vertices = hull.getVertices();
 *   for (int i = 0; i < vertices.length; i++)
 *    { Point3d pnt = vertices[i];
 *      System.out.println (pnt.x + " " + pnt.y + " " + pnt.z);
 *    }
 *
 *   System.out.println ("Faces:");
 *   int[][] faceIndices = hull.getFaces();
 *   for (int i = 0; i < faceIndices.length; i++)
 *    { for (int k = 0; k < faceIndices[i].length; k++)
 *       { System.out.print (faceIndices[i][k] + " ");
 *       }
 *      System.out.println ("");
 *    }
 * </pre>
 * As a convenience, there are also {@link #build(double[]) build}
 * and {@link #getVertices(double[]) getVertex} methods which
 * pass point information using an array of doubles.
 *
 * <h3><a name=distTol>Robustness</h3> Because this algorithm uses floating
 * point arithmetic, it is potentially vulnerable to errors arising from
 * numerical imprecision.  We address this problem in the same way as <a
 * href=http://www.qhull.org>qhull</a>, by merging faces whose edges are not
 * clearly convex. A face is convex if its edges are convex, and an edge is
 * convex if the centroid of each adjacent plane is clearly <i>below</i> the
 * plane of the other face. The centroid is considered below a plane if its
 * distance to the plane is less than the negative of a {@link
 * #getDistanceTolerance() distance tolerance}.  This tolerance represents the
 * smallest distance that can be reliably computed within the available numeric
 * precision. It is normally computed automatically from the point data,
 * although an application may {@link #setExplicitDistanceTolerance set this
 * tolerance explicitly}.
 *
 * <p>Numerical problems are more likely to arise in situations where data
 * points lie on or within the faces or edges of the convex hull. We have
 * tested QuickHull3D for such situations by computing the convex hull of a
 * random point set, then adding additional randomly chosen points which lie
 * very close to the hull vertices and edges, and computing the convex
 * hull again. The hull is deemed correct if {@link #check check} returns
 * <code>true</code>.  These tests have been successful for a large number of
 * trials and so we are confident that QuickHull3D is reasonably robust.
 *
 * <h3>Merged Faces</h3> The merging of faces means that the faces returned by
 * QuickHull3D may be convex polygons instead of triangles. If triangles are
 * desired, the application may {@link #triangulate triangulate} the faces, but
 * it should be noted that this may result in triangles which are very small or
 * thin and hence difficult to perform reliable convexity tests on. In other
 * words, triangulating a merged face is likely to restore the numerical
 * problems which the merging process removed. Hence is it
 * possible that, after triangulation, {@link #check check} will fail (the same
 * behavior is observed with triangulated output from <a
 * href=http://www.qhull.org>qhull</a>).
 *
 * <h3>Degenerate Input</h3>It is assumed that the input points
 * are non-degenerate in that they are not coincident, colinear, or
 * colplanar, and thus the convex hull has a non-zero volume.
 * If the input points are detected to be degenerate within
 * the {@link #getDistanceTolerance() distance tolerance}, an
 * IllegalArgumentException will be thrown.
 *
 * @author John E. Lloyd, Fall 2004 */

#pragma once

// #include <stdio.h>
#include <vector>

using std::vector;

class Vertex;
class Face;
class FaceList;
class Vertex;
class VertexList;
class Point3d;
class HalfEdge;

typedef vector<Face *> FaceVector;
typedef vector<HalfEdge *> HalfEdgeVector;

class QuickHull3D
{
#define null NULL

public:
  /**
   * Specifies that (on output) vertex indices for a face should be
   * listed in clockwise order.
   */
  static const int CLOCKWISE = 0x1, CCW = 0;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered starting from 1.
   */
  static const int INDEXED_FROM_ONE = 0x2;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered starting from 0.
   */
  static const int INDEXED_FROM_ZERO = 0x4;

  /**
   * Specifies that (on output) the vertex indices for a face should be
   * numbered with respect to the original input points.
   */
  static const int POINT_RELATIVE = 0x8;

  /**
   * Specifies that the distance tolerance should be
   * computed automatically from the input point data.
   */
  static constexpr double AUTOMATIC_TOLERANCE = -1;

  int findIndex = -1;

  // estimated size of the point set
  double charLength;

  vector<Vertex *> pointBuffer;
  vector<int> vertexPointIndices;
  vector<Face *> discardedFaces;

  vector<Vertex *> maxVtxs;
  vector<Vertex *> minVtxs;

  FaceVector faces;
  HalfEdgeVector horizon;

  FaceList *newFaces;
  VertexList *unclaimed;
  VertexList *claimed;

  int numVertices = 0;
  int numFaces = 0;
  int numPoints = 0;

  double explicitTolerance = AUTOMATIC_TOLERANCE;
  double tolerance;

  void initPrt(); // init pointers that can't be init here
  /**
   * Precision of a double.
   */
  const double DOUBLE_PREC = 2.2204460492503131e-16;

  double getDistanceTolerance();
  void setExplicitDistanceTolerance(double tol);
  double getExplicitDistanceTolerance();
  void addPointToFace(Vertex *vtx, Face *face);
  void removePointFromFace(Vertex *vtx, Face *face);
  Vertex *removeAllPointsFromFace(Face *face);

  QuickHull3D();
  QuickHull3D(vector<double> coords);
  QuickHull3D(vector<Point3d *> points);
  QuickHull3D(double *points, size_t n_points);
  ~QuickHull3D();
  void cleanup();

  HalfEdge *findHalfEdge(Vertex *tail, Vertex *head);
  void setHull(vector<double> coords, int nump,
               vector<vector<int>> &faceIndices, int numf);

  void build(vector<double> coords);
  void build(vector<double> coords, int nump);
  void build(vector<Point3d *> points);
  void build(vector<Point3d *> points, int nump);
  void build(double *coords, int nump);
  void triangulate();
  void initBuffers(int nump);
  void setPoints(vector<double> coords, int nump);
  void setPoints(vector<Point3d *> pnts, int nump);
  void setPoints(double *coords, int nump);
  void computeMaxAndMin();
  void createInitialSimplex();
  int getNumVertices();
  vector<Point3d *> getVertices();
  vector<double> getVertex();
  vector<double> getScaledVertex();
  int getVertices(vector<double> coords);
  vector<int> getVertexPointIndices();
  int getNumFaces();
  vector<vector<int>> getFaces();
  vector<vector<int>> getFaces(int indexFlags);
  void getFaceIndices(vector<int> &indices, Face *face, int flags);
  void resolveUnclaimedPoints(FaceList *newFaces);
  void deleteFacePoints(Face *face, Face *absorbingFace);

  static const int NONCONVEX_WRT_LARGER_FACE = 1;
  static const int NONCONVEX = 2;

  double oppFaceDistance(HalfEdge *he);
  bool doAdjacentMerge(Face *face, int mergeType);
  void calculateHorizon(Point3d *eyePnt, HalfEdge *edge0, Face *face, HalfEdgeVector &horizon);
  HalfEdge *addAdjoiningFace(Vertex *eyeVtx, HalfEdge *he);
  void addNewFaces(FaceList *newFaces, Vertex *eyeVtx, HalfEdgeVector horizon);
  Vertex *nextPointToAdd();
  void addPointToHull(Vertex *eyeVtx);
  void buildHull();
  void markFaceVertices(Face *face, int mark);
  void reindexFacesAndVertices();
  bool checkFaceConvexity(Face *face, double tol);
  bool checkFaces(double tol);
  bool check();
  bool check(double tol);
};
