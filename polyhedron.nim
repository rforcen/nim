# poly.nim
# common specs for polyhedron 
import math

type
  
  vec3* = array[3, float]

  Polyhedron* = object
    name* : string
    vertices* : seq[vec3]
    faces* : seq[seq[int]]
    edges*: seq[array[2,int]]

# yet another lin algebra oper's & func's 
# type vec3 = array[3, float]
{.push inline.}
proc `*`*(v:vec3, f:float) : vec3 = [v[0]*f, v[1]*f, v[2]*f]
proc `/`*(v:vec3, f:float) : vec3 = [v[0]/f, v[1]/f, v[2]/f]
proc `/=`*(v:var vec3, f:float) = v[0]/=f; v[1]/=f;  v[2]/=f
proc `*=`*(v:var vec3, f:float) = v[0]*=f; v[1]*=f;  v[2]*=f
proc `-`*(a:vec3, b:float):vec3 = [a[0]-b, a[1]-b, a[2]-b]
proc `-`*(a:vec3):vec3=[-a[0], -a[1], -a[2]]
proc `+`*(a,b:vec3):vec3 = [b[0]+a[0], b[1]+a[1], b[2]+a[2]]
proc `-`*(a,b:vec3):vec3 = [b[0]-a[0], b[1]-a[1], b[2]-a[2]]
proc `+=`*(a:var vec3,b:vec3) = a=a+b
proc `-=`*(a:var vec3,b:vec3) = a=a-b
proc hypot*(v:vec3):float = (v[0]*v[0] + v[1]*v[1] + v[2]*v[2]).sqrt
proc `**`*(a,b:vec3):vec3  =[a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]] # cross prod
proc `.*`*(a,b:vec3):float = a[0]*b[0]+a[1]*b[1]+a[2]*b[2]
proc `.^`*(a:vec3, i:int) : vec3 = [a[0]^i, a[1]^i, a[2]^i]
proc normalize*(v:vec3):vec3 =v/v.hypot 
proc normal*(v0, v1, v2: vec3): vec3 =
    let n = (v2 - v0) ** (v1 - v0)
    result = if n == [0.0, 0, 0]: n else: n.normalize()
proc unormal*(v0, v1, v2: vec3): vec3 = (v2 - v0) ** (v1 - v0)
    
proc max*(v:vec3):float=max(v[0],max(v[1],v[2]))
proc amax*(v:vec3):float=max(v[0].abs,max(v[1].abs,v[2].abs))
{.pop.}
  
proc triangularize*(n_sides:int) : seq[(int, int, int)]=
  for i in 0..<n_sides-2: # 0, i, i+1 : i=1..ns-1, for quad=4: 0 1 2, 0 2 3
    result.add (0, i+1, i+2)

proc centroid*(p:Polyhedron):vec3=
  var vol = 0.0
  for face in p.faces:
    for (a,b,c) in triangularize(face.len):
      let
        (a,b,c)=(p.vertices[face[a]], p.vertices[face[b]], p.vertices[face[c]])
        n = (b-a)**(c-a)
      vol += (a .* n) / 6
      for i in 0..2:
        result[i] += n[i] * ((a[i]+b[i])^2 + (b[i]+c[i])^2 + (c[i]+a[i])^2)
  result *= 1/(24*2*vol)

proc volume*(p:Polyhedron):float=
  for face in p.faces:
    for (a,b,c) in triangularize(face.len):
      let
        (a,b,c)=(p.vertices[face[a]], p.vertices[face[b]], p.vertices[face[c]])
        n = (b-a)**(c-a)
      result += (a .* n) / 6