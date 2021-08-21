#[ 
    convex hull

    usage: 

        proc newConvexHull*(points: seq[Point3d]): QuickHull3D =
        proc getVertices*(q: QuickHull3D): seq[Point3D] =
        proc getFaces*(q: QuickHull3D, indexFlags: int = CCW): seq[seq[int]] =

        let qh = newConvexHull(points)
        let (faces, vertices) = (qh.getFaces, qh.getVertices)

]#

import vmath

# Do / While
template Do(body: untyped) =
  while true:
    body

template While(cond: typed) =
  if not cond: break
  
# obj to ref conversion
proc box[T](x: T): ref T = new(result); result[] = x 

const
    DOUBLE_PREC = 2e-16
    VISIBLE = 1
    NON_CONVEX = 2
    DELETED = 3

    CLOCKWISE = 0x1
    CCW = 0
    INDEXED_FROM_ONE = 0x2
    NONCONVEX_WRT_LARGER_FACE = 1

    POINT_RELATIVE = 0x8
    AUTOMATIC_TOLERANCE: float = -1

type
    Vector3d = DVec3
    Point3d* = DVec3

    HalfEdge = object
        vertex : ref Vertex
        face : ref Face
        next, prev, opposite: ref HalfEdge

    Face = object
        he0: ref HalfEdge
        area: float
        planeOffset: float
        index: int
        numVerts: int
        next: ref Face
        mark: int # VISIBLE
        outside: ref Vertex
        normal, centroid: Point3d

    FaceList = object
        head, tail : ref Face
    
    Vertex = object
        pnt: Point3d
        index: int
        prev, next : ref Vertex
        face: ref Face

    VertexList = object
        head, tail : ref Vertex

# DVec3 enormalize
proc enormalize(v:DVec3):DVec3=
    let 
        lenSqr = v.lengthSq
        err = lenSqr-1
    if err > 2 * DOUBLE_PREC or err < -2 * DOUBLE_PREC:  v/lenSqr.sqrt
    else: v

# HalfEdge
proc newHalfEdge(v:ref Vertex, f:ref Face) : ref HalfEdge = 
    result = new(HalfEdge)
    result.vertex=v
    result.face=f

proc head(he:HalfEdge):ref Vertex = he.vertex
proc tail(he:HalfEdge):ref Vertex = 
    if he.prev != nil: he.prev.vertex else: nil
# proc setNext(he:var HalfEdge, edge:ref HalfEdge)=he.next = edge
proc getNext(he:HalfEdge):ref HalfEdge =  he.next
# proc setPrev(he:var HalfEdge, edge:ref HalfEdge) =   he.prev = edge
# proc getPrev(he: HalfEdge): ref HalfEdge = he.prev
proc getFace(he:HalfEdge):ref Face = he.face
proc getOpposite(he:HalfEdge):ref HalfEdge = he.opposite
proc setOpposite(he:var ref HalfEdge, edge:ref HalfEdge)=
    he.opposite = edge
    edge.opposite = he
proc oppositeFace(he:HalfEdge):ref Face=
    if he.opposite != nil: he.opposite.face else: nil
proc lengthSq(he:HalfEdge):float=
    if he.tail() != nil: he.head().pnt.distSq(he.tail().pnt)
    else: -1
# proc length(he:HalfEdge):float=
#     if he.tail() != nil: he.head().pnt.dist(he.tail().pnt)
#     else: -1

# FaceList
proc clear(fl:var FaceList)=
    fl.head = nil
    fl.tail = nil

proc add(fl:var FaceList, pvtx : ref Face)=
    var    vtx=pvtx

    if fl.head == nil: fl.head = vtx
    else:  fl.tail.next = vtx
    
    vtx.next = nil
    fl.tail = vtx

proc first(fl:FaceList) : ref Face = fl.head
# proc isEmpty(fl:FaceList):bool= fl.head == nil


# Face

# proc `=destroy`(f: var Face) =
#     var he = f.he0 # delete halfedge list
#     if he!=nil:
#         Do: 
#             var hAnt=he
#             hAnt = nil # delete hAnt
#             he = he.next
#             While he != f.he0

proc newFace():Face=
    Face(mark:VISIBLE)


# Face


proc computeCentroid(face: var Face) =
    face.centroid = dvec3(0, 0, 0)
    var he = face.he0
    Do:
        face.centroid += he.head().pnt
        he = he.next
        While he != face.he0
    face.centroid /= face.numVerts.float

