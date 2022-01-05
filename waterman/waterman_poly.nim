# waterman poly, cpp wrapper

import math, cppstl

# ffi 
{.passL:"-L. -lconvexhull".}

type
    Vertex* = array[3, float]
    Vertexes* = seq[Vertex]
    Face* = seq[cint]
    Faces* = seq[Face]

proc waterman_poly*(radius: float) : seq[float] =
    var coords :seq[float]

    let (a, b, c) = (0.0, 0.0, 0.0)
    var (max, min) = (-float.high, float.high)
    var s = radius # .sqrt()
    let radius2 = s 

    let (xra, xrb) = ((a - s).ceil(), (a + s).floor())

    var x = xra
    while x <= xrb:
        let r = radius2 - (x - a) * (x - a)
        if r < 0:
            x += 1
            continue
        
        s = r.sqrt()
        let yra = (b - s).ceil()
        let yrb = (b + s).floor()
        var y = yra

        var (zra, zrb) = (0.0, 0.0)

        while y <= yrb: 
            let ry = r - (y - b) * (y - b)
            if ry < 0: 
                y += 1
                continue
             #case ry < 0

            if ry == 0 and c == c.floor():
                #case ry=0
                if (x + y + c).mod(2) != 0:
                    y += 1
                    continue
                else:
                    zra = c
                    zrb = c
                
            else: 
                # case ry > 0
                s = ry.sqrt()
                zra = (c - s).ceil()
                zrb = (c + s).floor()
                if ((x + y).mod(2)) == 0: 
                    if zra.mod(2) != 0:
                        if zra <= c:
                            zra = zra + 1
                        else:
                            zra = zra - 1
                else:
                    if zra.mod(2) == 0:
                        if zra <= c:
                            zra = zra + 1
                        else:
                            zra = zra - 1
                        
            var z = zra
            while z <= zrb:
                # save vertex x,y,z
                max = max.max(z).max(y).max(x)
                min = min.min(z).min(y).min(y)

                coords.add(x)
                coords.add(y)
                coords.add(z)                
                z += 2

            y += 1
            
        x += 1
    
    coords

# QuickHull3D wrapper

const qhHeader="cpp/QuickHull3D.h"

type QuickHull3D {.importcpp, header:qhHeader.}=object
{.push importcpp, header:qhHeader.}
proc getScaledVertex(qh:QuickHull3D) : CppVector[cdouble]
proc getFaces(qh:QuickHull3D) : CppVector[CppVector[cint]]
{.pop.}
proc newQuickHull3D(coords:CppVector[cdouble]) : QuickHull3D {.importcpp:"QuickHull3D(@)", header:qhHeader.}

proc waterman*(rad: float): (Faces, Vertexes) =
  var qh = newQuickHull3D(waterman_poly(rad).toCppVector)

  let vertexes = cast[Vertexes](qh.getScaledVertex().toSeq)
  var faces: Faces
  for face in qh.getFaces():  faces.add face.toSeq

  (faces, vertexes)


when isMainModule:
  for i in countdown(1500, 500, 20):
    let (f, v) = waterman(i.float)
    echo i," faces/vertex:", f.len, "/", v.len

