# polyhedron conway tr_tab

import algorithm, sequtils, tables
import common, flag, vertex


#[ Kis(N)

 Kis (abbreviated from triakis) transforms an N-sided face into an N-pyramid
 rooted at the same base vertices. only kis n-sided faces, but n==0 means
 kis all. ]#

proc kisN*(p: Polyhedron; n:int=0; apexdist:float=0.1) : Polyhedron =
    const F_TOKEN:int='f'.toToken # greater than max vertexes
    let 
        centers = p.get_centers()
        normals = p.get_normals()
    var 
        flag : Flag
        foundAny = false

    # face map
    for nface, face in p.faces:
        let fname : Int4 = [F_TOKEN, nface, 0,0]
        var v1 = face[^1]

        for v2 in face:
            let iv2 = i4(v2)
            flag.add_vertex(iv2, p.vertex[v2], with_unit=false)

            if face.len == n or n == 0:
                foundAny=true
                flag.add_vertex(fname, centers[nface] + (normals[nface] * apexdist), with_unit=false) # raised center
                flag.add_face(@[i4(v1), iv2, fname])
            else:
                flag.add_face(i4(nface), i4(v1), iv2)

            v1 = v2

    flag.toPolyhedron("k" & (if n==0:"" else: $n) & p.name)

proc ambo*(p:Polyhedron) : Polyhedron =
    if not p.check: return p

    const 
        DUAL='d'.toToken
        ORIG='o'.toToken

    var flag : Flag
        

    for i, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]
        
        for v3 in face:
            let
                m12 = i4_min(v1, v2)
                m23 = i4_min(v2, v3)

            if v1 < v2: # vertices are the midpoints of all edges of original poly
                flag.add_vertex(m12, midpoint(p.vertex[v1], p.vertex[v2]))

            # two new flags:
            flag.add_face(i4(ORIG, i),  m12, m23) # One whose face corresponds to the original f:          
            flag.add_face(i4(DUAL, v2), m23, m12) # Another flag whose face  corresponds to (the truncated) v2:

            # shift over one
            (v1, v2) = (v2, v3)

    
    flag.toPolyhedron("a" & p.name)

proc gyro*(p:Polyhedron) : Polyhedron =
    if not p.check: return p

    const 
        CNTR = 'c'.toToken

    var flag:Flag

    let centers = p.get_centers

    flag.add_vertexes(p.vertex) 

    for i, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]

        flag.add_vertex(i4(CNTR, i), centers[i])

        for v3 in face:
            
            flag.add_vertex(i4(v1, v2), oneThird(p.vertex[v1], p.vertex[v2]), with_unit=false)
            
            # 5 new faces
            flag.add_face(@[i4(CNTR, i), i4(v1, v2), i4(v2, v1), i4(v2), i4(v2, v3)])

            # shift over one
            (v1, v2) = (v2, v3)

    flag.toPolyhedron("g" & p.name)

proc propellor*(p:Polyhedron):Polyhedron=
    if not p.check: return p

    var flag:Flag

    flag.add_vertexes(p.vertex) 

    for i, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]
        
        for v3 in face:
            flag.add_vertex(i4(v1, v2), oneThird(p.vertex[v1], p.vertex[v2]), with_unit=false)

            flag.add_face(i4(i), i4(v1, v2), i4(v2, v3)) 
            flag.add_face(@[i4(v1, v2), i4(v2, v1), i4(v2), i4(v2, v3)]) # five new flags

            # shift over one
            (v1, v2) = (v2, v3)
    
    flag.toPolyhedron("p" & p.name)

proc reflection*(p:Polyhedron):Polyhedron=
    if not p.check: return p

    var poly=p

    poly.vertex = -poly.vertex
    for face in poly.faces.mitems: face.reverse

    poly.name = "r" & poly.name
    poly

proc dual*(p:Polyhedron):Polyhedron=
    if not p.check: return p
    
    let 
        face_map = gen_face_map(p)
        centers = p.get_centers

    var 
        flag : Flag
        ok = true

    for i, face in p.faces:
        flag.add_vertex(i4(i), centers[i], with_unit=false)

        var v1 = face[^1]
        for v2 in face:
            if face.len>2 and i4(v2, v1) in face_map:
                flag.add_face(i4(v1), i4(face_map[i4(v2, v1)]), i4(i));
                v1 = v2
            else: ok=false

    if ok:  flag.toPolyhedron("d" & p.name)
    else: p