proc computeNormal(face: var Face) =

    var
        he1 = face.he0.next
        he2 = he1.next

        p0 = face.he0.head().pnt
        p2 = he1.head().pnt

        d2x = p2.x - p0.x
        d2y = p2.y - p0.y
        d2z = p2.z - p0.z

    face.normal = dvec3(0, 0, 0)

    face.numVerts = 2

    while he2 != face.he0:
        var
            d1x = d2x
            d1y = d2y
            d1z = d2z

        p2 = he2.head().pnt

        d2x = p2.x - p0.x
        d2y = p2.y - p0.y
        d2z = p2.z - p0.z

        face.normal.x += d1y*d2z - d1z*d2y
        face.normal.y += d1z*d2x - d1x*d2z
        face.normal.z += d1x*d2y - d1y*d2x

        he1 = he2
        he2 = he2.next
        inc face.numVerts

    face.area = face.normal.length()
    face.normal /= face.area

proc computeNormal(face: var Face, minArea: float) =
    face.computeNormal()

    if face.area < minArea:

        var
            hedgeMax: ref HalfEdge = nil
            lenSqrMax = 0.0
            hedge = face.he0
        Do:
            var lenSqr = hedge.lengthSq()
            if lenSqr > lenSqrMax:
                hedgeMax = hedge
                lenSqrMax = lenSqr

            hedge = hedge.next
            While hedge != face.he0

        let
            p2 = hedgeMax.head().pnt
            p1 = hedgeMax.tail().pnt
            lenMax = sqrt(lenSqrMax)
            ux = (p2.x - p1.x)/lenMax
            uy = (p2.y - p1.y)/lenMax
            uz = (p2.z - p1.z)/lenMax
            dot = face.normal.x*ux + face.normal.y*uy + face.normal.z*uz

        face.normal.x -= dot*ux
        face.normal.y -= dot*uy
        face.normal.z -= dot*uz

        face.normal = face.normal.enormalize()

proc computeNormalAndCentroid(face: var Face) =

    face.computeNormal()
    face.computeCentroid()
    face.planeOffset = face.normal.dot(face.centroid)

    var
        numv = 0
        he = face.he0
    Do:
        inc numv
        he = he.next
        While he != face.he0

    assert numv == face.numVerts

proc computeNormalAndCentroid(face: var Face, minArea: float) =
    face.computeNormal(minArea)
    face.computeCentroid()
    face.planeOffset = face.normal.dot(face.centroid)

proc createTriangle(v0, v1, v2: ref Vertex, minArea: float = 0.0): ref Face =
    var
        face = box(newFace())
        he0 = newHalfEdge(v0, face)
        he1 = newHalfEdge(v1, face)
        he2 = newHalfEdge(v2, face)

    he0.prev = he2
    he0.next = he1
    he1.prev = he0
    he1.next = he2
    he2.prev = he1
    he2.next = he0

    face.he0 = he0

    # compute the normal and offset
    face.computeNormalAndCentroid(minArea)
    face

# proc create(vtxArray: seq[ref Vertex], indices: seq[int]): ref Face =
#     var
#         face = new(Face)
#         hePrev: ref HalfEdge = nil

#     for i in indices:
#         let he = newHalfEdge(vtxArray[i], face)
#         if hePrev != nil:
#             he.setPrev(hePrev)
#             hePrev.setNext(he)
#         else:
#             face.he0 = he
#         hePrev = he
#     face.he0.setPrev(hePrev)
#     hePrev.setNext(face.he0)

#     # compute the normal and offset
#     face.computeNormalAndCentroid()
#     face

proc getEdge(face: Face, i_p: int): ref HalfEdge =
    var
        i = i_p
        he = face.he0

    while i > 0:
        he = he.next
        dec i
    while i < 0:
        he = he.prev
        inc i
    he

proc getFirstEdge(face: Face): ref HalfEdge = face.he0
# proc findEdge(face: Face, vt, vh: ref Vertex): ref HalfEdge =
#     var he = face.he0
#     Do:
#         if he.head() == vh and he.tail() == vt:
#             return he
#         he = he.next
#         While he != face.he0
#     nil

proc distanceToPlane(face: Face, p: Point3D): float =
    face.normal.x*p.x + face.normal.y*p.y + face.normal.z*p.z - face.planeOffset

# proc getNormal(face: Face): Point3D = face.normal
proc getCentroid(face: Face): Point3D = face.centroid
proc numVertices(face: Face): int = face.numVerts

