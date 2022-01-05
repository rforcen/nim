# mandelbrot using mpfr

import mpfr, weave, strformat

const fire_pallete: array[256, uint32] = [0'u32, 0, 4, 12, 16, 24, 32, 36, 44, 48, 56, 64, 68, 76, 80,
 88, 96, 100, 108, 116, 120, 128, 132, 140, 148, 152, 160, 164, 172, 180, 184, 192, 200, 1224, 3272, 4300, 6348, 7376,
 9424, 10448, 12500, 14548, 15576, 17624, 18648, 20700, 21724, 23776, 25824, 26848, 28900,
 29924, 31976, 33000, 35048, 36076, 38124, 40176, 41200, 43248, 44276, 46324, 47352, 49400,
 51452, 313596, 837884, 1363196, 1887484, 2412796, 2937084, 3461372, 3986684, 4510972, 5036284,
 5560572, 6084860, 6610172, 7134460, 7659772, 8184060, 8708348, 9233660, 9757948, 10283260, 10807548,
 11331836, 11857148, 12381436, 12906748, 13431036, 13955324, 14480636, 15004924, 15530236,
 16054524, 16579836, 16317692, 16055548, 15793404, 15269116, 15006972, 14744828, 14220540,
 13958396, 13696252, 13171964, 12909820, 12647676, 12123388, 11861244, 11599100, 11074812,
 10812668, 10550524, 10288380, 9764092, 9501948, 9239804, 8715516, 8453372, 8191228, 7666940,
 7404796, 7142652, 6618364, 6356220, 6094076, 5569788, 5307644, 5045500, 4783356, 4259068,
 3996924, 3734780, 3210492, 2948348, 2686204, 2161916, 1899772, 1637628, 1113340, 851196,
 589052, 64764, 63740, 62716, 61692, 59644, 58620, 57596, 55548, 54524, 53500, 51452, 50428,
 49404, 47356, 46332, 45308, 43260, 42236, 41212, 40188, 38140, 37116, 36092, 34044, 33020,
 31996, 29948, 28924, 27900, 25852, 24828, 23804, 21756, 20732, 19708, 18684, 16636, 15612,
 14588, 12540, 11516, 10492, 8444, 7420, 6396, 4348, 3324, 2300, 252, 248, 244, 240, 236, 232,
 228, 224, 220, 216, 212, 208, 204, 200, 196, 192, 188, 184, 180, 176, 172, 168, 164, 160, 156,
 152, 148, 144, 140, 136, 132, 128, 124, 120, 116, 112, 108, 104, 100, 96, 92, 88, 84, 80, 76,
 72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12, 8, 0, 0]

type
  Mandelbrot* = object
    w*, h*, iters: int
    center*, range*: cmpfr
    image*: seq[uint32]

proc do_scale(m: Mandelbrot, cr: cmpfr, i: int, j: int): cmpfr {.inline.} =
    cr + newCmpfr(
        (m.range.im - m.range.re) * i / m.w,
        (m.range.im - m.range.re) * j / m.h)

proc size*(m:Mandelbrot):int = m.w * m.h

proc newMandelbrot*(w, h, iters: int, center, range: cmpfr): Mandelbrot =
  Mandelbrot(w: w, h: h, iters: iters, center: center, range: range, image: newSeq[uint32](w*h))  

proc gen_pixel*(m: var Mandelbrot, index : int) =
  let
    i = index %% m.w
    j = index div m.w
    scale = 0.8 * m.w.float / m.h.float
    cr = newCmpfr(m.range.re, m.range.re)
    c0 : cmpfr =  m.do_scale(cr, i, j) * scale  - m.center

  var
    z : cmpfr = c0
    ix = m.iters

  for k in 0..<m.iters:
    z = z * z + c0 
    if z.abs2() > 4.0:
        ix = k
        break

  m.image[index] = 0xff00_0000'u32 or (
    if ix >= m.iters: 0'u32
    else: fire_pallete[((fire_pallete.len * ix) div 50) %% fire_pallete.len]
  )

proc gen_image(m:var Mandelbrot)=

  let mandel_ptr = m.addr # use a ptr in parallelFor

  Weave.init()

  parallelFor index in 0..<m.size:
    captures:{mandel_ptr}
    mandel_ptr[].gen_pixel(index)

  Weave.exit()

proc write_ppm*(m:Mandelbrot, fn: string) = # write image netpbm P7 format
  var f = open(fn, fmWrite)
  if not f.isNil:
    f.write &"P7\nWIDTH {m.w}\nHEIGHT {m.h}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n"      
    discard f.writeBuffer(m.image[0].unsafeAddr, m.image.len * m.image[0].sizeof)
    f.close()

when isMainModule:
  import times

  set_precision(256)
  
  let
    w = 512
    h = w
    iters = 200
    center = newCmpfr(0.5, 0.0)
    rng = newCmpfr(-2.0, 2.0)

  echo "mandelbrot mpfr ", w, "x", h, " iters:", iters, ", precision:", get_precision(), " bits"

  var mandel = newMandelbrot(w, h, iters, center, rng)

  var t0 = now()
  mandel.gen_image()
  echo "lap: ", (now() - t0).inMilliseconds(), "ms"
  echo "writing mandel.ppm file"

  mandel.write_ppm("mandel.ppm")
  echo "done"