proc chamfer*(p:Polyhedron, dist : float = 0.5):Polyhedron=
    if not p.check: return p
    

    let normals = p.get_normals
    var flag : Flag

    for i, face in p.faces:
        var 
            v1 = face[^1]
            v1new = i4(i, v1)

        for v2 in face:
            flag.add_vertex(i4(v2), p.vertex[v2] * (1.0 + dist), with_unit=false)
            let v2new = i4(i, v2)
            flag.add_vertex(v2new, p.vertex[v2] + ( normals[i] * (dist * 1.5)), with_unit=false)

            flag.add_face(i4('o', i), v1new, v2new)
            let facename = if v1 < v2: i4('h', v1, v2) else: i4('h', v2, v1)

            flag.add_face(facename, i4(v2), v2new)
            flag.add_face(facename, v2new, v1new)
            flag.add_face(facename, v1new, i4(v1))

            v1 = v2
            v1new = v2new

    flag.toPolyhedron("c" & p.name)

proc whirl*(p:Polyhedron):Polyhedron=
    if not p.check: return p
    

    var flag:Flag
    flag.add_vertexes(p.vertex)
    let centers = p.get_centers

    for i, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]
        
        for v3 in face:
            let v1_2 = oneThird(p.vertex[v1], p.vertex[v2])
            flag.add_vertex(i4(v1, v2), v1_2, with_unit=false)
            let 
                cv1name = i4('c', i, v1)
                cv2name = i4('c', i, v2)

            flag.add_vertex(cv1name, oneThird(centers[i], v1_2))

            #        auto fname = i4(i, 'f', v1);
            # New hexagon for each original edge
            flag.add_face(@[cv1name, i4(v1, v2), i4(v2, v1), i4(v2), i4(v2, v3), cv2name])

            # New face in center of each old face
            flag.add_face(i4('c', i), cv1name, cv2name)

            (v1, v2) = (v2, v3) # shift over one

    flag.toPolyhedron("w" & p.name)

proc quinto*(p:Polyhedron):Polyhedron=
    if not p.check: return p

    var flag:Flag

    let centers=p.get_centers

    for nface, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]
        let centroid = centers[nface]

        var vi4:seq[Int4]

        for v3 in face:
            let 
                t12 = i4_min(v1, v2)
                ti12 = i4_min(nface, v1, v2)
                t23 = i4_min(v2, v3)
                ti23 = i4_min(nface, v2, v3)
                iv2 = i4(v2)

            # for each face-corner, we make two new points:
            let
                midpt = midpoint(p.vertex[v1], p.vertex[v2])
                innerpt = midpoint(midpt, centroid)

            flag.add_vertex(t12, midpt, with_unit=false)
            flag.add_vertex(ti12, innerpt, with_unit=false)

            # and add the old corner-vertex
            flag.add_vertex(iv2, p.vertex[v2], with_unit=false)

            # pentagon for each vertex in original face

            flag.add_face(@[ti12, t12, iv2, t23, ti23])

            # inner rotated face of same vertex-number as original
            vi4.add(ti12)

            (v1, v2) = (v2, v3) # shift over one
        
        flag.add_face(vi4)


    flag.toPolyhedron("q" & p.name)

proc insetN*(p:Polyhedron, n:int=0, inset_dist:float=0.3, popout_dist:float = -0.1):Polyhedron=
    if not p.check: return p
    
    var flag:Flag
    flag.add_vertexes(p.vertex, with_unit=false)

    let 
        normals=p.get_normals
        centers=p.get_centers
    var foundAny=false

    for i, face in p.faces:
        var v1 = face[^1]

        for v2 in face:
            if face.len == n or n==0:
                foundAny=true
                flag.add_vertex(
                    i4('f'.toToken, i, v2),
                    tween(p.vertex[v2], centers[i], inset_dist) + ( normals[i] * popout_dist),
                    with_unit = false
                )

                flag.add_face(@[i4(v1), i4(v2), i4('f', i, v2), i4('f', i, v1)])
                # new inset, extruded face
                flag.add_face(i4('e', i), i4('f', i, v1), i4('f', i, v2))
            else:
                flag.add_face(i4(i), i4(v1), i4(v2)) # same old flag, if non-n

            v1 = v2
    
    if not foundAny: echo "no ",n, " components where found"
    
    flag.toPolyhedron(newname = "n" & (if n!=0: $n else: "") & p.name)

proc extrudeN*(p:Polyhedron, n:int=0):Polyhedron=
    var poly = p.insetN(n=n, inset_dist=0.0, popout_dist=0.3)
    poly.name="x" & (if n!=0: $n else: "") & p.name
    poly

proc loft*(p:Polyhedron, n:int = 0, alpha : float = 0.1):Polyhedron=
    var poly = p.insetN(n=n, inset_dist=alpha, popout_dist=0.0)
    poly.name="l" & (if n!=0: $n else: "") & p.name
    poly

