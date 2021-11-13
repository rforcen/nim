# algebraic surfaces

import math

type 
  vec3 = object
    x,y,z:float

# yet another lin algebra oper's & func's 
proc `*`(v:vec3, f:float) : vec3 {.inline.}= vec3(x:v.x*f, y:v.y*f, z:v.z*f)
proc `/`(v:vec3, f:float) : vec3 {.inline.}= vec3(x:v.x/f, y:v.y/f, z:v.z/f)
proc `/=`(v:var vec3, f:float){.inline.} = v.x/=f; v.y/=f;  v.z/=f
proc `-`(a:vec3, b:float):vec3 {.inline.}= vec3(x:a.x-b, y:a.y-b, z:a.z-b)
proc `-`(a,b:vec3):vec3 {.inline.}= vec3(x:b.x-a.x, y:b.y-a.y, z:b.z-a.z)
proc hypot(v:vec3):float {.inline.}= (v.x*v.x + v.y*v.y + v.z*v.z).sqrt
proc `**`(a,b:vec3):vec3 {.inline.} =vec3(x:a.y*b.z-a.z*b.y, y:a.z*b.x-a.x*b.z, z:a.x*b.y-a.y*b.x) # cross prod
proc normalize(v:vec3):vec3 {.inline.}=v/v.hypot 
proc normal(v0, v1, v2: vec3): vec3 =
    let n = (v2 - v0) ** (v1 - v0)
    result = if n == vec3(x:0.0, y:0.0, z:0.0): n else: n.normalize()

proc sqr(x:float):float{.inline.}=x*x

# AS funcs

proc Cap(u,v:float) : vec3 = 
  vec3( x : 0.5 * cos(u) * sin(2 * v),
        y : 0.5 * sin(u) * sin(2 * v),
        z : 0.5 * (sqr(cos(v)) - sqr(cos(u)) * sqr(sin(v))) )

proc Boy(u,v:float) : vec3 = 
  let
    dv = (2 - sqrt(2.0) * sin(3 * u) * sin(2 * v))
    d1 = (cos(u) * sin(2 * v))
    d2 = sqrt(2.0) * sqr(cos(v))
  vec3( x : (d2 * cos(2 * u) + d1) / dv,
        y : (d2 * sin(2 * u) + d1) / dv,
        z : (3 * sqr(cos(v))) / (2 - sqrt(2.0) * sin(3 * u) * sin(2 * v))  )

proc Roman(r,t:float) : vec3 = 
  let
    r2 = r * r
    rq = sqrt(1 - r2)
    st = sin(t)
    ct = cos(t)

  vec3( x : r2 * st * ct,
        y : r * st * rq,
        z : r * ct * rq  )

proc SeaShell(u,v:float) : vec3 =
  let
    N = 5.6 # number of turns
    H = 3.5 # height
    P = 2 # power
    L = 4 # Controls spike length
    K = 9

  proc W(u:float):float = (u / (2*PI)) ^ P

  vec3(
    x : W(u) * cos(N * u) * (1 + cos(v)),
    y : W(u) * sin(N * u) * (1 + cos(v)),
    z : W(u) * (sin(v) + (sin(v / 2) ^ K) * L.float) + H * ((u / (2 * PI)) ^ (P + 1))  )

proc TudorRose(u,v:float) : vec3 =
  proc R(u,v:float):float=cos(v) * cos(v) * max(abs(sin(4 * u)), 0.9 - 0.2 * abs(cos(8 * u)))
  vec3( x : R(u, v) * cos(u) * cos(v),
        y : R(u, v) * sin(u) * cos(v),
        z : R(u, v) * sin(v) * 0.5 )

proc Breather(u,v:float) : vec3 = 
  let
    aa = 0.45 # Values from 0.4 to 0.6 produce sensible results
    w1 = 1 - aa * aa
    w = sqrt(w1)

  proc d(u,v:float):float = aa * (((w * cosh(aa * u)) ^ 2) + ((aa * sin(w * v)) ^ 2))

  vec3( x : -u + (2 * w1 * cosh(aa * u) * sinh(aa * u) / d(u, v)),
        y : 2 * w * cosh(aa * u) * (-(w * cos(v) * cos(w * v)) - (sin(v) * sin(w * v))) / d(u, v),
        z : 2 * w * cosh(aa * u) * (-(w * sin(v) * cos(w * v)) + (cos(v) * sin(w * v))) / d(u, v) )

