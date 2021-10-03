# ui_gl.nim
import opengl/glut, opengl, opengl/glu

const CompiledScene = 1

var
    anglex {.global.}= 0.0
    angley {.global.}= 0.0
    iters {.global.}= 0
    zoom {.global.} = -4.0
    lastx  {.global.}= 0
    lasty  {.global.}= 0

proc draw_scene()=
    glutWireTeapot(0.5f64)

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
    if height != 0:
        glViewport(0, 0, width, height)
        glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
        glLoadIdentity() # Reset
        gluPerspective(45.0, width / height, 0.1, 100.0)

proc mouseDrag(x,y:GLint) {.cdecl.} =
    let d = 2.0
    angley += (x-lastx).float32 / d
    anglex += (y-lasty).float32 / d  

    lastx=x
    lasty=y

proc mouseWheel(button, dir, x,y:GLint) {.cdecl.} =
    case button:
        of 3: zoom-=0.1
        of 4: zoom+=0.1
        else: discard
    
proc keyhook(key:GLbyte, x,y:GLint) {.cdecl.} =
  case key.char:
  of 'q': quit(1)
  else: quit(1)
    

proc display() {.cdecl.} =
    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
    glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
    glLoadIdentity() # Reset the model-view matrix
    glTranslatef(0.0, 0.0, zoom) # zoom
    glColor3f(1.0, 1.0, 1.0)

    glRotatef(anglex, 1.0, 0.0, 0.0)
    glRotatef(-angley, 0.0, 1.0, 0.0)

    inc iters

    glCallList(CompiledScene)

    glutSwapBuffers() 
    glutPostRedisplay() # animate

var argc: cint = 0
glutInit(addr argc, nil)
glutInitDisplayMode(GLUT_DOUBLE)
glutInitWindowSize(1200, 1200)
glutInitWindowPosition(500, 500)
discard glutCreateWindow("gl ui")


glutDisplayFunc(display)
glutReshapeFunc(reshape)
glutKeyboardFunc(keyhook)
glutMouseFunc(mouseWheel)
glutMotionFunc(mouseDrag)
glutPassiveMotionFunc(mouseDrag)

loadExtensions()

glNewList(CompiledScene, GL_COMPILE) # list 1 is scene
draw_scene()
glEndList()

glClearColor(0.0, 0.0, 0.0, 1.0) # Set background color to black and opaque
glClearDepth(1.0) # Set background depth to farthest
glEnable(GL_DEPTH_TEST) # Enable depth testing for z-culling
glDepthFunc(GL_LEQUAL) # Set the type of depth-test
glShadeModel(GL_SMOOTH) # Enable smooth shading
glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

glutMainLoop()