proc hollow*(p:Polyhedron, inset_dist : float = 0.3, thickness : float = 0.1):Polyhedron=
    if not p.check: return p
    
    var flag:Flag
    flag.add_vertexes(p.vertex, with_unit=false)

    let
        normals = p.calc_avg_normals
        centers = p.get_centers

    for i, face in p.faces:
        var v1 = face[^1]

        for v2 in face:
            flag.add_vertex(i4('f', i, 'v', v2), tween(p.vertex[v2], centers[i], inset_dist), with_unit=false)
            flag.add_vertex(i4('d', i, 'v', v2), tween(p.vertex[v2], centers[i], inset_dist) - (normals[i] * thickness), with_unit=false)

            flag.add_face(@[i4(v1), i4(v2), i4('f', i, 'v', v2), i4('f', i, 'v', v1)])
            flag.add_face(@[i4('f', i, 'v', v1), i4('f', i, 'v', v2), i4('d', i, 'v', v2), i4('d', i, 'v', v1)])
            v1 = v2

    flag.toPolyhedron(newname = "H" & p.name)

proc perspectiva1*(p:Polyhedron):Polyhedron=

    if not p.check: return p

    var flag:Flag
    flag.add_vertexes(p.vertex, with_unit=false)

    let centers = p.get_centers

    for i, face in p.faces:
        var
            v1 = face[^2]
            v2 = face[^1]
            vi4:seq[Int4]
            vert1 = p.vertex[v1]
            vert2 = p.vertex[v2]

        for v3 in face:
            let
                vert3 = p.vertex[v3]
                v12 = i4(v1, v2) # names for "oriented" midpoints
                v21 = i4(v2, v1)
                v23 = i4(v2, v3)

            # on each Nface, N new points inset from edge midpoints towards
            # center = "stellated" points
            flag.add_vertex(v12, midpoint(midpoint(vert1, vert2), centers[i]), with_unit=false)

            # inset Nface made of new, stellated points
            vi4.add(v12)

            # new tri face constituting the remainder of the stellated Nface
            flag.add_face(@[v23, v12, i4(v2)])

            # one of the two new triangles replacing old edge between v1->v2
            flag.add_face(@[i4(v1), v21, v12]);

            (v1, v2) = (v2, v3)  # current becomes previous
            (vert1, vert2) = (vert2, vert3)
        
        flag.add_face(vi4)


    flag.toPolyhedron(newname = "P" & p.name)

proc trisub*(p:Polyhedron, n:int=2):Polyhedron=
    if p.faces.mapIt(it.len != 3).any(proc (x:bool):bool=x): return p
    else:
        # Calculate redundant set of new vertices for subdivided mesh.
        var
            newVs : Vertexes
            vmap : Table[string, int]
            pos = 0
        
        for fn, face in p.faces:
            let 
                (i1, i2, i3) = (face[^3], face[^2], face[^1])
                (v1, v2, v3) = (p.vertex[i1], p.vertex[i2], p.vertex[i3])
                v21 = v2 - v1
                v31 = v3 - v1

            for i in 0..n:
                for j in 0..n-i:
                    let v = (v1 + v21 * (i.float * 1.0 / n.float)) + (v31 * (j.float * 1.0 / n.float))
                    vmap["v" & $fn & "-" & $i & "-" & $j] = pos
                    inc pos
                    newVs.add(v);
        
        # The above vertices are redundant along original edges,
        # we need to build an index map into a uniqueified list of them.
        # We identify vertices that are closer than a certain epsilon distance.

        const EPSILON_CLOSE = 1.0e-8
        var
            uniqVs : Vertexes 
            newpos = 0
            uniqmap : Table[int, int]
            i = 0
        
        for v in newVs:
            if not uniqmap.contains(i): 
                uniqmap[i] = newpos
                uniqVs.add(v)
                for j in i + 1..newVs.high:
                    let w = newVs[j];
                    if distance(v, w) < EPSILON_CLOSE:
                        uniqmap[j] = newpos
                inc newpos

        var faces:Faces
        for fn in 0..p.faces.high:
            for i in 0..<n:
                for j in 0..<n-i:
                    faces.add(@[uniqmap[vmap["v" & $fn & "-" & $i & "-" & $j]], uniqmap[vmap["v" & $fn & "-" & $(i + 1) & "-" & $j]], uniqmap[vmap["v" & $fn & "-" & $i & "-" & $(j + 1)]]])
            for i in 1..<n:
                for j in 0..<n-i:
                    faces.add(@[uniqmap[vmap["v" & $fn & "-" & $i & "-" & $j]], uniqmap[vmap["v" & $fn & "-" & $i & "-" & $(j + 1)]],  uniqmap[vmap["v" & $fn & "-" & $(i - 1) & "-" & $(j + 1)]]])

        Polyhedron(name : "u" & $n, vertex: uniqVs, faces: faces)

