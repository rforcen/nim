#
# Voronoi tiles on parallel mode
#

import random, sequtils, sugar, streams, times, threadpool, cpuinfo, strformat
import pixie
import par

type
    Point = object
        x, y: int
        color: uint32
    Voronoi = object
        w, h: int
        points: seq[Point]
        image: seq[uint32]

proc size(v:Voronoi):int {.inline.} = v.w * v.h

proc gen_pixel(i, j: int, points:seq[Point]): uint32 =
    proc distance_sqr(x, y, px, py: int): int {.inline.} =
        result = (x-px) * (x-px) + (y-py) * (y-py)

    var
        dist = distance_sqr(i, j, points[0].x, points[0].y)
        is_center = false
        ind = 0

    for p in 0..points.high:
        let d = distance_sqr(i, j, points[p].x, points[p].y)

        if d < 2:
            is_center = true
            break

        if d < dist:
            dist = d
            ind = p

    0xff00_0000'u32 or
        (if is_center: 0'u32 else: points[ind].color)


proc gen_image(v: var Voronoi) = # mt mode
    v.image = newSeq[uint32](v.size)
    let (w, points) = (v.w, v.points) # can't use v. in par_apply

    v.image.par_apply(i => gen_pixel(i %% w, i div w, points))

proc image_bytes(v:Voronoi):int {.inline.} = v.image.len * sizeof(v.image[0])

proc write*(v: Voronoi, fn: string) = # write image to binary file
    var f = newFileStream(fn, fmWrite)
    if not f.isNil:
        f.writeData(v.image[0].unsafeAddr, v.image_bytes)
        f.close()

proc write_image*(m:Voronoi, fn:string) =
    let image = newImage(m.w, m.h)
    image.data = cast[seq[ColorRGBX]](m.image)
    image.writeFile(fn)

proc newVoronoi*(w, h, n: int): Voronoi =
    randomize()
    result = Voronoi(w: w, h: h)

    # generate x,y:rand(w,h), color:rand(max int32)
    result.points = toSeq(0..<n).map(x => Point(x: rand(w), y: rand(h),
            color: uint32(rand(0x00ff_ffff))))

    # mt mode
    result.gen_image()


when isMainModule:
    let
        w = 1000
        h = w
        n = w div 2

    echo fmt("Voronoi {w}x{w}x{n} with {countProcessors()} cpu...")
    let t0 = now()

    let voronoi = newVoronoi(w, h, n)

    echo fmt("lap:{(now()-t0).inMilliseconds()}ms")

    voronoi.write_image("voronoi.png")
