# waterman poly

import math, sugar

# ffi 
proc convex_hull(n_vertices: csize_t, vertices: ptr cdouble,
        n_faces: ptr csize_t, nh_vertices: ptr csize_t, o_faces: ptr ptr cint,
        o_vertices: ptr ptr cdouble) {.importc, header: "convexhull.h".}
proc free_ch(o_faces: ptr cint, o_vertices: ptr cdouble) {.importc,
        header: "convexhull.h".}

# loop / until
template loop*(body: untyped) =
  while true:
    body

template until*(cond: typed) =
  if cond: break

# c_int def 
when sizeof(cint)==8: 
  type c_int = int64
when sizeof(cint)==4: 
  type c_int = int32
when sizeof(cint)==2:
  type c_int = int16

type
    Vertex* = array[3, float]
    Vertexes* = seq[Vertex]
    Face* = seq[int]
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


proc waterman*(rad: float): (Faces, Vertexes) =
  const max_items = 0xfffffff

  let wp = waterman_poly(rad)

  var
    n_faces: csize_t = 0
    n_vertices: csize_t = 0
    o_faces: ptr cint = nil
    o_vertices: ptr cdouble = nil

  # echo "waterman n.vertex:", wp.len #, " vertices:", wp

  convex_hull(wp.len.csize_t, cast[ptr cdouble](wp[0].unsafeAddr),
          n_faces.unsafeAddr, n_vertices.unsafeAddr, o_faces.unsafeAddr,
          o_vertices.unsafeAddr)

  # echo "n.faces:", n_faces, " n_vertex:", n_vertices

  let # slice faces, vertices
    vertices = cast[ptr array[max_items, Vertex]](o_vertices)[0..<n_vertices]
    face_list = cast[ptr array[max_items, c_int]](o_faces)[0..<n_faces]

  free_ch(o_faces, o_vertices)

  # echo face_list
  # echo vertices

  # convert face_list to Faces
  var
    faces: Faces
    (i, n) = (0, face_list[0])

  proc fl2face(fl:seq[c_int]):Face=
    collect(newSeq):
      for f in fl: f.int

  loop:
    faces.add( fl2face(face_list[i+1..i+n]) )
    i+=n+1
    n = face_list[i]
    until n+i >= face_list.high
  faces.add( fl2face(face_list[i+1..i+n]) )

  # echo face_list[^15..^1], faces[^3..^1]

  # check
  for face in faces:
    for ix in face:
      for v in vertices[ix]:
        discard v  

  (faces, vertices)


when isMainModule:
  for i in 10..500:
    let (f, v) = waterman(i.float)
    echo i," faces/vertex:", f.len, "/", v.len
