//
//  QuickHull3D.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include "QuickHull3D.h"

#include "Face.h"
#include "Point3d.h"
#include "Vertex.h"
#include "FaceList.h"
#include "VertexList.h"
#include "HalfEdge.h"

#include <assert.h>
#include <algorithm>

// init all pointers
void QuickHull3D::initPrt()
{
  discardedFaces = vector<Face *>(3);
  maxVtxs = vector<Vertex *>(3);
  minVtxs = vector<Vertex *>(3);

  faces = FaceVector();
  horizon = HalfEdgeVector();

  newFaces = new FaceList;
  unclaimed = new VertexList;
  claimed = new VertexList;
}

void QuickHull3D::cleanup()
{
  for (auto face : faces) // delete faces
    delete face;
  faces.clear();

  for (auto he : horizon)
    delete he; // delete horizon
  horizon.clear();

  for (auto p : pointBuffer)
    delete p;
  pointBuffer.clear(); // delete points

  maxVtxs.clear();
  minVtxs.clear();

  delete newFaces;
  delete unclaimed;
  delete claimed;
}

QuickHull3D::~QuickHull3D()
{
  cleanup();
}

/**
 * Returns the distance tolerance that was used for the most recently
 * computed hull. The distance tolerance is used to determine when
 * faces are unambiguously convex with respect to each other, and when
 * points are unambiguously above or below a face plane, in the
 * presence of distTol numerical imprecision. Normally,
 * this tolerance is computed automatically for each set of input
 * points, but it can be set explicitly by the application.
 *
 * @return distance tolerance
 * @see QuickHull3D#setExplicitDistanceTolerance
 */
double QuickHull3D::getDistanceTolerance()
{
  return tolerance;
}

/**
 * Sets an explicit distance tolerance for convexity tests.
 * If {@link #AUTOMATIC_TOLERANCE AUTOMATIC_TOLERANCE}
 * is specified (the default), then the tolerance will be computed
 * automatically from the point data.
 *
 * @param tol explicit tolerance
 * @see #getDistanceTolerance
 */
void QuickHull3D::setExplicitDistanceTolerance(double tol)
{
  explicitTolerance = tol;
}

/**
 * Returns the explicit distance tolerance.
 *
 * @return explicit tolerance
 * @see #setExplicitDistanceTolerance
 */
double QuickHull3D::getExplicitDistanceTolerance()
{
  return explicitTolerance;
}

void QuickHull3D::addPointToFace(Vertex *vtx, Face *face)
{
  vtx->face = face;

  if (face->outside == null)
  {
    claimed->add(vtx);
  }
  else
  {
    claimed->insertBefore(vtx, face->outside);
  }
  face->outside = vtx;
}

void QuickHull3D::removePointFromFace(Vertex *vtx, Face *face)
{
  if (vtx == face->outside)
  {
    if (vtx->next != null && vtx->next->face == face)
    {
      face->outside = vtx->next;
    }
    else
    {
      face->outside = null;
    }
  }
  claimed->del(vtx);
}

Vertex *QuickHull3D::removeAllPointsFromFace(Face *face)
{
  if (face->outside != null)
  {
    Vertex *end = face->outside;
    while (end->next != null && end->next->face == face)
    {
      end = end->next;
    }
    claimed->del(face->outside, end);
    end->next = null;
    return face->outside;
  }
  else
  {
    return null;
  }
}

/**
 * Creates an empty convex hull object.
 */
QuickHull3D::QuickHull3D()
{
  initPrt();
}

/**
 * Creates a convex hull object and initializes it to the convex hull
 * of a set of points whose coordinates are given by an
 * array of doubles.
 *
 * @param coords x, y, and z coordinates of each input
 * point. The length of this array will be three times
 * the the number of input points.
 * @throws IllegalArgumentException the number of input points is less
 * than four, or the points appear to be coincident, colinear, or
 * coplanar.
 */
QuickHull3D::QuickHull3D(vector<double> coords)
{
  initPrt();
  build(coords);
}

QuickHull3D::QuickHull3D(double *points, size_t n_points)
{
  initPrt();
  build(points, (int)n_points / 3);
}

