//
//  Point3d.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include "Point3d.h"
#include "Vector3d.h"

Point3d::Point3d ()
{
}

/**
 * Creates a Point3d by copying a vector
 *
 * @param v vector to be copied
 */
Point3d::Point3d (Vector3d *v)
{
    set (v);
}

/**
 * Creates a Point3d with the supplied element values.
 *
 * @param x first element
 * @param y second element
 * @param z third element
 */
Point3d::Point3d (double x, double y, double z)
{
    set (x, y, z);
}
