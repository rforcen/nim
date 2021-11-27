# polygonizer for implicit 3d funcs 
# port from java 

import sequtils, tables, sugar, math, strformat, streams
import vec3

type
  LookupTable = object
    cubes : seq[Cube]

  Edge = object
    index, startVertexIndex, endVertexIndex : int
    connectedEdge0, connectedEdge1 : ref Edge

  Face = object
    index : int
    edges : seq[ref Edge]
    ambiguous : bool

  Cube = object
    index : int
    edges : seq[ref Edge]
    faces : seq[Face]

  EdgeKey = object
    i0, j0, k0, i1, j1, k1 : int

  Polygonizer = object
    min, max, d, nd : vec3
    idiv : veci3
    isovalue:float
    function : proc(x,y,z:float):float

    vertices, normals : seq[vec3]
    indices : seq[int] # in trigs

  vec3Func = proc(x,y,z:float):float


# Polygonizer
proc newPolygonizer*(min, max: vec3, idiv:veci3, isovalue:float, function:vec3Func):Polygonizer=
  Polygonizer(min:min, max:max, idiv:idiv, isovalue:isovalue, function:function)
proc newPolygonizer*(bounds : float, idiv:int, function:vec3Func) : Polygonizer =
  let b=bounds
  Polygonizer(min:[-b,-b,-b], max:[b,b,b], idiv:[idiv, idiv, idiv], isovalue:0, function:function)

proc box[T](x: T): ref T {.inline.} = new(result); result[] = x # obj to ref conversion

# edge
proc newEdge(index:int):Edge =
  const EDGE_VERTICES = [[0, 1], [1, 2], [3, 2], [0, 3], [4, 5], [5, 6], [7, 6], [4, 7], [0, 4], [1, 5], [2, 6], [3, 7] ]
  Edge(index:index, startVertexIndex: EDGE_VERTICES[index][0], endVertexIndex : EDGE_VERTICES[index][1])

proc setConnectedEdge(e:var Edge, index : int,  edge : ref Edge) =
  if index != 0 and index != 1:
    raise newException(IndexDefect, "edge index out of bounds")
  if index == 0: e.connectedEdge0 = edge
  else: e.connectedEdge1 = edge

proc getConnectedEdge(e:Edge, index:int):ref Edge=
  if index != 0 and index != 1:
      raise newException(IndexDefect, "edge index out of bounds")
  if index == 0: e.connectedEdge0 else: e.connectedEdge1

# edgekey
proc newEdgeKey(p0, p1 : veci3) : EdgeKey =
  if p1<p1: EdgeKey(i0:p0[0], j0:p0[1], k0:p0[2], i1:p1[0], j1:p1[1], k1:p1[2])
  else:     EdgeKey(i0:p1[0], j0:p1[1], k0:p1[2], i1:p0[0], j1:p0[1], k1:p0[2])

proc hash(ek:EdgeKey):int=
  const 
    BIT_SHIFT = 10
    BIT_MASK = (1 shl BIT_SHIFT)-1

  (((((ek.i0 and BIT_MASK) shl BIT_SHIFT) or (ek.j0 and BIT_MASK)) shl BIT_SHIFT) or (ek.k0 and BIT_MASK)) + (((((ek.i1 and BIT_MASK) shl BIT_SHIFT) or (ek.j1 and BIT_MASK)) shl BIT_SHIFT) or (ek.k1 and BIT_MASK))