/**
 * Creates a convex hull object and initializes it to the convex hull
 * of a set of points.
 *
 * @param points input points.
 * @throws IllegalArgumentException the number of input points is less
 * than four, or the points appear to be coincident, colinear, or
 * coplanar.
 */
QuickHull3D::QuickHull3D(vector<Point3d *> points)
{
  initPrt();
  build(points, (int)points.size());
}

HalfEdge *QuickHull3D::findHalfEdge(Vertex *tail, Vertex *head)
{
  // brute force ... OK, since setHull is not used much
  for (auto f : faces)
  {
    HalfEdge *he = ((Face *)f)->findEdge(tail, head);
    if (he != null)
    {
      return he;
    }
  }
  return null;
}

void QuickHull3D::setHull(vector<double> coords, int nump,
                          vector<vector<int>> &faceIndices, int numf)
{
  initBuffers(nump);
  setPoints(coords, nump);
  computeMaxAndMin();
  for (int i = 0; i < numf; i++)
  {
    Face *face = Face::create(pointBuffer, faceIndices[i]);
    HalfEdge *he = face->he0;
    do
    {
      HalfEdge *heOpp = findHalfEdge(he->head(), he->tail());
      if (heOpp != null)
      {
        he->setOpposite(heOpp);
      }
      he = he->next;
    } while (he != face->he0);
    faces.push_back(face);
  }
}

/**
 * Constructs the convex hull of a set of points whose
 * coordinates are given by an array of doubles.
 *
 * @param coords x, y, and z coordinates of each input
 * point. The length of this array will be three times
 * the number of input points.
 * @throws IllegalArgumentException the number of input points is less
 * than four, or the points appear to be coincident, colinear, or
 * coplanar.
 */
void QuickHull3D::build(vector<double> coords)
{
  build(coords, (int)coords.size() / 3);
}

/**
 * Constructs the convex hull of a set of points whose
 * coordinates are given by an array of doubles.
 *
 * @param coords x, y, and z coordinates of each input
 * point. The length of this array must be at least three times
 * <code>nump</code>.
 * @param nump number of input points
 * @throws IllegalArgumentException the number of input points is less
 * than four or greater than 1/3 the length of <code>coords</code>,
 * or the points appear to be coincident, colinear, or
 * coplanar.
 */
void QuickHull3D::build(vector<double> coords, int nump)
{
  assert((nump >= 4) && "Less than four input points specified");
  assert((coords.size() / 3 >= nump) && "Coordinate array too small for specified number of points");

  initBuffers(nump);
  setPoints(coords, nump);
  buildHull();
}

void QuickHull3D::build(double *coords, int nump)
{
  assert((nump >= 4) && "Less than four input points specified");
  assert((nump / 3 >= nump) && "Coordinate array too small for specified number of points");

  initBuffers(nump);
  setPoints(coords, nump);
  buildHull();
}

/**
 * Constructs the convex hull of a set of points.
 *
 * @param points input points
 * @throws IllegalArgumentException the number of input points is less
 * than four, or the points appear to be coincident, colinear, or
 * coplanar.
 */
void QuickHull3D::build(vector<Point3d *> points)
{
  build(points, (int)points.size());
}

/**
 * Constructs the convex hull of a set of points.
 *
 * @param points input points
 * @param nump number of input points
 * @throws IllegalArgumentException the number of input points is less
 * than four or greater then the length of <code>points</code>, or the
 * points appear to be coincident, colinear, or coplanar.
 */
void QuickHull3D::build(vector<Point3d *> points, int nump)
{
  assert((nump >= 4) && "Less than four input points specified");
  assert((points.size() >= nump) && "Point array too small for specified number of points");

  initBuffers(nump);
  setPoints(points, nump);
  buildHull();
}

/**
 * Triangulates any non-triangular hull faces. In some cases, due to
 * precision issues, the resulting triangles may be very thin or small,
 * and hence appear to be non-convex (this same limitation is present
 * in http://www.qhull.org).
 */
void QuickHull3D::triangulate()
{
  double minArea = 1000 * charLength * DOUBLE_PREC;
  newFaces->clear();

  for (auto face : faces)
  {
    if (face->mark == Face::VISIBLE)
    {
      face->triangulate(newFaces, minArea);
    }
  }
  for (Face *face = newFaces->first(); face != null; face = face->next)
  {
    faces.push_back(face);
  }
}

