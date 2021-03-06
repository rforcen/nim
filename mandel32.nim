# mandelbrot / parallel
# compile w/ 
# nim c --experimental --threads:on -d:release mandel.nim
# x 3 times faster than float64 version

import sequtils, streams, times, threadpool, cpuinfo
import pixie
import par
import complex_inline

{.experimental: "parallel".}

const fire_pallete: array[256, uint32] = [0'u32, 0, 4, 12, 16, 24, 32, 36,
        44, 48, 56, 64, 68, 76, 80,
 88, 96, 100, 108, 116, 120, 128, 132,
 140, 148, 152, 160, 164, 172, 180, 184, 192, 200, 1224, 3272, 4300, 6348, 7376,
 9424, 10448,
 12500, 14548, 15576, 17624, 18648, 20700, 21724, 23776, 25824, 26848, 28900,
 29924, 31976,
 33000, 35048, 36076, 38124, 40176, 41200, 43248, 44276, 46324, 47352, 49400,
 51452, 313596,
 837884, 1363196, 1887484, 2412796, 2937084, 3461372, 3986684, 4510972, 5036284,
 5560572,
 6084860, 6610172, 7134460, 7659772, 8184060, 8708348, 9233660, 9757948,
 10283260, 10807548,
 11331836, 11857148, 12381436, 12906748, 13431036, 13955324, 14480636, 15004924,
 15530236,
 16054524, 16579836, 16317692, 16055548, 15793404, 15269116, 15006972, 14744828,
 14220540,
 13958396, 13696252, 13171964, 12909820, 12647676, 12123388, 11861244, 11599100,
 11074812,
 10812668, 10550524, 10288380, 9764092, 9501948, 9239804, 8715516, 8453372,
 8191228, 7666940,
 7404796, 7142652, 6618364, 6356220, 6094076, 5569788, 5307644, 5045500,
 4783356, 4259068,
 3996924, 3734780, 3210492, 2948348, 2686204, 2161916, 1899772, 1637628,
 1113340, 851196,
 589052, 64764, 63740, 62716, 61692, 59644, 58620, 57596, 55548, 54524, 53500,
 51452, 50428,
 49404, 47356, 46332, 45308, 43260, 42236, 41212, 40188, 38140, 37116, 36092,
 34044, 33020,
 31996, 29948, 28924, 27900, 25852, 24828, 23804, 21756, 20732, 19708, 18684,
 16636, 15612,
 14588, 12540, 11516, 10492, 8444, 7420, 6396, 4348, 3324, 2300, 252, 248, 244,
 240, 236, 232,
 228, 224, 220, 216, 212, 208, 204, 200, 196, 192, 188, 184, 180, 176, 172, 168,
 164, 160, 156,
 152, 148, 144, 140, 136, 132, 128, 124, 120, 116, 112, 108, 104, 100, 96, 92,
 88, 84, 80, 76,
 72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12, 8, 0, 0]


# mandelbrot object

type
    Mandelbrot = object
        w*, h*, iters: int32
        center*, range*: Complex32
        image*: seq[uint32]

proc newMandelbrot*(w, h, iters: int32, center, range: Complex32): Mandelbrot =
    Mandelbrot(w: w, h: h, iters: iters, center: center, range: range)

proc size(m:Mandelbrot):int32 = m.w * m.h

proc do_scale(m: Mandelbrot, cr: Complex32, i: int, j: int): Complex32 =
    cr + complex32(
        (m.range.im - m.range.re) * i.float32 / float32(m.w),
        (m.range.im - m.range.re) * j.float32 / float32(m.h))

