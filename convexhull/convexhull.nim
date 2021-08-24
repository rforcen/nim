#[ 
    convex hull

    usage: 

        proc convexHull*(points: seq[Point3d]) : (seq[seq[int]], seq[Point3D]) =
        let (faces, vertices)=convexHull(points)

]#

import vmath, sequtils

# Do / While
template Do(body: untyped) =
  while true:
    body

template While(cond: typed) =
  if not cond: break

const
  DOUBLE_PREC = 2e-16
  HIDDEN = -1
  DISABLED = 0
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
  Vector3d = DVec3 # use float64 to ensure tolerance
  Point3d* = DVec3

  HalfEdge = object
    vertex: ptr Vertex
    face: ptr Face
    next, prev, opposite: ptr HalfEdge

  Face = object
    he0: ptr HalfEdge
    area: float
    planeOffset: float
    index: int
    numVerts: int
    next: ptr Face
    mark: int # VISIBLE
    outside: ptr Vertex
    normal, centroid: Point3d

  FaceList = object
    head, tail: ptr Face

  Vertex = object
    pnt: Point3d
    index: int
    prev, next: ptr Vertex
    face: ptr Face

  VertexList = object
    head, tail: ptr Vertex

# alloc procs
proc newHalfEdge(v: ptr Vertex, f: ptr Face): ptr HalfEdge =
  result = create(HalfEdge)
  result.vertex = v
  result.face = f

proc newFace(): ptr Face =
  result = create(Face)
  result.mark = VISIBLE

# HalfEdge

proc head(he: HalfEdge): ptr Vertex = he.vertex
proc tail(he: HalfEdge): ptr Vertex =
  if he.prev != nil: he.prev.vertex else: nil
proc getNext(he: HalfEdge): ptr HalfEdge = he.next
proc getFace(he: HalfEdge): ptr Face = he.face
proc getOpposite(he: HalfEdge): ptr HalfEdge = he.opposite
proc setOpposite(he: ptr HalfEdge, edge: ptr HalfEdge) =
  he.opposite = edge
  edge.opposite = he
proc oppositeFace(he: HalfEdge): ptr Face =
  if he.opposite != nil: he.opposite.face else: nil
proc lengthSq(he: HalfEdge): float =
  if he.tail() != nil: he.head().pnt.distSq(he.tail().pnt)
  else: -1

# FaceList
proc clear(fl: var FaceList) =
  fl.head = nil
  fl.tail = nil

proc add(fl: var FaceList, pvtx: ptr Face) =
  var vtx = pvtx

  if fl.head == nil: fl.head = vtx
  else: fl.tail.next = vtx

  vtx.next = nil
  fl.tail = vtx

proc first(fl: FaceList): ptr Face = fl.head

# Face

proc delete(face:var ptr Face) =
  face.dealloc
  face=nil

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
    d2 = p2 - p0

  face.normal = dvec3(0, 0, 0)
  face.numVerts = 2

  while he2 != face.he0:
    var d1=d2

    p2 = he2.head().pnt

    d2=p2-p0

    face.normal += d1.cross(d2) 

    he1 = he2
    he2 = he2.next
    inc face.numVerts

  face.area = face.normal.length()
  face.normal /= face.area

proc computeNormal(face: var Face, minArea: float) =
  face.computeNormal()

  if face.area < minArea:

    var
      hedgeMax: ptr HalfEdge = nil
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
      u = (p2-p1) / lenMax

    face.normal -= (face.normal.dot(u) * u).normalize

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

proc createTriangle(v0, v1, v2: ptr Vertex, minArea: float = 0.0): ptr Face =
  var
    face = newFace()
    he0 = newHalfEdge(v0, face)
    he1 = newHalfEdge(v1, face)
    he2 = newHalfEdge(v2, face)

  # face.halfedges = @[he0, he1, he2]

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

proc getEdge(face: Face, i_p: int): ptr HalfEdge =
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

proc getFirstEdge(face: Face): ptr HalfEdge = face.he0

proc distanceToPlane(face: Face, p: Point3D): float =
  face.normal.x*p.x + face.normal.y*p.y + face.normal.z*p.z - face.planeOffset

proc getCentroid(face: Face): Point3D = face.centroid
proc numVertices(face: Face): int = face.numVerts

