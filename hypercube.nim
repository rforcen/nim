# hypercube ani

import math

type 
  vec3 = array[3, float]
  vec4 = array[4, float]
  v16x3 = array[16, vec3]
  v16x4 = array[16, vec4]

  HyperCube = object
    rVector : array[6, float]
    threeWarp : float 
    faces : array[23, array[4,int]]
    cube4c : v16x4
    cube3c : array[16, vec3]
    cubepnts, nFaces, nCoords:int 

# Transform4D  over vec4

proc rotateXY(pnt:var vec4, theta:float) = 
  pnt = [pnt[0] * cos(theta) + pnt[1] * -sin(theta), pnt[0] * sin(theta) + pnt[1] * cos(theta), pnt[2], pnt[3]]

proc rotateYZ(pnt:var vec4, theta :float) =
  pnt = [ pnt[0], pnt[1] * cos(theta) + pnt[2] * sin(theta), pnt[1] * -sin(theta) + pnt[2] * cos(theta), pnt[3]]

proc rotateXZ(pnt : var vec4, theta :float) = 
  pnt = [ pnt[0] * cos(theta) + pnt[2] * -sin(theta), pnt[1],  pnt[0] * sin(theta) + pnt[2] * cos(theta), pnt[3]]

proc rotateXW(pnt : var vec4, theta :float) =
  pnt = [ pnt[0] * cos(theta) + pnt[3] * sin(theta), pnt[1], pnt[2], pnt[0] * -sin(theta) + pnt[3] * cos(theta)]

proc rotateYW(pnt : var vec4, theta :float) =
  pnt = [ pnt[0], pnt[1] * cos(theta) + pnt[3] * -sin(theta), pnt[2], pnt[1] * sin(theta) + pnt[3] * cos(theta)]

proc rotateZW(pnt : var vec4, theta :float) =
  pnt = [ pnt[0], pnt[1], pnt[2] * cos(theta) +  pnt[3] * -sin(theta), pnt[2] * sin(theta) + pnt[3] * cos(theta)]

proc project4Dto3D(pnt : vec4) : vec3 =
  [ pnt[1], pnt[2], pnt[3] ]

proc `*`(v:vec4, f:float) : vec4 = [v[0]*f,v[1]*f,v[2]*f,v[3]*f]

proc rotate(pnt : var vec4, ang : array[6, float]) = 
  pnt.rotateXY ang[0]
  pnt.rotateXZ ang[1]
  pnt.rotateXW ang[2]
  pnt.rotateYZ ang[3]
  pnt.rotateYW ang[4]
  pnt.rotateZW ang[5]


proc newHyperCube*() : HyperCube =
  let 
    u=0.5
    c4c = [ [u, u, u, u], [u, u, u, -u], [u, u, -u, u], [u, u, -u, -u], [u, -u, u, u
      ], [u, -u, u, -u], [u, -u, -u, u], [u, -u, -u, -u], [-u, u, u, u],
      [-u, u, u, -u], [-u, u, -u, u], [-u, u, -u, -u], [-u, -u, u, u],
      [-u, -u, u, -u], [-u, -u, -u, u], [-u, -u, -u, -u]]
  HyperCube(threeWarp:1.3, cubepnts:16, nFaces:23, nCoords:23*4, 
    faces:[ # 24 faces -> not required [9,1,13,5]?? creates a cross,
      [0, 2, 3, 1], [0, 4, 5, 1], [0, 4, 6, 2], [0, 8, 9, 1], [0, 8, 10, 2],
      [0, 8, 12, 4], [4, 6, 7, 5], [2, 6, 7, 3], [1, 5, 7, 3], [2, 10, 11, 3],
      [1, 9, 11, 3], [8, 10, 11, 9], [8, 12, 13, 9], [8, 12, 14, 10],
      [4, 12, 13, 5], [4, 12, 14, 6], [2, 10, 14, 6], [12, 14, 15, 13],
      [10, 14, 15, 11], [9, 13, 15, 11], [6, 14, 15, 7], [5, 13, 15, 7],
      [3, 11, 15, 7]], 
    cube4c:c4c)

proc genCube*(hc:var HyperCube)

proc rotVector*(hc:var HyperCube, rot_wx,  rot_wy,  rot_wz, rot_xy,  rot_xz,  rot_yz : float) =
  hc.rVector = [rot_xy, rot_xz, rot_wx, rot_yz, rot_wy, rot_wz]
  hc.genCube

proc flatProjection*(hc:HyperCube, fourcoords : var v16x4, threecoords : var v16x3 ) =
  # cube3[012]=cube4[123], just remove coord x from 4d
  for i in 0..<16:
    var
      pnt4 = fourcoords[i]
      warp = hc.threeWarp / (hc.threeWarp + pnt4[0])
    threecoords[i] = project4Dto3D(pnt4 * warp)

proc genCube*(hc:var HyperCube) =
  for i in 0..<16:
    rotate(hc.cube4c[i], hc.rVector)
  hc.flatProjection(hc.cube4c, hc.cube3c)

#-----------------#
when isMainModule:

  # ui_gl
  import opengl/glut, opengl, opengl/glu

  var
    iters {.global.} = 0
    zoom {.global.} = -4.0
    hc {.global.}  = newHyperCube()

  converter f2gld(v:vec3):ptr GLdouble = cast[ptr GLdouble](v.unsafeAddr)

  proc draw_scene() {.cdecl.} =

    glLoadIdentity() # Reset
    glTranslatef(0, 0, zoom)
    glRotatef(30, 0, 1, 0)

    hc.rotVector(0.015f, 0, 0, 0, 0, 0)

    glColor3f(1, 1, 1)
  
    for face in hc.faces:
      glBegin(GL_LINE_LOOP)
      for ix in face: glVertex3dv(hc.cube3c[ix])
      glEnd()

  proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
    if height != 0:
      glViewport(0, 0, width, height)
      glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
      glLoadIdentity() # Reset
      gluPerspective(45.0, width / height, 0.1, 100.0)

  proc keyhook(key: GLbyte, x, y: GLint) {.cdecl.} =
    case key.char:
    of 'q', '\e': quit(1)
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

    var argc: cint = 0
    glutInit(argc.addr, nil)
    glutInitDisplayMode(GLUT_DOUBLE)
    glutInitWindowSize(1200, 1200)
    glutInitWindowPosition(500, 500)
    discard glutCreateWindow("4d hypercube")


    glutDisplayFunc(display)
    glutReshapeFunc(reshape)
    glutKeyboardFunc(keyhook)

    loadExtensions()

    glClearColor(0.0, 0.0, 0.0, 1.0) # Set background color to black and opaque
    glClearDepth(1.0) # Set background depth to farthest

    glutMainLoop()


  main_gl()