proc gen_pixel(m: Mandelbrot, i: int, j: int): uint32 =
    let
        scale : float32 = 0.8 * float32(m.w) / float32(m.h)
        cr = complex32(m.range.re, m.range.re)
        c0 : Complex32 = scale * m.do_scale(cr, i, j) - m.center

    var
        z : Complex32 = c0
        ix = m.iters

    for k in 0..<m.iters:
        z = z * z + c0 # z*z is the typical 2nd order fractal
        if z.abs2() > 4.0'f32:
            ix = k
            break

    0xff00_0000'u32 or (
        if ix >= m.iters: 0'u32
        else: fire_pallete[((fire_pallete.len * ix) div 50) %% fire_pallete.len]
    )

# parallel generation using par_apply

proc gen_par*(m:var Mandelbrot) =
    let # local m parameters used in gen_pixel call
        w = m.w
        h = m.h

        iters = m.iters
        range = m.range
        center = m.center

    proc gen_pixel(item: int): uint32 =
        let
            i = item div w
            j = item %% w
            iw = i.float32 / w.float32
            jh = j.float32 / h.float32
            scale : float32 = 0.8'f32 * w.float32 / h.float32
            cr = complex(range.re, range.re)
            
        proc do_scale(cr: Complex): Complex =
            result = cr + complex( (range.im - range.re) * iw, (range.im - range.re) * jh)

        let c0 = scale * do_scale(cr) - center
        var
            z = c0
            ix = iters

        for k in 0..<iters:
            z = z * z + c0; # z*z is the typical 2nd order fractal
            if z.abs2() > 4.0'f32:
                ix = k
                break

        0xff00_0000'u32 or (
            if ix >= iters: 0'u32
            else: fire_pallete[((fire_pallete.len * ix) div 50) %% fire_pallete.len]
        )
    

    m.image = newSeq[uint32](m.size)
    par_apply(m.image, gen_pixel)

proc generate_st*(m: var Mandelbrot) =
    m.image = toSeq(0..<int(m.w * m.h)).
        mapIt(m.gen_pixel(it div m.w, it %% m.w))
        
proc generate_st1*(m: var Mandelbrot) = # bit faster
    m.image = newSeq[uint32](m.size)
    for i in 0..<m.size:
        m.image[i]=m.gen_pixel(i div m.w, i %% m.w)

# generate the chunk 'i' of 'n' -> img
proc gen_range(m: var Mandelbrot, chunk:Slice[int]) =
    for index in chunk:
        m.image[index] = m.gen_pixel(index %% m.w, index div m.w)

proc generate_mt*(m: var Mandelbrot) =
    
    m.image = newSeq[uint32](m.size)

    parallel:
        for chunk in chunk_ranges(m.size, countProcessors()):
            spawn m.gen_range(chunk)

proc write*(m: Mandelbrot, fn: string) = # write image to binary file
    var f = newFileStream(fn, fmWrite)
    if not f.isNil:
        f.writeData(m.image[0].unsafeAddr, m.image.len * sizeof(m.image[0]))
        f.close()

proc write_image*(m:Mandelbrot, fn:string) =
    let image = newImage(m.w, m.h)
    image.data = cast[seq[ColorRGBX]](m.image)
    image.writeFile(fn)

# main

when isMainModule:

    proc mandelbrot() =
        let
            w : int32= 1024*4'i32
            iters :int32= 200'i32
            center = complex32(0.5, 0.0)
            rng = complex32(-2.0, 2.0)

        echo "mandelbrot ", w, "x", w, " iters:", iters
        var mandel = newMandelbrot(w, w, iters, center, rng)
        var t0 = now()

        # generate ST mode
        mandel.generate_st1()
        echo "ST lap: ", (now() - t0).inMilliseconds(), "ms"

        # MT parallel mode
        # t0 = now()
        # mandel.generate_mt()
        # echo "MT lap: ", (now() - t0).inMilliseconds(), "ms"

        # par mode
        t0 = now()
        mandel.gen_par()
        echo "par lap: ", (now() - t0).inMilliseconds(), "ms"

        # write image to binary file
        # mandel.write("mandel.bin")
        mandel.write_image("mandel.png")

    mandelbrot()