void QuickHull3D::initBuffers(int nump)
{
  if ((int)pointBuffer.size() < nump)
  {
    vector<Vertex *> newBuffer = vector<Vertex *>(nump);
    vertexPointIndices = vector<int>(nump);
    for (size_t i = 0; i < pointBuffer.size(); i++)
    {
      newBuffer[i] = pointBuffer[i];
    }
    for (int i = (int)pointBuffer.size(); i < nump; i++)
    {
      newBuffer[i] = new Vertex();
    }
    pointBuffer = newBuffer;
  }
  faces.clear();
  claimed->clear();
  numFaces = 0;
  numPoints = nump;
}

void QuickHull3D::setPoints(vector<double> coords, int nump)
{
  for (int i = 0; i < nump; i++)
  {
    Vertex *vtx = pointBuffer[i];
    vtx->pnt->set(coords[i * 3 + 0], coords[i * 3 + 1], coords[i * 3 + 2]);
    vtx->index = i;
  }
}
void QuickHull3D::setPoints(double *coords, int nump)
{
  for (int i = 0; i < nump; i++)
  {
    Vertex *vtx = pointBuffer[i];
    vtx->pnt->set(coords[i * 3 + 0], coords[i * 3 + 1], coords[i * 3 + 2]);
    vtx->index = i;
  }
}

void QuickHull3D::setPoints(vector<Point3d *> pnts, int nump)
{
  for (int i = 0; i < nump; i++)
  {
    Vertex *vtx = pointBuffer[i];
    vtx->pnt->set(pnts[i]);
    vtx->index = i;
  }
}

void QuickHull3D::computeMaxAndMin()
{
  Vector3d *max = new Vector3d();
  Vector3d *min = new Vector3d();

  for (int i = 0; i < 3; i++)
  {
    maxVtxs[i] = minVtxs[i] = pointBuffer[0];
  }
  max->set(pointBuffer[0]->pnt);
  min->set(pointBuffer[0]->pnt);

  for (int i = 1; i < numPoints; i++)
  {
    Point3d *pnt = pointBuffer[i]->pnt;
    if (pnt->x > max->x)
    {
      max->x = pnt->x;
      maxVtxs[0] = pointBuffer[i];
    }
    else if (pnt->x < min->x)
    {
      min->x = pnt->x;
      minVtxs[0] = pointBuffer[i];
    }
    if (pnt->y > max->y)
    {
      max->y = pnt->y;
      maxVtxs[1] = pointBuffer[i];
    }
    else if (pnt->y < min->y)
    {
      min->y = pnt->y;
      minVtxs[1] = pointBuffer[i];
    }
    if (pnt->z > max->z)
    {
      max->z = pnt->z;
      maxVtxs[2] = pointBuffer[i];
    }
    else if (pnt->z < min->z)
    {
      min->z = pnt->z;
      maxVtxs[2] = pointBuffer[i];
    }
  }

  // this epsilon formula comes from QuickHull, and I'm
  // not about to quibble.
  charLength = std::max<double>(max->x - min->x, max->y - min->y);
  charLength = std::max<double>(max->z - min->z, charLength);
  if (explicitTolerance == AUTOMATIC_TOLERANCE)
  {
    tolerance =
        3 * DOUBLE_PREC * (std::max<double>(fabs(max->x), fabs(min->x)) + std::max<double>(fabs(max->y), fabs(min->y)) + std::max<double>(fabs(max->z), fabs(min->z)));
  }
  else
  {
    tolerance = explicitTolerance;
  }

  delete min;
  delete max;
}

/**
 * Creates the initial simplex from which the hull will be built.
 */
