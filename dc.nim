# Domain Coloring
# dc.nim


import math, complex, zvm, streams, threadpool, cpuinfo
import pixie
import par

type DomainColoring = object
    w: int
    h: int
    image: seq[uint32]
    zvm: Zvm

proc hsv_2_rgb(h: float, s: float, v: float): uint32 =
    # convert hsv to int with alpha 0xff00000
    var (r, g, b) = (0.0, 0.0, 0.0)

    if s == 0.0: (r, g, b) = (v, v, v)
    else:
        let h = if h == 1.0: 0.0 else: h
        let z = (h * 6.0).floor()
        let f = h * 6.0 - z

        let (p, q, t) = (
            v * (1.0 - s),
            v * (1.0 - s * f),
            v * (1.0 - s * (1.0 - f)) )

        case int(z):
            of 0: (r, g, b) = (v, t, p)
            of 1: (r, g, b) = (q, v, p)
            of 2: (r, g, b) = (p, v, t)
            of 3: (r, g, b) = (p, q, v)
            of 4: (r, g, b) = (t, p, v)
            of 5: (r, g, b) = (v, p, q)
            else: discard

    # generate the ARGB'u32
    result = cast[uint32]([uint8(b*255.0), uint8(g*255.0), uint8(r*255.0), 0xff'u8])


proc gen_pixel(zvm: Zvm, index, w, h: int): uint32 =

    const PI2 = PI * 2.0

    let limit = PI
    let (rmi, rma, imi, ima) = (-limit, limit, -limit, limit)
    let (i, j) = (index %% w, index div w)
    let im = ima - (ima - imi) * float(j) / float(h - 1)
    let re = rma - (rma - rmi) * float(i) / float(w - 1)

    let v = zvm.eval(complex(re, im))

    var hue = v.phase() # calc hue, arg:phase -pi..pi
    if hue < 0.0: hue += PI2
    hue /= PI2

    var (m, ranges, rangee) = (v.abs(), 0.0, 1.0)             # norm
    while m > rangee:
        ranges = rangee
        rangee *= E

    let k: float = (m - ranges) / (rangee - ranges)
    let kk =
        if k < 0.5: k * 2.0
        else: 1.0 - (k - 0.5) * 2.0

    func pow3(x: float): float {.inline.} = x*x*x

    let sat: float = 0.4 + (1.0 - pow3(1.0 - kk)) * 0.6
    let val: float = 0.6 + (1.0 - pow3(1.0 - (1.0 - kk))) * 0.4

    result = hsv_2_rgb(hue, sat, val)

proc write*(dc: DomainColoring, fn: string) = # write image to binary file
    var f = newFileStream(fn, fmWrite)
    if not f.isNil:
        f.writeData(dc.image[0].unsafeAddr, dc.image.len * sizeof(dc.image[0]))
        f.close()

proc gen_range(dc: var DomainColoring, chunk: Slice[int]) =
    for index in chunk:
        dc.image[index] = gen_pixel(dc.zvm, index, dc.w, dc.h)

proc write_image*(dc : DomainColoring, fn:string) =
    let image = newImage(dc.w, dc.h)
    image.data = cast[seq[ColorRGBX]](dc.image)
    image.writeFile(fn)

proc newDC(w, h: int, zexpr: string): DomainColoring =
    result = DomainColoring(w: w, h: h, zvm: newZvm(zexpr))

    result.image = newSeq[uint32](w*h)
    # for i in 0..w*h: # ST mode
    #     result.image[i] = gen_pixel(result.zvm, i, w, h)

    let 
        ncpus = countProcessors()

    parallel:
        for chunk in chunk_ranges(result.image.len, ncpus):
            spawn result.gen_range(chunk)

when isMainModule:
    import times

    let
        w = 1920
        zexpr = "z * sin( c(1,1)/cos(3/z) + tan(1/z+1) )"

    echo "DC: ", zexpr, ",", w*w

    let t = now()
    let dc = newDC(w, w, zexpr)
    echo "lap: ", (now()-t).inMilliseconds(), "ms"

    dc.write_image("dc.png")
