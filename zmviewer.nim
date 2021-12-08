# zm viewer

import zm, os, strformat
import opengl/glut, opengl, opengl/glu

const CompiledScene = 1
  
var
  mesh {.global.} : Mesh
  zoom {.global.} = -4.0
  anglex {.global.}= 0.0
  angley {.global.}= 0.0
  lastx  {.global.}= 0
  lasty  {.global.}= 0

converter v4f(v:array[4,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter v1f(v:array[1,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter v3f(v:array[3,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter itogf(i:int):GLfloat=i.GLfloat
converter itoub(i:int):GLubyte=i.GLubyte

proc set_light_position

proc draw_mesh=

  for trig in mesh.trigs:

    glBegin(GL_TRIANGLES) # trigs

    for i in trig:
      let sh = mesh.shape[i]

      glColor3fv(sh.color)
      glNormal3fv(sh.norm)      
      glVertex3fv(sh.pos)
    
    glEnd()

proc create_list() {.cdecl.} =
  glNewList(CompiledScene, GL_COMPILE) # list 1 is scene

  draw_mesh()

  glEndList()
  glutSetWindowTitle (&"zm viewer #vertices:{mesh.shape.len}, #triangles:{mesh.trigs.len}").cstring

proc draw_scene() {.cdecl.} =
  glPushMatrix()
  glTranslatef(0, 0, zoom)
  glRotatef(anglex, 1, 0, 0)
  glRotatef(-angley, 0, 1, 0)

  # set_light_position()
  glCallList(CompiledScene)
  glPopMatrix()

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  if height != 0:
    glViewport(0, 0, width, height)
    glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
    glLoadIdentity() # Reset
    gluPerspective(45.0, width / height, 0.1, 100.0)

proc keyhook(key: GLbyte, x, y: GLint) {.cdecl.} =
  case key.char:
  of 'q', '\e': quit(1)

  of 'c' : 
    anglex = 0
    angley = 0

  else: discard

  create_list()
  glutPostRedisplay() # animate


proc set_light_position =
  const
    light0_position = [1f, 0.5, 1, 0]
    light1_position = [-1f, 0.5, -1, 0]
  glLightfv(GL_LIGHT0, GL_POSITION, light0_position.v4f)
  glLightfv(GL_LIGHT1, GL_POSITION, light1_position)

proc scene_init =  
  let
    lmodel_ambient = [0f, 0, 0, 0]
    lmodel_twoside = [0f] # [GL_FALSE]
    light0_ambient = [0.5f, 0.5, 0.5, 0.4f]
    light0_diffuse = [0.3f, 0.3, 0.3, 0.0f]
    light0_specular = [0.2f, 0.2, 0.2, 0.2]
    bevel_mat_ambient = [0.1f, 0.1, 0, 1]
    bevel_mat_shininess = [10f]
    bevel_mat_specular = [0.4f, 0.4, 0.4, 0]
    bevel_mat_diffuse = [1f, 0, 0, 0]

  glClearColor(0,0,0, 0)

  glLightfv(GL_LIGHT0, GL_AMBIENT, light0_ambient)
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light0_diffuse)
  glLightfv(GL_LIGHT0, GL_SPECULAR, light0_specular)
  glEnable(GL_LIGHT0)

  glLightfv(GL_LIGHT1, GL_AMBIENT, light0_ambient)
  glLightfv(GL_LIGHT1, GL_DIFFUSE, light0_diffuse)
  glLightfv(GL_LIGHT1, GL_SPECULAR, light0_specular)
  glEnable(GL_LIGHT1)

  set_light_position()

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
  glEnable(GL_DEPTH_TEST)

proc mouseDrag(x,y:GLint) {.cdecl.} =
  let d = 2.0
  angley += (x-lastx).float / d
  anglex += (y-lasty).float / d  

  lastx=x
  lasty=y
  glutPostRedisplay() # animate


proc mouseWheel(button, dir, x,y:GLint) {.cdecl.} =
  case button:
      of 3: zoom+=0.1
      of 4: zoom-=0.1
      else: discard
  glutPostRedisplay() # animate
    

proc display() {.cdecl.} =
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
  glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
  glLoadIdentity() # Reset the model-view matrix

  draw_scene()

  glutSwapBuffers()

proc main_gl =
  glutInit()    
  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGBA or GLUT_DEPTH)
  glutInitWindowSize(1024, 768)
  
  discard glutCreateWindow "zm viewer"

  glutDisplayFunc(display)
  glutReshapeFunc(reshape)
  glutKeyboardFunc(keyhook)
  glutMouseFunc(mouseWheel)
  glutMotionFunc(mouseDrag)

  loadExtensions()

  glClearColor(0,0,0, 1) # Set background color to black and opaque
  glClearDepth(1) # Set background depth to farthest

  scene_init()
  glEnable( GL_POINT_SMOOTH )

  let file = if commandLineParams().len!=0: commandLineParams()[0] else: "sh.zm"

  mesh = ZMread(file)
  mesh.normalize

  # echo &"mesh {file}: #vertices {mesh.shape.len} #trigs {mesh.trigs.len}"
  # echo &"compression ratio:{100.0 * getFileSize(file).float / mesh.nbytes.float:.3}%"

  create_list()
  glutMainLoop()

main_gl()