void QuickHull3D::createInitialSimplex()
{
  double max = 0;
  int imax = 0;

  for (int i = 0; i < 3; i++)
  {
    double diff = maxVtxs[i]->pnt->get(i) - minVtxs[i]->pnt->get(i);
    if (diff > max)
    {
      max = diff;
      imax = i;
    }
  }

  assert(!(max <= tolerance) && "Input points appear to be coincident");

  vector<Vertex *> vtx = vector<Vertex *>(4);
  // set first two vertices to be those with the greatest
  // one dimensional separation

  vtx[0] = maxVtxs[imax];
  vtx[1] = minVtxs[imax];

  // set third vertex to be the vertex farthest from
  // the line between vtx0 and vtx1
  Vector3d *u01 = new Vector3d();
  Vector3d *diff02 = new Vector3d();
  Vector3d *nrml = new Vector3d();
  Vector3d *xprod = new Vector3d();
  double maxSqr = 0;
  u01->sub(vtx[1]->pnt, vtx[0]->pnt);
  u01->normalize();
  for (int i = 0; i < numPoints; i++)
  {
    diff02->sub(pointBuffer[i]->pnt, vtx[0]->pnt);
    xprod->cross(u01, diff02);
    double lenSqr = xprod->normSquared();
    if (lenSqr > maxSqr &&
        pointBuffer[i] != vtx[0] && // paranoid
        pointBuffer[i] != vtx[1])
    {
      maxSqr = lenSqr;
      vtx[2] = pointBuffer[i];
      nrml->set(xprod);
    }
  }

  assert(!(sqrt(maxSqr) <= 100 * tolerance) && "Input points appear to be colinear");

  nrml->normalize();

  double maxDist = 0;
  double d0 = vtx[2]->pnt->dot(nrml);
  for (int i = 0; i < numPoints; i++)
  {
    double dist = fabs(pointBuffer[i]->pnt->dot(nrml) - d0);
    if (dist > maxDist &&
        pointBuffer[i] != vtx[0] && // paranoid
        pointBuffer[i] != vtx[1] &&
        pointBuffer[i] != vtx[2])
    {
      maxDist = dist;
      vtx[3] = pointBuffer[i];
    }
  }
  assert(!(fabs(maxDist) <= 100 * tolerance) && "Input points appear to be coplanar");

  vector<Face *> tris = vector<Face *>(4);

  if (vtx[3]->pnt->dot(nrml) - d0 < 0)
  {
    tris[0] = Face::createTriangle(vtx[0], vtx[1], vtx[2]);
    tris[1] = Face::createTriangle(vtx[3], vtx[1], vtx[0]);
    tris[2] = Face::createTriangle(vtx[3], vtx[2], vtx[1]);
    tris[3] = Face::createTriangle(vtx[3], vtx[0], vtx[2]);

    for (int i = 0; i < 3; i++)
    {
      int k = (i + 1) % 3;
      tris[i + 1]->getEdge(1)->setOpposite(tris[k + 1]->getEdge(0));
      tris[i + 1]->getEdge(2)->setOpposite(tris[0]->getEdge(k));
    }
  }
  else
  {
    tris[0] = Face::createTriangle(vtx[0], vtx[2], vtx[1]);
    tris[1] = Face::createTriangle(vtx[3], vtx[0], vtx[1]);
    tris[2] = Face::createTriangle(vtx[3], vtx[1], vtx[2]);
    tris[3] = Face::createTriangle(vtx[3], vtx[2], vtx[0]);

    for (int i = 0; i < 3; i++)
    {
      int k = (i + 1) % 3;
      tris[i + 1]->getEdge(0)->setOpposite(tris[k + 1]->getEdge(1));
      tris[i + 1]->getEdge(2)->setOpposite(tris[0]->getEdge((3 - i) % 3));
    }
  }

  delete nrml; // release unused Vector3d items
  delete u01;
  delete diff02;
  delete xprod;

  for (int i = 0; i < 4; i++)
  {
    faces.push_back(tris[i]);
  }

  for (int i = 0; i < numPoints; i++)
  {
    Vertex *v = pointBuffer[i];

    if (v == vtx[0] || v == vtx[1] || v == vtx[2] || v == vtx[3])
    {
      continue;
    }

    maxDist = tolerance;
    Face *maxFace = null;
    for (int k = 0; k < 4; k++)
    {
      double dist = tris[k]->distanceToPlane(v->pnt);
      if (dist > maxDist)
      {
        maxFace = tris[k];
        maxDist = dist;
      }
    }
    if (maxFace != null)
    {
      addPointToFace(v, maxFace);
    }
  }

  tris.clear();
}

