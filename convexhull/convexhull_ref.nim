#[ 
    convex hull, ref version, 30% slower than ptr but safer and easier to maintain

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
    vertex: ref Vertex
    face: ref Face
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
    head, tail: ref Face

  Vertex = object
    pnt: ref Point3d
    index: int
    prev, next: ref Vertex
    face: ref Face

  VertexList = object
    head, tail: ref Vertex


proc box[T](x: T): ref T {.inline.} = new(result); result[] = x # obj to ref conversion

# new procs
proc newHalfEdge(v: ref Vertex, f: ref Face): ref HalfEdge {.inline.} = 
  HalfEdge(vertex: v, face: f).box
proc newFace: ref Face {.inline.} = Face(mark: VISIBLE).box
proc newVertex(pnt: ref Point3d, index: int): ref Vertex {.inline.} = 
  Vertex(pnt: pnt, index: index, face: nil).box

# Vertex
proc getPoint(v: ref Vertex): Point3d {.inline.} = v.pnt[]

# HalfEdge

proc head(he: HalfEdge): ref Vertex = he.vertex
proc tail(he: HalfEdge): ref Vertex =
  if he.prev != nil: he.prev.vertex else: nil
proc getNext(he: HalfEdge): ref HalfEdge = he.next
proc getFace(he: HalfEdge): ref Face = he.face
proc getOpposite(he: HalfEdge): ref HalfEdge = he.opposite
proc setOpposite(he: ref HalfEdge, edge: ref HalfEdge) =
  he.opposite = edge
  edge.opposite = he
proc oppositeFace(he: HalfEdge): ref Face =
  if he.opposite != nil: he.opposite.face else: nil
proc lengthSq(he: HalfEdge): float =
  if he.tail != nil: he.head.pnt.distSq he.tail.getPoint
  else: -1

# FaceList
proc clear(fl: var FaceList) =
  fl.head = nil
  fl.tail = nil

proc add(fl: var FaceList, pvtx: ref Face) =
  var vtx = pvtx

  if fl.head == nil: fl.head = vtx
  else: fl.tail.next = vtx

  vtx.next = nil
  fl.tail = vtx

proc first(fl: FaceList): ref Face = fl.head

# Face

proc computeCentroid(face: var Face) =
  face.centroid = dvec3(0, 0, 0)
  var he = face.he0
  Do:
    face.centroid += he.head.getPoint
    he = he.next
    While he != face.he0
  face.centroid /= face.numVerts.float

proc computeNormal(face: var Face) =

  var
    he1 = face.he0.next
    he2 = he1.next

    p0 = face.he0.head.getPoint
    p2 = he1.head.getPoint
    d2 = p2 - p0

  face.normal = dvec3(0, 0, 0)
  face.numVerts = 2

  while he2 != face.he0:
    var d1 = d2

    p2 = he2.head.getPoint

    d2 = p2-p0

    face.normal += d1.cross d2

    he1 = he2
    he2 = he2.next
    inc face.numVerts

  face.area = face.normal.length
  face.normal /= face.area

proc computeNormal(face: var Face, minArea: float) =
  face.computeNormal

  if face.area < minArea:

    var
      hedgeMax: ref HalfEdge = nil
      lenSqrMax = 0.0
      hedge = face.he0
    Do:
      var lenSqr = hedge.lengthSq
      if lenSqr > lenSqrMax:
        hedgeMax = hedge
        lenSqrMax = lenSqr

      hedge = hedge.next
      While hedge != face.he0

    let
      p2 = hedgeMax.head.getPoint
      p1 = hedgeMax.tail.getPoint
      lenMax = lenSqrMax.sqrt
      u = (p2-p1) / lenMax

    face.normal -= (face.normal.dot(u) * u).normalize

proc computeNormalAndCentroid(face: var Face) =

  face.computeNormal
  face.computeCentroid
  face.planeOffset = face.normal.dot face.centroid

  var
    numv = 0
    he = face.he0
  Do:
    inc numv
    he = he.next
    While he != face.he0

  assert numv == face.numVerts

