#[
   reading static resource:
    const imageIcon = "icon.png".staticRead

    let image = imageIcon.decodeImage
]#

##################


# ui_gl
import opengl/glut, opengl, opengl/glu
import sequtils
import pixie
import os
 
var
  mandalas : seq[GLuint]
  zoom {.global.} = -4.0
  anglex {.global.}= 0.0
  angley {.global.}= 0.0
  lastx  {.global.}= 0
  lasty  {.global.}= 0

converter v42gld(v:array[4,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter v42gld(v:array[3,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter v42gld(v:array[2,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter v42gld(v:array[1,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
converter itogf(i:int):GLfloat=i.GLfloat

proc polygon(n : int, scale : float = 1) : seq[array[2,float32]] = 
  for i in 0..<n:
    result.add [(scale * 0.5f * (1+sin(PI*(2*i/n-1)))).float32, (scale * 0.5 * (1+cos(PI*(2*i/n-1)))).float32]

proc set_texture(t:GLuint) = glBindTexture(GL_TEXTURE_2D, t)
proc enable_textures = glEnable(GL_TEXTURE_2D)

proc load_texture(buff : pointer, w,h:int) : GLuint = 
  glGenTextures(1, result.addr) # generate 1 texture in text_id
  glBindTexture(GL_TEXTURE_2D, result)
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE.Glint)  # Texture blends with object background
  
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, w.GLsizei, h.GLsizei, 0, GL_RGBA, GL_UNSIGNED_BYTE, buff)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

proc load_texture(file_name : string) : GLuint = 
  let img = readImage(file_name)
  load_texture(img.data[0].addr, img.width, img.height)

proc sceneInit() =  
  const
    lmodel_ambient = [0'f32, 0, 0, 0]
    lmodel_twoside = [0'f32] # [GL_FALSE]
    light0_ambient = [0.3'f32, 0.3, 0.3, 0.4f]
    light0_diffuse = [1'f32, 1.0, 1.0, 0.0f]
    light0_position = [1'f32, 0.5, 1, 0]
    light1_position = [-1'f32, 0.5, -1, 0]
    light0_specular = [0.2'f32, 0.2, 0.2, 0.2]
    bevel_mat_ambient = [0.1'f32, 0.1, 0, 1]
    bevel_mat_shininess = [10'f32]
    bevel_mat_specular = [1'f32, 1, 1, 0]
    bevel_mat_diffuse = [1'f32, 0, 0, 0]

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
  glEnable(GL_DEPTH_TEST)

  # glEnable(GL_CULL_FACE) # show only front face 
  # glCullFace(GL_FRONT)


proc cube(l:float32 = 0.7, faces:openArray[int] = [])=
  let
    textures=[[0,0],[1,0],[1,1],[0,1], [1,0],[1,1],[0,1],[0,0], [0,1],[0,0],[1,0],[1,1], [1,1],[0,1],[0,0],[1,0], [1,0],[1,1],[0,1],[0,0], [0,0],[1,0],[1,1],[0,1]]
    coords=[[-l,-l,l],[l,-l,l],[l,l,l],[-l,l,l],[-l,-l,-l],[-l,l,-l],[l,l,-l],[l,-l,-l],[-l,l,-l],[-l,l,l],[l,l,l],[l,l,-l],[-l,-l,-l],
        [l,-l,-l],[l,-l,l],[-l,-l,l],[l,-l,-l],[l,l,-l],[l,l,l],[l,-l,l],[-l,-l,-l],[-l,-l,l],[-l,l,l],[-l,l,-l]]

  if faces.len==0:
    glBegin(GL_QUADS)
    for (t,c) in zip(textures, coords):
      glTexCoord2f(t[0], t[1])
      glVertex3f(c[0], c[1], c[2])
    glEnd()
  else:
    for face in faces:
      glBegin(GL_QUADS)
      if face in 0..5:
        for i in 0..3:
          let ix=face*4+i
          glTexCoord2f(textures[ix][0], textures[ix][1])
          glVertex3f(coords[ix][0], coords[ix][1], coords[ix][2])
      glEnd()

proc dodecahedron(fcs : openArray[int] = []) = 
  let
    coords = [[0.0f, 0.0, 1.07047], [0.713644f, 0.0, 0.797878], [-0.356822f,
              0.618, 0.797878], [-0.356822f, -0.618, 0.797878], [0.797878f,
              0.618034, 0.356822], [0.797878f, -0.618, 0.356822], [-0.934172f,
              0.381966, 0.356822], [0.136294f, 1.0, 0.356822], [0.136294f, -1.0,
              0.356822], [-0.934172f, -0.381966, 0.356822], [0.934172f,
              0.381966, -0.356822], [0.934172f, -0.381966, -0.356822], [
              -0.797878f, 0.618, -0.356822], [-0.136294f, 1.0, -0.356822], [
              -0.136294f, -1.0, -0.356822], [-0.797878f, -0.618034, -0.356822],
              [0.356822f, 0.618, -0.797878], [0.356822f, -0.618, -0.797878], [
              -0.713644f, 0, -0.797878], [0.0f, 0.0, -1.07047]]
    faces = [[0, 1, 4, 7, 2], [0, 2, 6, 9, 3], [0, 3, 8, 5, 1], [1, 5, 11, 10, 4], 
             [2, 7, 13, 12, 6], [3, 9, 15, 14, 8], [4, 10, 16, 13, 7], [5, 8, 14, 17, 11], 
             [6, 12, 18, 15, 9], [10, 11, 17, 19, 16], [12, 13, 16, 19, 18], [14, 15, 18, 19, 17]]
    poly = polygon(5) 

  proc draw_face(face:openArray[int])=
    glBegin(GL_POLYGON)
    for i, ix in face.pairs:
      glTexCoord2fv(poly[i])
      glVertex3fv(coords[ix])
    glEnd()

  if fcs.len == 0:
    for face in faces:  draw_face(face)
  else:
    for face in fcs:    draw_face(faces[face])

proc panel(l : float = 1) = # texturized panel
  glBegin(GL_QUADS)
  glTexCoord2d(0,0); glVertex2d(-l, -l)
  glTexCoord2d(0,1); glVertex2d(-l, l)
  glTexCoord2d(1,1); glVertex2d(l, l)
  glTexCoord2d(1,0); glVertex2d(l, -l)
  glEnd()

proc scenario=
  glPushMatrix()
  glLoadIdentity()
  glTranslatef(0, 0, zoom)
  glRotatef(190, 1,0,0)
  glRotatef(-45, 0,1,0)
  cube(l=0.8, faces=[0,2,4])
  glPopMatrix()

proc sphere(r:float)=
  var quad : GLUquadric = gluNewQuadric()
  gluQuadricTexture(quad.addr, GLU_TRUE)
  gluSphere(quad.addr, r, 50,50)
  gluDeleteQuadric(quad)

proc mandala_cube=
  for f in 0..5:
    set_texture mandalas[f]
    cube(0.4, [f])

proc mandala_dodeca=
  for f in 0..11:
    set_texture mandalas[f %% mandalas.len]
    dodecahedron([f])

proc scale(s:float)=glScalef(s,s,s)

proc draw_scene() {.cdecl.} =

  glTranslatef(0, 0, zoom)
  glRotatef(anglex, 1, 0, 0)
  glRotatef(-angley, 0, 1, 0)

  glutSetWindowTitle("gl textures | " & $anglex & ", " & $angley)
  glEnable(GL_TEXTURE_2D)   

  # panel(0.5)
  set_texture(mandalas[0])
  scenario()

  scale(0.5)
  mandala_dodeca()
  


proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  if height != 0:
    glViewport(0, 0, width, height)
    glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
    glLoadIdentity() # Reset
    gluPerspective(45.0, width / height, 0.1, 100.0)

proc keyhook(key: GLbyte, x, y: GLint) {.cdecl.} =
  case key.char:
  of 'q', '\e': quit(1)
  of ' ' : 
    anglex = 0
    angley = 0

  else: discard

  glutSetWindowTitle "gl textures"

proc mouseDrag(x,y:GLint) {.cdecl.} =
  let d = 2.0
  angley += (x-lastx).float / d
  anglex += (y-lasty).float / d  

  lastx=x
  lasty=y

proc mouseWheel(button, dir, x,y:GLint) {.cdecl.} =
  case button:
      of 3: zoom+=0.1
      of 4: zoom-=0.1
      else: discard

proc display() {.cdecl.} =
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
  glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
  glLoadIdentity() # Reset the model-view matrix

  draw_scene()

  glutSwapBuffers()
  glutPostRedisplay() # animate

proc main_gl =

  glutInit()
  
  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGB or GLUT_DEPTH)

  glutInitWindowSize(1200, 1200)
  
  discard glutCreateWindow "gl textures"

  glutDisplayFunc(display)
  glutReshapeFunc(reshape)
  glutKeyboardFunc(keyhook)
  glutMouseFunc(mouseWheel)
  glutMotionFunc(mouseDrag)

  loadExtensions()

  glClearColor(0,0,0, 1) # Set background color to black and opaque
  glClearDepth(1) # Set background depth to farthest

  sceneInit()

  # load resource
  for file in walkDirRec "/home/asd/Documents/qt/VSlibQt/rsc/backgrounds/Mandalas/":
    mandalas.add file.load_texture

  enable_textures()

  glutMainLoop()

main_gl()
