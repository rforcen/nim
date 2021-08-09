# polyhedron
import sequtils, random, strformat, times
import opengl/glut, opengl, opengl/glu

import common, parser

when isMainModule:

    proc draw(p:Polyhedron) =
        var
            angle {.global.}= 0.0
            gpoly {.global.}: Polyhedron
            iters {.global.}= 0

        gpoly = p
        
        gpoly.set_centers
        gpoly.set_colors
        discard gpoly.normalize
     
        proc toGLfloat(v: Vertex): array[3, GLfloat] = [v[0].GLfloat, v[
                1].GLfloat, v[2].GLfloat]

        proc draw_scene()=
            # draw poly
            for (colors, faces) in zip(gpoly.colors, gpoly.faces):
                glBegin(GL_POLYGON) 

                glColor3f(colors[0].GLfloat, colors[1].GLfloat, colors[2].GLfloat)
                for ix in faces:
                    let v = gpoly.vertex[ix].toGLfloat
                    glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))

                glEnd()

                # poly line
                glColor3f(0.0, 0.0, 0.0)
                glBegin(GL_LINE_LOOP)
                for ix in faces:
                    let v = gpoly.vertex[ix].toGLfloat
                    glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))
                glEnd()

            # draw centers
            #[
            glColor3f(0.0, 0.0, 0.0)
            glPointSize(2.0)
            glBegin(GL_POINTS)
            for (center, normal) in zip(gpoly.centers, gpoly.normals):
                let vc=(center+normal.unit/20.0).toGLfloat
                glVertex3fv(cast[ptr GLfloat](vc.unsafeAddr))
            glEnd()
            ]#

        proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
            if height != 0:
                glViewport(0, 0, width, height)
                glMatrixMode(GL_PROJECTION) # To operate on the Projection matrix
                glLoadIdentity() # Reset
                gluPerspective(45.0, width / height, 0.1, 100.0)

        proc keyhook(key:GLbyte, x,y:GLint) {.cdecl.} =
            if key.char in "q\e": quit()

        proc display() {.cdecl.} =
            glClear(GL_COLOR_BUFFER_BIT or
                    GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
            glMatrixMode(GL_MODELVIEW) # To operate on model-view matrix
            glLoadIdentity() # Reset the model-view matrix
            glTranslatef(0.0, 0.0, -3.0) # zoom
            glColor3f(1.0, 1.0, 1.0)
            glRotatef(angle, 1.0, 1.0, 1.0)

            angle+=0.4

            inc iters

            #draw_scene()
            glCallList(1)

            glutSwapBuffers() 
            glutPostRedisplay() # animate

        var argc: cint = 0
        glutInit(addr argc, nil)
        glutInitDisplayMode(GLUT_DOUBLE)
        glutInitWindowSize(1200, 1200)
        glutInitWindowPosition(500, 500)
        discard glutCreateWindow(fmt("{gpoly.name}, n.vertex:{gpoly.vertex.len}, n.faces:{gpoly.faces.len}"))


        glutDisplayFunc(display)
        glutReshapeFunc(reshape)
        glutKeyboardFunc(keyhook)

        loadExtensions()

        glNewList(1, GL_COMPILE)
        draw_scene()
        glEndList()

        glClearColor(0.0, 0.0, 0.0, 1.0) # Set background color to black and opaque
        glClearDepth(1.0) # Set background depth to farthest
        glEnable(GL_DEPTH_TEST) # Enable depth testing for z-culling
        glDepthFunc(GL_LEQUAL) # Set the type of depth-test
        glShadeModel(GL_SMOOTH) # Enable smooth shading
        glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

        glutMainLoop()

    randomize()
    let t0=now()
    var p = transform("HaaqqkO") 
    # p.write_wrl
    let lap=(now()-t0).inMilliseconds()
    echo fmt("lap:{lap}ms, {p.name}: {p.faces.len} faces, {p.vertex.len} vertex")
    draw(p)