proc computeNormalAndCentroid(face: var Face, minArea: float) =
  face.computeNormal minArea
  face.computeCentroid
  face.planeOffset = face.normal.dot face.centroid

proc createTriangle(v0, v1, v2: ref Vertex, minArea: float = 0.0): ref Face =
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
  face.computeNormalAndCentroid minArea
  face

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

proc distanceToPlane(face: Face, p: Point3D): float = 
  face.normal.dot(p) - face.planeOffset

proc getCentroid(face: Face): Point3D = face.centroid
proc numVertices(face: Face): int = face.numVerts

proc connectHalfEdges(face: var Face, hedgePrev,
        hedge: ref HalfEdge): ref Face =

  var discardedFace: ref Face = nil

  if hedgePrev.oppositeFace == hedge.oppositeFace: # then there is a redundant edge that we can get rid off

    var
      oppFace = hedge.oppositeFace
      hedgeOpp: ref HalfEdge

    if hedgePrev == face.he0:
      face.he0 = hedge

    if oppFace.numVertices == 3: # then we can get rid of the opposite face altogether
      hedgeOpp = hedge.getOpposite.prev.getOpposite
      oppFace.mark = DELETED
      discardedFace = oppFace
    else:
      hedgeOpp = hedge.getOpposite.next

      if oppFace.he0 == hedgeOpp.prev:
        oppFace.he0 = hedgeOpp

      hedgeOpp.prev = hedgeOpp.prev.prev
      hedgeOpp.prev.next = hedgeOpp

    hedge.prev = hedgePrev.prev
    hedge.prev.next = hedge

    hedge.opposite = hedgeOpp
    hedgeOpp.opposite = hedge

    # oppFace was modified, so need to recompute
    oppFace.computeNormalAndCentroid

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

    let hedgeOpp = hedge.getOpposite

    assert hedgeOpp != nil, "unreflected half edge "
    assert hedgeOpp.getOpposite == hedge
    assert hedgeOpp.head == hedge.tail and hedge.head ==
            hedgeOpp.tail

    let oppFace = hedgeOpp.face

    assert oppFace != nil
    assert oppFace.mark != DELETED

    var d = face.distanceToPlane(hedge.head.getPoint).abs
    if d > maxd: maxd = d

    inc numv
    hedge = hedge.next

    While hedge != face.he0

  assert numv == face.numVerts

proc mergeAdjacentFace(face: var ref Face, hedgeAdj: ref HalfEdge,
        discarded: var seq[ref Face]): int =

  var
    oppFace = hedgeAdj.oppositeFace
    numDiscarded = 0

  discarded[numDiscarded] = oppFace
  inc numDiscarded
  oppFace.mark = DELETED

  let hedgeOpp = hedgeAdj.getOpposite
  var
    hedgeAdjPrev = hedgeAdj.prev
    hedgeAdjNext = hedgeAdj.next
    hedgeOppPrev = hedgeOpp.prev
    hedgeOppNext = hedgeOpp.next

  while hedgeAdjPrev.oppositeFace == oppFace:
    hedgeAdjPrev = hedgeAdjPrev.prev
    hedgeOppNext = hedgeOppNext.next

  while hedgeAdjNext.oppositeFace == oppFace:
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

  face.computeNormalAndCentroid
  face.checkConsistency

  numDiscarded


# VertexList

proc clear(v: var VertexList) =
  v.head = nil
  v.tail = nil

proc add(v: var VertexList, vtx: ref Vertex) =
  if v.head == nil:
    v.head = vtx
  else:
    v.tail.next = vtx

  vtx.prev = v.tail
  vtx.next = nil
  v.tail = vtx

