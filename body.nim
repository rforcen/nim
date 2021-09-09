# n-body w/gl interface

import vmath, sequtils, strutils, math, re, sugar, os, strformat

const G = 6.67e-11 # G grav const

# Body

type Body* = object
  r, v: DVec2
  mass: float

proc newBody*(r, v: DVec2, mass: float): Body =
  Body(r: r, v: v, mass: mass)

proc do_move(b: var Body, f: DVec2, dt: float) =
  b.v += f / b.mass * dt
  b.r += b.v * dt

proc force_from(sb: Body, b: Body): DVec2 = # newton gravity formula
  result = b.r - sb.r
  let f = (G * sb.mass * b.mass) / result.lengthSq
  result = result.normalize * f

proc fromv5*(v: openArray[float]): Body =
  newBody(r = dvec2(v[0], v[1]), v = dvec2(v[2], v[3]), mass = v[4])


# body set

type BodySet = object
  radius: float
  bodies*: seq[Body]

proc newBodySet*(): BodySet =
  BodySet()

proc three_bodies*(): BodySet =
  BodySet(
      radius: 1.25e11,
      bodies: @[
          fromv5([0.0, 0.0, 0.0500e04, 0.0, 5.974e24]),
          fromv5([0.0, 4.500e10, 3e4, 0.0, 1.989e30]),
          fromv5([0.0, -4.500e10, -3e4, 0.0, 1.989e30]),
    ])


proc inc_time*(bs: var BodySet, dt: float) =
  let n=bs.bodies.high
  var f = newSeq[DVec2](bs.bodies.len)

  for i in 0..n:
    for j in 0..n:
      if j != i: # calc only lower diag
        f[i] += bs.bodies[i].force_from(bs.bodies[j])

  for i in 0..n: # move the bodies
    bs.bodies[i].do_move(f[i], dt)

proc get_coords*(bs: BodySet, scale: float = 1): seq[DVec2] =
  bs.bodies.mapIt(it.r * scale / bs.radius)

proc read*(bs: var BodySet, path: string) =
  let nums = toSeq(findAll(readFile(path),
      re"[+-]?(\d+([.]\d*)?([eE][+-]?\d+)?|[.]\d+([eE][+-]?\d+)?)")).mapIt(it.parseFloat)

  bs.radius = nums[1]
  bs.bodies = collect(newSeq):
    for i in 0..<nums[0].int:
      fromv5(nums[i * 5 + 2..i * 5 + 2 + 4])

proc all_files*(path:string):seq[string] = toSeq(walkDir(path)).mapIt(it.path)

when isMainModule:
  proc test01* =
    var bs = newBodySet()
    bs.read("bodies/hypnosis")
    echo bs
    for i in 0..10000:
      bs.inc_time(1e5)
    echo bs

  # ui_gl
  import opengl/glut, opengl, opengl/glu

  var
    iters {.global.} = 0
    zoom {.global.} = -4.0

    body_file {.global.} = "bodies/hypnosis"
    body_files=all_files("bodies")
    nbody=0
    bs {.global.} = newBodySet()
    time_inc = 20e3

  proc draw_scene() =
    bs.inc_time(time_inc)
    glColor3f(1, 0.5, 0.6)
    for c in bs.get_coords():
      glLoadIdentity() # Reset
      glTranslated(c.x, c.y, zoom)
      glutSolidSphere(0.04, 20, 20)
    glutSetWindowTitle fmt "nbodies: {body_file} {time_inc}"

  proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
    if height != 0:
      glViewport(0, 0, width, height)
      glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
      glLoadIdentity() # Reset
      gluPerspective(45.0, width / height, 0.1, 100.0)

  proc keyhook(key: GLbyte, x, y: GLint) {.cdecl.} =
    case key.char:
    of 'r': bs.read(body_file)
    of 'q', '\e': quit(1)
    of '+': time_inc+=3e3
    of '-': time_inc-=3e3
    of ' ': # next file in folder
      nbody.inc
      if nbody>=body_files.len: nbody=0
      body_file=body_files[nbody]
      bs.read(body_file)
      iters=0
    else: discard


  proc display() {.cdecl.} =
    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
    glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
    glLoadIdentity() # Reset the model-view matrix
    glColor3f(1.0, 1.0, 1.0)

    inc iters

    draw_scene()

    glutSwapBuffers()
    glutPostRedisplay() # animate

  proc main_gl =

    bs.read(body_file)

    var argc: cint = 0
    glutInit(addr argc, nil)
    glutInitDisplayMode(GLUT_DOUBLE)
    glutInitWindowSize(1200, 1200)
    glutInitWindowPosition(500, 500)
    discard glutCreateWindow("n bodies:" & body_file)


    glutDisplayFunc(display)
    glutReshapeFunc(reshape)
    glutKeyboardFunc(keyhook)
    # glutMouseFunc(mouseWheel)
    # glutMotionFunc(mouseDrag)
    # glutPassiveMotionFunc(mouseDrag)

    loadExtensions()

    glClearColor(0.0, 0.0, 0.0, 1.0) # Set background color to black and opaque
    glClearDepth(1.0) # Set background depth to farthest
    # glEnable(GL_DEPTH_TEST) # Enable depth testing for z-culling
    # glDepthFunc(GL_LEQUAL) # Set the type of depth-test
    # glShadeModel(GL_SMOOTH) # Enable smooth shading
    # glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

    glutMainLoop()


  main_gl()
  # test01()
