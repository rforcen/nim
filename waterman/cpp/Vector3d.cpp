//
//  Vector3d.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include <stdio.h>

#include "Vector3d.h"

Vector3d::Vector3d ()
{}

/**
 * Creates a 3-vector by copying an existing one.
 *
 * @param v vector to be copied
 */
Vector3d::Vector3d (Vector3d *v)
{
    set (v);
}

/**
 * Creates a 3-vector with the supplied element values.
 *
 * @param x first element
 * @param y second element
 * @param z third element
 */
Vector3d::Vector3d (double x, double y, double z)
{
    set (x, y, z);
}

/**
 * Gets a single element of this vector.
 * Elements 0, 1, and 2 correspond to x, y, and z.
 *
 * @param i element index
 * @return element value throws ArrayIndexOutOfBoundsException
 * if i is not in the range 0 to 2.
 */
double Vector3d::get (int i)
{
    switch (i)
    { case 0:
        { return x;
        }
        case 1:
        { return y;
        }
        case 2:
        { return z;
        }
        default:
        { return 0;
        }
    }
}

/**
 * Sets a single element of this vector.
 * Elements 0, 1, and 2 correspond to x, y, and z.
 *
 * @param i element index
 * @param value element value
 * return element value throws ArrayIndexOutOfBoundsException
 * if i is not in the range 0 to 2.
 */
void Vector3d::set (int i, double value)
{
    switch (i)
    { case 0:
        { x = value;
            break;
        }
        case 1:
        { y = value;
            break;
        }
        case 2:
        { z = value;
            break;
        }
        default:
        { 
        }
    }
}

/**
 * Sets the values of this vector to those of v1.
 *
 * @param v1 vector whose values are copied
 */
void Vector3d::set (Vector3d *v1)
{
    x = v1->x;
    y = v1->y;
    z = v1->z;
}

/**
 * Adds vector v1 to v2 and places the result in this vector.
 *
 * @param v1 left-hand vector
 * @param v2 right-hand vector
 */
void Vector3d::add (Vector3d *v1, Vector3d *v2)
{
    x = v1->x + v2->x;
    y = v1->y + v2->y;
    z = v1->z + v2->z;
}

/**
 * Adds this vector to v1 and places the result in this vector.
 *
 * @param v1 right-hand vector
 */
void Vector3d::add (Vector3d *v1)
{
    x += v1->x;
    y += v1->y;
    z += v1->z;
}

/**
 * Subtracts vector v1 from v2 and places the result in this vector.
 *
 * @param v1 left-hand vector
 * @param v2 right-hand vector
 */
void Vector3d::sub (Vector3d *v1, Vector3d *v2)
{
    x = v1->x - v2->x;
    y = v1->y - v2->y;
    z = v1->z - v2->z;
}

/**
 * Subtracts v1 from this vector and places the result in this vector.
 *
 * @param v1 right-hand vector
 */
void Vector3d::sub (Vector3d *v1)
{
    x -= v1->x;
    y -= v1->y;
    z -= v1->z;
}

/**
 * Scales the elements of this vector by <code>s</code>.
 *
 * @param s scaling factor
 */
void Vector3d::scale (double s)
{
    x = s*x;
    y = s*y;
    z = s*z;
}

/**
 * Scales the elements of vector v1 by <code>s</code> and places
 * the results in this vector.
 *
 * @param s scaling factor
 * @param v1 vector to be scaled
 */
void Vector3d::scale (double s, Vector3d *v1)
{
    x = s*v1->x;
    y = s*v1->y;
    z = s*v1->z;
}

/**
 * Returns the 2 norm of this vector. This is the square root of the
 * sum of the squares of the elements.
 *
 * @return vector 2 norm
 */
double Vector3d::norm()
{
    return sqrt(x*x + y*y + z*z);
}

/**
 * Returns the square of the 2 norm of this vector. This
 * is the sum of the squares of the elements.
 *
 * @return square of the 2 norm
 */
double Vector3d::normSquared()
{
    return x*x + y*y + z*z;
}

/**
 * Returns the Euclidean distance between this vector and vector v.
 *
 * @return distance between this vector and v
 */
double Vector3d::distance(Vector3d *v)
{
    double dx = x - v->x;
    double dy = y - v->y;
    double dz = z - v->z;
    
    return sqrt (dx*dx + dy*dy + dz*dz);
}

/**
 * Returns the squared of the Euclidean distance between this vector
 * and vector v.
 *
 * @return squared distance between this vector and v
 */
double Vector3d::distanceSquared(Vector3d *v)
{
    double dx = x - v->x;
    double dy = y - v->y;
    double dz = z - v->z;
    
    return (dx*dx + dy*dy + dz*dz);
}

/**
 * Returns the dot product of this vector and v1.
 *
 * @param v1 right-hand vector
 * @return dot product
 */
double Vector3d::dot (Vector3d *v1)
{
    return x*v1->x + y*v1->y + z*v1->z;
}

/**
 * Normalizes this vector in place.
 */
void Vector3d::normalize()
{
    double lenSqr = x*x + y*y + z*z;
    double err = lenSqr - 1;
    if (err > (2*DOUBLE_PREC) ||
        err < -(2*DOUBLE_PREC))
    { double len = sqrt(lenSqr);
        x /= len;
        y /= len;
        z /= len;
    }
}

/**
 * Sets the elements of this vector to zero.
 */
void Vector3d::setZero()
{
    x = 0;
    y = 0;
    z = 0;
}

/**
 * Sets the elements of this vector to the prescribed values.
 *
 * @param x value for first element
 * @param y value for second element
 * @param z value for third element
 */
void Vector3d::set (double x, double y, double z)
{
    this->x = x;
    this->y = y;
    this->z = z;
}

/**
 * Computes the cross product of v1 and v2 and places the result
 * in this vector.
 *
 * @param v1 left-hand vector
 * @param v2 right-hand vector
 */
void Vector3d::cross (Vector3d *v1, Vector3d *v2)
{
    double tmpx = v1->y*v2->z - v1->z*v2->y;
    double tmpy = v1->z*v2->x - v1->x*v2->z;
    double tmpz = v1->x*v2->y - v1->y*v2->x;
    
    x = tmpx;
    y = tmpy;
    z = tmpz;
}

/**
 * Sets the elements of this vector to uniformly distributed
 * random values in a specified range, using a supplied
 * random number generator.
 *
 * @param lower lower random value (inclusive)
 * @param upper upper random value (exclusive)
 * param generator random number generator
 */
void Vector3d::setRandom (double lower, double upper)
{
    double range = upper-lower;
    
    x = rand()*range + lower;
    y = rand()*range + lower;
    z = rand()*range + lower;
}

/**
 * Returns a string representation of this vector, consisting
 * of the x, y, and z coordinates.
 *
 * @return string representation
 */
string Vector3d::toString()
{
    return std::to_string(x) + " " + std::to_string(y) + " " + std::to_string(z);
}