proc connectHalfEdges(face: var Face, hedgePrev,
        hedge: ptr HalfEdge): ptr Face =

  var discardedFace: ptr Face = nil

  if hedgePrev.oppositeFace() == hedge.oppositeFace(): # then there is a redundant edge that we can get rid off

    var
      oppFace = hedge.oppositeFace()
      hedgeOpp: ptr HalfEdge

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

  assert face.numVerts >= 3

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

proc mergeAdjacentFace(face: var ptr Face, hedgeAdj: ptr HalfEdge,
        discarded: var seq[ptr Face]): int =

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


# VertexList

proc clear(v: var VertexList) =
  v.head = nil
  v.tail = nil

proc add(v: var VertexList, vtx: ptr Vertex) =
  if v.head == nil:
    v.head = vtx
  else:
    v.tail.next = vtx

  vtx.prev = v.tail
  vtx.next = nil
  v.tail = vtx

proc addAll(v: var VertexList, vtx: var ptr Vertex) =
  if v.head == nil:
    v.head = vtx
  else:
    v.tail.next = vtx

  vtx.prev = v.tail
  while vtx.next != nil:
    vtx = vtx.next

  v.tail = vtx

proc del(v: var VertexList, vtx: ptr Vertex) =
  if vtx.prev == nil:
    v.head = vtx.next
  else:
    vtx.prev.next = vtx.next

  if vtx.next == nil:
    v.tail = vtx.prev
  else:
    vtx.next.prev = vtx.prev

proc del(v: var VertexList, vtx1, vtx2: ptr Vertex) =
  if vtx1.prev == nil:
    v.head = vtx2.next
  else:
    vtx1.prev.next = vtx2.next

  if vtx2.next == nil:
    v.tail = vtx1.prev
  else:
    vtx2.next.prev = vtx1.prev

proc insertBefore(v: var VertexList, vtx, next: ptr Vertex) =
  vtx.prev = next.prev
  if next.prev == nil:
    v.head = vtx
  else:
    next.prev.next = vtx

  vtx.next = next
  next.prev = vtx

proc first(v: VertexList): ptr Vertex = v.head
proc isEmpty(v: VertexList): bool = v.head == nil

type FaceVector = seq[ptr Face]
type HalfEdgeVector = seq[ptr HalfEdge]
type VertexVector = seq[Vertex]

# QuickHull3D

type QuickHull3D* = object
  pointBuffer: VertexVector
  faces: FaceVector
  vertexPointIndices: seq[int]
  newFaces: FaceList
  discardedFaces: FaceVector
  unclaimed, claimed: VertexList
  horizon: HalfEdgeVector
  minVtxs, maxVtxs: VertexVector
  explicitTolerance, tolerance: float # = AUTOMATIC_TOLERANCE

proc `=destroy`(q: var QuickHull3D) =
  for f in q.faces.mitems: f.delete

  q.faces = @[] # not sure this is neccesary
  q.pointBuffer = @[]
  q.vertexPointIndices = @[]
  q.discardedFaces = @[]
  q.minVtxs = @[]
  q.maxVtxs = @[]
  q.horizon = @[]  


proc getDistanceTolerance(q: QuickHull3D): float = q.tolerance

proc addPointToFace(q: var QuickHull3D, vtx: ptr Vertex, face: ptr Face) =

  vtx.face = face

  if face.outside == nil:
    q.claimed.add(vtx)
  else:
    q.claimed.insertBefore(vtx, face.outside)
  face.outside = vtx

proc removePointFromFace(q: var QuickHull3D, vtx: ptr Vertex, face: ptr Face) =
  if vtx == face.outside:
    if vtx.next != nil and vtx.next.face == face:
      face.outside = vtx.next
    else:
      face.outside = nil
  q.claimed.del(vtx)

proc setPoints(q: var QuickHull3D, points: seq[Point3D]) =
  q.vertexPointIndices = newSeq[int](points.len)

  for i, point in points:
    q.pointBuffer.add( Vertex(pnt : point, index : i) )

proc buildHull(q: var QuickHull3D)

proc build(q: var QuickHull3D, points: seq[Point3D]) =
  assert points.len >= 4, "QH needs more than 4 points"

  q.setPoints(points)
  q.buildHull()