/**
 * Returns the number of vertices in this hull.
 *
 * @return number of vertices
 */
int QuickHull3D::getNumVertices()
{
  return numVertices;
}

/**
 * Returns the vertex points in this hull.
 *
 * @return array of vertex points
 * @see QuickHull3D#getVertices(double[])
 * @see QuickHull3D#getFaces()
 */
vector<Point3d *> QuickHull3D::getVertices()
{
  vector<Point3d *> vtxs = vector<Point3d *>(numVertices);
  for (int i = 0; i < numVertices; i++)
  {
    vtxs[i] = pointBuffer[vertexPointIndices[i]]->pnt;
  }
  return vtxs;
}

vector<double> QuickHull3D::getScaledVertex()
{
  auto v = getVertex();
  double maxv = *std::max_element(v.begin(), v.end());

  for (auto &p : v)
    p /= maxv;

  return v;
}
vector<double> QuickHull3D::getVertex()
{
  vector<double> v;
  for (int i = 0; i < numVertices; i++)
  {
    auto pb = pointBuffer[vertexPointIndices[i]]->pnt;
    v.push_back(pb->x);
    v.push_back(pb->y);
    v.push_back(pb->z);
  }
  return v;
}

/**
 * Returns the coordinates of the vertex points of this hull.
 *
 * @param coords returns the x, y, z coordinates of each vertex.
 * This length of this array must be at least three times
 * the number of vertices.
 * @return the number of vertices
 * @see QuickHull3D#getVertices()
 * @see QuickHull3D#getFaces()
 */
int QuickHull3D::getVertices(vector<double> coords)
{
  for (int i = 0; i < numVertices; i++)
  {
    Point3d *pnt = pointBuffer[vertexPointIndices[i]]->pnt;
    coords[i * 3 + 0] = pnt->x;
    coords[i * 3 + 1] = pnt->y;
    coords[i * 3 + 2] = pnt->z;
  }
  return numVertices;
}

/**
 * Returns an array specifing the index of each hull vertex
 * with respect to the original input points.
 *
 * @return vertex indices with respect to the original points
 */
vector<int> QuickHull3D::getVertexPointIndices()
{
  vector<int> indices = vector<int>(numVertices);
  for (int i = 0; i < numVertices; i++)
  {
    indices[i] = vertexPointIndices[i];
  }
  return indices;
}

/**
 * Returns the number of faces in this hull.
 *
 * @return number of faces
 */
int QuickHull3D::getNumFaces()
{
  return (int)faces.size();
}

/**
 * Returns the faces associated with this hull.
 *
 * <p>Each face is represented by an integer array which gives the
 * indices of the vertices. These indices are numbered
 * relative to the
 * hull vertices, are zero-based,
 * and are arranged counter-clockwise. More control
 * over the index format can be obtained using
 * {@link #getFaces(int) getFaces(indexFlags)}.
 *
 * @return array of integer arrays, giving the vertex
 * indices for each face.
 * @see QuickHull3D#getVertices()
 * @see QuickHull3D#getFaces(int)
 */
vector<vector<int>> QuickHull3D::getFaces()
{
  return getFaces(CCW);
}

/**
 * Returns the faces associated with this hull.
 *
 * <p>Each face is represented by an integer array which gives the
 * indices of the vertices. By default, these indices are numbered with
 * respect to the hull vertices (as opposed to the input points), are
 * zero-based, and are arranged counter-clockwise. However, this
 * can be changed by setting {@link #POINT_RELATIVE
 * POINT_RELATIVE}, {@link #INDEXED_FROM_ONE INDEXED_FROM_ONE}, or
 * {@link #CLOCKWISE CLOCKWISE} in the indexFlags parameter.
 *
 * @param indexFlags specifies index characteristics (0 results
 * in the default)
 * @return array of integer arrays, giving the vertex
 * indices for each face.
 * @see QuickHull3D#getVertices()
 */
