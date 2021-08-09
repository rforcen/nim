# poly_common.nim

import random, sugar, math, tables, sequtils, streams, strutils

type
    Vertex* = array[3, float]
    Color = Vertex
    Vertexes* = seq[Vertex]
    Colors* = seq[Color]
    Face* = seq[int]
    Faces* = seq[Face]

type Polyhedron* = object
    name*: string
    vertex*, colors*, normals*, centers*: Vertexes
    areas*: seq[float]
    faces*: Faces

type Johnsons* = object
    i*: int
    faces*: Faces
    vertex*: Vertexes

# vertex ops

proc cross*(v0, v1: Vertex): Vertex {.inline.} = [(v0[1] * v1[2]) - (v0[2] * v1[
        1]), (v0[2] * v1[0]) - (v0[0] * v1[2]), (v0[0] * v1[1]) - (v0[1] * v1[0])]

proc dot*(v0, v1: Vertex): float {.inline.} = v0[0]*v1[0]+v0[1]*v1[1]+v0[2]*v1[2]
proc distance_squared*(v0, v1: Vertex): float {.inline.} = dot(v0,v1)
proc distance*(v0, v1: Vertex): float {.inline.} = dot(v0, v1).sqrt

proc `+`*(v0, v1: Vertex): Vertex {.inline.} = [v0[0]+v1[0], v0[1]+v1[1], v0[
        2]+v1[2]]
proc `-`*(v0, v1: Vertex): Vertex {.inline.} = [v0[0]-v1[0], v0[1]-v1[1], v0[
        2]-v1[2]]
proc `-`*(v:Vertex) : Vertex = [-v[0], -v[1], -v[2]]
proc `*`*(v0: Vertex, f: float): Vertex {.inline.} = [v0[0]*f, v0[1]*f, v0[2]*f]
proc `/`*(v0: Vertex, c: float): Vertex {.inline.} = [v0[0]/c, v0[1]/c, v0[2]/c]
proc `/=`*(v0: var Vertex, c: float) {.inline.} = 
    v0[0]/=c
    v0[1]/=c
    v0[2]/=c
proc `+=`*(v0: var Vertex, v1: Vertex) {.inline.} = 
    v0[0]+=v1[0]
    v0[1]+=v1[1]
    v0[2]+=v1[2]

proc `-`*(vs:var Vertexes) : Vertexes = 
    for v in vs.mitems: v = -v

proc max_abs*(v:Vertex):float = v[0].abs.max(v[1].abs.max(v[2].abs))
proc normal*(v0, v1, v2: Vertex): Vertex {.inline.} = cross(v1 - v0, v2 - v1)

proc unit*(v: Vertex): Vertex {.inline.} =
    if v == [0.0, 0.0, 0.0]: v
    else: v / dot(v, v).sqrt

proc centroid*(p: Polyhedron, face: Face): Vertex =
    var centroid: Vertex # calc centroid of face
    for ic in face: centroid += p.vertex[ic]
    centroid / face.len.float

proc midpoint*( vec1, vec2 : Vertex) : Vertex = (vec1 + vec2) / 2.0

proc tween*(v1, v2 : Vertex, t : float) : Vertex  =
    (v1 * (1.0 - t) ) + (v2 * t)

proc oneThird*(v1, v2 : Vertex) : Vertex =
    tween(v1, v2, 1.0 / 3.0)

proc intersect*(set1, set2, set3 : Face) : int = 
  for s1 in set1:
    for s2 in set2:
      if s1 == s2:
        for s3 in set3:
          if s1 == s3: return s1
  -1  # empty intersection


proc random_pallete*(n: int): Colors =
    func hsl2rgb(h, s, l: float): Color =
        func hue2rgb(p, q, pt: float): float =
            var t = pt
            if t < 0.0: t+=1.0
            if t > 1.0: t-=1.0
            if t < 1.0 / 6.0: return p + (q - p) * 6.0 * t
            if t < 1.0 / 2.0: return q
            if t < 2.0 / 3.0: return p + (q - p) * (2.0 / 3.0 - t) * 6.0
            p

        var r, g, b: float

        if s == 0.0:
            (r, g, b) = (l, l, l) # acromatic
        else:
            let
                q = if l < 0.5: l * (1.0 + s) else: l + s - l * s
                p = 2.0 * l - q
            r = hue2rgb(p, q, h + 1.0 / 3.0)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1.0 / 3.0)
        return [r, g, b]

    proc random_color(): Color = hsl2rgb(rand(1.0), 0.5 * rand(1.0) + 0.3,
            0.5 * rand(1.0) + 0.45)

    randomize()
    collect(newSeq):
        for i in 0..<n:
            random_color()

