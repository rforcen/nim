#
# poly flag

import sugar, algorithm, sequtils, tables
import common, vertex

proc toToken*(c : char):int32 = c.int32 shl 24

# Flag 

type Int4* = array[4,int32]

const i4_base = [-1'i32,-1,-1,-1]

proc cmp*(x,y:Int4):int32=
    if x[0]!=y[0]: return x[0]-y[0]
    elif x[1]!=y[1]: return x[1]-y[1]
    elif x[2]!=y[2]: return x[2]-y[2]
    else: return x[3]-y[3]

proc i4*(i : int32):Int4=[i,-1,-1,-1]
proc i4*(i0,i1 : int32):Int4=[i0,i1,-1,-1]
proc i4*(i0,i1,i2 : int32):Int4=[i0,i1,i2,-1]
proc i4*(i0,i1,i2,i3 : int32):Int4=[i0,i1,i2,i3]

proc i4*(c0:char, i1,i2 : int32):Int4=[c0.toToken,i1,i2,-1]
proc i4*(c0:char, i1 : int32):Int4=[c0.toToken,i1,-1,-1]
proc i4*(c0:char, i0:int32, c1:char, i1:int32) : Int4 = [c0.toToken, i0, c1.toToken, i1]


proc i4_min*(v1, v2: int32) : Int4 = 
    if v1 < v2: i4(v1, v2) else: i4(v2, v1)

proc i4_min*(i, v1, v2 : int32) : Int4 =
    if v1 < v2: i4(i, v1, v2) else: i4(i, v2, v1)

type VertexIndex* = object
    index : int32
    vertex : Vertex

type I4Vix* = object
    index:Int4
    vix : VertexIndex

proc cmp*(x,y:I4Vix):int32=cmp(x.index, y.index)

type MapIndex = array[3,Int4]
proc cmp(x,y:MapIndex):int32=
    if cmp(x[0],y[0])!=0: cmp(x[0],y[0])
    elif cmp(x[1],y[1])!=0: cmp(x[1],y[1])
    else: cmp(x[2],y[2])

proc  gen_face_map*(poly : Polyhedron):Table[Int4, int32]= # make table of face as fn of edge
    var face_map : Table[Int4, int32]

    for i, face in poly.faces:
      
      var v1 = face[^1] # previous vertex index
      for v2 in face:
        face_map[i4(v1, v2)] = i.int32
        v1 = v2 # current becomes previous
      
    face_map

# flag

type Flag* = object
    vertexes : Vertexes
    faces: Faces
    v : seq[I4Vix]
    m : seq[MapIndex] # m[i4][i4]=i4 -> m[]<<i4,i4,i4
    fcs : seq[seq[Int4]]
    v_index : int32 # index of last added vertex (add_vertex)
    error* : bool

proc add_vertex*(flag:var Flag, i:Int4, v:Vertex, with_unit:bool=true )=
    flag.v.add(I4Vix(index:i, vix: VertexIndex(index:flag.v_index, vertex:if with_unit: v.unit else: v)))
    inc flag.v_index

proc add_vertexes*(flag:var Flag, vx:Vertexes, with_unit:bool=true) =
    for i, v in vx:
        flag.add_vertex(i4(i.int32), v, with_unit) #I4Vix(index:i4(i), vix: VertexIndex(index:0, vertex:v.unit))

proc add_face*(flag:var Flag, f:seq[Int4]) = flag.fcs.add(f)

proc add_face*(flag:var Flag, i0,i1,i2: Int4) = flag.m.add([i0,i1,i2])

proc index_vertexes(flag:var Flag)=
    flag.v = flag.v.sortedByIt(it.index).deduplicate(isSorted=true) # by index
    flag.vertexes.setLen(flag.v.len) # numerate & create vertexes[]

    for i in 0..flag.v.high:
        flag.v[i].vix.index = i.int32
        flag.vertexes[i]=flag.v[i].vix.vertex

# gen. vector of from index of face change in m
proc from_to_m(flag:Flag) : Face =
    var 
        v_ft : seq[int32]
        c0 = flag.m[0][0]
        frm = 0

    for i in 0..flag.m.high: 
      if flag.m[i][0] != c0:
        v_ft.add(frm.int32)
        frm = i
        c0 = flag.m[i][0]

    v_ft.add(frm.int32)
    v_ft
  
proc find_vertex_index(flag:var Flag, v : Int4) : int32 =
    let ix = flag.v.lowerBound(v, proc (x:I4Vix, k:Int4):int=cmp(x.index, k))
    try:
        flag.v[ix].vix.index
    except IndexDefect:
        flag.error=true
        0

proc  find_m(flag: var Flag, m0, m1 : Int4) : Int4 =
    let ix = flag.m.lowerBound([m0, m1, i4(0)], proc (x:MapIndex, k:MapIndex) : int = cmp(x,k))
    try:
        flag.m[ix][2]
    except IndexDefect:
        flag.error=true
        i4_base
  
proc process_m(flag:var Flag)= # faces = flag.m
    if flag.m.len!=0:
        flag.m = flag.m.sortedByIt(it)
        let ft = flag.from_to_m()

        block face_list:
            for i in ft:
                let 
                    m0 = flag.m[i]
                    v0 = m0[2]
                var 
                    v = v0
                    mm0 = m0[0]
                    n_iter=0
                var face : Face

                while true:
                    face.add(flag.find_vertex_index(v))
                    
                    v = flag.find_m(mm0, v)
                    if v==v0: break 
                
                    inc n_iter
                    if n_iter>100 or flag.error:
                        # echo "max loop:", flag.m[0..2],"\n",mm0,v0
                        flag.error = true
                        break face_list

                flag.faces.add(face)

proc process_fcs(flag:var Flag)=# faces << fcs
    if not flag.error:
        for fc in flag.fcs:
            let face = collect(newSeq):
                for vix in fc: flag.find_vertex_index(vix)
            flag.faces.add(face)

proc toPolyhedron*(flag:var Flag, p:Polyhedron, tr_name:string):Polyhedron=
    flag.error=false
    flag.index_vertexes

    flag.faces = @[]
    
    flag.process_m
    flag.process_fcs

    if not flag.error:
        result=Polyhedron(name:tr_name & p.name, vertex: flag.vertexes, faces: flag.faces)
        result.simplify
    else: result=p