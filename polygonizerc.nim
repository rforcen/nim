# poligonizer port from c

import strformat, random, math, streams
import implicit_funcs

const 
  # L:left direction:	-x, -i, R:right direction:	+x, +i, B: bottom direction: -y, -j
  # T:top direction:	+y, +j  N:near direction:	-z, -k , F far direction:	+z, +k 
  (L,R,B,T,N,F) = (0,1,2,3,4,5)

  # left bottom near corner # left bottom far corner  # left top near corner    
  # left top far corner     # right bottom near corner# right bottom far corner 
  # right top near corner   # right top far corner
  (LBN, LBF, LTN, LTF, RBN, RBF, RTN, RTF) = (0,1,2,3,4,5,6,7)

  ##  Cubical Polygonization (optional) 
  (LB,LT,LN,LF,RB,RT,RN,RF,BN,BF,TN,TF)=(0,1,2,3,4,5,6,7,8,9,10,11)

  HASHBIT=4
  HASHSIZE=(1 shl (3 * HASHBIT)) # hash table size (32768) 
  MASK=((1 shl HASHBIT) - 1)

  TET* =0 # use tetrahedral decomposition
  NOTET* =1 # no tetrahedral decomposition

  RES=40

{.push inline.}
proc hash(i, j, k: int): int = ((i and MASK) shl HASHBIT) or ((j and MASK) shl HASHBIT) or (k and MASK) 
proc bit(i, bit: int): int = (i shr bit) and 1
proc flip(i, bit: int): int = i xor (1 shl bit)           ##  flip the given bit of i
proc box[T](x: T): ref T {.inline.} = new(result); result[] = x # obj to ref conversion

proc itob(i:int):bool = cast[bool](i)
proc btoi(b:bool):int = cast[int](b)

{.pop.}

type 
  ImplicitFunc = proc(x,y,z:float):float

  Point = object
    x,y,z:float

  Test = object
    p : Point
    value : float
    ok : int
  
  Vertex = object
    position , normal : Point
  
  Vertices = seq[Vertex]

  Triangle = object
    i1, i2, i3 : int

  Triangles = seq[Triangle]

  Corner = object
    i, j, k : int
    point : Point
    value :float
  
  Cube = object
    i, j, k: int
    corners : array[8, ref Corner]
  
  Cubes = object
    cube : Cube
    next : ref Cubes

  CenterList = object
    i, j, k: int
    next : ref CenterList

  CornerList = object
    i, j, k: int
    value:float
    next : ref CornerList

  EdgeList = object
    i1, j1, k1, i2, j2, k2 : int
    vid : int
    next : ref EdgeList
  
  IntList = object
    i : int
    next : ref IntList
  
  IntLists = object
    list : ref IntList
    next : ref IntLists
  
  Polygonizer = object
    function: ImplicitFunc # implicit surface function 
    mode : int
    triproc: proc(p:var Polygonizer, i1,i2,i3:int, v:Vertices) : int     # triangle output function 
    size, delta : float   # cube size, normal delta 
    bounds : int           # cube range within lattice 
    start : Point          # start point on surface 
    cubes : ref Cubes         # active cubes 
    centers : array[HASHSIZE, ref CenterList] # cube center hash table 
    corners : array[HASHSIZE, ref CornerList] # corner value hash table 
    edges : array[HASHSIZE, ref EdgeList]     # edge and vertex id hash table 
    lefthanded:bool

    vertices : Vertices  # surface vertices 
    triangles:Triangles  # surface triangles

var 
  cubetable: array[256, ref IntLists]

# 			edge: LB, LT, LN, LF, RB, RT, RN, RF, BN, BF, TN, TF
  corner1 = [LBN, LTN, LBN, LBF, RBN, RTN, RBN, RBF, LBN, LBF, LTN, LTF]
  corner2 = [LBF, LTF, LTN, LTF, RBF, RTF, RTN, RTF, RBN, RBF, RTN, RTF]
  leftface = [B, L, L, F, R, T, N, R, N, B, T, F]

