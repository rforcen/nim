#[
  mesh.nim

  ZM mesh compressed file format
  "ZM"(compressed shape len'u32)(compressed trigs len'u32)(shape compress)(trigs compress)

  CTM file r/w
  PLY read
]#

import strformat, zippy, math, ctm

type
  vec3* = array[3, float32]
  vec3i* = array[3, uint32]
  Trig = vec3i

  Vertex* = object
    pos*, norm*, uv*, color* : vec3

  Mesh* = object
    shape* : seq[Vertex]
    trigs* : seq[Trig]

  MeshStr = tuple[shape:string, trigs:string]

# vec3 op's
{.push inline.}
proc `+`*(a,b:vec3):vec3 = [b[0]+a[0], b[1]+a[1], b[2]+a[2]]
proc `-`*(a:vec3, b:float32):vec3 = [a[0]-b, a[1]-b, a[2]-b]
proc `-`*(a:vec3):vec3=[-a[0], -a[1], -a[2]]
proc `-`*(a,b:vec3):vec3 = [a[0]-b[0], a[1]-b[1], a[2]-b[2]]
proc `*`*(v:vec3, f:float32) : vec3 = [v[0]*f, v[1]*f, v[2]*f]
proc `/`*(v:vec3, f:float32) : vec3 = [v[0]/f, v[1]/f, v[2]/f]
proc `+=`*(a:var vec3,b:vec3) = a=a+b
proc `-=`*(a:var vec3,b:vec3) = a=a-b
proc `/=`*(v:var vec3, f:float32) = v[0]/=f; v[1]/=f;  v[2]/=f
proc `*=`*(v:var vec3, f:float32) = v[0]*=f; v[1]*=f;  v[2]*=f
proc hypot*(v:vec3):float32 = (v[0]*v[0] + v[1]*v[1] + v[2]*v[2]).sqrt
proc `**`*(a,b:vec3):vec3  =[a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]] # cross prod
proc `.*`*(a,b:vec3):float32 = a[0]*b[0]+a[1]*b[1]+a[2]*b[2] # dot prod
proc `.^`*(a:vec3, i:int) : vec3 = [a[0]^i, a[1]^i, a[2]^i]
proc normalize*(v:vec3):vec3 =v/v.hypot 
proc normal*(v0, v1, v2: vec3): vec3 =
    let n = (v2 - v0) ** (v1 - v0)
    result = if n == [0f, 0, 0]: n else: n.normalize()
proc unormal*(v0, v1, v2: vec3): vec3 = (v2 - v0) ** (v1 - v0)
    
proc max*(v:vec3):float32=max(v[0],max(v[1],v[2]))
proc amax*(v:vec3):float32=max(v[0].abs,max(v[1].abs,v[2].abs))
{.pop.}

# misc helpers & converters
proc nbytes[T](x:seq[T]):int = x.len * T.sizeof
proc nbytes(ms:MeshStr):int = ms.shape.len + ms.trigs.len
proc nbytes*(ms:Mesh):int = ms.shape.nbytes + ms.trigs.nbytes

converter saddr[T](x:seq[T]):pointer = x[0].unsafeAddr
converter saddr(x:string):pointer = x[0].unsafeAddr

converter vec3tobin(v:vec3):string=
  result = newString(v.sizeof)
  copyMem(result, v.unsafeAddr, v.sizeof)  

converter vec3tobin(v:vec3i):string=
  result = newString(v.sizeof)
  copyMem(result, v.unsafeAddr, v.sizeof)

proc tostr[T](x:seq[T]):string= # convert seq[T] -> string
  result = newString(x.nbytes)
  copyMem(result, x, x.nbytes)

converter fromstr[T](x:string):seq[T]=
  result = newSeq[T](x.len div T.sizeof)
  copyMem(result, x, x.len)

converter toShape(x:string):seq[Vertex] = fromstr[Vertex] x 
converter toTrigs(x:string):seq[Trig]   = fromstr[Trig] x