proc addAll(v: var VertexList, vtx: var ref Vertex) =
  if v.head == nil:
    v.head = vtx
  else:
    v.tail.next = vtx

  vtx.prev = v.tail
  while vtx.next != nil:
    vtx = vtx.next

  v.tail = vtx

proc del(v: var VertexList, vtx: ref Vertex) =
  if vtx.prev == nil:
    v.head = vtx.next
  else:
    vtx.prev.next = vtx.next

  if vtx.next == nil:
    v.tail = vtx.prev
  else:
    vtx.next.prev = vtx.prev

proc del(v: var VertexList, vtx1, vtx2: ref Vertex) =
  if vtx1.prev == nil:
    v.head = vtx2.next
  else:
    vtx1.prev.next = vtx2.next

  if vtx2.next == nil:
    v.tail = vtx1.prev
  else:
    vtx2.next.prev = vtx1.prev

proc insertBefore(v: var VertexList, vtx, next: ref Vertex) =
  vtx.prev = next.prev
  if next.prev == nil:
    v.head = vtx
  else:
    next.prev.next = vtx

  vtx.next = next
  next.prev = vtx

proc first(v: VertexList): ref Vertex = v.head
proc isEmpty(v: VertexList): bool = v.head == nil

type FaceVector = seq[ref Face]
type HalfEdgeVector = seq[ref HalfEdge]
type VertexVector = seq[ref Vertex]

# QuickHull3D

type QuickHull3D* = object
  pointBuffer: VertexVector
  faces: FaceVector
  numVertices: int
  vertexPointIndices: seq[int]
  newFaces: FaceList
  discardedFaces: FaceVector
  unclaimed, claimed: VertexList
  horizon: HalfEdgeVector
  minVtxs, maxVtxs: VertexVector
  explicitTolerance, tolerance: float # = AUTOMATIC_TOLERANCE

proc getDistanceTolerance(q: QuickHull3D): float = q.tolerance

proc addPointToFace(q: var QuickHull3D, vtx: ref Vertex, face: ref Face) =

  vtx.face = face

  if face.outside == nil:
    q.claimed.add vtx
  else:
    q.claimed.insertBefore(vtx, face.outside)
  face.outside = vtx

proc removePointFromFace(q: var QuickHull3D, vtx: ref Vertex, face: ref Face) =
  if vtx == face.outside:
    if vtx.next != nil and vtx.next.face == face:
      face.outside = vtx.next
    else:
      face.outside = nil
  q.claimed.del vtx

proc setPoints(q: var QuickHull3D, points: seq[Point3D]) =
  q.vertexPointIndices = newSeq[int]points.len

  for i, point in points:
    q.pointBuffer.add newVertex(pnt = point.box, index = i)

proc buildHull(q: var QuickHull3D)