proc connectHalfEdges(face: var Face, hedgePrev,
        hedge: ref HalfEdge): ref Face =

    var discardedFace: ref Face = nil

    if hedgePrev.oppositeFace() == hedge.oppositeFace(): # then there is a redundant edge that we can get rid off

        var
            oppFace = hedge.oppositeFace()
            hedgeOpp: ref HalfEdge

        if hedgePrev == face.he0:
            face.he0 = hedge

        if oppFace.numVertices() == 3: # then we can get rid of the opposite face altogether
            hedgeOpp = hedge.getOpposite().prev.getOpposite()
            oppFace.mark = DELETED
            discardedFace = oppFace
        else:
            hedgeOpp = hedge.getOpposite().next

            if oppFace.he0 == hedgeOpp.prev:
                oppFace.he0 = hedgeOpp

            hedgeOpp.prev = hedgeOpp.prev.prev
            hedgeOpp.prev.next = hedgeOpp

        hedge.prev = hedgePrev.prev
        hedge.prev.next = hedge

        hedge.opposite = hedgeOpp
        hedgeOpp.opposite = hedge

        # oppFace was modified, so need to recompute
        oppFace.computeNormalAndCentroid()

    else:
        hedgePrev.next = hedge
        hedge.prev = hedgePrev

    discardedFace

proc checkConsistency(face: Face) =
    # do a sanity check on the face
    var
        hedge = face.he0
        maxd = 0.0
        numv = 0

    assert(face.numVerts >= 3) # + getVertexString())/

    Do:

        let hedgeOpp = hedge.getOpposite()

        assert hedgeOpp != nil, "unreflected half edge "
        assert hedgeOpp.getOpposite() == hedge
        assert (hedgeOpp.head() == hedge.tail() and hedge.head() ==
                hedgeOpp.tail())

        let oppFace = hedgeOpp.face

        assert oppFace != nil
        assert oppFace.mark != DELETED

        var d = face.distanceToPlane(hedge.head().pnt).abs
        if d > maxd: maxd = d

        inc numv
        hedge = hedge.next

        While hedge != face.he0

    assert(numv == face.numVerts)

proc mergeAdjacentFace(face: var ref Face, hedgeAdj: ref HalfEdge,
        discarded: var seq[ref Face]): int =

    var
        oppFace = hedgeAdj.oppositeFace()
        numDiscarded = 0

    discarded[numDiscarded] = oppFace
    inc numDiscarded
    oppFace.mark = DELETED

    let hedgeOpp = hedgeAdj.getOpposite()
    var
        hedgeAdjPrev = hedgeAdj.prev
        hedgeAdjNext = hedgeAdj.next
        hedgeOppPrev = hedgeOpp.prev
        hedgeOppNext = hedgeOpp.next

    while hedgeAdjPrev.oppositeFace() == oppFace:
        hedgeAdjPrev = hedgeAdjPrev.prev
        hedgeOppNext = hedgeOppNext.next

    while hedgeAdjNext.oppositeFace() == oppFace:
        hedgeOppPrev = hedgeOppPrev.prev
        hedgeAdjNext = hedgeAdjNext.next


    var hedge = hedgeOppNext

    while hedge != hedgeOppPrev.next:
        hedge.face = face
        hedge = hedge.next


    if hedgeAdj == face.he0:
        face.he0 = hedgeAdjNext


    # handle the half edges at the head
    var discardedFace = face.connectHalfEdges(hedgeOppPrev, hedgeAdjNext)
    if discardedFace != nil:
        discarded[numDiscarded] = discardedFace
        inc numDiscarded


    # handle the half edges at the tail
    discardedFace = face.connectHalfEdges(hedgeAdjPrev, hedgeOppNext)
    if discardedFace != nil:
        discarded[numDiscarded] = discardedFace
        inc numDiscarded

    face.computeNormalAndCentroid()
    face.checkConsistency()

    numDiscarded

# proc areaSquared(face: Face, hedge0, hedge1: ref HalfEdge): float =

#     # return the squared area of the triangle defined
#     # by the half edge hedge0 and the point at the
#     # head of hedge1.

#     let
#         p0 = hedge0.tail().pnt
#         p1 = hedge0.head().pnt
#         p2 = hedge1.head().pnt

#         dx1 = p1.x - p0.x
#         dy1 = p1.y - p0.y
#         dz1 = p1.z - p0.z

#         dx2 = p2.x - p0.x
#         dy2 = p2.y - p0.y
#         dz2 = p2.z - p0.z

#         x = dy1*dz2 - dz1*dy2
#         y = dz1*dx2 - dx1*dz2
#         z = dx1*dy2 - dy1*dx2

#     x*x + y*y + z*z

# proc triangulate(face: var ref Face, newFaces: ref FaceList, minArea: float) =
#     if face.numVertices() < 4: return

#     let v0 = face.he0.head()
#     var
#         hedge = face.he0.next
#         oppPrev = hedge.opposite
#         face0: ref Face = nil

#     hedge = hedge.next
#     while hedge != face.he0.prev:
#         var f = createTriangle(v0, hedge.prev.head(), hedge.head(), minArea)
#         f.he0.next.setOpposite (oppPrev)
#         f.he0.prev.setOpposite (hedge.opposite)
#         oppPrev = f.he0
#         newFaces.add(f)
#         if face0 == nil:
#             face0 = f
#         hedge = hedge.next


