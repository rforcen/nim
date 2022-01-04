
/**
 * Basic triangular face used to form the hull.
 *
 * <p>The information stored for each face consists of a planar
 * normal, a planar offset, and a doubly-linked list of three <a
 * href=HalfEdge>HalfEdges</a> which surround the face in a
 * counter-clockwise direction.
 *
 * @author John E. Lloyd, Fall 2004 */

#pragma once

#include <stdlib.h>
#include <vector>
#include <string>

using std::vector;
using std::string;

class Vertex;
class HalfEdge;
class Point3d;
class Vector3d;
class Vertex;
class FaceList;

class Face
{
#define null NULL
public:
    HalfEdge *he0=null;
    
    double area=0;
    
    double planeOffset=0;
    int index=0;
    int numVerts=0;
    
    Face *next=null;
    
    static const int VISIBLE = 1;
    static const int NON_CONVEX = 2;
    static const int DELETED = 3;
    int mark = VISIBLE;
    
    Vertex *outside=null;
    
private:
    Point3d *centroid=null;
    Vector3d *normal=null;
    
public:
    Face ();
    ~Face ();
    
    void computeCentroid (Point3d *centroid);
    void computeNormal (Vector3d *normal, double minArea);
    void computeNormal (Vector3d *normal);
    void computeNormalAndCentroid();
    void computeNormalAndCentroid(double minArea);
    static Face *createTriangle (Vertex *v0, Vertex *v1, Vertex *v2);
    static Face *createTriangle (Vertex *v0, Vertex *v1, Vertex *v2,
                                 double minArea);
    static Face *create (vector<Vertex*> vtxArray, vector<int>&indices);
    
  
    
    HalfEdge *getEdge(int i);
    HalfEdge *getFirstEdge();
    HalfEdge *findEdge (Vertex *vt, Vertex *vh);
    double distanceToPlane (Point3d *p);
    Vector3d *getNormal ();
    Point3d *getCentroid ();
    int numVertices();
    string getVertexString ();
    void getVertexIndices (vector<int>&idxs);
    Face *connectHalfEdges (HalfEdge *hedgePrev, HalfEdge *hedge);
    void checkConsistency();
    int mergeAdjacentFace (HalfEdge *hedgeAdj,  vector<Face*>&discarded);
    double areaSquared (HalfEdge *hedge0, HalfEdge *hedge1);
    void triangulate (FaceList *newFaces, double minArea);
};