proc computeMaxAndMin(q: var QuickHull3D) =

  for i in 0..q.maxVtxs.high:
    q.maxVtxs[i] = q.pointBuffer[0]
    q.minVtxs[i] = q.pointBuffer[0]

  var 
    max = q.pointBuffer[0].pnt
    min = q.pointBuffer[0].pnt

  for pb in q.pointBuffer:
    let pnt = pb.pnt

    if pnt.x > max.x:
      max.x = pnt.x
      q.maxVtxs[0] = pb
    elif pnt.x < min.x:
      min.x = pnt.x
      q.minVtxs[0] = pb

    if pnt.y > max.y:
      max.y = pnt.y
      q.maxVtxs[1] = pb
    elif pnt.y < min.y:
      min.y = pnt.y
      q.minVtxs[1] = pb
    if pnt.z > max.z:
      max.z = pnt.z
      q.maxVtxs[2] = pb
    elif pnt.z < min.z:
      min.z = pnt.z
      q.maxVtxs[2] = pb



  # this epsilon formula comes from QuickHull, and I'm
  # not about to quibble.
  if q.explicitTolerance == AUTOMATIC_TOLERANCE:
    q.tolerance = 3 * DOUBLE_PREC * (max(max.x.abs, min.x.abs) + max(
            max.y.abs, min.y.abs) + max(max.z.abs, min.z.abs))
  else:
    q.tolerance = q.explicitTolerance

proc createInitialSimplex(q: var QuickHull3D) =
  var
    max = 0.0
    imax = 0

  for i in 0..q.maxVtxs.high:
    let diff = q.maxVtxs[i].pnt[i] - q.minVtxs[i].pnt[i]
    if diff > max:
      max = diff
      imax = i

  assert max > q.tolerance, "Input points appear to be coincident"


  # set first two vertices to be those with the greatest
  # one dimensional separation
  var vtx = @[q.maxVtxs[imax].addr, q.minVtxs[imax].addr, nil, nil]

  # set third vertex to be the vertex farthest from
  # the line between vtx0 and vtx1
  var 
    u01, nrml, xprod: DVec3
    maxSqr = 0.0

  u01 = (vtx[1].pnt - vtx[0].pnt).normalize()

  for i, pb in q.pointBuffer:

    xprod = cross(u01, pb.pnt - vtx[0].pnt)
    let lenSqr = xprod.lengthSq()

    if lenSqr > maxSqr and pb != vtx[0][] and pb != vtx[1][]:
      maxSqr = lenSqr
      vtx[2] = q.pointBuffer[i].addr
      nrml = xprod

  assert sqrt(maxSqr) > 100 * q.tolerance, "Input points appear to be colinear"

  nrml = nrml.normalize()

  var
    maxDist = 0.0
    d0 = vtx[2].pnt.dot(nrml)

  for i, pb in q.pointBuffer:
    let dist = abs(pb.pnt.dot(nrml) - d0)
    if dist > maxDist and pb != vtx[0][] and pb != vtx[1][] and  pb != vtx[2][]:
      maxDist = dist
      vtx[3] = q.pointBuffer[i].addr


  assert abs(maxDist) > 100.0 * q.tolerance, "Input points appear to be coplanar"

  var tris = newSeq[ptr Face](4)

  if vtx[3].pnt.dot(nrml) - d0 < 0:
    tris[0] = createTriangle(vtx[0], vtx[1], vtx[2])
    tris[1] = createTriangle(vtx[3], vtx[1], vtx[0])
    tris[2] = createTriangle(vtx[3], vtx[2], vtx[1])
    tris[3] = createTriangle(vtx[3], vtx[0], vtx[2])

    for i in 0..<3:
      let k = (i + 1) %% 3
      tris[i + 1].getEdge(1).setOpposite(tris[k + 1].getEdge(0))
      tris[i + 1].getEdge(2).setOpposite(tris[0].getEdge(k))
  else:
    tris[0] = createTriangle(vtx[0], vtx[2], vtx[1])
    tris[1] = createTriangle(vtx[3], vtx[0], vtx[1])
    tris[2] = createTriangle(vtx[3], vtx[1], vtx[2])
    tris[3] = createTriangle(vtx[3], vtx[2], vtx[0])

    for i in 0..<3:
      let k = (i + 1) %% 3
      tris[i + 1].getEdge(0).setOpposite(tris[k + 1].getEdge(1))
      tris[i + 1].getEdge(2).setOpposite(tris[0].getEdge((3 - i) %% 3))

  for t in tris: q.faces.add(t)

  for i,v in q.pointBuffer:
    if vtx.anyIt(it == v): continue

    maxDist = q.tolerance
    var maxFace: ptr Face
    for t in tris:
      let dist = t.distanceToPlane(v.pnt)
      if dist > maxDist:
        maxFace = t
        maxDist = dist

    if maxFace != nil:
      q.addPointToFace(q.pointBuffer[i].addr, maxFace)