#  face on left when going corner1 to corner2
  rightface = [L, T, N, L, B, R, R, F, B, F, N, T]

# list iterator
{.push inline.}
iterator items[T : IntLists|IntList|CenterList|CornerList|EdgeList](pil:ref T):ref T=
  var il=pil
  while il!=nil:
    yield il
    il=il.next

proc `==`(l:CenterList, il:tuple[i,j,k:int]):bool=l.i == il.i and l.j == il.j and l.k == il.k
proc `==`(l:CornerList, il:tuple[i,j,k:int]):bool=l.i == il.i and l.j == il.j and l.k == il.k
proc `==`(l:EdgeList, il:tuple[i1,j1,k1,i2,j2,k2,:int]):bool=
  l.i1 == il.i1 and l.j1 == il.j1 and l.k1 == il.k1 and
  l.i2 == il.i2 and l.j2 == il.j2 and l.k2 == il.k2

{.pop.}
##

proc triangle2(p:var Polygonizer, i1, i2, i3:int, vertices : Vertices) : int

proc newPolygonizer*(function:ImplicitFunc, bounds:int, size:float):Polygonizer=
  Polygonizer(function:function, bounds:bounds, size:size, mode:TET, lefthanded:false, triproc:triangle2, delta : size / (RES * RES))

proc triangle2(p:var Polygonizer, i1, i2, i3:int, vertices : Vertices) : int=
  p.triangles.add if not p.lefthanded: Triangle(i1:i1, i2:i2, i3:i3) else: Triangle(i1:i1, i2:i3, i3:i2)
  return 1

# nextcwedge: next clockwise edge from given edge around given face
proc nextcwedge(edge, face : int) : int =
  template choose(dir, op1, op2 : int): int =
    if face == dir: op1 else: op2
    
  case edge
  of LB: choose(L, LF, BN)
  of LT: choose(L, LN, TF)
  of LN: choose(L, LB, TN)
  of LF: choose(L, LT, BF)
  of RB: choose(R, RN, BF)
  of RT: choose(R, RF, TN)
  of RN: choose(R, RT, BN)
  of RF: choose(R, RB, TF)
  of BN: choose(B, RB, LN)
  of BF: choose(B, LB, RF)
  of TN: choose(T, LT, RN)
  of TF: choose(T, RT, LF)
  else: 0
  
#  otherface: face adjoining edge that is not the given face
proc otherface (edge, face : int) : int = 
  result = leftface[edge]
  if face == result: result=rightface[edge]

proc makecubetable(p:var Polygonizer)=
  var 
    done:array[12,bool]
    pos:array[8, int]

  for i in 0..<256:

    for c in 0..<8 :  pos[c] = bit(i, c)

    for e in 0..<12:
      if not done[e] and pos[corner1[e]] != pos[corner2[e]]:
      
        var
          ints : ref IntList = nil
          start = e
          edge = e

          # get face that is to right of edge from pos to neg corner: 
          face = if pos[corner1[e]]!=0: rightface[e] else: leftface[e]

        while true:
          edge = nextcwedge(edge, face)
          done[edge] = true
          if pos[corner1[edge]] != pos[corner2[edge]]:          
            var
              tmp = ints
              ints = new(IntList)
            ints.i = edge
            ints.next = tmp # add edge to head of list 
            if edge == start: break
            face = otherface(edge, face)
        
        # add ints to head of table entry 
        cubetable[i] = IntLists(list:ints, next:cubetable[i]).box
  

proc setcenter(p:var Polygonizer, i, j, k : int) : int =
  let index = hash(i, j, k)

  for l in p.centers[index]:
    if l[]==(i,j,k): return 1

  p.centers[index] = CenterList(i:i, j:j, k:k, next:p.centers[index]).box

  return 0

#[ setcorner: return corner with the given lattice location
   set (and cache) its function value ]#