#     hedge = newHalfEdge(face.he0.prev.prev.head(), face)
#     hedge.setOpposite(oppPrev)

#     hedge.prev = face.he0
#     hedge.prev.next = hedge

#     hedge.next = face.he0.prev
#     hedge.next.prev = hedge

#     face.computeNormalAndCentroid(minArea)
#     face.checkConsistency()

#     var f = face0
#     while f != nil:
#         f.checkConsistency()
#         f = face.next


# Vertex
proc newVertex(pnt:Point3d, index: int): Vertex =
    result = Vertex(pnt: pnt, index: index, face:box(newFace()))

# VertexList

proc clear(v:var VertexList)=
    v.head = nil
    v.tail = nil

proc add(v:var VertexList, pvtx:ref Vertex)=
    var vtx=pvtx
    if v.head == nil:
        v.head = vtx
    else:
        v.tail.next = vtx
    
    vtx.prev = v.tail
    vtx.next = nil
    v.tail = vtx

proc addAll(v:var VertexList, pvtx: ref Vertex)=
    var vtx=pvtx
    if v.head == nil:
        v.head = vtx
    else:
        v.tail.next = vtx
    
    vtx.prev = v.tail
    while vtx.next != nil:
        vtx = vtx.next
    
    v.tail = vtx

proc del(v:var VertexList, pvtx:ref Vertex)=
    var vtx=pvtx
    if vtx.prev == nil:
        v.head = vtx.next
    else:
        vtx.prev.next = vtx.next
    
    if vtx.next == nil:
        v.tail = vtx.prev
    else:
        vtx.next.prev = vtx.prev
    
proc del(v:var VertexList, pvtx1, pvtx2:ref Vertex)=
    var 
        vtx1=pvtx1
        vtx2=pvtx2
        
    if vtx1.prev == nil:
        v.head = vtx2.next
    else:
        vtx1.prev.next = vtx2.next
    
    if vtx2.next == nil:
        v.tail = vtx1.prev
    else:
        vtx2.next.prev = vtx1.prev

proc insertBefore(v:var VertexList, vtx, next:ref Vertex)=
    vtx.prev = next.prev
    if next.prev == nil:
        v.head = vtx
    else:
        next.prev.next = vtx
    
    vtx.next = next
    next.prev = vtx

proc first(v:VertexList):ref Vertex=v.head
proc isEmpty(v:VertexList):bool = v.head == nil




# QuickHull3D



type FaceVector = seq[ref Face]
type HalfEdgeVector = seq[ref HalfEdge]

type QuickHull3D* = object
    findIndex: int                      # = -1
    charLength: float
    pointBuffer: seq[ref Vertex]
    vertexPointIndices: seq[int]
    discardedFaces: seq[ref Face]
    minVtxs, maxVtxs: seq[ref Vertex]
    faces: FaceVector
    horizon: HalfEdgeVector
    newFaces: ref FaceList
    unclaimed, claimed: ref VertexList
    numVertices, numFaces, numPoints: int
    explicitTolerance, tolerance: float # = AUTOMATIC_TOLERANCE

proc initPrt(qh: var QuickHull3D) =
    qh.discardedFaces = newSeq[ref Face](3)
    qh.maxVtxs = newSeq[ref Vertex](3)
    qh.minVtxs = newSeq[ref Vertex](3)
    # qh.faces = FaceVector()
    # qh.horizon = HalfEdgeVector()
    new(qh.newFaces)
    new(qh.unclaimed)
    new(qh.claimed)

proc `=destroy`(q: var QuickHull3D) =
    for face in q.faces.mitems: face = nil
    for he in q.horizon.mitems: he = nil
    for p in q.pointBuffer.mitems: p = nil

proc getDistanceTolerance(q: QuickHull3D): float = q.tolerance
# proc setExplicitDistanceTolerance(q:var QuickHull3D, tol:float):float = q.explicitTolerance = tol
# proc getExplicitDistanceTolerance(q:QuickHull3D):float = q.explicitTolerance

proc addPointToFace(q: var QuickHull3D, pvtx: ref Vertex, pface: ref Face) =
    var
        vtx = pvtx
        face = pface

    vtx.face = face

    if face.outside == nil:
        q.claimed.add(vtx)
    else:
        q.claimed.insertBefore(vtx, face.outside)
    face.outside = vtx

proc removePointFromFace(q: var QuickHull3D, pvtx: ref Vertex,
        pface: ref Face) =
    var
        vtx = pvtx
        face = pface

    if vtx == face.outside:
        if vtx.next != nil and vtx.next.face == face:
            face.outside = vtx.next
        else:
            face.outside = nil
    q.claimed.del(vtx)

