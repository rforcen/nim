# yet another opencl wrapper (nvidia oriented)
# yacl.nim

import nimcl, opencl, times, streams

type
  OCL* = object
    platform: PPlatformId
    device: PDeviceId
    context: PContext
    queue: PCommandQueue
    kernel*: PKernel
    program: Pprogram


proc `=destroy`*(ocl: var OCL) =
  if not ocl.kernel.isNil: release(ocl.kernel)
  if not ocl.program.isNil: release(ocl.program)
  release(ocl.queue)
  release(ocl.context)

proc namedDevice*(name: string, n_device: int): OCL =
  let
    platform = getPlatformByName(name)
    device = platform.getDevices[n_device]
    context = @[device].createContext
    queue = context.commandQueueFor(device)

  OCL(platform: platform, device: device, context: context, queue: queue)

# nvidia specific cl init
proc nvidiaDevice*(): OCL = namedDevice("NVIDIA", 0)

# nvidia specific cl init
proc intelDevice*(): OCL = namedDevice("Intel", 0)

proc compile*(ocl: var OCL, source: string, kernel_func: string) =
  ocl.program = ocl.context.createAndBuild(source, ocl.device)
  ocl.kernel = ocl.program.createKernel(kernel_func)

proc buffer*[T](ocl: OCL, buff: seq[T]): PMem = ocl.context.bufferLike(buff)

proc run*(ocl: OCL, size: int) = ocl.queue.run(ocl.kernel, size)

proc read*[T](ocl: OCL, v: var seq[T], gb: Pmem) = ocl.queue.read(v, gb)

proc write*[T](ocl: OCL, v: var seq[T], gb: Pmem) = ocl.queue.write(v, gb)


proc write_file*[T](vi: seq[T], fn: string) = # write image to binary file
  var f = newFileStream(fn, fmWrite)
  if not f.isNil:
    f.writeData(vi[0].unsafeAddr, vi.len * sizeof(T))
    f.close()

# mesh utils

type float4* = object
  x, y, z, t: float32
type Vertex* = object
  position, normal, color, texture: float4

proc generate_faces*(n: int): seq[seq[int]] =
  var faces: seq[seq[int]] = @[]
  for i in 0..<n - 1:
    for j in 0..<n - 1:
      faces.add(@[
          (i + 1) * n + j,
          (i + 1) * n + j + 1,
          i * n + j + 1,
          i * n + j,
      ])
    faces.add(@[(i + 1) * n, (i + 1) * n + n - 1, i * n, i * n + n - 1])

  for i in 0..<n - 1:
    faces.add(@[i, i + 1, n * (n - 1) + i + 1, n * (n - 1) + i])
  faces

proc write_wrl*(mesh: seq[Vertex], faces: seq[seq[int]], name: string): void =
  var f = newFileStream(name, fmWrite)


  if not f.isNil:
    f.write("""
#VRML V2.0 utf8 

# Spherical Harmonics :        

# lights on
DirectionalLight {  direction -.5 -1 0   intensity 1  color 1 1 1 }
DirectionalLight {  direction  .5  1 0   intensity 1  color 1 1 1 }
           
Shape {
    # default material
    appearance Appearance {
        material Material { }
    }
    geometry IndexedFaceSet {
        
        coord Coordinate {
            point [
""")

    for s in mesh:
      let p = s.position
      f.write(p.x, " ", p.y, " ", p.z, "\n")

    f.write(
        """]
        }
        color Color {
            color [
            """)

    for s in mesh:
      let p = s.color
      f.write(p.x, " ", p.y, " ", p.z, "\n")

    f.write(
        """]
        }
        normal Normal {
            vector [
        """)

    #  normals
    for s in mesh:
      let p = s.normal
      f.write(p.x, " ", p.y, " ", p.z, "\n")
    f.write(
        """]
        }
        coordIndex [
            """)
    #  faces
    for face in faces:
      for ix in face:
        f.write($ix, " ")

      f.write("-1,\n")

    f.write(
        """]
        colorPerVertex TRUE
        convex TRUE
        solid TRUE
    }
}""")
    f.close()