proc setcorner(p:var Polygonizer, i, j, k:int) : ref Corner = 
  var index = hash(i, j, k)

  result = Corner(i:i, j:j, k:k, point:Point(
      x: p.start.x + (i.float - 0.5) * p.size, 
      y: p.start.y + (j.float - 0.5) * p.size, 
      z: p.start.z + (k.float - 0.5) * p.size)).box
  
  for l in p.corners[index]:
    if l[]==(i,j,k):
      result.value = l.value
      return
  
  result.value = p.function(result.point.x, result.point.y, result.point.z)
  p.corners[index] = CornerList(i:i, j:j, k:k, value:result.value, next : p.corners[index]).box


proc find(p:Polygonizer, sign:int, x, y, z:float) : Test =
  var range = p.size
  result.ok = 1
  
  for i in 0..<10000:
    result.p = Point(x:x + range * (rand(1.0) - 0.5), y:y + range * (rand(1.0) - 0.5), z:z + range * (rand(1.0) - 0.5))
    result.value = p.function(result.p.x, result.p.y, result.p.z)
    if sign == (result.value > 0.0).btoi:  return
    range = range * 1.0005 # slowly expand search outwards 
  
  result.ok = 0

# converge: from two points of differing sign, converge to zero crossing 

proc converge(p1, p2 : Point, v:float, function:ImplicitFunc, p:var Point)=
  var  pos, neg : Point

  if v < 0:  pos=p2;  neg=p1
  else:      pos=p1;  neg=p2

  for i in 0..RES:
    p = Point(x: 0.5 * (pos.x + neg.x), y: 0.5 * (pos.y + neg.y), z: 0.5 * (pos.z + neg.z))

    if function(p.x, p.y, p.z) > 0.0:  pos=p
    else:  neg=p

# normal: compute unit length surface normal at point 
proc normal(p:Polygonizer, point : Point, v:var Point)=
  var f = p.function(point.x, point.y, point.z)
  v = Point(
      x: p.function(point.x + p.delta, point.y, point.z) - f,
      y: p.function(point.x, point.y + p.delta, point.z) - f,
      z: p.function(point.x, point.y, point.z + p.delta) - f)
  f = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
  if f != 0.0:
    v.x /= f
    v.y /= f
    v.z /= f

# setedge: set vertex id for edge 
proc setedge(p:var Polygonizer, pi1, pj1, pk1, pi2, pj2, pk2, vid: int)=
  var (i1,j1,k1,i2,j2,k2)=(pi1,pj1,pk1,pi2,pj2,pk2)

  if (i1,j1,k1) > (i2,j2,k2):
    swap i1,i2
    swap j1,j2
    swap k1,k2

  let index = hash(i1, j1, k1) + hash(i2, j2, k2)
  p.edges[index] = EdgeList(i1:i1, i2:i2, j1:j1, j2:j2, k1:k1, k2:k2, vid:vid, next:p.edges[index]).box

# getedge: return vertex id for edge return -1 if not set 
proc getedge(p:var Polygonizer, pi1, pj1, pk1, pi2, pj2, pk2 : int) : int =
  var (i1,j1,k1,i2,j2,k2)=(pi1,pj1,pk1,pi2,pj2,pk2)

  if i1 > i2 or (i1 == i2 and (j1 > j2 or (j1 == j2 and k1 > k2))):
    swap i1,i2
    swap j1,j2
    swap k1,k2
  
  for e in p.edges[hash(i1, j1, k1) + hash(i2, j2, k2)]:
    if e[]==(i1,j1,k1,i2,j2,k2):
      return e.vid
  return -1


# Vertices 

#[ vertid: return index for vertex on edge:
   c1.value and c2.value are presumed of different sign
   return saved index if any else compute vertex and save ]#

proc vertid(p:var Polygonizer, c1, c2: ref Corner) : int = 
  var 
    v : Vertex
    a = c1.point
    b = c2.point

  var vid = p.getedge(c1.i, c1.j, c1.k, c2.i, c2.j, c2.k)
  if vid != -1:  return vid # previously computed 

  converge(a, b, c1.value, p.function, v.position) # position 
  p.normal(v.position, v.normal)                  # normal 
  p.vertices.add v                        # save vertex 
  vid = p.vertices.high
  p.setedge(c1.i, c1.j, c1.k, c2.i, c2.j, c2.k, vid)
  return vid