#[
proc findHalfEdge(q:QuickHull3D, tail, head : ref Vertex) : ref HalfEdge =
    # brute force ... OK, since setHull is not used much
    for f in q.faces:
        let he = f.findEdge(tail, head) #((Face *)f)->findEdge(tail, head)
        if he != nil:
            return he
    return nil
]#

proc initBuffers(q: var QuickHull3D, nump: int) =
    q.pointBuffer = newSeq[ref Vertex](nump)
    q.vertexPointIndices = newSeq[int](nump)

    q.faces = @[]
    if q.claimed != nil: q.claimed.clear()
    q.numFaces = 0
    q.numPoints = nump

proc setPoints(q: var QuickHull3D, points: seq[Point3D]) =
    for i, point in points:
        q.pointBuffer[i] = newVertex(pnt=point, index=i).box

proc buildHull(q: var QuickHull3D)

proc build(q: var QuickHull3D, points: seq[Point3D]) =
    assert points.len >= 4, "need more than 4 points"

    q.initBuffers(points.len)
    q.setPoints(points)
    q.buildHull()

proc computeMaxAndMin(q: var QuickHull3D) =
    var
        max, min: Point3d

    for i in 0..<3:
        q.maxVtxs[i] = q.pointBuffer[0]
        q.minVtxs[i] = q.pointBuffer[0]

    max = q.pointBuffer[0].pnt
    min = q.pointBuffer[0].pnt

    for i in 1..<q.numPoints:
        let pnt = q.pointBuffer[i].pnt

        if pnt.x > max.x:
            max.x = pnt.x
            q.maxVtxs[0] = q.pointBuffer[i]
        elif pnt.x < min.x:
            min.x = pnt.x
            q.minVtxs[0] = q.pointBuffer[i]

        if pnt.y > max.y:
            max.y = pnt.y
            q.maxVtxs[1] = q.pointBuffer[i]
        elif pnt.y < min.y:
            min.y = pnt.y
            q.minVtxs[1] = q.pointBuffer[i]
        if pnt.z > max.z:
            max.z = pnt.z
            q.maxVtxs[2] = q.pointBuffer[i]
        elif pnt.z < min.z:
            min.z = pnt.z
            q.maxVtxs[2] = q.pointBuffer[i]



    # this epsilon formula comes from QuickHull, and I'm
    # not about to quibble.
    q.charLength = max(max.x - min.x, max.y - min.y)
    q.charLength = max(max.z - min.z, q.charLength)

    if q.explicitTolerance == AUTOMATIC_TOLERANCE:
        q.tolerance = 3 * DOUBLE_PREC * (max(max.x.abs, min.x.abs) + max(
                max.y.abs, min.y.abs) + max(max.z.abs, min.z.abs))
    else:
        q.tolerance = q.explicitTolerance

#[
proc triangulate(q:var QuickHull3D)=
    let minArea = 1000 * q.charLength * DOUBLE_PREC
    q.newFaces.clear()

    for face in q.faces.mitems:
        if face.mark == VISIBLE:
            face.triangulate(q.newFaces, minArea)

        var face = q.newFaces.first()
        while face != nil:
            q.faces.add(face)
            face = face.next
        ]#