proc build(q: var QuickHull3D, points: seq[Point3D]) =
  assert points.len >= 4, "QH needs more than 4 points"

  q.setPoints points
  q.buildHull

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
    let diff = q.maxVtxs[i].getPoint[i] - q.minVtxs[i].getPoint[i]
    if diff > max:
      max = diff
      imax = i

  assert max > q.tolerance, "Input points appear to be coincident"


  # set first two vertices to be those with the greatest
  # one dimensional separation
  var vtx = @[q.maxVtxs[imax], q.minVtxs[imax], nil, nil]

  # set third vertex to be the vertex farthest from
  # the line between vtx0 and vtx1
  var
    u01, nrml, xprod: DVec3
    maxSqr = 0.0

  u01 = (vtx[1].getPoint - vtx[0].getPoint).normalize

  for i, pb in q.pointBuffer:

    xprod = u01.cross pb.pnt - vtx[0].getPoint
    let lenSqr = xprod.lengthSq

    if lenSqr > maxSqr and pb != vtx[0][] and pb != vtx[1][]:
      maxSqr = lenSqr
      vtx[2] = q.pointBuffer[i]
      nrml = xprod

  assert maxSqr.sqrt > 100 * q.tolerance, "Input points appear to be colinear"

  nrml = nrml.normalize

  var
    maxDist = 0.0
    d0 = vtx[2].pnt.dot nrml

  for i, pb in q.pointBuffer:
    let dist = (pb.pnt.dot(nrml) - d0).abs
    if dist > maxDist and pb != vtx[0][] and pb != vtx[1][] and pb != vtx[2][]:
      maxDist = dist
      vtx[3] = q.pointBuffer[i]


  assert maxDist.abs > 100.0 * q.tolerance, "Input points appear to be coplanar"

  var tris = newSeq[ref Face]4

  if vtx[3].pnt.dot(nrml) - d0 < 0:
    tris[0] = createTriangle(vtx[0], vtx[1], vtx[2])
    tris[1] = createTriangle(vtx[3], vtx[1], vtx[0])
    tris[2] = createTriangle(vtx[3], vtx[2], vtx[1])
    tris[3] = createTriangle(vtx[3], vtx[0], vtx[2])

    for i in 0..<3:
      let k = (i + 1) %% 3
      tris[i + 1].getEdge(1).setOpposite tris[k + 1].getEdge(0)
      tris[i + 1].getEdge(2).setOpposite tris[0].getEdge(k)
  else:
    tris[0] = createTriangle(vtx[0], vtx[2], vtx[1])
    tris[1] = createTriangle(vtx[3], vtx[0], vtx[1])
    tris[2] = createTriangle(vtx[3], vtx[1], vtx[2])
    tris[3] = createTriangle(vtx[3], vtx[2], vtx[0])

    for i in 0..<3:
      let k = (i + 1) %% 3
      tris[i + 1].getEdge(0).setOpposite tris[k + 1].getEdge(1)
      tris[i + 1].getEdge(2).setOpposite tris[0].getEdge((3 - i) %% 3)

  q.faces.insert tris

  for i, v in q.pointBuffer:
    if vtx.anyIt it == v: continue

    maxDist = q.tolerance
    var maxFace: ref Face
    for t in tris:
      let dist = t.distanceToPlane v.getPoint
      if dist > maxDist:
        maxFace = t
        maxDist = dist

    if maxFace != nil:
      q.addPointToFace q.pointBuffer[i], maxFace

proc getFaceIndices(q: QuickHull3D, face: ref Face, flags: int): seq[int] =
  let
    ccw = (flags and CLOCKWISE) == 0
    indexedFromOne = (flags and INDEXED_FROM_ONE) != 0
    pointRelative = (flags and POINT_RELATIVE) != 0

  var
    indices: seq[int]
    hedge = face.he0

  Do:
    var idx = hedge.head.index
    if pointRelative:
      idx = q.vertexPointIndices[idx]
    if indexedFromOne:
      inc idx

    assert idx >= 0, "negative face index"

    indices.add idx
    hedge = if ccw: hedge.next else: hedge.prev

    While hedge != face.he0
  indices

proc resolveUnclaimedPoints(q: var QuickHull3D, newFaces: FaceList) =
  var
    vtxNext = q.unclaimed.first
    vtx = vtxNext

  while vtx != nil:

    vtxNext = vtx.next

    var
      maxDist = q.tolerance
      maxFace: ref Face = nil
      newFace = newFaces.first

    while newFace != nil:
      if newFace.mark == VISIBLE:

        let dist = newFace.distanceToPlane vtx.getPoint
        if dist > maxDist:
          maxDist = dist
          maxFace = newFace

        if maxDist > 1000 * q.tolerance:
          break

      newFace = newFace.next

    if maxFace != nil:
      q.addPointToFace vtx, maxFace

    vtx = vtxNext

proc removeAllPointsFromFace(q: var QuickHull3D, face: ref Face): ref Vertex =
  if face.outside != nil:
    var end_face = face.outside
    while end_face.next != nil and end_face.next.face == face:
      end_face = end_face.next

    q.claimed.del face.outside, end_face
    end_face.next = nil
    face.outside
  else:
    nil


