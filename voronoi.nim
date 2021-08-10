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

proc distance_sqr(x, y, px, py: int): int {.inline.} =
    result = (x-px) * (x-px) + (y-py) * (y-py)

proc gen_pixel(v: Voronoi, i, j: int): uint32 =
    var
        dist = distance_sqr(i, j, v.points[0].x, v.points[0].y)
        is_center = false
        ind = 0

    for p in 0..<v.points.len:
        let d = distance_sqr(i, j, v.points[p].x, v.points[p].y)

        if d < 2:
            is_center = true
            break

        if d < dist:
            dist = d
            ind = p

    0xff00_0000'u32 or
        (if is_center: 0'u32 else: v.points[ind].color)

proc gen_image*(v: var Voronoi) = # st mode
    v.image = collect(newSeq):
        for i in 0..<v.w:
            for j in 0..<v.h:
                v.gen_pixel(i, j)

# set image chunk from..to
proc set_chunk(v: var Voronoi, i, n: int) =
    for index in chunk_range(v.image.len, i, n):
        v.image[index] = v.gen_pixel(index %% v.w, index div v.w)

proc gen_image_mt(v: var Voronoi) = # mt mode
    v.image = newSeq[uint32](v.w * v.h)
    let ncpus = countProcessors()

    parallel:
        for i in 0..<ncpus:
            spawn v.set_chunk(i, ncpus)

proc image_bytes(v:Voronoi):int {.inline.} = v.image.len * sizeof(v.image[0])

proc write*(v: Voronoi, fn: string) = # write image to binary file
    var f = newFileStream(fn, fmWrite)
    if not f.isNil:
        f.writeData(v.image[0].unsafeAddr, v.image_bytes)
        f.close()

proc newVoronoi*(w, h, n: int): Voronoi =
    randomize()
    result = Voronoi(w: w, h: h)
    # generate x,y:rand(w,h), color:rand(max int32)
    result.points = toSeq(0..<n).map(x => Point(x: rand(w), y: rand(h),
            color: uint32(rand(0x00ff_ffff))))

    # mt mode
    result.gen_image_mt()

    # st mode
    # result.gen_image()

proc write_image*(m:Voronoi, fn:string) =
    let image = newImage(m.w, m.h)
    image.data = cast[seq[ColorRGBX]](m.image)
    image.writeFile(fn)

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