# fwds
proc normalize*(poly: var Polyhedron): Polyhedron
proc range(left, right: int, inclusive: bool): Face

# Polyhedron methods

proc newPoly*(name: string, vertex: Vertexes, faces: Faces): Polyhedron =
    result = Polyhedron(name: name, vertex: vertex, faces: faces)
    discard result.normalize

proc pyramid*(n: int = 4): Polyhedron =
    let
        theta = (2.0 * PI) / n.float # pie angle
        height = 1.0
    var
        vertex: Vertexes = @[]
        faces: Faces = @[]

    for i in 0..<n: vertex.add([-cos(i.float * theta), -sin(i.float * theta), -0.2])
    vertex.add([0.0, 0.0, height.float]) # apex

    faces.add(range(n - 1, 0, true)) # base
    for i in 0..<n: # n triangular sides
        faces.add(@[i, (i + 1) %% n, n])

    newPoly("Y" & $n, vertex, faces)

proc prism*(n: int): Polyhedron =

    let
        theta = (2.0 * PI) / n.float # pie angle
        h = sin(theta / 2.0)         # half-edge

    var vertexes: Vertexes

    for i in 0..<n: vertexes.add([-cos(i.float * theta), -sin(i.float * theta), -h])
    for i in 0..<n: vertexes.add([-cos(i.float * theta), -sin(i.float * theta), h])
    # # vertex #'s 0 to n-1 around one face, vertex #'s n to 2n-1 around other

    var faces: Faces
    faces.add(range(n - 1, 0, true))
    faces.add(range(n, 2 * n, false))
    for i in 0..<n: faces.add(@[i, (i + 1) %% n, ((i + 1) %% n) + n, i + n])

    newPoly("P" & $n, vertexes, faces)

proc antiprism*(n: int): Polyhedron =

    var
        theta = (2.0 * PI) / n.float # pie angle
        h = sqrt(1.0 - (4.0 / ((4.0 + (2.0 * cos(theta / 2.0))) - (2.0 * cos(theta)))))
        r = sqrt(1.0 - (h * h))
        f = sqrt((h * h) + pow(r * cos(theta / 2.0), 2.0))

    # correction so edge midpoints (not vertexes) on unit sphere
    r = -r / f
    h = -h / f

    var vertexes: Vertexes

    for i in 0..<n: vertexes.add([r * cos(i.float * theta), r * sin(i.float *
            theta), h])
    for i in 0..<n: vertexes.add([r * cos((i.float + 0.5) * theta), r * sin((
            i.float + 0.5) * theta), -h])

    var faces: Faces
    faces.add(range(n - 1, 0, true))
    faces.add(range(n, (2 * n) - 1, true)) # top
    for i in 0..<n:
        # 2n triangular sides
            faces.add(@[i, (i + 1) %% n, i + n])
            faces.add(@[i, i + n, ((((n + i) - 1) %% n) + n)])

    newPoly("A" & $n, vertexes, faces)

proc cupola*(n: int, alpha, height: float): Polyhedron =

    if n < 2: return Polyhedron()

    let
        s = 1.0 # alternative face/height scaling
        rb = s / 2.0 / sin(PI / 2.0 / n.float)
        rt = s / 2.0 / sin(PI / n.float)

    var vheight = height

    if height == 0:
        vheight = (rb - rt)
    # set correct height for regularity for n=3,4,5
    if n >= 3 and n <= 5:
        vheight = s * sqrt(1.0 - 1.0 / 4.0 / sin(PI / n.float) / sin(PI / n.float))
    # init 3N vertexes
    var vertexes = newSeq[Vertex](n * 3)

    # fill vertexes
    for i in 0..<n:
        vertexes[i * 2] = [rb * cos(PI * (2.0 * i.float) / n.float + PI / 2.0 / n.float + alpha),
                                    rb * sin(PI * (2.0 * i.float) / n.float +
                                            PI / 2.0 / n.float + alpha), 0.0]
        vertexes[2 * i + 1] = [rb * cos(PI * (2.0 * i.float + 1.0) / n.float + PI / 2.0 / n.float - alpha),
                                        rb * sin(PI * (2.0 * i.float + 1) /
                                                n.float + PI / 2.0 / n.float -
                                                alpha), 0.0]
        vertexes[2 * n + i] = [rt * cos(2.0 * PI * i.float / n.float), rt * sin(
                2.0 * PI * i.float / n.float), vheight]


    var faces: Faces
    faces.add(range(2 * n - 1, 0, true))
    faces.add(range(2 * n, 3 * n - 1, true)) # base, top
    for i in 0..<n:
        # n triangular sides and n square sides
            faces.add(@[(2 * i + 1) %% (2 * n), (2 * i + 2) %% (2 * n), 2 * n +
                    (i + 1) %% n])
            faces.add(@[2 * i, (2 * i + 1) %% (2 * n), 2 * n + (i + 1) %% n, 2 *
                    n + i])


    newPoly("U" & $n, vertexes, faces)

