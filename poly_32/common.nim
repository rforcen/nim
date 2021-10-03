# poly_common.nim

import random, sugar, math, tables, sequtils, strformat, streams, strutils
import vertex
import par, threadpool

type
    Color* = Vertex
    Vertexes* = seq[Vertex]
    Colors* = seq[Color]
    Face* = seq[int32]
    Faces* = seq[Face]

type Polyhedron* = object
    name*: string
    vertex*, colors*, normals*, centers*: Vertexes
    areas*: seq[float32]
    faces*: Faces

type Johnsons* = object
    i*: int32
    faces*: Faces
    vertex*: Vertexes


proc `-`*(vs: var Vertexes): Vertexes =
    for v in vs.mitems: v = -v
    vs

# when to do mt
proc do_serial(p: Polyhedron): bool = p.faces.len < 500

proc centroid*(p: Polyhedron, face: Face): Vertex =
    var centroid: Vertex # calc centroid of face
    for ic in face: centroid += p.vertex[ic]
    centroid / face.len.float32

proc intersect*(set1, set2, set3: Face): int32 =
    for s1 in set1:
        for s2 in set2:
            if s1 == s2:
                for s3 in set3:
                    if s1 == s3: return s1
    -1 # empty intersection


proc random_pallete*(n: int32): Colors =
    func hsl2rgb(h, s, l: float32): Color =
        func hue2rgb(p, q, pt: float32): float32 =
            var t = pt
            if t < 0.0: t+=1.0
            if t > 1.0: t-=1.0
            if t < 1.0 / 6.0: return p + (q - p) * 6.0 * t
            if t < 1.0 / 2.0: return q
            if t < 2.0 / 3.0: return p + (q - p) * (2.0 / 3.0 - t) * 6.0
            p

        var r, g, b: float32

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
proc range(left, right: int32, inclusive: bool): Face

# Polyhedron methods

proc newPoly*(name: string, vertex: Vertexes, faces: Faces): Polyhedron =
    result = Polyhedron(name: name, vertex: vertex, faces: faces)
    discard result.normalize

