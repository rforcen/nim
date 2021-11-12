# hypercube ani

import math

type 
  vec3 = array[3, float]
  vec4 = array[4, float]
  v16x3 = array[16, vec3]
  v16x4 = array[16, vec4]

  HyperCube = object
    rot_vec : array[6, float]
    warp3 : float 
    faces : array[23, array[4,int]]
    cube4c : v16x4
    cube3c : array[16, vec3]
    cubepnts, nFaces, nCoords:int 

# yet another lin algebra oper's & func's 
proc `*`(v:vec4, f:float) : vec4 = [v[0]*f,v[1]*f,v[2]*f,v[3]*f]
proc `-`(a,b:vec3):vec3= [b[0]-a[0], b[1]-a[1], b[2]-a[2]]
proc hypot(a,b:float):float=(a*a+b*b).sqrt
proc hypot(v:vec3):float = (v[0]*v[0] + v[1]*v[1] + v[2]*v[2]).sqrt
proc `**`(a,b:vec3):vec3=[a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]] # cross

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

proc rotate(pnt : var vec4, ang : array[6, float]) = 
  pnt.rotateXY ang[0]
  pnt.rotateXZ ang[1]
  pnt.rotateXW ang[2]
  pnt.rotateYZ ang[3]
  pnt.rotateYW ang[4]
  pnt.rotateZW ang[5]

proc newHyperCube*() : HyperCube =
  const u=0.5

  HyperCube(warp3:1.3, cubepnts:16, nFaces:23, nCoords:23*4, 
    faces:[ [0, 2, 3, 1], [0, 4, 5, 1], [0, 4, 6, 2], [0, 8, 9, 1], [0, 8, 10, 2],
      [0, 8, 12, 4], [4, 6, 7, 5], [2, 6, 7, 3], [1, 5, 7, 3], [2, 10, 11, 3],
      [1, 9, 11, 3], [8, 10, 11, 9], [8, 12, 13, 9], [8, 12, 14, 10],
      [4, 12, 13, 5], [4, 12, 14, 6], [2, 10, 14, 6], [12, 14, 15, 13],
      [10, 14, 15, 11], [9, 13, 15, 11], [6, 14, 15, 7], [5, 13, 15, 7],
      [3, 11, 15, 7]], 
    cube4c:[ [u, u, u, u], [u, u, u, -u], [u, u, -u, u], [u, u, -u, -u], [u, -u, u, u
      ], [u, -u, u, -u], [u, -u, -u, u], [u, -u, -u, -u], [-u, u, u, u],
      [-u, u, u, -u], [-u, u, -u, u], [-u, u, -u, -u], [-u, -u, u, u],
      [-u, -u, u, -u], [-u, -u, -u, u], [-u, -u, -u, -u]])

proc gen_cube*(hc:var HyperCube)

proc rot_vect*(hc:var HyperCube, rot_wx,  rot_wy,  rot_wz, rot_xy,  rot_xz,  rot_yz : float) =
  hc.rot_vec = [rot_xy, rot_xz, rot_wx, rot_yz, rot_wy, rot_wz]
  hc.gen_cube

proc flat_proj*(hc:HyperCube, fourcoords : var v16x4, threecoords : var v16x3 ) =
  # cube3[012]=cube4[123], just remove coord x from 4d
  for i in 0..<16:
    var
      pnt4 = fourcoords[i]
      warp = hc.warp3 / (hc.warp3 + pnt4[0])
    threecoords[i] = project4Dto3D(pnt4 * warp)

proc gen_cube*(hc:var HyperCube) =
  for i in 0..<16:
    rotate(hc.cube4c[i], hc.rot_vec)
  hc.flat_proj(hc.cube4c, hc.cube3c)