proc anticupola*(n: int, alpha, height: float): Polyhedron =
    if n < 3: return Polyhedron()

    let
        s = 1.0 # alternative face/height scaling
        rb = s / 2.0 / sin(PI / 2.0 / n.float)
        rt = s / 2.0 / sin(PI / n.float)
    var vheight = height

    if height == 0: vheight = (rb - rt)

    # init 3N vertexes
    var vertexes = newSeq[Vertex](n * 3)

    # fill vertexes
    for i in 0..<n:
        vertexes[2 * i] = [rb * cos(PI * (2.0 * i.float) / n.float + alpha),
                rb * sin(PI * (2 * i.float) / n.float + alpha), 0.0]
        vertexes[2 * i + 1] = [rb * cos(PI * (2.0 * i.float + 1.0) / n.float -
                alpha), rb * sin(PI * (2.0 * i.float + 1.0) / n.float - alpha), 0.0]
        vertexes[2 * n + i] = [rt * cos(2.0 * PI * i.float / n.float), rt * sin(
                2.0 * PI * i.float / n.float), vheight]

    # create faces
    var faces: Faces
    faces.add(range(2 * n - 1, 0, true))
    faces.add(range(2 * n, 3 * n - 1, true)) # base
    for i in 0..<n: # n triangular sides and n square sides
        faces.add(@[(2 * i) %% (2 * n), (2 * i + 1) %% (2 * n), 2 * n + (i) %% n])
        faces.add(@[2 * n + (i + 1) %% n, (2 * i + 1) %% (2 * n), (2 * i + 2) %%
                (2 * n)])
        faces.add(@[2 * n + (i + 1) %% n, 2 * n + (i) %% n, (2 * i + 1) %% (2 * n)])


    newPoly("U" & $n, vertexes, faces)

# aux
proc range(left, right: int, inclusive: bool): Face =
    if left < right: toSeq(left .. (if inclusive: right else: right-1))
    else: toSeq(countdown(left, if inclusive: right else: right+1))

proc normalize*(poly: var Polyhedron): Polyhedron =
    var max = poly.vertex[0][0]
    for v in poly.vertex: max = max(max, max_abs(v))

    if max != 0.0:
        for v in poly.vertex.mitems:
            v /= max
    poly

# calc poly terms
proc calc_normals*(p: Polyhedron):Vertexes=
    collect(newSeq):
        for face in p.faces:
            normal(p.vertex[face[0]], p.vertex[face[1]], p.vertex[face[2]])

proc calc_avg_normals*(p:Polyhedron):Vertexes=
    collect(newSeq):
        for face in p.faces:
            var
                normalV: Vertex
                v1 = p.vertex[face[^2]]
                v2 = p.vertex[face[^1]]

            for ic in face: # running sum of normal vectors
                let v3 = p.vertex[ic]
                normalV += normal(v1, v2, v3)
                v1 = v2
                v2 = v3 # shift over one

            unit(normalV)

proc calc_areas*(p:Polyhedron):seq[float]=
    var max_area = -1.0
    var areas = collect(newSeq):
        for index, (face, normal) in zip(p.faces, p.normals):
            var
                vsum: Vertex
                v1 = p.vertex[face[^2]]
                v2 = p.vertex[face[^1]]

            for ix in face:
                vsum += cross(v1, v2)
                v1 = v2
                v2 = p.vertex[ix];

            let area = abs(dot(p.normals[index], vsum)) / 2.0
            max_area = max_area.max(area)
            area

    if max_area!=0.0: # scale to max
        for a in areas.mitems: a /= max_area
    areas