vector<vector<int>> QuickHull3D::getFaces(int indexFlags)
{
  vector<vector<int>> allFaces = vector<vector<int>>(faces.size());
  int k = 0;
  for (auto face : faces)
  {
    allFaces[k] = vector<int>(face->numVertices());
    getFaceIndices(allFaces[k], face, indexFlags);
    k++;
  }
  return allFaces;
}

void QuickHull3D::getFaceIndices(vector<int> &indices, Face *face, int flags)
{
  bool ccw = ((flags & CLOCKWISE) == 0);
  bool indexedFromOne = ((flags & INDEXED_FROM_ONE) != 0);
  bool pointRelative = ((flags & POINT_RELATIVE) != 0);

  HalfEdge *hedge = face->he0;
  int k = 0;
  do
  {
    int idx = hedge->head()->index;
    if (pointRelative)
    {
      idx = vertexPointIndices[idx];
    }
    if (indexedFromOne)
    {
      idx++;
    }
    assert(k < indices.size());
    indices[k++] = idx;
    hedge = (ccw ? hedge->next : hedge->prev);
  } while (hedge != face->he0);
}

void QuickHull3D::resolveUnclaimedPoints(FaceList *newFaces)
{
  Vertex *vtxNext = unclaimed->first();
  for (Vertex *vtx = vtxNext; vtx != null; vtx = vtxNext)
  {
    vtxNext = vtx->next;

    double maxDist = tolerance;
    Face *maxFace = null;
    for (Face *newFace = newFaces->first(); newFace != null;
         newFace = newFace->next)
    {
      if (newFace->mark == Face::VISIBLE)
      {
        double dist = newFace->distanceToPlane(vtx->pnt);
        if (dist > maxDist)
        {
          maxDist = dist;
          maxFace = newFace;
        }
        if (maxDist > 1000 * tolerance)
        {
          break;
        }
      }
    }
    if (maxFace != null)
    {
      addPointToFace(vtx, maxFace);
    }
    else
    {
    }
  }
}

void QuickHull3D::deleteFacePoints(Face *face, Face *absorbingFace)
{
  Vertex *faceVtxs = removeAllPointsFromFace(face);
  if (faceVtxs != null)
  {
    if (absorbingFace == null)
    {
      unclaimed->addAll(faceVtxs);
    }
    else
    {
      Vertex *vtxNext = faceVtxs;
      for (Vertex *vtx = vtxNext; vtx != null; vtx = vtxNext)
      {
        vtxNext = vtx->next;
        double dist = absorbingFace->distanceToPlane(vtx->pnt);
        if (dist > tolerance)
        {
          addPointToFace(vtx, absorbingFace);
        }
        else
        {
          unclaimed->add(vtx);
        }
      }
    }
  }
}

// static const int NONCONVEX_WRT_LARGER_FACE = 1;
// static const int NONCONVEX = 2;

double QuickHull3D::oppFaceDistance(HalfEdge *he)
{
  return he->face->distanceToPlane(he->opposite->face->getCentroid());
}

bool QuickHull3D::doAdjacentMerge(Face *face, int mergeType)
{
  HalfEdge *hedge = face->he0;

  bool convex = true;
  do
  {
    Face *oppFace = hedge->oppositeFace();
    bool merge = false;
    double dist1;

    if (mergeType == NONCONVEX)
    { // then merge faces if they are definitively non-convex
      if (oppFaceDistance(hedge) > -tolerance ||
          oppFaceDistance(hedge->opposite) > -tolerance)
      {
        merge = true;
      }
    }
    else // mergeType == NONCONVEX_WRT_LARGER_FACE
    {    // merge faces if they are parallel or non-convex
      // wrt to the larger face; otherwise, just mark
      // the face non-convex for the second pass.
      if (face->area > oppFace->area)
      {
        if ((dist1 = oppFaceDistance(hedge)) > -tolerance)
        {
          merge = true;
        }
        else if (oppFaceDistance(hedge->opposite) > -tolerance)
        {
          convex = false;
        }
      }
      else
      {
        if (oppFaceDistance(hedge->opposite) > -tolerance)
        {
          merge = true;
        }
        else if (oppFaceDistance(hedge) > -tolerance)
        {
          convex = false;
        }
      }
    }

    if (merge)
    {
      int numd = face->mergeAdjacentFace(hedge, discardedFaces);
      for (int i = 0; i < numd; i++)
      {
        deleteFacePoints(discardedFaces[i], face);
      }

      return true;
    }
    hedge = hedge->next;
  } while (hedge != face->he0);
  if (!convex)
  {
    face->mark = Face::NON_CONVEX;
  }
  return false;
}

