#pragma once

#include "QuickHull3D.h"
#include "Point3d.h"

class WatermanPoly
{

public:
  QuickHull3D hull;

  WatermanPoly();
  vector<double> genPoly(double radius);
  QuickHull3D genHull(double radius);

  bool ok = true;
};