proc calc_centers*(p:Polyhedron):Vertexes=
    collect(newSeq):
        for face in p.faces:
            var fcenter: Vertex # average vertex coords
            for ic in face: fcenter += p.vertex[ic]
            fcenter / face.len.float #  return face - ordered array  of  centroids

# set poly 
proc set_normals*(p: var Polyhedron) =
    p.normals = p.calc_normals

proc set_avg_normals*(p: var Polyhedron) =
    p.normals = p.calc_avg_normals

proc set_areas*(p: var Polyhedron) =
    if p.normals.len == 0: p.set_normals # normals required
    p.areas = p.calc_areas

proc set_colors*(p: var Polyhedron) = # per areas
    const MAX_COLORS=1000.0
    func sigfigs(x: float): int = (x * MAX_COLORS).floor.int

    proc gen_color_dict(areas: seq[float]): Table[int, Vertex] =
        let pallette = random_pallete(40)

        var color_dict: Table[int, Vertex] # color dict<sigfigs, pallette>

        for a in areas:
            discard color_dict.hasKeyOrPut(sigfigs(a), pallette[color_dict.len %% pallette.len])
        color_dict

    if p.areas.len == 0: p.set_areas # areas required
    let color_dict = gen_color_dict(p.areas)
    # echo p.areas

    p.colors = collect(newSeq):
        for a in p.areas:
            color_dict[sigfigs(a)]

proc set_centers*(p: var Polyhedron) = # per face
    p.centers = p.calc_centers
    
# getters
proc get_normals*(p: Polyhedron): Vertexes =
    if p.normals.len == 0: p.calc_normals
    else: p.normals

proc get_centers*(p: Polyhedron): seq[Vertex] =
    if p.centers.len == 0: p.calc_centers
    else: p.centers

proc get_areas*(p: Polyhedron): seq[float] =
    if p.areas.len == 0: p.calc_areas
    else: p.areas

proc simplify*(poly:Polyhedron):Polyhedron=
    # used vertexes in faces
    var
        old_new : Table[int, int] # table[old index, new seq index]

    let used_vertex = collect(newSeq):
        for face in poly.faces: # used vertex
            for ix in face:
                if not old_new.contains(ix):
                    old_new[ix]=old_new.len
                    poly.vertex[ix]
                    
    var faces=poly.faces
    for face in faces.mitems:
        for ix in face.mitems: 
            ix = old_new[ix]

    Polyhedron(name:poly.name, vertex:used_vertex, faces:faces)

# wrl
proc write_wrl*(poly: var Polyhedron) =
    poly.set_normals
    poly.set_areas    
    poly.set_colors

    # create face index / vertex index hash
    var tfv:Table[int,int]
    for iface, face in poly.faces: # find iv in faces
        for ix in face:
            tfv[ix]=iface

    var f = newFileStream(poly.name & ".wrl", fmWrite)

    if not f.isNil:
        f.write("""
#VRML V2.0 utf8 

# Polyhedron : ·fname·       

# lights on
DirectionalLight {  direction -.5 -1 0   intensity 1  color 1 1 1 }
DirectionalLight {  direction  .5  1 0   intensity 1  color 1 1 1 }
           
Shape {
    # default material
    appearance Appearance {
        material Material { }
    }
    geometry IndexedFaceSet {
        
        coord Coordinate {
            point [
""".replace("·fname·", poly.name))

        # vertex
        for p in poly.vertex: f.write(p[0], " ", p[1], " ", p[2], "\n")


        f.write(
            """]
        }
        color Color {
            color [
            """)
        # colors are per face -> per vertex
        for iface, face in poly.faces: # find iv in faces
            let c = poly.colors[iface]
            for ix in face: f.write(c[0], " ", c[1], " ", c[2], "\n")

        f.write(
            """]
        }
        normal Normal {
            vector [
        """)

        #  normals per vertex
        for iface, face in poly.faces: # find iv in faces
            let c = poly.normals[iface]
            for ix in face: f.write(c[0], " ", c[1], " ", c[2], "\n")
               
        f.write(
            """]
        }
        coordIndex [
            """)
        #  faces
        for face in poly.faces:
            for ix in face: f.write($ix, " ")
            f.write("-1,\n")

        f.write(
            """]
        colorPerVertex FALSE
        convex TRUE
        solid TRUE
    }
}""")
        f.close()