proc createInitialSimplex(q: var QuickHull3D) =
    var
        max = 0.0
        imax = 0

    for i in 0..<3:
        let diff = q.maxVtxs[i].pnt[i] - q.minVtxs[i].pnt[i]
        if diff > max:
            max = diff
            imax = i

    assert max > q.tolerance, "Input points appear to be coincident"

    var vtx = newSeq[ref Vertex](4)

    # set first two vertices to be those with the greatest
    # one dimensional separation
    vtx[0] = q.maxVtxs[imax]
    vtx[1] = q.minVtxs[imax]

    # set third vertex to be the vertex farthest from
    # the line between vtx0 and vtx1
    var
        u01: DVec3
        diff02: DVec3
        nrml: DVec3
        xprod: DVec3

        maxSqr = 0.0

    u01 = vtx[1].pnt - vtx[0].pnt
    u01 = u01.normalize()

    for i in 0..<q.numPoints:

        diff02 = q.pointBuffer[i].pnt - vtx[0].pnt
        xprod = cross(u01, diff02)
        let lenSqr = xprod.lengthSq()

        if lenSqr > maxSqr and
            q.pointBuffer[i] != vtx[0] and # paranoid
            q.pointBuffer[i] != vtx[1]:

            maxSqr = lenSqr
            vtx[2] = q.pointBuffer[i]
            nrml = xprod

    assert sqrt(maxSqr) > 100 * q.tolerance, "Input points appear to be colinear"

    nrml = nrml.normalize()

    var
        maxDist = 0.0
        d0 = vtx[2].pnt.dot(nrml)

    for i in 0..<q.numPoints:
        let dist = abs(q.pointBuffer[i].pnt.dot(nrml) - d0)
        if dist > maxDist and
            q.pointBuffer[i] != vtx[0] and # paranoid
            q.pointBuffer[i] != vtx[1] and
            q.pointBuffer[i] != vtx[2]:

            maxDist = dist
            vtx[3] = q.pointBuffer[i]


    assert abs(maxDist) > 100.0 * q.tolerance, "Input points appear to be coplanar"

    var tris = newSeq[ref Face](4)

    if vtx[3].pnt.dot(nrml) - d0 < 0:
        tris[0] = createTriangle(vtx[0], vtx[1], vtx[2])
        tris[1] = createTriangle(vtx[3], vtx[1], vtx[0])
        tris[2] = createTriangle(vtx[3], vtx[2], vtx[1])
        tris[3] = createTriangle(vtx[3], vtx[0], vtx[2])

        for i in 0..<3:
            let k = (i + 1) %% 3
            var e1 = tris[i + 1].getEdge(1)
            e1.setOpposite(tris[k + 1].getEdge(0))
            var e2 = tris[i + 1].getEdge(2)
            e2.setOpposite(tris[0].getEdge(k))
    else:
        tris[0] = createTriangle(vtx[0], vtx[2], vtx[1])
        tris[1] = createTriangle(vtx[3], vtx[0], vtx[1])
        tris[2] = createTriangle(vtx[3], vtx[1], vtx[2])
        tris[3] = createTriangle(vtx[3], vtx[2], vtx[0])

        for i in 0..<3:
            let k = (i + 1) %% 3
            var e1 = tris[i + 1].getEdge(0)
            e1.setOpposite(tris[k + 1].getEdge(1))
            var e2 = tris[i + 1].getEdge(2)
            e2.setOpposite(tris[0].getEdge((3 - i) %% 3))

    for i in 0..<4:
        q.faces.add(tris[i])


    for i in 0..<q.numPoints:
        var v = q.pointBuffer[i]

        if v == vtx[0] or v == vtx[1] or v == vtx[2] or v == vtx[3]:
            continue

        maxDist = q.tolerance
        var maxFace: ref Face
        for k in 0..<4:
            let dist = tris[k].distanceToPlane(v.pnt)
            if dist > maxDist:
                maxFace = tris[k]
                maxDist = dist

        if maxFace != nil:
            q.addPointToFace(v, maxFace)



proc getFaceIndices(q: QuickHull3D, indices: var seq[int], face: ref Face, flags: int) =
    let
        ccw = (flags and CLOCKWISE) == 0
        indexedFromOne = (flags and INDEXED_FROM_ONE) != 0
        pointRelative = (flags and POINT_RELATIVE) != 0

    var
        hedge = face.he0
        k = 0

    Do:
        var idx = hedge.head().index
        if pointRelative:
            idx = q.vertexPointIndices[idx]
        if indexedFromOne:
            inc idx

        assert k < indices.len, "index out of range"
        assert idx >= 0, "negative ace index"

        indices[k] = idx
        inc k
        hedge = if ccw: hedge.next else: hedge.prev

        While hedge != face.he0

proc resolveUnclaimedPoints(q: var QuickHull3D, newFaces: ref FaceList) =
    var
        vtxNext = q.unclaimed.first()
        vtx = vtxNext

    while vtx != nil:

        vtxNext = vtx.next

        var
            maxDist = q.tolerance
            maxFace: ref Face = nil
            newFace = newFaces.first()

        while newFace != nil:
            if newFace.mark == VISIBLE:

                let dist = newFace.distanceToPlane(vtx.pnt)
                if dist > maxDist:
                    maxDist = dist
                    maxFace = newFace

                if maxDist > 1000 * q.tolerance:
                    break

            newFace = newFace.next

        if maxFace != nil:
            q.addPointToFace(vtx, maxFace)

        vtx = vtxNext

proc removeAllPointsFromFace(q: var QuickHull3D, face: ref Face): ref Vertex =
    if face.outside != nil:
        var end_face = face.outside
        while end_face.next != nil and end_face.next.face == face:
            end_face = end_face.next

        q.claimed.del(face.outside, end_face)
        end_face.next = nil
        return face.outside
    else:
        return nil


proc deleteFacePoints(q: var QuickHull3D, pface, pabsorbingFace: ref Face) =

    var
        face = pface
        absorbingFace = pabsorbingFace
        faceVtxs = q.removeAllPointsFromFace(face)

    if faceVtxs != nil:
        if absorbingFace == nil:
            q.unclaimed.addAll(faceVtxs)
        else:

            var
                vtxNext = faceVtxs
                vtx = vtxNext
            while vtx != nil:
                vtxNext = vtx.next
                if absorbingFace.distanceToPlane(vtx.pnt) > q.tolerance:
                    q.addPointToFace(vtx, absorbingFace)
                else:
                    q.unclaimed.add(vtx)
                vtx = vtxNext