# Tetrahedral Polygonization 

#[ dotet: triangulate the tetrahedron
 * b, c, d should appear clockwise when viewed from a
 * return 0 if client aborts, 1 otherwise ]#

proc dotet(p:var Polygonizer, cube : Cube, c1, c2, c3, c4:int):int=
  var
    a = cube.corners[c1]
    b = cube.corners[c2]
    c = cube.corners[c3]
    d = cube.corners[c4]

    index, e1, e2, e3, e4, e5, e6 :int
    
    apos = a.value > 0
    bpos = b.value > 0
    cpos = c.value > 0
    dpos = d.value > 0

  if apos: index += 8
  if bpos: index += 4
  if cpos: index += 2
  if dpos: index += 1

  # index is now 4-bit number representing one of the 16 possible cases 
  if apos != bpos:  e1 = p.vertid(a, b)
  if apos != cpos:  e2 = p.vertid(a, c)
  if apos != dpos:  e3 = p.vertid(a, d)
  if bpos != cpos:  e4 = p.vertid(b, c)
  if bpos != dpos:  e5 = p.vertid(b, d)
  if cpos != dpos:  e6 = p.vertid(c, d)

  # 14 productive tetrahedral cases (0000 and 1111 do not yield polygons)
  case index:
    of 1: return p.triproc(p, e5, e6, e3, p.vertices)
    of 2: return p.triproc(p, e2, e6, e4, p.vertices)
    of 3: return p.triproc(p, e3, e5, e4, p.vertices) and p.triproc(p, e3, e4, e2, p.vertices)
    of 4: return p.triproc(p, e1, e4, e5, p.vertices)
    of 5: return p.triproc(p, e3, e1, e4, p.vertices) and p.triproc(p, e3, e4, e6, p.vertices)
    of 6: return p.triproc(p, e1, e2, e6, p.vertices) and p.triproc(p, e1, e6, e5, p.vertices)
    of 7: return p.triproc(p, e1, e2, e3, p.vertices)
    of 8: return p.triproc(p, e1, e3, e2, p.vertices)
    of 9: return p.triproc(p, e1, e5, e6, p.vertices) and p.triproc(p, e1, e6, e2, p.vertices)
    of 10: return p.triproc(p, e1, e3, e6, p.vertices) and p.triproc(p, e1, e6, e4, p.vertices)
    of 11: return p.triproc(p, e1, e5, e4, p.vertices)
    of 12: return p.triproc(p, e3, e2, e4, p.vertices) and p.triproc(p, e3, e4, e5, p.vertices)
    of 13: return p.triproc(p, e6, e2, e4, p.vertices)
    of 14: return p.triproc(p, e5, e3, e6, p.vertices)
    else: discard
    
  return 1

# Cubical Polygonization (optional) 

# docube: triangulate the cube directly, without decomposition 

proc docube(p:var Polygonizer, cube : var Cube) : int =
  var index=0
  for i in 0..<8:
    if cube.corners[i].value > 0:
      index += (1 shl i)

  for polys in cubetable[index]:  
    var 
      a = -1
      b = -1
      count = 0

    for edges in polys.list:    
      var
        c1 = cube.corners[corner1[edges.i]]
        c2 = cube.corners[corner2[edges.i]]
        c = p.vertid(c1, c2)
      count.inc
      if count > 2 and p.triproc(p, a, b, c, p.vertices)==0:
        return 0
      if count < 3: a = b
      b = c

  return 1

#[testface: given cube at lattice (i, j, k), and four corners of face,
  if surface crosses face, compute other four corners of adjacent cube
  and add new_cube cube to cube stack ]#

