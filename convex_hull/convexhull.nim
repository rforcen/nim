# convex hull
# nim cpp --passL:libconvexhull.a --passC:-std=c++11 convexhull.nim

# void convex_hull(size_t n_vertices, double *vertices, size_t *n_faces, size_t *n_vertices, int **o_faces, double **o_vertices)
proc convex_hull*(n_vertices: csize_t, vertices: ptr cdouble,
        n_faces: ptr csize_t, nh_vertices: ptr csize_t, o_faces: ptr ptr cint,
        o_vertices: ptr ptr cdouble) {.importc, header: "convexhull.h".}
proc free_ch*(o_faces: ptr cint, o_vertices: ptr cdouble) {.importc,
        header: "convexhull.h".}

import waterman

template loop(body: untyped): typed =
  while true:
    body

template until(cond: typed): typed =
  if cond: break


proc wp_ch(rad: float): (seq[seq[int32]], seq[float]) =
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
    vertices = cast[ptr array[max_items, float]](o_vertices)[0..<n_vertices]
    face_list = cast[ptr array[max_items, int32]](o_faces)[0..<n_faces]

  free_ch(o_faces, o_vertices)

  echo face_list
  # echo vertices

  # convert face_list to faces[[]]
  var
    faces: seq[seq[int32]]
    i = 0

  while true:
    faces.add(face_list[i+1..i+face_list[i]])
    i+=face_list[i]+1
    if face_list[i]+i >= face_list.high: break

  # check
  for face in faces:
      for ix in face:
          let v=vertices[ix]
  

  (faces, vertices)

when isMainModule:
  let (f, v) = wp_ch(90)

  echo f[0..10]
  echo v[0..15]

  echo "faces/vertex:", f.len, "/", v.len