void QuickHull3D::calculateHorizon(Point3d *eyePnt, HalfEdge *edge0, Face *face, HalfEdgeVector &horizon)
{
  //       oldFaces.add (face);
  deleteFacePoints(face, null);
  face->mark = Face::DELETED;

  HalfEdge *edge;
  if (edge0 == null)
  {
    edge0 = face->getEdge(0);
    edge = edge0;
  }
  else
  {
    edge = edge0->getNext();
  }
  do
  {
    Face *oppFace = edge->oppositeFace();
    if (oppFace->mark == Face::VISIBLE)
    {
      if (oppFace->distanceToPlane(eyePnt) > tolerance)
      {
        calculateHorizon(eyePnt, edge->getOpposite(), oppFace, horizon);
      }
      else
      {
        horizon.push_back(edge);
      }
    }
    edge = edge->getNext();
  } while (edge != edge0);
}

HalfEdge *QuickHull3D::addAdjoiningFace(Vertex *eyeVtx, HalfEdge *he)
{
  Face *face = Face::createTriangle(eyeVtx, he->tail(), he->head());
  faces.push_back(face);
  face->getEdge(-1)->setOpposite(he->getOpposite());
  return face->getEdge(0);
}

void QuickHull3D::addNewFaces(FaceList *newFaces, Vertex *eyeVtx, HalfEdgeVector horizon)
{
  newFaces->clear();

  HalfEdge *hedgeSidePrev = null;
  HalfEdge *hedgeSideBegin = null;

  for (auto horizonHe : horizon)
  {
    HalfEdge *hedgeSide = addAdjoiningFace(eyeVtx, horizonHe);

    if (hedgeSidePrev != null)
    {
      hedgeSide->next->setOpposite(hedgeSidePrev);
    }
    else
    {
      hedgeSideBegin = hedgeSide;
    }
    newFaces->add(hedgeSide->getFace());
    hedgeSidePrev = hedgeSide;
  }
  hedgeSideBegin->next->setOpposite(hedgeSidePrev);
}

Vertex *QuickHull3D::nextPointToAdd()
{
  if (!claimed->isEmpty())
  {
    Face *eyeFace = claimed->first()->face;
    Vertex *eyeVtx = null;
    double maxDist = 0;
    for (Vertex *vtx = eyeFace->outside;
         vtx != null && vtx->face == eyeFace;
         vtx = vtx->next)
    {
      double dist = eyeFace->distanceToPlane(vtx->pnt);
      if (dist > maxDist)
      {
        maxDist = dist;
        eyeVtx = vtx;
      }
    }
    return eyeVtx;
  }
  else
  {
    return null;
  }
}

void QuickHull3D::addPointToHull(Vertex *eyeVtx)
{
  horizon.clear();
  unclaimed->clear();

  removePointFromFace(eyeVtx, eyeVtx->face);
  calculateHorizon(eyeVtx->pnt, null, eyeVtx->face, horizon);
  newFaces->clear();
  addNewFaces(newFaces, eyeVtx, horizon);

  // first merge pass ... merge faces which are non-convex
  // as determined by the larger face

  for (Face *face = newFaces->first(); face != null; face = face->next)
  {
    if (face->mark == Face::VISIBLE)
    {
      while (doAdjacentMerge(face, NONCONVEX_WRT_LARGER_FACE))
        ;
    }
  }
  // second merge pass ... merge faces which are non-convex
  // wrt either face
  for (Face *face = newFaces->first(); face != null; face = face->next)
  {
    if (face->mark == Face::NON_CONVEX)
    {
      face->mark = Face::VISIBLE;
      while (doAdjacentMerge(face, NONCONVEX))
        ;
    }
  }
  resolveUnclaimedPoints(newFaces);
}