proc deleteFacePoints(q: var QuickHull3D, face, absorbingFace: ref Face) =
  var faceVtxs = q.removeAllPointsFromFace(face)

  if faceVtxs != nil:
    if absorbingFace == nil:
      q.unclaimed.addAll faceVtxs
    else:
      var
        vtxNext = faceVtxs
        vtx = vtxNext

      while vtx != nil:
        vtxNext = vtx.next
        if absorbingFace.distanceToPlane(vtx.getPoint) > q.tolerance:
          q.addPointToFace vtx, absorbingFace
        else:
          q.unclaimed.add vtx
        vtx = vtxNext


proc oppFaceDistance(q: QuickHull3D, he: ref HalfEdge): float =
  he.face.distanceToPlane he.opposite.face.getCentroid


proc doAdjacentMerge(q: var QuickHull3D, face: var ref Face,
        mergeType: int): bool =

  var
    hedge = face.he0
    convex = true

  Do:

    var
      oppFace = hedge.oppositeFace
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
        if q.oppFaceDistance(hedge) > -q.tolerance: merge = true
        elif q.oppFaceDistance(hedge.opposite) > -q.tolerance: convex = false
      else:
        if q.oppFaceDistance(hedge.opposite) > -q.tolerance: merge = true
        elif q.oppFaceDistance(hedge) > -q.tolerance: convex = false

    if merge:
      for i in 0..<face.mergeAdjacentFace(hedge, q.discardedFaces):
        q.deleteFacePoints q.discardedFaces[i], face
      return true

    hedge = hedge.next

    While hedge != face.he0

  if not convex:
    face.mark = NON_CONVEX

  false


proc calculateHorizon(q: var QuickHull3D, eyePnt: ref Point3d,
        pedge0: ref HalfEdge, face: ref Face, horizon: var HalfEdgeVector) =

  q.deleteFacePoints face, nil
  face.mark = DELETED

  var
    edge: ref HalfEdge
    edge0 = pedge0

  if edge0 == nil:
    edge0 = face.getEdge 0
    edge = edge0
  else:
    edge = edge0.getNext

  Do:
    var oppFace = edge.oppositeFace
    if oppFace.mark == VISIBLE:
      if oppFace.distanceToPlane(eyePnt[]) > q.tolerance:
        q.calculateHorizon eyePnt, edge.getOpposite, oppFace, horizon
      else:
        horizon.add edge

    edge = edge.getNext
    While edge != edge0

proc addAdjoiningFace(q: var QuickHull3D, eyeVtx: ref Vertex,
        he: ref HalfEdge): ref HalfEdge =
  var face = createTriangle(eyeVtx, he.tail, he.head)
  q.faces.add face
  face.getEdge(-1).setOpposite he.getOpposite
  face.getEdge 0

proc addNewFaces(q: var QuickHull3D, newFaces: var FaceList,
        eyeVtx: ref Vertex, horizon: HalfEdgeVector) =

  newFaces.clear

  var
    hedgeSidePrev: ref HalfEdge = nil
    hedgeSideBegin: ref HalfEdge = nil

  for horizonHe in horizon:

    var hedgeSide = q.addAdjoiningFace(eyeVtx, horizonHe)

    if hedgeSidePrev != nil:
      hedgeSide.next.setOpposite hedgeSidePrev
    else:
      hedgeSideBegin = hedgeSide

    newFaces.add hedgeSide.getFace
    hedgeSidePrev = hedgeSide

  hedgeSideBegin.next.setOpposite(hedgeSidePrev)

proc nextPointToAdd(q: QuickHull3D): ref Vertex =
  if not q.claimed.isEmpty:
    var
      eyeFace = q.claimed.first.face
      eyeVtx: ref Vertex = nil
      maxDist = 0.0

    var vtx = eyeFace.outside
    while vtx != nil and vtx.face == eyeFace:

      let dist = eyeFace.distanceToPlane(vtx.getPoint)
      if dist > maxDist:
        maxDist = dist
        eyeVtx = vtx

      vtx = vtx.next

    return eyeVtx
  else:
    return nil