proc pyramid*(n: int32 = 4): Polyhedron =
    let
        theta = (2.0'f32 * PI) / n.float32 # pie angle
        height = 1.0'f32
    var
        vertex: Vertexes = @[]
        faces: Faces = @[]

    for i in 0..<n: vertex.add([-cos(i.float32 * theta).float32, -sin(i.float32 * theta).float32, -0.2])
    vertex.add([0.0'f32, 0.0'f32, height.float32]) # apex

    faces.add(range(n - 1, 0, true)) # base
    for i in 0..<n: # n triangular sides
        faces.add(@[i, (i + 1) %% n, n])

    newPoly("Y" & $n, vertex, faces)

proc prism*(n: int32): Polyhedron =

    let
        theta = (2.0 * PI) / n.float32 # pie angle
        h = sin(theta / 2.0)         # half-edge

    var vertexes: Vertexes

    for i in 0..<n: vertexes.add([-cos(i.float32 * theta).float32, -sin(i.float32 * theta).float32, -h])
    for i in 0..<n: vertexes.add([-cos(i.float32 * theta).float32, -sin(i.float32 * theta).float32, h])
    # # vertex #'s 0 to n-1 around one face, vertex #'s n to 2n-1 around other

    var faces: Faces
    faces.add(range(n - 1, 0, true))
    faces.add(range(n, 2 * n, false))
    for i in 0..<n: faces.add(@[i, (i + 1) %% n, ((i + 1) %% n) + n, i + n])

    newPoly("P" & $n, vertexes, faces)

proc antiprism*(n: int32): Polyhedron =

    var
        theta:float32 = (2.0 * PI) / n.float32 # pie angle
        h:float32 = sqrt(1.0 - (4.0 / ((4.0 + (2.0 * cos(theta / 2.0))) - (2.0 * cos(theta)))))
        r:float32 = sqrt(1.0 - (h * h))
        f:float32 = sqrt((h * h) + pow(r * cos(theta / 2.0), 2.0))

    # correction so edge midpoints (not vertexes) on unit sphere
    r = -r / f
    h = -h / f

    var vertexes: Vertexes

    for i in 0..<n: vertexes.add([r * cos(i.float32 * theta), r * sin(i.float32 *
            theta), h])
    for i in 0..<n: vertexes.add([r * cos((i.float32 + 0.5'f32) * theta), r * sin((
            i.float32 + 0.5'f32) * theta).float32, -h])

    var faces: Faces
    faces.add(range(n - 1, 0, true))
    faces.add(range(n, (2 * n) - 1, true)) # top
    for i in 0..<n:
        # 2n triangular sides
            faces.add(@[i, (i + 1) %% n, i + n])
            faces.add(@[i, i + n, ((((n + i) - 1) %% n) + n)])

    newPoly("A" & $n, vertexes, faces)

proc cupola*(n: int32, alpha, height: float32): Polyhedron =

    if n < 2: return Polyhedron()

    let
        s:float32 = 1.0'f32 # alternative face/height scaling
        rb:float32 = s / 2.0 / sin(PI / 2.0 / n.float32)
        rt:float32 = s / 2.0 / sin(PI / n.float32)

    var vheight = height

    if height == 0:
        vheight = (rb - rt)
    # set correct height for regularity for n=3,4,5
    if n >= 3 and n <= 5:
        vheight = s * sqrt(1.0 - 1.0 / 4.0 / sin(PI / n.float32) / sin(PI / n.float32))
    # init 3N vertexes
    var vertexes = newSeq[Vertex](n * 3)

    # fill vertexes
    for i in 0..<n:
        vertexes[i * 2] = [rb * cos(PI * (2.0'f32 * i.float32) / n.float32 + PI / 2.0'f32 / n.float32 + alpha).float32,
                                    rb * sin(PI * (2.0 * i.float32).float32 / n.float32 +
                                            PI / 2.0 / n.float32 + alpha), 0.0]
        vertexes[2 * i + 1] = [rb * cos(PI * (2.0 * i.float32 + 1.0) / n.float32 + PI / 2.0 / n.float32 - alpha).float32,
                                        rb * sin(PI * (2.0 * i.float32 + 1) /
                                                n.float32 + PI / 2.0 / n.float32 -
                                                alpha), 0.0]
        vertexes[2 * n + i] = [rt * cos(2.0 * PI * i.float32 / n.float32).float32, rt * sin(
                2.0 * PI * i.float32 / n.float32), vheight]


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

proc anticupola*(n: int32, alpha, height: float32): Polyhedron =
    if n < 3: return Polyhedron()

    let
        s:float32 = 1.0 # alternative face/height scaling
        rb:float32 = s / 2.0 / sin(PI / 2.0 / n.float32)
        rt:float32 = s / 2.0 / sin(PI / n.float32)
    var vheight = height

    if height == 0: vheight = (rb - rt)

    # init 3N vertexes
    var vertexes = newSeq[Vertex](n * 3)

    # fill vertexes
    for i in 0..<n:
        vertexes[2 * i] = [rb * cos(PI * (2.0'f32 * i.float32) / n.float32 + alpha).float32,
                rb * sin(PI * (2 * i.float32) / n.float32 + alpha), 0.0'f32]
        vertexes[2 * i + 1] = [rb * cos(PI * (2.0 * i.float32 + 1.0) / n.float32 -
                alpha).float32, rb * sin(PI * (2.0 * i.float32 + 1.0) / n.float32 - alpha), 0.0]
        vertexes[2 * n + i] = [rt * cos(2.0 * PI * i.float32 / n.float32).float32, rt * sin(
                2.0 * PI * i.float32 / n.float32), vheight]

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
proc range(left, right: int32, inclusive: bool): Face =
    if left < right: toSeq(left .. (if inclusive: right else: right-1))
    else: toSeq(countdown(left, if inclusive: right else: right+1))

proc normalize*(poly: var Polyhedron): Polyhedron =
    if poly.vertex.len > 0:
        var max = poly.vertex[0][0]
        for v in poly.vertex: max = max(max, max_abs(v))

        if max != 0.0:
            for v in poly.vertex.mitems:
                v /= max
    poly

# calc poly terms

proc normal_face(p: Polyhedron, normals: var Vertexes, rng: Slice[int32]) =
    for i in rng:
        let face = p.faces[i]
        normals[i] = if face.len > 2: normal(p.vertex[face[0]], p.vertex[face[1]], p.vertex[face[2]]) else: zeroVertex

proc calc_normals*(p: Polyhedron): Vertexes =
    if p.do_serial:
        result = collect(newSeq):
            for face in p.faces:
                if face.len > 2: normal(p.vertex[face[0]], p.vertex[face[1]],
                        p.vertex[face[2]])
                else: zeroVertex
    else: # mt
        var normals: Vertexes = newSeq[Vertex](p.faces.len)
        parallel:
            for r in par_ranges(normals):
                spawn p.normal_face(normals, r)
        result = normals

proc calc_avg_normals*(p: Polyhedron): Vertexes =
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

proc face_area(p: Polyhedron, areas: var seq[float32], r: Slice[int32]) =
    for i in r:
        let
            face = p.faces[i]
            normal = p.normals[i]

        areas[i] =
            if face.len > 2:
                var
                    vsum: Vertex
                    v1 = p.vertex[face[^2]]
                    v2 = p.vertex[face[^1]]

                for ix in face:
                    vsum += cross(v1, v2)
                    v1 = v2
                    v2 = p.vertex[ix];

                abs(dot(normal, vsum)) / 2.0
            else: 0.0'f32

proc calc_areas*(p: Polyhedron): seq[float32] =
    proc face_area(i: int32): float32 =
        let
            face = p.faces[i]
            normal = p.normals[i]

        if face.len > 2:
            var
                vsum: Vertex
                v1 = p.vertex[face[^2]]
                v2 = p.vertex[face[^1]]

            for ix in face:
                vsum += cross(v1, v2)
                v1 = v2
                v2 = p.vertex[ix];

            abs(dot(normal, vsum)) / 2.0
        else: 0.0'f32

    var max_area = 0.0'f32
    if p.do_serial:
        result = collect(newSeq):
            for i in 0..<p.faces.len:
                let area = face_area(i.int32)
                max_area = max_area.max(area)
                area
    else: # mt
        result = newSeq[float32](p.faces.len)
        parallel:
            for r in par_ranges(result):
                spawn p.face_area(result, r)
        for area in result: max_area = max_area.max(area) # calc max_area

    if max_area != 0: # scale to max
        for a in result.mitems: a /= max_area

proc face_center(p: Polyhedron, centers: var Vertexes, r: Slice[int32]) =
    for i in r:
        let face = p.faces[i]
        var fcenter: Vertex # average vertex coords
        for ic in face: fcenter += p.vertex[ic]
        centers[i] = fcenter / face.len.float32 #  return face - ordered array  of  centroids

proc calc_centers*(p: Polyhedron): Vertexes =
    proc face_center(i: int): Vertex =
        let face = p.faces[i]
        var fcenter: Vertex # average vertex coords
        for ic in face: fcenter += p.vertex[ic]
        fcenter / face.len.float32 #  return face - ordered array  of  centroids
   
    if p.do_serial:
        collect(newSeq):
            for i in 0..<p.faces.len:
                face_center(i.int32)
    else: #mt
        var centers: Vertexes = newSeq[Vertex](p.faces.len)
        parallel:
            for r in par_ranges(centers.len.int32):
                spawn p.face_center(centers, r)
        centers


proc check*(p: Polyhedron): bool =
    for face in p.faces:
        if face.len < 3: return false
    true

proc `$`*(p: Polyhedron): string =
    fmt("{p.name}: {p.faces.len} faces, {p.vertex.len} vertex")

# set poly
proc set_normals*(p: var Polyhedron) =
    p.normals = p.calc_normals

proc set_avg_normals*(p: var Polyhedron) =
    p.normals = p.calc_avg_normals

proc set_areas*(p: var Polyhedron) =
    if p.normals.len == 0: p.set_normals # normals required
    p.areas = p.calc_areas

proc set_colors*(p: var Polyhedron) = # per areas
    const MAX_COLORS = 1000.0
    func sigfigs(x: float32): int32 {.inline.} = (x * MAX_COLORS).int32

    proc gen_color_dict(areas: seq[float32]): Table[int32, Vertex] =
        let pallette = random_pallete(40)

        var color_dict: Table[int32, Vertex] # color dict<sigfigs, pallette>

        for a in areas:
            discard color_dict.hasKeyOrPut(sigfigs(a), pallette[
                    color_dict.len %% pallette.len])
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

proc get_areas*(p: Polyhedron): seq[float32] =
    if p.areas.len == 0: p.calc_areas
    else: p.areas

proc simplify*(poly: var Polyhedron) =
    # used vertexes in faces
    var old_new: Table[int32, int32] # table[old index, new seq index]

    let used_vertex : Vertexes = collect(newSeq):
        for face in poly.faces: # used vertex
            for ix in face:
                if not old_new.contains(ix):
                    old_new[ix] = old_new.len.int32
                    poly.vertex[ix.int]

    for face in poly.faces.mitems:
        for ix in face.mitems:
            ix = old_new[ix]

    poly.vertex=used_vertex

# wrl
proc write_wrl*(poly: var Polyhedron) =
    poly.set_normals
    poly.set_areas
    poly.set_colors


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
        vertex: @[[1.0'f32, 1.0, 1.0], [1.0'f32, -1.0, -1.0], [-1.0'f32, 1.0, -1.0], [-1.0'f32,
                -1.0, 1.0]],
        faces: @[@[0'i32, 1, 2], @[0'i32, 2, 3], @[0'i32, 3, 1], @[1'i32, 3, 2]])
    Cube* = Polyhedron(
        name: "C",
        vertex: @[[1.0'f32, 1.0, 1.0], [-1.0'f32, 1.0, 1.0], [-1.0'f32, -1.0, 1.0], [1.0'f32,
                -1.0, 1.0], [1.0'f32, -1.0, -1.0], [1.0'f32, 1.0, -1.0], [-1.0'f32, 1.0,
                -1.0], [-1.0'f32, -1.0, -1.0]],
        faces: @[@[3'i32, 0, 1, 2], @[3'i32, 4, 5, 0], @[0'i32, 5, 6, 1], @[1'i32, 6, 7, 2], @[
                2'i32, 7, 4, 3], @[5'i32, 4, 7, 6]])
    Hexahedron* = Cube
    Icosahedron* = Polyhedron(
        name: "I",
        vertex: @[[0.0'f32, 0.0, 1.176], [1.051'f32, 0.0, 0.526], [0.324'f32, 1.0, 0.525], [
                -0.851'f32, 0.618, 0.526], [-0.851'f32, -0.618, 0.526], [0.325'f32, -1.0,
                0.526], [0.851'f32, 0.618, -0.526], [0.851'f32, -0.618, -0.526], [
                -0.325'f32, 1.0, -0.526], [-1.051'f32, 0.0, -0.526], [-0.325'f32, -1.0,
                -0.526], [0.0'f32, 0.0, -1.176]],
        faces: @[@[0'i32, 1, 2], @[0'i32, 2, 3], @[0'i32, 3, 4], @[0'i32, 4, 5], @[0'i32, 5, 1], @[
                1'i32, 5, 7], @[1'i32, 7, 6], @[1'i32, 6, 2], @[2'i32, 6, 8], @[2'i32, 8, 3], @[3'i32,
                8, 9], @[3'i32, 9, 4], @[4'i32, 9, 10], @[4'i32, 10, 5], @[5'i32, 10, 7], @[6'i32,
                7, 11], @[6'i32, 11, 8], @[7'i32, 10, 11], @[8'i32, 11, 9], @[9'i32, 11, 10]])
    Octahedron* = Polyhedron(
        name: "O",
        vertex: @[[0.0'f32, 0.0, 1.414], [1.414'f32, 0.0, 0.0], [0.0'f32, 1.414, 0.0], [
                -1.414'f32, 0.0, 0.0], [0.0'f32, -1.414, 0.0], [0.0'f32, 0.0, -1.414]],
        faces: @[@[0'i32, 1, 2], @[0'i32, 2, 3], @[0'i32, 3, 4], @[0'i32, 4, 1], @[1'i32, 4, 5], @[
                1'i32, 5, 2], @[2'i32, 5, 3], @[3'i32, 5, 4]])
    Dodecahedron* = Polyhedron(
        name: "D",
        vertex: @[[0.0'f32, 0.0, 1.07047], [0.713644'f32, 0.0, 0.797878], [-0.356822'f32,
                0.618, 0.797878], [-0.356822'f32, -0.618, 0.797878], [0.797878'f32,
                0.618034, 0.356822], [0.797878'f32, -0.618, 0.356822], [-0.934172'f32,
                0.381966, 0.356822], [0.136294'f32, 1.0, 0.356822], [0.136294'f32, -1.0,
                0.356822], [-0.934172'f32, -0.381966, 0.356822], [0.934172'f32,
                0.381966, -0.356822], [0.934172'f32, -0.381966, -0.356822], [
                -0.797878'f32, 0.618, -0.356822], [-0.136294'f32, 1.0, -0.356822], [
                -0.136294'f32, -1.0, -0.356822], [-0.797878'f32, -0.618034, -0.356822],
                [0.356822'f32, 0.618, -0.797878], [0.356822'f32, -0.618, -0.797878], [
                -0.713644'f32, 0, -0.797878], [0.0'f32, 0.0, -1.07047]],
        faces: @[@[0'i32, 1, 4, 7, 2], @[0'i32, 2, 6, 9, 3], @[0'i32, 3, 8, 5, 1], @[1'i32, 5,
                11, 10, 4], @[2'i32, 7, 13, 12, 6], @[3'i32, 9, 15, 14, 8], @[4'i32, 10, 16,
                13, 7], @[5'i32, 8, 14, 17, 11], @[6'i32, 12, 18, 15, 9], @[10'i32, 11, 17,
                19, 16], @[12'i32, 13, 16, 19, 18], @[14'i32, 15, 18, 19, 17]])

  