proc compress*(m:Mesh) : MeshStr = (m.shape.tostr.compress, m.trigs.tostr.compress)
proc uncompress*(m:MeshStr) : Mesh =  Mesh( shape: m.shape.uncompress, trigs: m.trigs.uncompress)

proc normalize*(m:var Mesh)=
  var max = -float32.high
  for v in m.shape: max = max.max(v.pos.max)
  if max != 0:
    for v in m.shape.mitems: v.pos /= max

proc clear*(m:var Mesh)=
  m.shape.setLen 0
  m.trigs.setLen 0

proc nvertex*(m:Mesh):int = m.shape.len
proc ntrigs*(m:Mesh):int = m.trigs.len

# ZM file r/w
const ZM_id = 0x4d5a # "ZM"

proc ZMwrite*(m:Mesh, file_name:string)=
  var fh = open(file_name, fmWrite)
  
  fh.write "ZM"
  let 
    cmp = m.compress
    shapel = cmp.shape.len.uint32
    trigsl = cmp.trigs.len.uint32

  discard fh.writeBuffer(shapel.unsafeAddr, 4)
  discard fh.writeBuffer(trigsl.unsafeAddr, 4)
  discard fh.writeBuffer(cmp.shape, cmp.shape.len)
  discard fh.writeBuffer(cmp.trigs, cmp.trigs.len)

  fh.close

proc ZMread*(file_name : string) : Mesh =
  var 
    fh = open(file_name)
    id : uint16
    shapel, trigsl : uint32
  
  discard fh.readBuffer(id.unsafeAddr, 2) # id
  assert id == ZM_id
  discard fh.readBuffer(shapel.unsafeAddr, 4) # shape, trigs compressed lengths
  discard fh.readBuffer(trigsl.unsafeAddr, 4)

  var cmp : MeshStr = (shape : newString(shapel.int), trigs : newString(trigsl.int))
  discard fh.readBuffer(cmp.shape, shapel.int) # s,t compressed data
  discard fh.readBuffer(cmp.trigs, trigsl.int)

  fh.close
  cmp.uncompress


# CTM
proc CTMwrite*(m:Mesh, file_name:string)=
  let 
    context = ctmNewContext(CTM_EXPORT)
    vertCount = m.shape.len.CTMuint
    triCount = m.trigs.len.CTMuint
    
  var 
    indices = newSeq[CTMuint](3*triCount) 
    vertices = newSeq[CTMfloat](3*vertCount) 
    normals = newSeq[CTMfloat](3*vertCount) 
    
  # mesh to ctm
  for i,v in m.shape.pairs:
    for j in 0..2:  vertices[i*3+j]=v.pos[j].CTMfloat
    for j in 0..2:  normals[i*3+j]=v.norm[j].CTMfloat

  copyMem(indices[0].addr, m.trigs[0].unsafeAddr, m.trigs.nbytes)

  context.ctmCompressionMethod(CTM_METHOD_MG2)
  ctmDefineMesh(context, cast[ptr CTMfloat](vertices[0].addr), vertCount, cast[ptr CTMuint](indices[0].addr), triCount, cast[ptr CTMfloat](normals[0].addr))

  ctmSave(context,file_name)
  let errc = ctmGetError(context)
  if errc!=CTM_NONE:
    raise newException(IOError, "CTM: error saving file:" & file_name & ", code:" & $errc)

  context.ctmFreeContext

proc CTMread*(file_name:string) : Mesh =
  let context = ctmNewContext(CTM_IMPORT)

  ctmLoad(context, file_name)
  if ctmGetError(context)==CTM_NONE: # Access the mesh data
    let 
      vertCount = ctmGetInteger(context, CTM_VERTEX_COUNT).int
      triCount = ctmGetInteger(context, CTM_TRIANGLE_COUNT).int
      
      indices = cast[CTMuintarray](ctmGetIntegerArray(context, CTM_INDICES))
      vertices = cast[CTMfloatarray](ctmGetFloatArray(context, CTM_VERTICES))
      normals = cast[CTMfloatarray](ctmGetFloatArray(context, CTM_NORMALS))

    for i in countup(0, vertCount*3-1, 3): 
      result.shape.add Vertex(
        pos:[vertices[i],vertices[i+1],vertices[i+2]],
        norm:[normals[i], normals[i+1], normals[i+2]])

    for i in countup(0, triCount*3-1, 3): 
      result.trigs.add [indices[i+0], indices[i+1], indices[i+2]]

  context.ctmFreeContext

