# Vertex

import math

type Vertex* = array[3, float32]
const zeroVertex* =[0.0'f32, 0.0, 0.0]

# vertex ops

proc cross*(v0, v1: Vertex): Vertex {.inline.} = [(v0[1] * v1[2]) - (v0[2] * v1[
        1]), (v0[2] * v1[0]) - (v0[0] * v1[2]), (v0[0] * v1[1]) - (v0[1] * v1[0])]

proc dot*(v0, v1: Vertex): float32 {.inline.} = v0[0]*v1[0]+v0[1]*v1[1]+v0[2]*v1[2]

proc distance_squared*(v0, v1: Vertex): float32 {.inline.} = dot(v0,v1)
proc distance*(v0, v1: Vertex): float32 {.inline.} = dot(v0, v1).sqrt

proc `+`*(v0, v1: Vertex): Vertex {.inline.} = [v0[0]+v1[0], v0[1]+v1[1], v0[2]+v1[2]]
proc `+`*(v0: Vertex, f:float32): Vertex {.inline.} = [v0[0]+f, v0[1]+f, v0[2]+f]
        
proc `-`*(v0, v1: Vertex): Vertex {.inline.} = [v0[0]-v1[0], v0[1]-v1[1], v0[2]-v1[2]]
proc `-`*(v0: Vertex, f:float32): Vertex {.inline.} = [v0[0]-f, v0[1]-f, v0[2]-f]

proc `-`*(v:Vertex) : Vertex = [-v[0], -v[1], -v[2]]

proc `*`*(v0: Vertex, f: float32): Vertex {.inline.} = [v0[0]*f, v0[1]*f, v0[2]*f]
proc `*`*(v0, v1: Vertex): float32 {.inline.} = v0.dot(v1)
proc `**`*(v0, v1: Vertex): Vertex {.inline.} = v0.cross(v1)

proc `/`*(v0: Vertex, c: float32): Vertex {.inline.} = [v0[0]/c, v0[1]/c, v0[2]/c]
proc `/=`*(v0: var Vertex, c: float32) {.inline.} = 
    v0[0]/=c
    v0[1]/=c
    v0[2]/=c

proc `+=`*(v0: var Vertex, v1: Vertex) {.inline.} = 
    v0[0]+=v1[0]
    v0[1]+=v1[1]
    v0[2]+=v1[2]

proc max_abs*(v:Vertex):float32 = v[0].abs.max(v[1].abs.max(v[2].abs))
proc normal*(v0, v1, v2: Vertex): Vertex {.inline.} = cross(v1 - v0, v2 - v1)

proc unit*(v: Vertex): Vertex {.inline.} =
    if v == [0.0'f32, 0.0, 0.0]: v
    else: v / dot(v, v).sqrt

proc midpoint*( vec1, vec2 : Vertex) : Vertex = (vec1 + vec2) / 2.0

proc tween*(v1, v2 : Vertex, t : float32) : Vertex  =
    (v1 * (1.0 - t) ) + (v2 * t)

proc oneThird*(v1, v2 : Vertex) : Vertex =
    tween(v1, v2, 1.0 / 3.0)