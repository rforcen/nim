# Domain Coloring
# dc.nim


import math, complex, zvm, streams, weave, strformat

type DomainColoring* = object
  w,h: int
  image*: seq[uint32]
  zvm: Zvm

proc hsv_2_rgb(h: float, s: float, v: float): uint32 =
  # convert hsv to int with alpha 0xff00000
  let (r, g, b) = 
    if s == 0.0: (v, v, v)
    else:
      let 
        h = if h == 1.0: 0.0 else: h
        z = (h * 6.0).floor()
        f = h * 6.0 - z

        (p, q, t) = ( v * (1.0 - s), v * (1.0 - s * f),  v * (1.0 - s * (1.0 - f)) )

      case int(z):
        of 0: (v, t, p)
        of 1: (q, v, p)
        of 2: (p, v, t)
        of 3: (p, q, v)
        of 4: (t, p, v)
        of 5: (v, p, q)
        else: (0.0,0.0,0.0)      

  # generate the ARGB'u32
  result = cast[uint32]([uint8(b*255), uint8(g*255), uint8(r*255), 0xff'u8])


proc set_pixel(dc : var DomainColoring, index: int) =

  const PI2 = PI * 2.0

  let 
    limit = PI
    (rmi, rma, imi, ima) = (-limit, limit, -limit, limit)
    (i, j) = (index %% dc.w, index div dc.w)
    im = ima - (ima - imi) * j.float / (dc.h - 1).float
    re = rma - (rma - rmi) * i.float / (dc.w - 1).float

    v = dc.zvm.eval(complex(re, im))

  var hue = v.phase() # calc hue, arg:phase -pi..pi
  if hue < 0.0: hue += PI2
  hue /= PI2

  var (m, ranges, rangee) = (v.abs(), 0.0, 1.0)             # norm
  while m > rangee:
      ranges = rangee
      rangee *= E

  let 
    k = (m - ranges) / (rangee - ranges)
    kk =
      if k < 0.5: k * 2.0
      else: 1.0 - (k - 0.5) * 2.0

    sat = 0.4 + (1.0 - (1.0 - kk)^3) * 0.6
    val = 0.6 + (1.0 - (1.0 - (1.0 - kk))^3) * 0.4

  dc.image[index] = hsv_2_rgb(hue, sat, val)

proc write_ppm*(dc: DomainColoring, fn: string) = # write image netpbm P7 format
  var f = newFileStream(fn, fmWrite)
  if not f.isNil:
    f.write &"P7\nWIDTH {dc.w}\nHEIGHT {dc.h}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n"      
    f.writeData(dc.image[0].unsafeAddr, dc.image.len * sizeof(dc.image[0]))
    f.close()

proc write_ppm6*(dc: DomainColoring, fn: string) = # write image to P6 netpbm
  var f = newFileStream(fn, fmWrite)
  if not f.isNil:
    f.write &"P6\n{dc.w} {dc.h} 255\n"
    for pix in dc.image: f.writeData(pix.unsafeAddr, 3) #rgb
    f.close()

# proc write_image*(dc : DomainColoring, fn:string) = # needs pixie...
#     let image = newImage(dc.w, dc.h)
#     image.data = cast[seq[ColorRGBX]](dc.image)
#     image.writeFile(fn)

proc newDC(w, h: int, zexpr: string): DomainColoring =
  result = DomainColoring(w: w, h: h, zvm: newZvm(zexpr), image:newSeq[uint32](w*h))

  Weave.init() # generate dc image in parallel

  let dc_ptr = result.addr
  parallelFor index in 0..<w*h:
    captures: {dc_ptr}
    dc_ptr[].set_pixel(index)
  
  Weave.exit()

#################
when isMainModule:
  import times

  let
    w = 1920
    zexpr = "z * sin( c(1,1)/cos(3/z) + tan(1/z+1) )"

  echo &"DC:{zexpr} items:{w*w}"

  let t = now()
  let dc = newDC(w, w, zexpr)
  echo &"lap:{(now()-t).inMilliseconds()} ms"

  dc.write_ppm6("dc.ppm")
