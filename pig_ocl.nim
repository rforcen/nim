#
# pig: parallel image generation in opencl 
# mandelbrot, voronoi, domain coloring, spherical harmonics
# opencl sources in cl folder
#

import yacl, sequtils, sugar, strutils, nimcl, times, zvm, random
import pixie

proc write_image*(fn:string, img:seq[uint32], w,h:int) =
    let image = newImage(w, h)
    image.data = cast[seq[ColorRGBX]](img)
    image.writeFile(fn)

# mandelbrot
proc mandelbrot =
  let
    w = 1920
    size = w*w

  var
    image = newSeq[uint32](size)

    center = [2'f32, 1] # parameters: float32(2), float32, int32
    scale: float32 = 2
    iters = 400

  var ocl = nvidiaDevice()
  ocl.compile(readFile("cl/mandelbrot.cl"), "mandelbrot")

  let gpuImage = ocl.buffer(image)

  ocl.kernel.args(gpuImage, center, scale.float32, iters.int32)

  echo "mandelbrot cl, w=", w
  let t0 = now()
  ocl.run(size)

  ocl.read(image, gpuImage)
  echo "generated fbi file lap: ", (now()-t0).inMilliseconds, "ms"

  write_file(image, "cl-mandel.bin")

  # Clean up
  release(gpuImage)

# voronoi tiles
proc voronoi() =
  type Point = object
    x, y: float32
    color, pad: uint32

  let
    w = 1024*2
    size = w*w
    n_points = w div 2

  randomize()
  var points: seq[Point] = toSeq(0..<n_points).map(x => Point(x: rand(1.0).float32, y: rand(1.0).float32,
            color: uint32(rand(0x00ff_ffff))))

  var image = newSeq[uint32](size)

  var ocl = nvidiaDevice()
  ocl.compile(readFile("cl/voronoi.cl"), "voronoi")

  let gpuImage = ocl.buffer(image)
  let gpuPoints = ocl.buffer(points)

  ocl.kernel.args(gpuImage, gpuPoints, n_points.int32)
  ocl.write(points, gpuPoints)

  echo "voronoi cl, w=", w
  let t0 = now()
  ocl.run(size)

  ocl.read(image, gpuImage)
  echo "generated fbi file lap: ", (now()-t0).inMilliseconds, "ms"

  write_image("cl-voronoi.png", image, w, w)

  # Clean up
  release(gpuImage)
  release(gpuPoints)

# domain coloring fixed cl formula
proc domain_coloring =
  let
    w = 1920
    size = w*w

  var
    image = newSeq[uint32](size)

  var ocl = nvidiaDevice()
  ocl.compile(readFile("cl/dc.cl"), "domain_coloring")

  let gpuImage = ocl.buffer(image)

  ocl.kernel.args(gpuImage)

  echo "domain coloring cl, w=", w
  let t0 = now()
  ocl.run(size)

  ocl.read(image, gpuImage)
  echo "generated fbi file lap: ", (now()-t0).inMilliseconds, "ms"

  write_file(image, "cl-dc.bin")

  # Clean up
  release(gpuImage)

# zvm based domain coloring
proc domain_coloring_zvm =
  let
    w = 1920
    size = w*w
    zvm = newZvm(Predef_funcs[18])

  var
    image = newSeq[uint32](size)
    code = zvm.code # int is 64 bit
    ocl = nvidiaDevice()

  let real_def = """
    // define real, real2, real3 types
    typedef _fp_  real;
    typedef _fp_2 real2;
    typedef _fp_3 real3;

  """.multiReplace(("_fp_","float"))

  ocl.compile(real_def & readFile("cl/dc_zvm.cl"), "domain_coloring")

  let
    gpuImage = ocl.buffer(image)
    gpuCode = ocl.buffer(code)

  ocl.kernel.args(gpuImage, gpuCode)
  ocl.write(code, gpuCode)

  echo "domain coloring zvm cl, w=", w
  let t0 = now()
  ocl.run(size)

  ocl.read(image, gpuImage)
  echo "generated fbi file lap: ", (now()-t0).inMilliseconds, "ms"

  write_file(image, "cl-dc.bin")

  # Clean up
  release(gpuImage)
  release(gpuCode)

# spherical harmonic, generates wrl file, (view with view3dscene)
proc spherical_harmonics =

  let
    resolution = 512*2
    color_map = 0
    code = 234
  let
    size = resolution * resolution

  var
    mesh = newSeq[Vertex](size)

  var ocl = nvidiaDevice()
  ocl.compile(readFile("cl/sh.cl"), "spherical_harmonics")

  let t0 = now()
  let gpuMesh = ocl.buffer(mesh)
  ocl.kernel.args(gpuMesh, resolution.int32, color_map.int32, code.int32)

  echo "spherical harmonics cl, resol=", resolution
  ocl.run(size)

  ocl.read(mesh, gpuMesh)
  echo "generating cl-sh.wrl file lap: ", (now()-t0).inMilliseconds, "ms..."

  write_wrl(mesh, generate_faces(resolution), "cl-sh.wrl")


when isMainModule:
  # mandelbrot()
  voronoi()
  # domain_coloring()
  # domain_coloring_zvm()
  # spherical_harmonics()
