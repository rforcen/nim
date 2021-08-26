import math, vmath

proc waterman_poly*(radius: float): seq[DVec3] =
  var coords: seq[DVec3]

  let (a, b, c) = (0.0, 0.0, 0.0)
  var s = radius # .sqrt
  let radius2 = s

  let (xra, xrb) = ((a - s).ceil, (a + s).floor)

  for ix in xra.int..xrb.int:

    let x=ix.float
    let r = radius2 - (x - a) * (x - a)
    if r < 0: continue

    s = r.sqrt
    let yra = (b - s).ceil
    let yrb = (b + s).floor


    for iy in yra.int..yrb.int:

      let 
        y = iy.float
        ry = r - (y - b) * (y - b)

      if ry < 0:  continue  #case ry < 0

      var (zra, zrb) = (0.0, 0.0)
      if ry == 0 and c == c.floor:    #case ry=0
        if (x + y + c).mod(2) != 0:  continue
        else:  (zra, zrb) = (c, c)
      else:  # case ry > 0
        s = ry.sqrt
        (zra, zrb) = ( (c - s).ceil, (c + s).floor)
        if ((x + y).mod(2)) == 0:
          if zra.mod(2) != 0: zra += (if zra <= c:1 else: -1)
        else:
          if zra.mod(2) == 0: zra += (if zra <= c:1 else: -1)

      for z in countup(zra.int, zrb.int, 2): # save vertex x,y,z
        coords.add(dvec3(x, y, z.float))
  coords
  
proc waterman_poly_org*(radius: float): seq[DVec3] =
  var coords: seq[DVec3]

  let (a, b, c) = (0.0, 0.0, 0.0)
  var s = radius # .sqrt
  let radius2 = s

  let (xra, xrb) = ((a - s).ceil, (a + s).floor)

  var x = xra
  while x <= xrb:
    let r = radius2 - (x - a) * (x - a)
    if r < 0:
      x += 1
      continue

    s = r.sqrt
    let yra = (b - s).ceil
    let yrb = (b + s).floor
    var y = yra

    var (zra, zrb) = (0.0, 0.0)

    while y <= yrb:
      let ry = r - (y - b) * (y - b)
      if ry < 0:
        y += 1
        continue
      #case ry < 0

      if ry == 0 and c == c.floor:
        #case ry=0
        if (x + y + c).mod(2) != 0:
          y += 1
          continue
        else:
          zra = c
          zrb = c

      else:
        # case ry > 0
        s = ry.sqrt
        zra = (c - s).ceil
        zrb = (c + s).floor
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
        coords.add(dvec3(x, y, z))
        z += 2

      y += 1

    x += 1

  coords

proc normalize*(vec:var seq[DVec3])=
  var max = 0.0

  for v in vec: max = max.max(v.x.max(v.y.max(v.z)))
  if max != 0.0:
    for v in vec.mitems: v/=max
