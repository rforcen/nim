# waterman poly / convex hull
# gl display
# compile w/
# nim cpp -d:release -d:danger waterman.nim && ./waterman

import waterman_poly
import opengl/glut, opengl, opengl/glu, strformat, random

const CompiledScene = 1

when isMainModule:

    proc draw() =
        var
            anglex {.global.}= 0.0
            angley {.global.}= 0.0
            zoom {.global.} = -4.0

            faces {.global} : Faces
            vertices {.global.} ,colors {.global.} : Vertexes

            lastx  {.global.}= 0
            lasty  {.global.}= 0

            radius  {.global.} :float

        proc gen_colors():Vertexes {.cdecl.}
        proc gen_wat() {.cdecl.}

        

        proc gen_wat() {.cdecl.}=
          (faces, vertices) = waterman(radius)
          colors = gen_colors()

     
        proc gen_colors():Vertexes {.cdecl.}= 
          var colors=newSeq[Vertex](400)
          for face in faces:
            colors[face.len] = [rand(1.0), rand(1.0), rand(1.0)]
          colors

        proc toGLfloat(v: Vertex): array[3, GLfloat] = [v[0].GLfloat, v[1].GLfloat, v[2].GLfloat]

        proc draw_scene()=
            proc poly=
                for face in faces:
                    glBegin(GL_POLYGON) 

                    let color = colors[face.len]
                    glColor3f(color[0].GLfloat, color[1].GLfloat, color[2].GLfloat)
                    for ix in face:
                        let v = vertices[ix].toGLfloat
                        glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))

                    glEnd()

            proc lines=
                for face in faces:
                    glColor3f(0.0, 0.0, 0.0)
                    glBegin(GL_LINE_LOOP)
                    for ix in face:
                        let v = vertices[ix].toGLfloat
                        glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))
                    glEnd()
            
            poly()
            lines()

        proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
            if height != 0:
                glViewport(0, 0, width, height)
                glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
                glLoadIdentity() # Reset
                gluPerspective(45.0, width / height, 0.1, 100.0)

        proc mouseDrag(x,y:GLint) {.cdecl.} =
            let d = 2.0
            angley += (x-lastx).float / d
            anglex += (y-lasty).float / d  

            lastx=x
            lasty=y

        proc mouseWheel(button, dir, x,y:GLint) {.cdecl.} =
            case button:
                of 3: zoom-=0.1
                of 4: zoom+=0.1
                else: discard
            
        proc keyhook(key:GLbyte, x,y:GLint) {.cdecl.} =
            case key.char:
            of 'q', '\e': quit()
            of ' ' : # random waterman
              radius = rand(8000.0) + 4.0
              gen_wat()
              glNewList(CompiledScene, GL_COMPILE) # list 1 is scene
              glutSetWindowTitle (&("Waterman {radius.int}, faces:{faces.len}, vertices:{vertices.len}")).cstring
              draw_scene()
              glEndList()

            else: discard
            

        proc display() {.cdecl.} =
            glClear(GL_COLOR_BUFFER_BIT or
                    GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
            glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
            glLoadIdentity() # Reset the model-view matrix
            glTranslatef(0.0, 0.0, zoom) # zoom
            glColor3f(1.0, 1.0, 1.0)

            glRotatef(anglex, 1.0, 0.0, 0.0)
            glRotatef(-angley, 0.0, 1.0, 0.0)

            glCallList(CompiledScene)

            glutSwapBuffers() 
            glutPostRedisplay() # animate

        var argc: cint = 0
        glutInit(addr argc, nil)
        glutInitDisplayMode(GLUT_DOUBLE)
        glutInitWindowSize(1200, 1200)
        glutInitWindowPosition(500, 500)
        discard glutCreateWindow((&("Waterman {radius.int} faces:{faces.len}, vertices:{vertices.len}")).cstring)


        glutDisplayFunc(display)
        glutReshapeFunc(reshape)
        glutKeyboardFunc(keyhook)
        glutMouseFunc(mouseWheel)
        glutMotionFunc(mouseDrag)
        glutPassiveMotionFunc(mouseDrag)

        loadExtensions()

        randomize()        
        radius = 45#rand(800.0)+4.0
        gen_wat()

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


when isMainModule:
  draw()
  

