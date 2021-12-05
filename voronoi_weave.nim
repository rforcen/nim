# voronoi using weave for parallel generation

import weave, sequtils, random, sugar, times, strformat, pixie

proc box[T](x: T): ref T {.inline.} = new(result); result[] = x # obj to ref conversion

type
  Point = object
    x, y: int
    color: uint32
  Voronoi = object
    w, h: int
    points: seq[Point]
    image: seq[uint32]

proc get_size(v:Voronoi):int = v.w * v.h

proc newVoronoi*(w, h, n: int): Voronoi =
  randomize()
  Voronoi(
    w: w, h: h, 
    image : newSeq[uint32](w*h), 
    points : toSeq(0..<n).map(x => Point(x: rand(w), y: rand(h), color: uint32(rand(0x00ff_ffff)))))

proc distance_sqr(x, y:int, p:Point): int  = 
  proc sqr(x:int):int = x*x
  sqr(x-p.x) + sqr(y-p.y)

proc generate_pixel*(voronoi:var Voronoi, index:int)=
  let
    i = index %% voronoi.w
    j = index div voronoi.w
  
  var
    dist = int.high
    is_center = false
    ind = 0

  for p in 1..voronoi.points.high:
    let d = distance_sqr(i, j, voronoi.points[p])

    if d < 2:
      is_center = true
      break

    if d < dist:
      dist = d
      ind = p

  voronoi.image[index]=0xff00_0000'u32 or (if is_center: 0'u32 else: voronoi.points[ind].color)

proc write_image*(v:Voronoi, fn:string) =
  assert v.image.len==v.get_size
  let image = newImage(v.w, v.h)
  image.data = cast[seq[ColorRGBX]](v.image)
  image.writeFile(fn)

when isMainModule:
  let 
    w = 1024*2
    n = w div 2

  var voronoi = newVoronoi(w,w,n) # use a ref in parallelFor


  echo fmt"voronoi {w}x{w}x{n}..."

  Weave.init()

  let t0=now()

  let voronoi_ptr = voronoi.addr
  parallelFor index in 0..<voronoi.get_size:
    voronoi_ptr[].generate_pixel(index)

  Weave.exit()

  echo fmt"lap:",(now()-t0).inMilliseconds
  voronoi.write_image("voronoi.png")