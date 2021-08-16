//
//  Vertex.cpp
//  WatermanPoly
//
//  Created by asd on 09/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>


#include "Face.h"
#include "Point3d.h"

#include "Vertex.h"

Vertex::Vertex() : pnt(new Point3d)
{ }

Vertex::~Vertex() {
    delete pnt;
}
/**
 * Constructs a vertex with the specified coordinates
 * and index.
 */
Vertex::Vertex (double x, double y, double z, int idx) : pnt(new Point3d)
{
    pnt->set(x, y, z);
    index = idx;
}