proc Klein(u,v:float) : vec3 = 
  let 
    t = 4.5
    tmp = (4 + 2 * cos(u) * cos(t * v) - sin(2 * u) * sin(t * v))

  vec3( x : sin(v) * tmp,
        y : cos(v) * tmp,
        z : 2 * cos(u) * sin(t * v) + sin(2 * u) * cos(t * v) )

proc Klein0(u,v:float) : vec3 =
  vec3( x : if 0 <= u and u < PI:  6 * cos(u) * (1 + sin(u)) + 4 * (1 - 0.5f * cos(u)) * cos(u) * cos(v) 
            else:                  6 * cos(u) * (1 + sin(u)) + 4 * (1 - 0.5f * cos(u)) * cos(v + PI),
        y : if 0 <= u and u < PI:  16 * sin(u) + 4 * (1 - 0.5f * cos(u)) * sin(u) * cos(v) 
              else: 16 * sin(u),
        z : 4 * (1 - 0.5f * cos(u)) * sin(v) )

proc Bour(u,v:float) : vec3 =
  vec3( x : u * cos(v) - 0.5 * u * u * cos(2 * v),
        y : -u * sin(v) - 0.5 * u * u * sin(2 * v),
        z : 4 / 3 * pow(u, 1.5) * cos(1.5 * v) )

proc Dini(u,v:float) : vec3 =
  var psi = 0.3 # aa
  if psi < 0.001: psi = 0.001
  if psi > 0.999: psi = 0.999
  psi = psi * PI
  let
    sinpsi = sin(psi)
    cospsi = cos(psi)
    g = (u - cospsi * v) / sinpsi
    s = exp(g)
    r = (2 * sinpsi) / (s + 1 / s)
    t = r * (s - 1 / s) * 0.5f

  vec3( x : u - t,
        y : r * cos(v),
        z : r * sin(v) )

proc Enneper(u,v:float) : vec3 =
  vec3( x : u - u * u * u / 3 + u * v * v,
        y : v - v * v * v / 3 + v * u * u,
        z : u * u - v * v )

proc Scherk(u,v:float) : vec3 =

  let
    aa = 0.1
    vv = v + 0.1

  vec3( x : u,
        y : v,
        z : (ln(abs(cos(aa * vv) / cos(aa * u)))) / aa )

proc CanonicalSpiral(u,v:float) : vec3 =
  vec3( x : u * v * sin(15 * v),
        y : v,
        z : u * v * cos(15 * v) )

proc BohemianDome(u,v:float) : vec3 =
  let 
    A = 0.5
    B = 1.5
    C = 1.0

  vec3( x : A * cos(u),
        y : B * cos(v) + A * sin(u),
        z : C * sin(v) )

proc AstroidalEllipse(u,v:float):vec3=
  let 
    A = 1.0
    B = 1.0
    C = 1.0
  vec3( x : pow(A * cos(u) * cos(v), 3),
        y : pow(B * sin(u) * cos(v), 3),
        z : pow(C * sin(v), 3) )

proc Apple(u,v:float):vec3=
  let
    R1 = 4.0
    R2 = 3.8

  vec3( x : cos(u) * (R1 + R2 * cos(v)) + pow((v / PI), 100),
        y : sin(u) * (R1 + R2 * cos(v)) + 0.25 * cos(5 * u),
        z : -2.3 * ln(1 - v * 0.3157) + 6 * sin(v) + 2 * cos(v) )

proc Ammonite(u,v:float):vec3=
  proc W(u:float):float = pow(u / (2*PI), 2.2)
  let
    N = 5.6 # number of turns
    F = 120.0 # wave frequency
    A = 0.2 # wave amplitude
    
  vec3( x : W(u) * cos(N * u) * (2 + sin(v + cos(F * u) * A)),
        y : W(u) * sin(N * u) * (2 + sin(v + cos(F * u) * A)),
        z : W(u) * cos(v) )

proc PluckerConoid(u,v:float):vec3=
  vec3( x : u * v,
        y : u * sqrt(1 - sqr(v)),
        z : 1 - sqr(v) )

proc Cayley(u,v:float):vec3=
  vec3( x : u * sin(v) - u * cos(v),
        y : sqr(u) * sin(v) * cos(v),
        z : u ^ 3 * sqr(sin(v)) * cos(v) )