proc addPointToHull(q: var QuickHull3D, eyeVtx: ref Vertex) =

  q.horizon = @[]
  q.unclaimed.clear

  q.removePointFromFace eyeVtx, eyeVtx.face
  q.calculateHorizon eyeVtx.pnt, nil, eyeVtx.face, q.horizon
  q.newFaces.clear
  q.addNewFaces q.newFaces, eyeVtx, q.horizon

  # first merge pass ... merge faces which are non-convex
  # as determined by the larger face

  var face = q.newFaces.first
  while face != nil:
    if face.mark == VISIBLE:
      while q.doAdjacentMerge(face, NONCONVEX_WRT_LARGER_FACE): discard
    face = face.next


  # second merge pass ... merge faces which are non-convex
  # wrt either face

  face = q.newFaces.first
  while face != nil:

    if face.mark == NON_CONVEX:
      face.mark = VISIBLE
      while q.doAdjacentMerge(face, NONCONVEX): discard

    face = face.next


  q.resolveUnclaimedPoints(q.newFaces)

proc reindexFacesAndVertices(q: var QuickHull3D)
proc buildHull(q: var QuickHull3D) =

  q.computeMaxAndMin
  q.createInitialSimplex

  var eyeVtx = q.nextPointToAdd

  while eyeVtx != nil:
    q.addPointToHull eyeVtx
    eyeVtx = q.nextPointToAdd

  q.reindexFacesAndVertices


proc markFaceVertices(q: var QuickHull3D, face: ref Face, mark: int) =
  var
    he0 = face.getFirstEdge
    he = he0
  Do:
    he.head.index = mark
    he = he.next

    While he != he0

proc reindexFacesAndVertices(q: var QuickHull3D) =
  for pb in q.pointBuffer.mitems: pb.index = HIDDEN

  # remove inactive faces and mark active vertices
  var i = 0
  while i < q.faces.len:
    if q.faces[i].mark != VISIBLE:
      q.faces.del i
    else:
      q.markFaceVertices q.faces[i], DISABLED
      inc i

  # reindex vertices->calculate new q.numVertices
  (q.numVertices, i) = (0, 0)

  for pb in q.pointBuffer.mitems:
    if pb.index == DISABLED:
      q.vertexPointIndices[q.numVertices] = i
      pb.index = q.numVertices
      inc q.numVertices
    inc i

proc checkFaceConvexity(q: QuickHull3D, face: ref Face, tol: float): bool =
  var he = face.he0

  Do:
    face.checkConsistency
    # make sure edge is convex
    if q.oppFaceDistance(he) > tol: return false
    if q.oppFaceDistance(he.opposite) > tol: return false
    if he.next.oppositeFace == he.oppositeFace: return false

    he = he.next

    While he != face.he0

  return true


proc checkFaces(q: QuickHull3D, tol: float): bool = # check edge convexity
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
        if face.distanceToPlane(p.getPoint) > pointTol:
          return false
  true


proc check*(q: QuickHull3D): bool = q.check(q.getDistanceTolerance)

proc newConvexHull(points: seq[Point3d]): QuickHull3D =
  result = QuickHull3D(
      explicitTolerance: AUTOMATIC_TOLERANCE,
      discardedFaces: newSeq[ref Face](3), 
      maxVtxs: newSeq[ref Vertex](3), minVtxs: newSeq[ref Vertex](3))

  result.build(points)

proc getVertices(q: QuickHull3D): seq[Point3D] =
  var max = 0.0

  for i in 0..q.numVertices: # calculated in reindex
    result.add q.pointBuffer[q.vertexPointIndices[i]].getPoint
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