# facefactory
proc createFace(faceindex, bitPatternOnCube :int, edges:var seq[ref Edge]):Face =
  const
    FACE_VERTICES = [[0, 1, 2, 3],[0, 1, 5, 4],[0, 3, 7, 4],[4, 5, 6, 7], [3, 2, 6, 7], [1, 2, 6, 5]]
    FACE_EDGES = [ [0,  1,  2,  3], [0, 9, 4, 8], [3, 11, 7, 8], [4, 5, 6, 7], [2, 10,  6, 11], [1, 10, 5, 9]]
    EDGE_CONNECTIVITY_ON_FACE = @[@[@[-1,-1,-1,-1], @[]], @[@[-1,-1,-1, 0], @[]], 
      @[@[ 1,-1,-1,-1], @[]], @[@[-1,-1,-1, 1], @[]], @[@[-1, 2,-1,-1], @[]], @[@[-1, 0,-1, 2], @[-1, 2,-1, 0]], 
      @[@[ 2,-1,-1,-1], @[]], @[@[-1,-1,-1, 2], @[]], @[@[-1,-1, 3,-1], @[]], @[@[-1,-1, 0,-1], @[]], 
      @[@[ 1,-1, 3,-1], @[ 3,-1, 1,-1]], @[@[-1,-1, 1,-1], @[]], 
      @[@[-1, 3,-1,-1], @[]], @[@[-1, 0,-1,-1], @[]], @[@[ 3,-1,-1,-1], @[]], @[@[-1,-1,-1,-1], @[]]]
    CW  = 1
    CCW = 0
    FACE_ORIENTATION = [CW, CCW, CW, CCW, CW, CCW]

  proc isAmbiguousBitPattern(bitPatternOnFace : int) : bool = bitPatternOnFace == 5 or bitPatternOnFace == 10

  proc buildBitPatternOnFace(bitPatternOnCube, faceIndex : int) : int =

    proc isBitOn(bitPatternOnCube, vertexIndex : int) : bool = (bitPatternOnCube and (1 shl vertexIndex)) != 0

    for vertexIndex in 0..<4:
      if isBitOn(bitPatternOnCube, FACE_VERTICES[faceIndex][vertexIndex]):
        result = result or (1 shl vertexIndex)

  let bitPatternOnFace = buildBitPatternOnFace(bitPatternOnCube, faceIndex)
    
  result = Face( index:faceindex, 
    edges: @[
          edges[FACE_EDGES[faceIndex][0]],  edges[FACE_EDGES[faceIndex][1]],
          edges[FACE_EDGES[faceIndex][2]],  edges[FACE_EDGES[faceIndex][3]]],
    ambiguous : isAmbiguousBitPattern(bitPatternOnFace))
  var connectivity = EDGE_CONNECTIVITY_ON_FACE[bitPatternOnFace]

  for i in 0..<2:
    if connectivity[i].len != 0:
      for vertexIndex in 0..<4:
          if connectivity[i][vertexIndex] != -1: 
            if FACE_ORIENTATION[faceIndex] == CW:
              result.edges[vertexIndex].setConnectedEdge(i, result.edges[connectivity[i][vertexIndex]])
            else:
              result.edges[connectivity[i][vertexIndex]].setConnectedEdge(i, result.edges[vertexIndex])

# cube
proc newCube(index:int):Cube =
  result.index=index
  for edgeIndex in 0..<12: result.edges.add box(newEdge(edgeIndex))
  for faceindex in 0..<6 : result.faces.add createFace(faceindex, index, result.edges)

proc getEdgeConnectivity(c:Cube, connectionSwitches : openArray[int]) : seq[int] =
  result = @[-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]

  for faceIndex in 0..<6:
      let face = c.faces[faceIndex]
      if face.ambiguous == false and connectionSwitches[faceIndex] != 0:
        raise newException(IndexDefect, "face in cube is not ambigous")
      for edgeIndex in 0..<4:
        let edge = face.edges[edgeIndex]
        if edge.getConnectedEdge(0) in face.edges:
          result[edge.index] = edge.getConnectedEdge(connectionSwitches[faceIndex]).index

# LookupTable: set of 256 cubes
var lookupTable = LookupTable(
  cubes: collect(newSeq, for i in 0..<256: newCube(i))
)

# evaluate func
proc sample(p:Polygonizer, plane:var seq[seq[float]], z:float)=
  for j in 0..p.idiv[1]:
    let y=p.min[1] + j.float * p.d[1]
    for i in 0..p.idiv[0]:
      let x = p.min[0] + i.float * p.d[0]
      plane[j][i]=p.function(x,y,z)

proc lerp(t:float, v0, v1:vec3) : vec3 = [v0[0] + t * (v1[0] - v0[0]), v0[1] + t * (v1[1] - v0[1]), v0[2] + t * (v1[2] - v0[2])]

converter i2f(i:int):float=i.float

proc calcNormal(p : Polygonizer, v : vec3) : vec3 =
  let 
    (x,y,z)=(v[0], v[1], v[2])
   
    f = p.function(x, y, z)

  result = [ 
    -(p.function(x+p.nd[0], y, z) - f) / p.nd[0], 
    -(p.function(x, y+p.nd[1], z) - f) / p.nd[1], 
    -(p.function(x, y, z+p.nd[2]) - f) / p.nd[2]]

  let l = result.hypot
    
  if l > 0.0: result /= l