proc getFaceIndices(q: QuickHull3D, face: ptr Face, flags: int): seq[int] =
  let
    ccw = (flags and CLOCKWISE) == 0
    indexedFromOne = (flags and INDEXED_FROM_ONE) != 0
    pointRelative = (flags and POINT_RELATIVE) != 0

  var
    indices: seq[int] = @[]
    hedge = face.he0
    k = 0

  Do:
    var idx = hedge.head().index
    if pointRelative:
      idx = q.vertexPointIndices[idx]
    if indexedFromOne:
      inc idx

    assert idx >= 0, "negative ace index"

    indices.add(idx)
    inc k
    hedge = if ccw: hedge.next else: hedge.prev

    While hedge != face.he0
  indices

proc resolveUnclaimedPoints(q: var QuickHull3D, newFaces: FaceList) =
  var
    vtxNext = q.unclaimed.first()
    vtx = vtxNext

  while vtx != nil:

    vtxNext = vtx.next

    var
      maxDist = q.tolerance
      maxFace: ptr Face = nil
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

proc removeAllPointsFromFace(q: var QuickHull3D, face: ptr Face): ptr Vertex =
  if face.outside != nil:
    var end_face = face.outside
    while end_face.next != nil and end_face.next.face == face:
      end_face = end_face.next

    q.claimed.del(face.outside, end_face)
    end_face.next = nil
    return face.outside
  else:
    return nil


proc deleteFacePoints(q: var QuickHull3D, face, absorbingFace: ptr Face) =
  var faceVtxs = q.removeAllPointsFromFace(face)

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


proc oppFaceDistance(q: QuickHull3D, he: ptr HalfEdge): float =
  he.face.distanceToPlane(he.opposite.face.getCentroid())


proc doAdjacentMerge(q: var QuickHull3D, face: var ptr Face,
        mergeType: int): bool =

  var
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
      for i in 0..<face.mergeAdjacentFace(hedge, q.discardedFaces):
        q.deleteFacePoints(q.discardedFaces[i], face)
      return true

    hedge = hedge.next

    While hedge != face.he0

  if not convex:
    face.mark = NON_CONVEX

  false


proc calculateHorizon(q: var QuickHull3D, eyePnt: ptr Point3d,
        pedge0: ptr HalfEdge, face: ptr Face, horizon: var HalfEdgeVector) =

  q.deleteFacePoints(face, nil)
  face.mark = DELETED

  var
    edge: ptr HalfEdge
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

proc addAdjoiningFace(q: var QuickHull3D, eyeVtx: ptr Vertex,
        he: ptr HalfEdge): ptr HalfEdge =
  var face = createTriangle(eyeVtx, he.tail(), he.head())
  q.faces.add(face)
  face.getEdge(-1).setOpposite(he.getOpposite())
  face.getEdge(0)

proc addNewFaces(q: var QuickHull3D, newFaces: var FaceList,
        eyeVtx: ptr Vertex, horizon: HalfEdgeVector) =

  newFaces.clear()

  var
    hedgeSidePrev: ptr HalfEdge = nil
    hedgeSideBegin: ptr HalfEdge = nil

  for horizonHe in horizon:

    var hedgeSide = q.addAdjoiningFace(eyeVtx, horizonHe)

    if hedgeSidePrev != nil:
      hedgeSide.next.setOpposite(hedgeSidePrev)
    else:
      hedgeSideBegin = hedgeSide

    newFaces.add(hedgeSide.getFace())
    hedgeSidePrev = hedgeSide

  hedgeSideBegin.next.setOpposite(hedgeSidePrev)