proc testface(p:var Polygonizer, i, j, k:int, old:var Cube, face, c1, c2, c3, c4:int) =
  let facebit = [2, 2, 1, 1, 0, 0]
  var
    oldcubes = p.cubes
    pos = old.corners[c1].value > 0
    bit = facebit[face]

  # test if no surface crossing, cube out of bounds, or already visited: 
  if ((old.corners[c2].value > 0) == pos and
     (old.corners[c3].value > 0) == pos and
     (old.corners[c4].value > 0) == pos) or
     (abs(i) > p.bounds or abs(j) > p.bounds or abs(k) > p.bounds) or
     (p.setcenter(i, j, k)!=0) : return

  # create new_cube cube: 
  var new_cube=Cube(i:i,j:j,k:k) 
  for cc in [c1,c2,c3,c4]: new_cube.corners[flip(cc, bit)] = old.corners[cc]
  for n in 0..<8:
    if new_cube.corners[n] == nil:
      new_cube.corners[n] = p.setcorner(i + bit(n, 2), j + bit(n, 1), k + bit(n, 0))

  #add cube to top of stack: 
  p.cubes = Cubes(cube:new_cube, next:oldcubes).box


proc polygonize(p:var Polygonizer, x, y, z:float) : string =
  var noabort : bool

  p.makecubetable()

  randomize()

  let
    input = p.find(1,  x, y, z)
    output = p.find(0, x, y, z)

  if not input.ok.itob and not output.ok.itob:
    return "can't find starting point"

  converge(input.p, output.p, input.value, p.function, p.start)

  # push initial cube on stack: 
  p.cubes = new(Cubes)

  # set corners of initial cube: 
  for n in 0..<8:
    p.cubes.cube.corners[n] = p.setcorner(bit(n, 2), bit(n, 1), bit(n, 0))

  # no vertices yet

  discard p.setcenter(0, 0, 0)

  while p.cubes != nil: # process active cubes till none left 
    var
      c : Cube
      temp = p.cubes

    c = p.cubes.cube

    noabort = 
      if p.mode == TET: # either decompose into tetrahedra and polygonize: 
        ( p.dotet(c, LBN, LTN, RBN, LBF) and
          p.dotet(c, RTN, LTN, LBF, RBN) and
          p.dotet(c, RTN, LTN, LTF, LBF) and
          p.dotet(c, RTN, RBN, LBF, RBF) and
          p.dotet(c, RTN, LBF, LTF, RBF) and
          p.dotet(c, RTN, LTF, RTF, RBF)).itob
      else:  # or polygonize the cube directly: 
        p.docube(c).itob

    if not noabort: return "aborted"

    # pop current cube from stack 
    p.cubes = p.cubes.next
    temp=nil

    # test six face directions, maybe add to stack: 
    p.testface(c.i - 1, c.j, c.k, c, L, LBN, LBF, LTN, LTF)
    p.testface(c.i + 1, c.j, c.k, c, R, RBN, RBF, RTN, RTF)
    p.testface(c.i, c.j - 1, c.k, c, B, LBN, LBF, RBN, RBF)
    p.testface(c.i, c.j + 1, c.k, c, T, LTN, LTF, RTN, RTF)
    p.testface(c.i, c.j, c.k - 1, c, N, LBN, LTN, RBN, RTN)
    p.testface(c.i, c.j, c.k + 1, c, F, LBF, LTF, RBF, RTF)
  
  return "ok"

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
element face {p.triangles.len}
property list uchar int vertex_indices
end_header
"""

  for v in p.vertices:
    st.write fmt"{v.position.x} {v.position.y} {v.position.z} {v.normal.x} {v.normal.y} {v.normal.z}", "\n"
  for t in p.triangles:
    st.write fmt"3 {t.i1} {t.i2} {t.i3}", "\n"

  st.close


when isMainModule:
  echo "polygonizing..."
  var p = newPolygonizer(DecoCube, 60, 0.06)
  echo fmt"polygonize result:{p.polygonize(0, 0, 0)}"
  echo fmt"#vertices:{p.vertices.len} #trigs:{p.triangles.len}"
  p.write_ply("pisc.ply")