proc UpDownShell(u,v:float):vec3=
  vec3( x : u * sin(u) * cos(v),
        y : u * cos(u) * cos(v),
        z : u * sin(v) )

proc ButterFly(u, v : float) : vec3 =
  let t1 = (exp(cos(u)) - 2 * cos(4 * u) + (sin(u / 12) ^ 5)) * sin(v)
  vec3( x : sin(u) * t1,
        y : cos(u) * t1,
        z : sin(v) )

proc Rose(u, v : float) : vec3 =
  const 
    a = 1.0
    n = 7.0

  vec3( x:a * sin(n * u) * cos(u) * sin(v), 
        y:a * sin(n * u) * sin(u) * sin(v), 
        z:cos(v) / (n * 3) ) 

proc Kuen(u , v :float) : vec3 =
  vec3( x : 2 * cosh(v) * (cos(u) + u * sin(u)) / (cosh(v) * cosh(v) + u * u),
        y : 2 * cosh(v) * (-u * cos(u) + sin(u)) / (cosh(v) * cosh(v) + u * u),
        z : v - (2 * sinh(v) * cosh(v)) / (cosh(v) * cosh(v) + u * u)  )


proc Tanaka(s,t:float, n:int) : vec3 =
  const tanaka_params = [[0.0, 4, 3, 4, 5, 7, 4], [0.0, 4, 3, 0, 5, 7, 4], [0.0, 3, 4, 8, 5, 5, 2], [14.0, 3, 1, 8, 5, 5, 2]]
  var a, b1, b2, c, d, w, h:float
    #[  a  center hole size of a torus
        b1 number of cross
        b2 number of cross
        c  distance from the center of rotation
        d  number of torus
        w  gap width
        h  height ]#

  proc set_param(n : int) =
    var np=n %% tanaka_params.len
    a = tanaka_params[np][0]
    b1 = tanaka_params[np][1]
    b2 = tanaka_params[np][2]
    c = tanaka_params[np][3]
    d = tanaka_params[np][4]
    w = tanaka_params[np][5]
    h = tanaka_params[np][6]
    
  proc f(v:float):float = sin(2*sin(sin(sin(v))))

  set_param(n)
  vec3( x : (a - cos(t) + w * sin(b1 * s)) * cos(b2 * s),
        y : (a - cos(t) + w * sin(b1 * s)) * f(b2 * s),
        z : h * (w * sin(b1 * s) + f(t)) + c )

proc Tanaka0(u,v:float):vec3 = Tanaka(u,v,0)
proc Tanaka1(u,v:float):vec3 = Tanaka(u,v,1)
proc Tanaka2(u,v:float):vec3 = Tanaka(u,v,2)
proc Tanaka3(u,v:float):vec3 = Tanaka(u,v,3)

const
  as_names = ["cap","boy", "roman", "sea shell", "tudor rose", "breather",
            "klein bottle", "klein bottle 0", "bour", "dini", "enneper",
            "scherk", "conical spiral", "bohemian dome", "astrodial ellipse",
            "apple", "ammonite", "plucker comoid", "cayley", "up down shell",
            "butterfly", "rose", "kuen", 
            "tanaka-0", "tanaka-1", "tanaka-2", "tanaka-3"]
            
  as_ranges=[[(0.0, PI), (0.0, PI)],
            [(0.0, PI), (0.0, PI)],
            [(0.0, 1.0), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI), (0.0, PI)],
            [(-20.0, 20.0), (20.0, 80.0)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(-1.0, 1.0), (-1.0, 1.0)],
            [(1.0, 30.0), (1.0, 30.0)],
            [(0.0, 1.0), (-1.0, 1.0)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (-PI, PI)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(-2.0, 2.0), (-1.0, 1.0)],
            [(0.0, 3.0), (0.0, PI*2)],
            [(-10.0, 10.0), (-10.0, 10.0)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(-4.0, 4.0), (-3.75, +3.75)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)],
            [(0.0, PI*2), (0.0, PI*2)]
            ]

  as_funcs = [ Cap, Boy, Roman, SeaShell, TudorRose, Breather, 
               Klein, Klein0, Bour, Dini, Enneper, 
               Scherk, CanonicalSpiral, BohemianDome, AstroidalEllipse,
               Apple, Ammonite, PluckerConoid, Cayley, UpDownShell, 
               ButterFly, Rose, Kuen,
               Tanaka0, Tanaka1, Tanaka2, Tanaka3 ]

