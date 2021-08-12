# polyhedron
import sequtils, random, strformat, times
import opengl/glut, opengl, opengl/glu

import common, parser, vertex, transform

const CompiledScene = 1

when isMainModule:

    proc draw(p:Polyhedron) =
        var
            anglex {.global.}= 0.0
            angley {.global.}= 0.0
            gpoly {.global.}: Polyhedron
            iters {.global.}= 0
            zoom {.global.} = -4.0
            nice_poly {.global.}: string

        var 
            lastx  {.global.}= 0
            lasty  {.global.}= 0

        gpoly = p
        
        gpoly.set_centers
        gpoly.set_colors
        discard gpoly.normalize
     
        proc toGLfloat(v: Vertex): array[3, GLfloat] = [v[0].GLfloat, v[
                1].GLfloat, v[2].GLfloat]

        proc draw_scene()=
            proc poly=
                for (colors, face) in zip(gpoly.colors, gpoly.faces):
                    glBegin(GL_POLYGON) 

                    glColor3f(colors[0].GLfloat, colors[1].GLfloat, colors[2].GLfloat)
                    for ix in face:
                        let v = gpoly.vertex[ix].toGLfloat
                        glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))

                    glEnd()

            proc lines=
                for face in gpoly.faces:
                    glColor3f(0.0, 0.0, 0.0)
                    glBegin(GL_LINE_LOOP)
                    for ix in face:
                        let v = gpoly.vertex[ix].toGLfloat
                        glVertex3fv(cast[ptr GLfloat](v.unsafeAddr))
                    glEnd()

            proc centers =
                glColor3f(0.0, 0.0, 0.0)
                glPointSize(2.0)
                glBegin(GL_POINTS)
                for (center, normal) in zip(gpoly.centers, gpoly.normals):
                    let vc=(center+normal.unit/20.0).toGLfloat
                    glVertex3fv(cast[ptr GLfloat](vc.unsafeAddr))
                glEnd()
            
            poly()
            # centers()
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
            proc compile_poly=
                glNewList(CompiledScene, GL_COMPILE) # list 1 is scene
                draw_scene()
                glEndList()
                glutSetWindowTitle(fmt("{gpoly.name}, n.vertex:{gpoly.vertex.len}, n.faces:{gpoly.faces.len}"))

            proc gen_poly(tr:string)=
                let t0=now()
                gpoly = transform(tr)
                let lap=(now()-t0).inMilliseconds()

                echo fmt("{gpoly.name}: {gpoly.faces.len} faces, {gpoly.vertex.len} vertex, lap:{lap}ms")

                gpoly.set_centers
                gpoly.set_colors
                discard gpoly.normalize
                compile_poly()
                


            case key.char:
            of 'q', '\e': quit()
            of '+' : zoom+=0.4
            of '-' : zoom-=0.4
            of 'r' : # random transf
                let tr=rand_transform()
                gen_poly(tr)
                echo tr, "->", gpoly.name
            of ' ' : # random preset
                gen_poly(rand_preset())
            of 'c' : 
                gpoly.set_colors
                compile_poly()
            of 'n': nice_poly &= gpoly.name & ","
            of 'p': echo nice_poly

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

            inc iters

            glCallList(CompiledScene)

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

import os
proc main=
    randomize()

    let t0=now()
    var tr = if paramCount()==1: paramStr(1) else: rand_preset()
    var p = transform(tr) 
    # p.write_wrl
    let lap=(now()-t0).inMilliseconds()
    echo fmt("{p.name}: {p.faces.len} faces, {p.vertex.len} vertex, lap:{lap}ms")
    draw(p)

main()