const
    Tetrahedron* = Polyhedron(
        name: "T",
        vertex: @[[1.0, 1.0, 1.0], [1.0, -1.0, -1.0], [-1.0, 1.0, -1.0], [-1.0,
                -1.0, 1.0]],
        faces: @[@[0, 1, 2], @[0, 2, 3], @[0, 3, 1], @[1, 3, 2]])
    Cube* = Polyhedron(
        name: "C",
        vertex: @[[1.0, 1.0, 1.0], [-1.0, 1.0, 1.0], [-1.0, -1.0, 1.0], [1.0,
                -1.0, 1.0], [1.0, -1.0, -1.0], [1.0, 1.0, -1.0], [-1.0, 1.0,
                -1.0], [-1.0, -1.0, -1.0]],
        faces: @[@[3, 0, 1, 2], @[3, 4, 5, 0], @[0, 5, 6, 1], @[1, 6, 7, 2], @[
                2, 7, 4, 3], @[5, 4, 7, 6]])
    Hexahedron* = Cube
    Icosahedron* = Polyhedron(
        name: "I",
        vertex: @[[0.0, 0.0, 1.176], [1.051, 0.0, 0.526], [0.324, 1.0, 0.525], [
                -0.851, 0.618, 0.526], [-0.851, -0.618, 0.526], [0.325, -1.0,
                0.526], [0.851, 0.618, -0.526], [0.851, -0.618, -0.526], [
                -0.325, 1.0, -0.526], [-1.051, 0.0, -0.526], [-0.325, -1.0,
                -0.526], [0.0, 0.0, -1.176]],
        faces: @[@[0, 1, 2], @[0, 2, 3], @[0, 3, 4], @[0, 4, 5], @[0, 5, 1], @[
                1, 5, 7], @[1, 7, 6], @[1, 6, 2], @[2, 6, 8], @[2, 8, 3], @[3,
                8, 9], @[3, 9, 4], @[4, 9, 10], @[4, 10, 5], @[5, 10, 7], @[6,
                7, 11], @[6, 11, 8], @[7, 10, 11], @[8, 11, 9], @[9, 11, 10]])
    Octahedron* = Polyhedron(
        name: "O",
        vertex: @[[0.0, 0.0, 1.414], [1.414, 0.0, 0.0], [0.0, 1.414, 0.0], [
                -1.414, 0.0, 0.0], [0.0, -1.414, 0.0], [0.0, 0.0, -1.414]],
        faces: @[@[0, 1, 2], @[0, 2, 3], @[0, 3, 4], @[0, 4, 1], @[1, 4, 5], @[
                1, 5, 2], @[2, 5, 3], @[3, 5, 4]])
    Dodecahedron* = Polyhedron(
        name: "D",
        vertex: @[[0.0, 0.0, 1.07047], [0.713644, 0.0, 0.797878], [-0.356822,
                0.618, 0.797878], [-0.356822, -0.618, 0.797878], [0.797878,
                0.618034, 0.356822], [0.797878, -0.618, 0.356822], [-0.934172,
                0.381966, 0.356822], [0.136294, 1.0, 0.356822], [0.136294, -1.0,
                0.356822], [-0.934172, -0.381966, 0.356822], [0.934172,
                0.381966, -0.356822], [0.934172, -0.381966, -0.356822], [
                -0.797878, 0.618, -0.356822], [-0.136294, 1.0, -0.356822], [
                -0.136294, -1.0, -0.356822], [-0.797878, -0.618034, -0.356822],
                [0.356822, 0.618, -0.797878], [0.356822, -0.618, -0.797878], [
                -0.713644, 0, -0.797878], [0.0, 0.0, -1.07047]],
        faces: @[@[0, 1, 4, 7, 2], @[0, 2, 6, 9, 3], @[0, 3, 8, 5, 1], @[1, 5,
                11, 10, 4], @[2, 7, 13, 12, 6], @[3, 9, 15, 14, 8], @[4, 10, 16,
                13, 7], @[5, 8, 14, 17, 11], @[6, 12, 18, 15, 9], @[10, 11, 17,
                19, 16], @[12, 13, 16, 19, 18], @[14, 15, 18, 19, 17]])