proc oppFaceDistance(q: var QuickHull3D, he: ref HalfEdge): float =
    he.face.distanceToPlane(he.opposite.face.getCentroid())


proc doAdjacentMerge(q: var QuickHull3D, pface: ref Face,
        mergeType: int): bool =

    var
        face = pface
        hedge = face.he0
        convex = true

    Do:

        var
            oppFace = hedge.oppositeFace()
            merge = false

        if mergeType == NONCONVEX: # then merge faces if they are definitively non-convex
            if q.oppFaceDistance(hedge) > -q.tolerance or
                q.oppFaceDistance(hedge.opposite) > -q.tolerance:
                merge = true
        else: #[ mergeType == NONCONVEX_WRT_LARGER_FACE
                 merge faces if they are parallel or non-convex
                wrt to the larger face otherwise, just mark
                the face non-convex for the second pass. ]#
                
            if face.area > oppFace.area:
                if q.oppFaceDistance(hedge) > -q.tolerance:
                    merge = true
                elif q.oppFaceDistance(hedge.opposite) > -q.tolerance:
                    convex = false
            else:
                if q.oppFaceDistance(hedge.opposite) > -q.tolerance:
                    merge = true
                elif q.oppFaceDistance(hedge) > -q.tolerance:
                    convex = false

        if merge:
            let numd = face.mergeAdjacentFace(hedge, q.discardedFaces)
            for i in 0..<numd:
                q.deleteFacePoints(q.discardedFaces[i], face)
            return true

        hedge = hedge.next

        While hedge != face.he0

    if not convex:
        face.mark = NON_CONVEX

    false


proc calculateHorizon(q: var QuickHull3D, eyePnt: ref Point3d,
        pedge0: ref HalfEdge, face: ref Face, horizon: var HalfEdgeVector) =

    #       oldFaces.add (face)
    var rface: ref Face = nil
    q.deleteFacePoints(face, rface)
    face.mark = DELETED

    var
        edge: ref HalfEdge
        edge0 = pedge0

    if edge0 == nil:
        edge0 = face.getEdge(0)
        edge = edge0
    else:
        edge = edge0.getNext()

    Do:
        var oppFace = edge.oppositeFace()
        if oppFace.mark == VISIBLE:
            if oppFace.distanceToPlane(eyePnt[]) > q.tolerance:
                q.calculateHorizon(eyePnt, edge.getOpposite(), oppFace, horizon)
            else:
                horizon.add(edge)

        edge = edge.getNext()
        While edge != edge0

proc addAdjoiningFace(q: var QuickHull3D, eyeVtx: ref Vertex,
        he: ref HalfEdge): ref HalfEdge =
    var face = createTriangle(eyeVtx, he.tail(), he.head())
    q.faces.add(face)
    var e0 = face.getEdge(-1)
    e0.setOpposite(he.getOpposite())
    face.getEdge(0)

proc addNewFaces(q: var QuickHull3D, pnewFaces: ref FaceList,
        eyeVtx: ref Vertex, horizon: HalfEdgeVector) =
    var newFaces = pnewFaces

    newFaces.clear()

    var
        hedgeSidePrev: ref HalfEdge = nil
        hedgeSideBegin: ref HalfEdge = nil

    for horizonHe in horizon:

        var hedgeSide = q.addAdjoiningFace(eyeVtx, horizonHe)

        if hedgeSidePrev != nil:
            hedgeSide.next.setOpposite(hedgeSidePrev)
        else:
            hedgeSideBegin = hedgeSide

        newFaces.add(hedgeSide.getFace())
        hedgeSidePrev = hedgeSide

    hedgeSideBegin.next.setOpposite(hedgeSidePrev)

proc nextPointToAdd(q: QuickHull3D): ref Vertex =
    if not q.claimed.isEmpty():
        var
            eyeFace = q.claimed.first().face
            eyeVtx: ref Vertex = nil
            maxDist = 0.0

        var vtx = eyeFace.outside
        while vtx != nil and vtx.face == eyeFace:

            let dist = eyeFace.distanceToPlane(vtx.pnt)
            if dist > maxDist:
                maxDist = dist
                eyeVtx = vtx

            vtx = vtx.next

        return eyeVtx
    else:
        return nil