####
proc polygonize*(p:var Polygonizer)=
  var
    edgeToIndex : array[12, int]
    indexTable : Table[EdgeKey, int] 
    upperPlane = newSeqWith(p.idiv[1]+1, newSeq[float](p.idiv[0]+1))
    lowerPlane = newSeqWith(p.idiv[1]+1, newSeq[float](p.idiv[0]+1))
    eps = if p.isovalue == 0.0: 1.0e-5 else: p.isovalue * 1.0e-5

  p.vertices.setLen 0
  p.normals.setLen 0
  p.indices.setLen 0

  p.d = (p.max-p.min) / p.idiv
  p.nd = p.d * 0.001

  p.sample(lowerPlane, p.min[2])
  for k in 0..<p.idiv[2]:
    let 
      z1=p.min[2] + k.float * p.d[2]
      z2=p.min[2] + (k + 1).float * p.d[2]
    
    p.sample(upperPlane, z2)
    for j in 0..<p.idiv[1]:
      let
        y1 = p.min[1] + j.float * p.d[1]
        y2 = p.min[1] + (j + 1).float * p.d[1]

      for i in 0..<p.idiv[0]:
        let
          x1 = p.min[0] + i.float * p.d[0]
          x2 = p.min[0] + (i + 1).float * p.d[0]
          
        # Set sampled function values on each corner of the cube
        var values = [  lowerPlane[j][i],lowerPlane[j+1][i],lowerPlane[j+1][i+1],lowerPlane[j][i+1],
                        upperPlane[j][i],upperPlane[j+1][i],upperPlane[j+1][i+1],upperPlane[j][i+1] ]

        # Adjust the function values which are almost same as the
        # isovalue
        for i in 0..7:
          if abs(values[i] - p.isovalue) < eps: values[i] += 10.0 * eps

        # Calculate index into the lookup table
        var 
          cubeIndex = 0
          p2val=1
        for i in 0..7:
          if values[i] > p.isovalue: cubeIndex += p2val
          p2val = p2val shl 1

        # Skip the empty cube
        if cubeIndex == 0 or cubeIndex == 255:
          continue

        # Set up corner positions of the cube
        var 
          positionsD : array[8, vec3]  = [[x1, y1, z1],[x1, y2, z1],[x2, y2, z1],[x2, y1, z1],[x1, y1, z2],[x1, y2, z2],[x2, y2, z2],[x2, y1, z2]]
          positionsI : array[8, veci3] = [[i,j,k],[i,j+1,k],[i+1,j+1,k],[i+1,j,k],[i,j,k+1],[i,j+1,k+1],[i+1,j+1,k+1],[i+1,j,k+1]]

        # Find the cube edges which have intersection points with the isosurface
        let cube = lookupTable.cubes[cubeIndex]

        for edgeIndex in 0..<12:
          let edge = cube.edges[edgeIndex]
          if edge.getConnectedEdge(0) != nil:
            let key = newEdgeKey(positionsI[edge.startVertexIndex], positionsI[edge.endVertexIndex])
            if key in indexTable:
              edgeToIndex[edgeIndex] = indexTable[key]
            else:
              let
                t = (p.isovalue - values[edge.startVertexIndex]) / (values[edge.endVertexIndex] - values[edge.startVertexIndex])
                v = lerp(t, positionsD[edge.startVertexIndex], positionsD[edge.endVertexIndex])

              p.vertices.add(v)
              p.normals.add(p.calcNormal(v))
              
              edgeToIndex[edgeIndex] = p.vertices.high
              indexTable[key] = p.vertices.high
            

        # Resolve topological ambiguity on cube faces
        var connectionSwitches = collect(newSeq):
          for faceIndex in 0..<6:
            let face = cube.faces[faceIndex]
            if face.ambiguous:
              let
                d0 = values[face.edges[0].endVertexIndex] - values[face.edges[0].startVertexIndex]
                d1 = values[face.edges[2].endVertexIndex] - values[face.edges[2].startVertexIndex]
                t = (p.isovalue - values[face.edges[1].startVertexIndex]) / (values[face.edges[1].endVertexIndex] -
                      values[face.edges[1].startVertexIndex])
              if t > -d0 / (d1 - d0):1 else:0
            else:
              0
    

        # Get the connectivity graph of the cube edges and trace
        # it to generate triangles
        var 
          connectivity = cube.getEdgeConnectivity(connectionSwitches)
          edgeIndex=0

        while edgeIndex<12:
          if connectivity[edgeIndex] != -1:
            let
              index0 = edgeIndex
              index1 = connectivity[index0]
              index2 = connectivity[index1]

            p.indices.add(edgeToIndex[index0])
            p.indices.add(edgeToIndex[index1])
            p.indices.add(edgeToIndex[index2])

            connectivity[index0] = -1
            connectivity[index1] = -1
            if connectivity[index2] != index0:
              connectivity[index0] = index2
              continue
            
            connectivity[index2] = -1
          edgeIndex.inc

    # Swap the lower and upper plane
    swap lowerPlane, upperPlane