# PLY
proc PLYwrite*(m:Mesh, file_name : string)= # in binary format
  var fh = open(file_name, fmWrite, bufSize=4096)

  fh.write &"""ply
format binary_little_endian 1.0
comment polygonizer generated
element vertex {m.shape.len}
property float x
property float y
property float z
property float nx
property float ny
property float nz
element face {m.trigs.len}
property list uchar int vertex_indices
end_header
"""

  var bf : string

  for v in m.shape:
    bf.add v.pos
    bf.add v.norm
  var bw = fh.writeBuffer(bf[0].addr, bf.len)
  assert bw == bf.len
    
  bf = ""
  for t in m.trigs:
    bf.add '\3'
    bf.add t  

  bw = fh.writeBuffer(bf[0].addr, bf.len)
  assert bw == bf.len

  fh.close

# check mesh
proc check*(m:Mesh):bool=
  result=false
  for f in m.trigs:
    for i in f:
      try:
        discard m.shape[i]
      except IndexDefect:
        raise newException(IndexDefect, "bad mesh, index issue")
  result=true

##################
when isMainModule:
  import os, random

  proc comp_perf=
    let m = ZMread("pisc.zm")
    # 4 x v + 1
    var tcs=0
    for i in 0..3:
      var  s:string
      for v in m.shape:
        let p = [v.pos, v.norm, v.color, v.uv][i]
        s.add p
      let cs = s.compress
      echo i, ":", cs.len
      tcs += cs.len
    
    let cts = m.trigs.toStr.compress.len
    echo &"total size:{m.nbytes}, trigs size:{cts}, shape:{tcs}, total comp:{tcs+cts}"

  proc random_mesh(n:int = 10_000) : Mesh =
    proc rand():vec3 = [rand(1.0).float32, rand(1.0), rand(1.0)]

    echo &"generating random mesh with {n} items"
    for i in 0..<n:
      result.shape.add Vertex(pos:[(i/n).float32, 1, 2 ], norm:rand())
      result.trigs.add [(i %% 600).uint32, (i %% 1000).uint32, (i %% 400).uint32]

  proc zm_test=
    var mesh = random_mesh(10_000)
    let file = "mesh.zm"

    echo &"compressing & writing mesh of {mesh.nbytes} bytes"
    mesh.ZMwrite file
    
    echo "reading"
    let meshu = ZMread file
    echo if meshu == mesh: "check, ok" else: "fail"
    echo &"ratio:{100.0 * getFileSize(file).float / mesh.nbytes.float:.3}%"

    mesh.CTMwrite "mesh.ctm"

  proc test_cdmesh* =
    let mesh = random_mesh()
    echo "compressing"
    let cmp = mesh.compress
    echo &"compression ratio:{mesh.nbytes / cmp.nbytes:.3}"

    echo "uncompressing"
    let umesh = cmp.uncompress

    echo if umesh == mesh: "check, ok" else: "fail"

  proc test00* =
    var mesh = random_mesh()

    echo "compressing"
    let cm = compress(mesh.shape.tostr)
    echo "compression: org:", mesh.shape.nbytes ," bytes, compressed:", cm.len, " bytes"

    let dd = uncompress(cm)
    echo "uncompress:", dd.len

    # check equality data==dd
    echo mesh.shape.tostr == dd

    # copy back to original mesh
    let meshc = mesh
    mesh.shape = @[]; mesh.trigs = @[]

    mesh.shape = dd.toShape

    echo meshc.shape == mesh.shape

  zm_test()
  # comp_perf()