proc addPointToHull(q: var QuickHull3D, eyeVtx: ref Vertex) =

    q.horizon.setLen(0)
    q.unclaimed.clear()

    q.removePointFromFace(eyeVtx, eyeVtx.face)
    let he_nil: ref HalfEdge = nil
    q.calculateHorizon(box(eyeVtx.pnt), he_nil, eyeVtx.face, q.horizon)
    q.newFaces.clear()
    q.addNewFaces(q.newFaces, eyeVtx, q.horizon)

    # first merge pass ... merge faces which are non-convex
    # as determined by the larger face

    var face = q.newFaces.first()
    while face != nil:

        if face.mark == VISIBLE:
            while q.doAdjacentMerge(face, NONCONVEX_WRT_LARGER_FACE): discard
        face = face.next


    # second merge pass ... merge faces which are non-convex
    # wrt either face

    face = q.newFaces.first()
    while face != nil:

        if face.mark == NON_CONVEX:
            face.mark = VISIBLE
            while q.doAdjacentMerge(face, NONCONVEX): discard

        face = face.next


    q.resolveUnclaimedPoints(q.newFaces)

proc reindexFacesAndVertices(q: var QuickHull3D)
proc buildHull(q: var QuickHull3D) =

    q.computeMaxAndMin()
    q.createInitialSimplex()

    var
        cnt = 0
        eyeVtx = q.nextPointToAdd()

    while eyeVtx != nil:
        q.addPointToHull(eyeVtx)
        inc cnt
        eyeVtx = q.nextPointToAdd()
    q.reindexFacesAndVertices()


proc markFaceVertices(q: var QuickHull3D, face: ref Face, mark: int) =
    var
        he0 = face.getFirstEdge()
        he = he0
    Do:
        he.head().index = mark
        he = he.next

        While he != he0

proc reindexFacesAndVertices(q: var QuickHull3D) =
    for i in 0..<q.numPoints:
        q.pointBuffer[i].index = -1

    # remove inactive faces and mark active vertices
    q.numFaces = 0

    var i = 0
    while i < q.faces.len:
        if q.faces[i].mark != VISIBLE:
            q.faces.del(i)
        else:
            q.markFaceVertices(q.faces[i], 0)
            inc q.numFaces
            inc i

    # reindex vertices
    q.numVertices = 0
    for i in 0..<q.numPoints:
        var vtx = q.pointBuffer[i]
        if vtx.index == 0:
            q.vertexPointIndices[q.numVertices] = i
            vtx.index = q.numVertices
            inc q.numVertices

proc checkFaceConvexity(q: var QuickHull3D, face: ref Face, tol: float): bool =
    var
        dist = 0.0
        he = face.he0

    Do:
        face.checkConsistency()
        # make sure edge is convex
        dist = q.oppFaceDistance(he)
        if dist > tol:
            return false

        dist = q.oppFaceDistance(he.opposite)
        if dist > tol:
            return false

        if he.next.oppositeFace() == he.oppositeFace():
            return false

        he = he.next

        While he != face.he0

    return true


proc checkFaces(q: var QuickHull3D, tol: float): bool =

    # check edge convexity
    var convex = true
    for face in q.faces:
        if face.mark == VISIBLE:
            if not q.checkFaceConvexity(face, tol):
                convex = false

    convex


proc check(q: var QuickHull3D, tol: float): bool =

    # check to make sure all edges are fully connected
    # and that the edges are convex
    var
        dist: float
        pointTol = 10 * tol

    if not q.checkFaces(q.tolerance):
        return false


    # check point inclusion

    for i in 0..<q.numPoints:
        let pnt = q.pointBuffer[i].pnt
        for face in q.faces:
            if face.mark == VISIBLE:
                dist = face.distanceToPlane(pnt)
                if dist > pointTol:
                    return false
    return true


proc check*(q: var QuickHull3D): bool = q.check(q.getDistanceTolerance)

# used for testing

proc waterman_poly*(radius: float32): seq[Point3d] =
    var coords: seq[Point3d]

    let (a, b, c) = (0.0, 0.0, 0.0)
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
                coords.add(dvec3(x, y, z))
                z += 2

            y += 1

        x += 1

    coords


# global interfaced proc's

proc newConvexHull*(points: seq[Point3d]): QuickHull3D =
    result = QuickHull3D()
    result.initPrt
    result.explicitTolerance = AUTOMATIC_TOLERANCE
    result.build(points)
    result.initPrt

proc getVertices*(q: QuickHull3D): seq[Point3D] =
    var
        vtxs: seq[Point3D]
        max = 0.0

    for i in 0..<q.numVertices:
        vtxs.add(q.pointBuffer[q.vertexPointIndices[i]].pnt)
        max = max.max(vtxs[i].x.max(vtxs[i].y.max(vtxs[i].z)))

    if max != 0.0:
        for v in vtxs.mitems: v/=max
    vtxs

proc getFaces*(q: QuickHull3D, indexFlags: int = CCW): seq[seq[int]] =

    var allFaces: seq[seq[int]] = newSeq[seq[int]](q.faces.len)

    for k, face in q.faces:
        allFaces[k] = newSeq[int](face.numVertices())
        q.getFaceIndices(allFaces[k], face, indexFlags)
    allFaces