#-----------------#
when isMainModule:

  # ui_gl
  import opengl/glut, opengl, opengl/glu

  var
    iters {.global.} = 0
    zoom {.global.} = -4.0

    hc {.global.}  = newHyperCube()

  converter v42gld(v:array[4,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
  converter v42gld(v:array[1,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)

  proc sceneInit() =  # works nice for golden solid colors (requires normals)
    let
      lmodel_ambient = [0'f32, 0, 0, 0]
      lmodel_twoside = [0'f32] # [GL_FALSE]
      light0_ambient = [0.1'f32, 0.1, 0.1, 1.0f]
      light0_diffuse = [1'f32, 1.0, 1.0, 0.0f]
      light0_position = [1'f32, 0.5, 1, 0]
      light1_position = [-1'f32, 0.5, -1, 0]
      light0_specular = [1'f32, 1, 1, 0]
      bevel_mat_ambient = [0'f32, 0, 0, 1]
      bevel_mat_shininess = [40'f32]
      bevel_mat_specular = [1'f32, 1, 1, 0]
      bevel_mat_diffuse = [1'f32, 0, 0, 0]

    glClearColor(0,0,0, 1)

    glLightfv(GL_LIGHT0, GL_AMBIENT, light0_ambient)
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light0_diffuse)
    glLightfv(GL_LIGHT0, GL_SPECULAR, light0_specular)
    glLightfv(GL_LIGHT0, GL_POSITION, light0_position)
    glEnable(GL_LIGHT0)

    glLightfv(GL_LIGHT1, GL_AMBIENT, light0_ambient)
    glLightfv(GL_LIGHT1, GL_DIFFUSE, light0_diffuse)
    glLightfv(GL_LIGHT1, GL_SPECULAR, light0_specular)
    glLightfv(GL_LIGHT1, GL_POSITION, light1_position)
    glEnable(GL_LIGHT1)

    glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE, lmodel_twoside)
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient)
    glEnable(GL_LIGHTING)

    glMaterialfv(GL_FRONT, GL_AMBIENT, bevel_mat_ambient)
    glMaterialfv(GL_FRONT, GL_SHININESS, bevel_mat_shininess)
    glMaterialfv(GL_FRONT, GL_SPECULAR, bevel_mat_specular)
    glMaterialfv(GL_FRONT, GL_DIFFUSE, bevel_mat_diffuse)

    glEnable(GL_COLOR_MATERIAL)
    glShadeModel(GL_SMOOTH)

    glEnable(GL_LINE_SMOOTH)
    glEnable(GL_POLYGON_SMOOTH) # creates white shade on lines -> remove
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)

  proc cylinder(x,y:vec3, rad:float) =
    # add proc glutSolidCylinder*(radius, height:GLdouble, slices, stacks : GLint) @ glut.nim
    let
      v : vec3 = x - y
      axis = if hypot(v[0], v[1]) < 0.001: [1.0, 0, 0] else: v ** [0.0, 0, 1]
      height = v.hypot
      angle = -arctan2(hypot(v[0], v[1]), v[2]) * 180 / PI # in deg.

    glPushMatrix()

    glTranslatef(x[0], x[1], x[2])
    glRotated(angle, axis[0], axis[1], axis[2])

    glutSolidCylinder(rad, height, 20, 1)

    glPopMatrix()

  proc sphere(center:vec3, rad:float) =
    glPushMatrix()
    glTranslatef(center[0], center[1], center[2])
    glutSolidSphere(rad, 10, 10)
    glPopMatrix()

  proc draw_scene() {.cdecl.} =

    glLoadIdentity() # Reset
    glTranslatef(0, 0, zoom)
    glRotatef(30, 0, 1, 0)

    hc.rot_vect(0.015, 0, 0, 0, 0, 0)
    
    glColor3f(0.5, 0.5, 0) # gold

    for c in hc.cube3c: # edge spheres
      sphere(c, 0.025)

    var ft : seq[(vec3,vec3)] # from - to segment

    for face in hc.faces: # point 2 point cyls
      var v:seq[vec3]
      for ix in face: 
        v.add hc.cube3c[ix]
      v.add v[0]

      for i in 0..v.high-1:
        if not ((v[i], v[i+1]) in ft): # don't repeat from-to / to-from segment
          ft.add (v[i], v[i+1]) # f-t & t-f
          ft.add (v[i+1], v[i])

          cylinder(v[i], v[i+1], 0.02)

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
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
    glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
    glLoadIdentity() # Reset the model-view matrix

    inc iters

    draw_scene()

    glutSwapBuffers()
    glutPostRedisplay() # animate

  proc main_gl =

    glutInit()
    glutInitDisplayMode(GLUT_DOUBLE)
    glutInitWindowSize(1200, 1200)
    glutInitWindowPosition(500, 500)
    discard glutCreateWindow("4d hypercube")


    glutDisplayFunc(display)
    glutReshapeFunc(reshape)
    glutKeyboardFunc(keyhook)

    loadExtensions()

    glClearColor(0, 0, 0, 1) # Set background color to black and opaque
    glClearDepth(1) # Set background depth to farthest

    sceneInit()

    glutMainLoop()


  main_gl()