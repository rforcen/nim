/**
 * A three-element vector. This class is actually a reduced version of the
 * Vector3d class contained in the author's matlib package (which was partly
 * inspired by javax.vecmath). Only a mininal number of methods
 * which are relevant to convex hull generation are supplied here.
 *
 * @author John E. Lloyd, Fall 2004
 */

#pragma once

#include <stdio.h>
#include <math.h>
#include <string>

using std::string;

class Vector3d
{
public:
  // Precision of a double.
  constexpr static const double DOUBLE_PREC = 2.2204460492503131e-16;
  double x = 0, y = 0, z = 0;

public:
  Vector3d();
  Vector3d(Vector3d *v);
  Vector3d(double x, double y, double z);
  double get(int i);
  void set(int i, double value);
  void set(Vector3d *v1);
  void add(Vector3d *v1, Vector3d *v2);
  void add(Vector3d *v1);
  void sub(Vector3d *v1, Vector3d *v2);
  void sub(Vector3d *v1);
  void scale(double s);
  void scale(double s, Vector3d *v1);
  double norm();
  double normSquared();
  double distance(Vector3d *v);
  double distanceSquared(Vector3d *v);
  double dot(Vector3d *v1);
  void normalize();
  void setZero();
  void set(double x, double y, double z);
  void cross(Vector3d *v1, Vector3d *v2);
  void setRandom(double lower, double upper);
  string toString();
};
