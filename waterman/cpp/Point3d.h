/**
 * A three-element spatial point.
 */


#ifndef _Header_Point3d_h
#define _Header_Point3d_h

#include "Vector3d.h"

class Point3d: public Vector3d
{
public:
    Point3d ();
    Point3d (Vector3d *v);
    Point3d (double x, double y, double z);
};

#endif
