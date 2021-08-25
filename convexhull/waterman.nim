# waterman poly / convex hull ui

import convexhull, tables
import opengl/glut, opengl, opengl/glu, strformat, random

const CompiledScene = 1
type Vertexes = seq[Point3d]
type Faces = seq[seq[int]]

when isMainModule:

    proc rand_radius():float = 40 + rand(6000.float)

    proc draw() =
        var
            anglex {.global.}= 0.0
            angley {.global.}= 0.0
            zoom {.global.} = -4.0

            faces {.global} : Faces
            vertices {.global.} : Vertexes

            lastx  {.global.}= 0
            lasty  {.global.}= 0

            radius  {.global.} :float


        proc title = glutSetWindowTitle(fmt("Waterman {radius.int}, faces:{faces.len}, vertices:{vertices.len}"))

        proc gen_wat() {.cdecl.}=
            faces = @[]
            vertices = @[]
            (faces, vertices) = convexHull(waterman_poly(radius))
            title()
    
        proc draw_scene()
        proc gen_list()=
            glNewList(CompiledScene, GL_COMPILE) # list 1 is scene
            title()
            draw_scene()
            glEndList()


        proc draw_scene()=
            proc poly=
                var colors : Table[int,array[3,float]]

                for face in faces:
                    glBegin(GL_POLYGON) 
                    
                    glColor3dv(colors.mgetOrPut(face.len, [rand(1.0),rand(1.0),rand(1.0)])[0].unsafeAddr) 
                    for ix in face:
                        glVertex3dv(cast[ptr GLdouble](vertices[ix].unsafeAddr))

                    glEnd()

            proc lines=
                for face in faces:
                    glColor3f(0.0, 0.0, 0.0)
                    glBegin(GL_LINE_LOOP)
                    for ix in face:
                        glVertex3dv(cast[ptr GLdouble](vertices[ix].unsafeAddr))
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
                of 3: zoom+=0.1
                of 4: zoom-=0.1
                else: discard
            
        proc keyhook(key:GLbyte, x,y:GLint) {.cdecl.} =
            case key.char:
            of 'q', '\e': quit()
            of 'c' : # recolor
              gen_list()
            of ' ' : # random waterman
              radius = rand_radius()
              gen_wat()
              gen_list()
            of 'z' : 
                (anglex, angley, lastx, lasty)=(0.0,0.0,0,0)

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
        discard glutCreateWindow(fmt("Waterman {radius.int} faces:{faces.len}, vertices:{vertices.len}"))

        glutDisplayFunc(display)
        glutReshapeFunc(reshape)
        glutKeyboardFunc(keyhook)
        glutMouseFunc(mouseWheel)
        glutMotionFunc(mouseDrag)
        # glutPassiveMotionFunc(mouseDrag)

        loadExtensions()

        randomize()        
        radius = rand_radius()
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

    import times, strformat
    proc test_qh()=
        for radius in countdown(29000, 20000, 500):
            let t0 = now()
            let (faces, vertices) = convexHull( waterman_poly(radius.float) )
            let lap=(now()-t0).inMilliseconds
            echo fmt "rad={radius} lap:{lap}ms, faces:{faces.len}, vertices:{vertices.len}"

        GC_fullCollect()
        echo "ctrl-d to end"
        discard readAll(stdin)

    proc bench_qh()=
        let 
            t0 = now()
            radius=6000
        let (faces, vertices) = convexHull( waterman_poly(radius.float) )
        let lap=(now()-t0).inMilliseconds
        echo fmt "rad={radius} lap:{lap}ms, faces:{faces.len}, vertices:{vertices.len}"

    draw()
    # bench_qh()