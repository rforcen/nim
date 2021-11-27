# vec3.nim
# yet another lin algebra oper's & func's 

import math

type 
  vec3* = array[3, float]
  veci3* = array[3, int]
{.push inline.}
proc `*`*(v:vec3, f:float) : vec3 = [v[0]*f, v[1]*f, v[2]*f]
proc `/`*(v:vec3, f:float) : vec3 = [v[0]/f, v[1]/f, v[2]/f]
proc `/`*(a:vec3, b:veci3) : vec3 = [a[0]/b[0].float, a[1]/b[1].float, a[2]/b[2].float]
proc `/=`*(v:var vec3, f:float) = v[0]/=f; v[1]/=f;  v[2]/=f
proc `*=`*(v:var vec3, f:float) = v[0]*=f; v[1]*=f;  v[2]*=f
proc `-`*(a:vec3, b:float):vec3 = [a[0]-b, a[1]-b, a[2]-b]
proc `-`*(a:vec3):vec3=[-a[0], -a[1], -a[2]]
proc `+`*(a,b:vec3):vec3 = [b[0]+a[0], b[1]+a[1], b[2]+a[2]]
proc `-`*(a,b:vec3):vec3 = [a[0]-b[0], a[1]-b[1], a[2]-b[2]]
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

proc `<`*(a,b:veci3):bool = 
  if a[0]<b[0]: return true
  if a[0]>b[0]: return false
  if a[1]<b[1]: return true
  if a[1]>b[1]: return false
  if a[2]<b[2]: return true
  false
{.pop.}
  