proc write_ply(p:Polygonizer, file_name : string)=
  var st =newFileStream(file_name, fmWrite)
  st.write fmt"""ply
format ascii 1.0
comment polygonizer generated
element vertex {p.vertices.len}
property float x
property float y
property float z
property float nx
property float ny
property float nz
element face {p.indices.len div 3}
property list uchar int vertex_indices
end_header
"""

  for (v,n) in zip(p.vertices, p.normals):
    st.write fmt"{v[0]} {v[1]} {v[2]} {n[0]} {n[1]} {n[2]}", "\n"
  for i in countup(0, p.indices.high, 3):
    st.write fmt"3 {p.indices[i]} {p.indices[i+1]} {p.indices[i+2]}", "\n"

  st.close

##### demo implicit func list
proc sqr(x:float):float=x*x
proc cube(x:float):float=x*x*x
proc sqr3(x:float):float=x*x*x
proc sqr4(x:float):float=x*x*x*x
proc sphere(x,y,z:float):float= x*x+y*y+z*z

proc NordstarndWeird(x,y,z:float):float=
  25*(x*x*x*(y + z) + y*y*y*(x + z) + z*z*z*(x + y)) + 50*(x*x*y*y + x*x*z*z + y*y*z*z) - 125*(x*x*y*z + y*y*x*z + z*z*x*y) + 60*x*y*z - 4*(x*y + y*z + z*x)

proc DecoCube(x,y,z:float):float =
  let 
    a = 0.95
    b = 0.01
  (sqr(x*x + y*y - a*a) + sqr(z*z - 1))*(sqr(y*y + z*z - a*a) + sqr(x*x - 1))*(sqr(z*z + x*x - a*a) + sqr(y*y - 1)) - b

proc Cassini(x,y,z:float):float =
  let a = 0.3
  (sqr((x - a)) + z*z) * (sqr((x + a)) + z*z) - y^4 # ( (x-a)^2 + y^2) ((x+a)^2 + y^2) = z^4 a = 0.5
    
proc Orth(x,y,z:float):float=
  let 
    a = 0.06
    b = 2;
  (sqr(x*x + y*y - 1) + z*z)*(sqr(y*y + z*z - 1) + x*x)*(sqr(z*z + x*x - 1) + y*y)-a*a*(1 + b*(x*x + y*y + z*z))

proc Orthogonal(x,y,z:float):float =
  let (a,b) = (0.06, 2)
  Orth(x,y,z)

proc Orth3(x,y,z:float):float =
  4.0 - Orth(x + 0.5, y - 0.5, z - 0.5) - Orth(x - 0.5, y + 0.5, z - 0.5) - Orth(x - 0.5, y - 0.5, z + 0.5)
    
proc Pretzel(x,y,z:float):float =
  let aa = 1.6
  sqr( ((x - 1)*(x - 1) + y*y - aa*aa) * ((x + 1)*(x + 1) + y*y - aa*aa)) + z*z*10 - 1
    
proc Tooth(x,y,z:float):float =
  sqr4(x) + sqr4(y) + sqr4(z) - sqr(x) - sqr(y) - sqr(z)
    
proc Pilz(x,y,z:float):float =
  let (a,b) = (0.05, -0.1)
  sqr( sqr(x*x + y*y - 1) + sqr(z - 0.5)) * ( sqr(y*y / a*a + sqr(z + b) - 1.0) + x*x) - a * (1.0 + a*sqr(z - 0.5))
    