void QuickHull3D::buildHull()
{
  int cnt = 0;
  Vertex *eyeVtx;

  computeMaxAndMin();
  createInitialSimplex();
  while ((eyeVtx = nextPointToAdd()) != null)
  {
    addPointToHull(eyeVtx);
    cnt++;
  }
  reindexFacesAndVertices();
}

void QuickHull3D::markFaceVertices(Face *face, int mark)
{
  HalfEdge *he0 = face->getFirstEdge();
  HalfEdge *he = he0;
  do
  {
    he->head()->index = mark;
    he = he->next;
  } while (he != he0);
}

void QuickHull3D::reindexFacesAndVertices()
{
  for (int i = 0; i < numPoints; i++)
  {
    pointBuffer[i]->index = -1;
  }
  // remove inactive faces and mark active vertices
  numFaces = 0;

  for (auto it = faces.begin(); it != faces.end();)
  {
    Face *face = *it;
    if (face->mark != Face::VISIBLE)
      it = faces.erase(it);
    else
    {
      markFaceVertices(face, 0);
      numFaces++;
      it++;
    }
  }

  // reindex vertices
  numVertices = 0;
  for (int i = 0; i < numPoints; i++)
  {
    Vertex *vtx = pointBuffer[i];
    if (vtx->index == 0)
    {
      vertexPointIndices[numVertices] = i;
      vtx->index = numVertices++;
    }
  }
}

bool QuickHull3D::checkFaceConvexity(Face *face, double tol)
{
  double dist;
  HalfEdge *he = face->he0;
  do
  {
    face->checkConsistency();
    // make sure edge is convex
    dist = oppFaceDistance(he);
    if (dist > tol)
    {
      return false;
    }
    dist = oppFaceDistance(he->opposite);
    if (dist > tol)
    {
      return false;
    }
    if (he->next->oppositeFace() == he->oppositeFace())
    {
      return false;
    }
    he = he->next;
  } while (he != face->he0);
  return true;
}

bool QuickHull3D::checkFaces(double tol)
{
  // check edge convexity
  bool convex = true;
  for (auto face : faces)
  {
    if (face->mark == Face::VISIBLE)
      if (!checkFaceConvexity(face, tol))
        convex = false;
  }
  return convex;
}

/**
 * Checks the correctness of the hull using the distance tolerance
 * returned by {@link QuickHull3D#getDistanceTolerance
 * getDistanceTolerance}; see
 * {@link QuickHull3D#check(PrintStream,double)
 * check(PrintStream,double)} for details.
 *
 * @param ps print stream for diagnostic messages; may be
 * set to <code>null</code> if no messages are desired.
 * @return true if the hull is valid
 * @see QuickHull3D#check(PrintStream,double)
 */
bool QuickHull3D::check()
{
  return check(getDistanceTolerance());
}

/**
 * Checks the correctness of the hull. This is done by making sure that
 * no faces are non-convex and that no points are outside any face.
 * These tests are performed using the distance tolerance <i>tol</i>.
 * Faces are considered non-convex if any edge is non-convex, and an
 * edge is non-convex if the centroid of either adjoining face is more
 * than <i>tol</i> above the plane of the other face. Similarly,
 * a point is considered outside a face if its distance to that face's
 * plane is more than 10 times <i>tol</i>.
 *
 * <p>If the hull has been {@link #triangulate triangulated},
 * then this routine may fail if some of the resulting
 * triangles are very small or thin.
 *
 * @param ps print stream for diagnostic messages; may be
 * set to <code>null</code> if no messages are desired.
 * @param tol distance tolerance
 * @return true if the hull is valid
 * @see QuickHull3D#check(PrintStream)
 */
bool QuickHull3D::check(double tol)
{
  // check to make sure all edges are fully connected
  // and that the edges are convex
  double dist;
  double pointTol = 10 * tol;

  if (!checkFaces(tolerance))
  {
    return false;
  }

  // check point inclusion

  for (int i = 0; i < numPoints; i++)
  {
    Point3d *pnt = pointBuffer[i]->pnt;
    for (auto face : faces)
    {
      if (face->mark == Face::VISIBLE)
      {
        dist = face->distanceToPlane(pnt);
        if (dist > pointTol)
        {
          return false;
        }
      }
    }
  }
  return true;
}
