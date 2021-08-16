//
//  HalfEdge.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include "HalfEdge.h"
#include "Face.h"
#include "Vertex.h"
#include "Point3d.h"

HalfEdge::HalfEdge (Vertex* v, Face* f)
{
    vertex = v;
    face = f;
}

HalfEdge::HalfEdge ()
{}

/**
 * Sets the value of the next edge adjacent
 * (counter-clockwise) to this one within the triangle.
 *
 * @param edge next adjacent edge */
void HalfEdge::setNext (HalfEdge *edge)
{
    next = edge;
}

/**
 * Gets the value of the next edge adjacent
 * (counter-clockwise) to this one within the triangle.
 *
 * @return next adjacent edge */
HalfEdge* HalfEdge::getNext()
{
    return next;
}

/**
 * Sets the value of the previous edge adjacent (clockwise) to
 * this one within the triangle.
 *
 * @param edge previous adjacent edge */
void HalfEdge::setPrev (HalfEdge *edge)
{
    prev = edge;
}

/**
 * Gets the value of the previous edge adjacent (clockwise) to
 * this one within the triangle.
 *
 * @return previous adjacent edge
 */
HalfEdge*HalfEdge::getPrev()
{
    return prev;
}

/**
 * Returns the triangular face located to the left of this
 * half-edge.
 *
 * @return left-hand triangular face
 */
Face*HalfEdge::getFace()
{
    return face;
}

/**
 * Returns the half-edge opposite to this half-edge.
 *
 * @return opposite half-edge
 */
HalfEdge*HalfEdge::getOpposite()
{
    return opposite;
}

/**
 * Sets the half-edge opposite to this half-edge.
 *
 * @param edge opposite half-edge
 */
void HalfEdge::setOpposite (HalfEdge *edge)
{
    opposite = edge;
    edge->opposite = this;
}

/**
 * Returns the head vertex associated with this half-edge.
 *
 * @return head vertex
 */
Vertex*HalfEdge::head()
{
    return vertex;
}

/**
 * Returns the tail vertex associated with this half-edge.
 *
 * @return tail vertex
 */
Vertex*HalfEdge::tail()
{
    return prev != null ? prev->vertex : null;
}

/**
 * Returns the opposite triangular face associated with this
 * half-edge.
 *
 * @return opposite triangular face
 */
Face*HalfEdge::oppositeFace()
{
    return opposite != null ? opposite->face : null;
}

/**
 * Produces a string identifying this half-edge by the point
 * index values of its tail and head vertices.
 *
 * @return identifying string
 */
string HalfEdge::getVertexString()
{
    if (tail() != null)
    { return "" +
        std::to_string(tail()->index)+ "-" +
        std::to_string(head()->index);
    }
    else
    { return "?-" + std::to_string(head()->index);
    }
}

/**
 * Returns the length of this half-edge.
 *
 * @return half-edge length
 */
double HalfEdge::length()
{
    if (tail() != null)
    { return head()->pnt->distance(tail()->pnt);
    }
    else
    { return -1;
    }
}

/**
 * Returns the length squared of this half-edge->
 *
 * @return half-edge length squared
 */
double HalfEdge::lengthSquared()
{
    if (tail() != null)
    { return head()->pnt->distanceSquared(tail()->pnt);
    }
    else
    { return -1;
    }
}