proc Bretzel(x,y,z:float):float =
  let 
    a = 0.003
    b = 0.7
  sqr(x*x*(1 - x*x) - y*y)  + 0.5*z*z - a*(1 + b*(x*x + y*y + z*z))

proc BarthDecic(x,y,z:float):float =
  let 
    GR = 1.6180339887 # Golden ratio
    GR2 = GR * GR
    GR4 = GR2 * GR2
    w = 0.3
    
  8*(x*x - GR4*y*y)*(y*y - GR4*z*z)*(z*z - GR4*x*x)*(x*x*x*x + y*y*y*y + z*z*z*z - 2*x*x*y*y - 2*x*x*z*z - 2*y*y*z*z)+
  (3 + 5*GR)*sqr((x*x + y*y + z*z - w*w))*sqr((x*x + y*y + z*z - (2 - GR)*w*w))*w*w
    
proc Clebsch0 (x,y,z:float):float =
  81*(cube(x) + cube(y) + cube(z)) - 189*(sqr(x)*y + sqr(x)*z + sqr(y)*x + sqr(y)*z + sqr(z)*x + sqr(z)*y) + 54*(x*y*z) + 126*(x*y + x*z + y*z) - 9*(sqr(x) + sqr(y) + sqr(z)) - 9*(x + y + z) + 1
    
proc Clebsch(x,y,z:float):float =
  16 * cube(x) + 16 * cube(y) - 31 * cube(z) + 24 * sqr(x) * z - 48 * sqr(x) * y - 48 * x * sqr(y) + 24 * sqr(y) * z - 54 * sqrt(3.0) * sqr(z) - 72 * z
    
proc Chubs(x,y,z:float):float =
  x^4 + y^4 + z^4 - sqr(x) - sqr(y) - sqr(z) + 0.5 # x^4 + y^4 + z^4 - x^2 - y^2 - z^2 + 0.5 = 0
    
proc Chair(x,y,z:float):float =
  let 
    k = 5
    a = 0.95
    b = 0.8
  sqr(sqr(x) + sqr(y) + sqr(z) - a*sqr(k)) - b*((sqr((z - k)) - 2*sqr(x))*(sqr((z + k)) - 2*sqr(y)))
  # (x^2+y^2+z^2-a*k^2)^2-b*((z-k)^2-2*x^2)*((z+k)^2-2*y^2)=0, 	  with k=5, a=0.95 and b=0.8.

proc Roman(x,y,z:float):float =
  let r=2
  sqr(x)*sqr(y) + sqr(y)*sqr(z) + sqr(z)*sqr(x) - r*x*y*z

proc Sinxyz(x,y,z:float):float =
  sin(x)*sin(y)*sin(z)
    
proc F001(x,y,z:float):float =
  sqr3(x)+sqr3(y)+sqr4(z)-10 # x^3 + y^3 + z^4 -10 = 0
    
proc TangleCube(x,y,z:float):float =
  sqr4(x) - 5*sqr(x) + sqr4(y) - 5*sqr(y) + sqr4(z) - 5*sqr(z) + 11.8

proc Goursat(x,y,z:float):float = # (x^4 + y^4 + z^4) + a * (x^2 + y^2 + z^2)^2 + b * (x^2 + y^2 + z^2) + c = 0 	
  let (a,b,c)=(0,0,-1)
  sqr4(x)+sqr4(y)+sqr4(z) + a*sqr(sqr(x)+sqr(y)+sqr(z)) + b*(sqr(x)+sqr(y)+sqr(z)) + c
    
proc Blob(x,y,z:float):float=
  4 - sphere(x + 0.5, y - 0.5, z - 0.5) - sphere(x - 0.5, y + 0.5, z - 0.5) - sphere(x - 0.5, y - 0.5, z + 0.5)

proc Sphere(x,y,z:float):float= sphere(x,y,z)-1

let ImplicitFuncs* = [
  Sphere, Blob, NordstarndWeird, DecoCube, Cassini, Orth, Orth3, 
  Pretzel, Tooth, Pilz, Bretzel , BarthDecic, Clebsch0, Clebsch,
  Chubs, Chair, Roman, TangleCube, Goursat, Sinxyz
]

################## generate ply file -> ctmviewer
when isMainModule:
  var p = newPolygonizer(bounds=2, idiv=150, Bretzel) # tweak bounds for each func

  p.polygonize()
  p.write_ply("impfunc.ply")
