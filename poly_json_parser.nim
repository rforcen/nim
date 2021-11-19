# poly json parser & browser
# poly's from https://github.com/tesseralis/
# json poly location: https://github.com/tesseralis/polyhedra-viewer/tree/canon/src/data/polyhedra

import std/json, streams, math, strformat, os, algorithm
import polyhedron


proc read_json_poly(file:string) : Polyhedron =
  var f = newFileStream(file)
  let jsonNode = parseJson f.readAll

  for f in ["name","vertices","faces","edges"]:
    case f:
    of "name":  result.name = jsonNode[f].getStr
    of "vertices":
      for v in jsonNode["vertices"].getElems:
        result.vertices.add [v.getElems[0].getFloat,v.getElems[1].getFloat,v.getElems[2].getFloat]
    of "edges":
      for e in jsonNode[f].getElems:
        result.edges.add [e.getElems[0].getInt,e.getElems[1].getInt]
    of "faces":
      for face in jsonNode[f].getElems:
        var fi:seq[int]
        for f in face: fi.add f.getInt
        result.faces.add fi
  f.close

# load all json poly set
proc load_json_path(path:string="/home/asd/Documents/polyhedron/json/"):seq[string]=
  for f in os.walkDirRec path:  result.add f
  result.sort
  
when isMainModule:
  import opengl/glut, opengl, opengl/glu
  import math, random

  const CompiledScene = 1
    
  var
    n_poly {.global.} = 0 
    polyhedrons {.global.} : seq[string] = load_json_path()
    poly {.global.} = read_json_poly(polyhedrons[n_poly])

    zoom {.global.} = -4.0
    anglex {.global.}= 0.0
    angley {.global.}= 0.0
    lastx  {.global.}= 0
    lasty  {.global.}= 0
    palette {.global.} = [(0, 95, 115, 1),(10, 147, 150, 1),(148, 210, 189, 1),(233, 216, 166, 1),(238, 155, 0, 1),(202, 103, 2, 1),(187, 62, 3, 1),(174, 32, 18, 1),(155, 34, 38, 1)]

  converter v4f(v:array[4,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
  converter v1f(v:array[1,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
  converter v3f(v:array[3,float]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
  converter v42gld(v:seq[float]):ptr GLfloat = cast[ptr GLfloat](v[0].unsafeAddr)
  converter v3gld(v:vec3):ptr GLdouble = cast[ptr GLdouble](v.unsafeAddr)
  converter itogf(i:int):GLfloat=i.GLfloat
  converter itoub(i:int):GLubyte=i.GLubyte

  proc normal(p:Polyhedron, face:seq[int]) : vec3 = normal( p.vertices[face[0]], p.vertices[face[1]], p.vertices[face[2]] )

  proc glutSolidCylinder*(radius, height:GLdouble, slices, stacks : GLint) {.dynlib: "libglut.so.3", importc.}
  
  proc cylinder(x,y:vec3, rad:float) =
    let
      v : vec3 = x - y
      axis = if hypot(v[0], v[1]) < 0.001: [1.0, 0, 0] else: v ** [0.0, 0, 1]
      height = v.hypot
      angle = -arctan2(hypot(v[0], v[1]), v[2]) * 180 / PI # in deg.

    glPushMatrix()

    glTranslatef(x[0], x[1], x[2])
    glRotated(angle, axis[0], axis[1], axis[2])

    glutSolidCylinder(rad, height, 10, 1)

    glPopMatrix()

  proc set_light_position

  proc draw_poly(p:Polyhedron)=
    # use alpha channel
    # glEnable(GL_BLEND)
    # glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    for face in p.faces:
      
      let (r,g,b,_) = palette[(face.len-3) %% palette.len]
      glColor4ub(r,g,b,250)

      let nrm = p.normal face

      glBegin(GL_POLYGON) # faces
      for f in face: 
        glNormal3dv(nrm)      
        glVertex3dv(p.vertices[f])
      glEnd()
    
      # glColor3ub(0,0,0) # raised lines
      # glBegin(GL_LINE_LOOP)
      # for f in face: 
      #   var c : vec3 = (p.vertices[f]) + (nrm * 0.001)
      #   glVertex3dv(c)
      # glEnd()

      glColor3f(0.5, 0.5, 0) # nice golden cylinders edges
      for e in p.edges: cylinder(p.vertices[e[0]], p.vertices[e[1]], rad=0.01)

      glPointSize(14) # points
      glColor3f(0.5, 0.5, 0.3)
      glBegin(GL_POINTS)
      for v in p.vertices:
        glVertex3dv(v)
      glEnd()


  proc create_list() {.cdecl.} =
    glNewList(CompiledScene, GL_COMPILE) # list 1 is scene
    draw_poly(poly)
    glEndList()
    glutSetWindowTitle fmt "polyhedron{n_poly} - {poly.name} V:{poly.vertices.len}, F:{poly.faces.len}, E:{poly.edges.len}"
    palette.shuffle

  proc draw_scene() {.cdecl.} =
    glPushMatrix()
    glTranslatef(0, 0, zoom)
    glRotatef(anglex, 1, 0, 0)
    glRotatef(-angley, 0, 1, 0)

    set_light_position()
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
    of ' ':
      n_poly = rand(polyhedrons.len)
      poly = read_json_poly(polyhedrons[n_poly])
    of '+':
      if n_poly<polyhedrons.high:
        n_poly.inc
        poly = read_json_poly(polyhedrons[n_poly])
    of '-':
      if n_poly>0:
        n_poly.dec
        poly = read_json_poly(polyhedrons[n_poly])

    of 'c' : 
      anglex = 0
      angley = 0

    else: discard

    create_list()

  proc set_light_position =
    const
      light0_position = [1f, 0.5, 1, 0]
      light1_position = [-1f, 0.5, -1, 0]
    glLightfv(GL_LIGHT0, GL_POSITION, light0_position.v4f)
    glLightfv(GL_LIGHT1, GL_POSITION, light1_position)

  proc scene_init =  # works nice for golden solid colors (requires normals)
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
    glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGBA or GLUT_DEPTH)
    glutInitWindowSize(1200, 1200)
    
    discard glutCreateWindow "polyhedron"

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

    create_list()
    glutMainLoop()

  main_gl()