proc nextPointToAdd(q: QuickHull3D): ptr Vertex =
  if not q.claimed.isEmpty():
    var
      eyeFace = q.claimed.first().face
      eyeVtx: ptr Vertex = nil
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


proc addPointToHull(q: var QuickHull3D, eyeVtx: ptr Vertex) =

  q.horizon.setLen(0)
  q.unclaimed.clear()

  q.removePointFromFace(eyeVtx, eyeVtx.face)
  let he_nil: ptr HalfEdge = nil
  q.calculateHorizon(eyeVtx.pnt.unsafeAddr, he_nil, eyeVtx.face, q.horizon)
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

  var eyeVtx = q.nextPointToAdd()

  while eyeVtx != nil:
    q.addPointToHull(eyeVtx)
    eyeVtx = q.nextPointToAdd()

  q.reindexFacesAndVertices()


proc markFaceVertices(q: var QuickHull3D, face: ptr Face, mark: int) =
  var
    he0 = face.getFirstEdge()
    he = he0
  Do:
    he.head().index = mark
    he = he.next

    While he != he0

proc reindexFacesAndVertices(q: var QuickHull3D) =
  for pb in q.pointBuffer.mitems: pb.index = HIDDEN

  # remove inactive faces and mark active vertices
  var i = 0
  while i < q.faces.len:
    if q.faces[i].mark != VISIBLE:
      q.faces[i].delete
      q.faces.del(i)
    else:
      q.markFaceVertices(q.faces[i], DISABLED)
      inc i

  # reindex vertices
  var i_vert = 0
  i=0
  for pb in q.pointBuffer.mitems:
    if pb.index == DISABLED:
      q.vertexPointIndices[i_vert] = i
      pb.index = i_vert
      inc i_vert
    inc i

proc checkFaceConvexity(q: QuickHull3D, face: ptr Face, tol: float): bool =
  var he = face.he0

  Do:
    face.checkConsistency()
    # make sure edge is convex
    if q.oppFaceDistance(he) > tol: return false
    if q.oppFaceDistance(he.opposite) > tol: return false
    if he.next.oppositeFace() == he.oppositeFace():  return false

    he = he.next

    While he != face.he0

  return true


proc checkFaces(q: QuickHull3D, tol: float): bool =  # check edge convexity
  result = true
  block faces:
    for face in q.faces:
      if face.mark == VISIBLE:
        if not q.checkFaceConvexity(face, tol):
          result = false
          break faces


proc check(q: QuickHull3D, tol: float): bool =

  # check to make sure all edges are fully connected
  # and that the edges are convex
  var pointTol = 10 * tol

  if not q.checkFaces(q.tolerance):
    return false


  # check point inclusion

  for p in q.pointBuffer:
    for face in q.faces:
      if face.mark == VISIBLE:
        if face.distanceToPlane(p.pnt) > pointTol:
          return false
  true


proc check*(q: QuickHull3D): bool = q.check(q.getDistanceTolerance)

# used for testing

proc waterman_poly*(radius: float): seq[Point3d] =
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


proc newConvexHull(points: seq[Point3d]): QuickHull3D =
  result = QuickHull3D(explicitTolerance : AUTOMATIC_TOLERANCE)

  result.discardedFaces = newSeq[ptr Face](3)
  result.maxVtxs = newSeq[Vertex](3)
  result.minVtxs = newSeq[Vertex](3)
  result.build(points)

proc getVertices(q: QuickHull3D): seq[Point3D] =
  var max = 0.0

  for i, pnt in q.pointBuffer:
    result.add(q.pointBuffer[q.vertexPointIndices[i]].pnt)
    max = max.max(result[i].x.max(result[i].y.max(result[i].z)))

  if max != 0.0:
    for v in result.mitems: v/=max
  result

proc getFaces(q: QuickHull3D, indexFlags: int = CCW): seq[seq[int]] =
  for face in q.faces:
    result.add(q.getFaceIndices(face, indexFlags))

# global interfaced proc's
proc convexHull*(points: seq[Point3d]): (seq[seq[int]], seq[Point3D]) =
  let q = newConvexHull(points)
  (q.getFaces, q.getVertices)