proc scale(v:seq[vec3]):seq[vec3]=
  var
    max=v[0].x
    min=max

  for i in countup(0, v.high, 5): # skip normal
    for j in 0..<4:
      let vv = v[i+j]
      max = max(max, max(vv.x,max(vv.y, vv.z)))
      min = min(min, min(vv.x,min(vv.y, vv.z)))

  result=v

  var dif = (max-min).abs
  if dif!=0:
    for i in countup(0, v.high, 5): # skip normal
      for j in 0..<4:
        result[i+j] /= dif

# eval parametric func (quad, normal)

proc eval(algsrf_func : proc (u,v:float):vec3, resol:int, p0:(float,float), p1:(float,float)) : seq[vec3] =

  let
    difU = (p0[0]-p0[1]).abs
    difV = (p1[0]-p1[1]).abs
    fromU=p0[0]
    fromV=p1[0]

    dr = 1 / resol
    dt = dr
  
  proc scaleU(x:float):float = x * difU + fromU
  proc scaleV(x:float):float = x * difV + fromV

  for i in 0..resol:
    let idr = i.float  * dr

    for j in 0..resol:
      let
        jdt = j.float * dt
        jdr = jdt
      
      # add quad x 4, normal
      
      result.add algsrf_func(scaleU(idr), scaleV(jdr))
      result.add algsrf_func(scaleU(idr+dr), scaleV(jdr))
      result.add algsrf_func(scaleU(idr+dr), scaleV(jdr+dt))
      result.add algsrf_func(scaleU(idr), scaleV(jdr+dt))

      result.add normal(result[^1],result[^2],result[^3])

proc eval(n_as, resol:int) : seq[vec3] =
  eval(as_funcs[n_as], resol, as_ranges[n_as][0], as_ranges[n_as][1]).scale



when isMainModule:
  
  # ui_gl
  import opengl/glut, opengl, opengl/glu

  var
    zoom {.global.} = -2.0
    anglex {.global.}= 0.0
    angley {.global.}= 0.0
    lastx  {.global.}= 0
    lasty  {.global.}= 0
    n_as {.global.} = as_funcs.high
    alg_srf {.global.}  =  eval(n_as, 512)

  converter vec32dblp(v: var vec3):ptr GLdouble = cast[ptr GLdouble](v.unsafeAddr)
  converter v42gld(v:array[4,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)
  converter v42gld(v:array[1,float32]):ptr GLfloat = cast[ptr GLfloat](v.unsafeAddr)

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
    glEnable(GL_DEPTH_TEST)

  proc draw_scene() {.cdecl.} =

    glLoadIdentity() # Reset
    glTranslatef(0, 0, zoom)
    glRotatef(anglex, 1.0, 0.0, 0.0)
    glRotatef(-angley, 0.0, 1.0, 0.0)
  

    glColor3f(0.35, 0.35, 0.55)

    for i in countup(0, alg_srf.high, 5):
      glBegin(GL_QUADS)
      for j in 0..<4: # quad, normal
        glNormal3dv(alg_srf[i+4])
        glVertex3dv(alg_srf[i+j]) 
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
    of ' ' : 
      anglex = 0
      angley = 0
    of '+' : 
      if n_as<as_funcs.high:
        n_as.inc
        alg_srf = eval(n_as, 512)
    of '-' : 
      if n_as!=0:
        n_as.dec
        alg_srf = eval(n_as, 512)

    else: discard

    glutSetWindowTitle "algebraic surfaces - " & as_names[n_as]

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
    glutInitWindowPosition(500, 500)
    
    discard glutCreateWindow("algebraic surfaces - " & as_names[n_as])

    glutDisplayFunc(display)
    glutReshapeFunc(reshape)
    glutKeyboardFunc(keyhook)
    glutMouseFunc(mouseWheel)
    glutMotionFunc(mouseDrag)

    loadExtensions()

    glClearColor(0, 0, 0, 1) # Set background color to black and opaque
    glClearDepth(1) # Set background depth to farthest

    sceneInit()

    glutMainLoop()


  main_gl()
