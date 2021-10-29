# line_art.nim

#[
  Hamid Naderi Yeganeh. idea & formulas

    - See more at: http://www.ams.org/mathimagery/displayimage.php?album=40&pid=565#top_display_media

    http://www.math.wustl.edu/News2015/News2015_Feb_Yeganeh.html

    http://www.huffingtonpost.com/hamid-naderi-yeganeh/using-mathematical-formul_b_9313484.html

]#

import math, streams, strformat, complex

type 
  Graph[T] = object
    n,w:int
    scale_factor, xoff, yoff : float
    foo : proc (k:float) : T

  Line = object
    x0,y0, x1,y1:float

  Circle = object
    x,y,r:float

  Ellipse = object
    c : Complex64 # cx, cy
    a,b :float

proc foci_ecc_2_center_radii(f0, f1: Complex, ecc: float) : Ellipse = 
    proc sqr(x: float) : float =  x * x
    
    let 
      c = (f1 - f0).abs2 / 2
      a = c / ecc
      b = a * (1 - ecc.sqr).sqrt
      fmid = (f0 + f1) / 2

    Ellipse(c:fmid, a:a, b:b)

# scale a gr_obj (line/cicle)  by graph
proc scale[T : Line | Circle | Ellipse](gr_obj:T, g : Graph[T]) : T =
  let scale = g.w.float / g.scale_factor

  when T is Line:
    Line( x0:(gr_obj.x0 + g.x_off + 1) * scale, y0: g.w.float / 2 - (1 + gr_obj.y0 + g.y_off) * scale,
          x1:(gr_obj.x1 + g.x_off + 1) * scale, y1: g.w.float / 2 - (1 + gr_obj.y1 + g.y_off) * scale  )
  elif T is Circle:
    Circle(x:gr_obj.x * scale + g.w.float / 2, y:g.w.float / 2 - gr_obj.y * scale, r:gr_obj.r * scale)
  elif T is Ellipse:
    Ellipse(c:complex64((g.x_off + gr_obj.c.re) * scale, g.w / 2 - (g.y_off + gr_obj.c.im) * scale) , a: gr_obj.a * scale, b: gr_obj.b * scale)

proc write_svg*[T : Line | Circle | Ellipse](name:string, g:Graph[T]) =
  let sw=0.3 # stroke width
  var f = newFileStream(name, fmWrite)

  if not f.isNil:
    # header
    f.write fmt"<svg width='{g.w}' height='{g.w}' fill='none' stroke='blue' stroke-width='{sw}'>{'\n'}<rect width='{g.w}' height='{g.w}' style='fill:white' />{'\n'}"

    for k in 1..g.n: # gr obj
      let go = g.foo(k.float).scale(g)

      when T is Line:    f.write fmt"<line x1='{go.x0:.2f}' y1='{go.y0:.2f}' x2='{go.x1:.2f}' y2='{go.y1:.2f}'/>{'\n'}"
      elif T is Circle:  f.write fmt"<circle cx='{go.x:.2f}' cy='{go.y:.2f}' r='{go.r:.2f}'/>{'\n'}"
      elif T is Ellipse: f.write fmt"<ellipse cx='{go.c.re:.2f}' cy='{go.c.im:.2f}' rx='{go.a:.2f}' ry='{go.b:.2f}'/>{'\n'}"

    f.write "</svg>"

# func depot
proc line1(i:float) : Line = Line(x0: -sin(2*PI*i/1000), y0: -cos(2*PI*i/1000), x1: (-1/2)*sin(8*PI*i/1000), y1: (-1/2)*cos(12*PI*i/1000) )
proc line2(i:float) : Line = Line(x0: -sin(4*PI*i/1000), y0: -cos(2*PI*i/1000), x1: (-1/2)*sin(8*PI*i/1000), y1: (-1/2)*cos(4*PI*i/1000) )
proc bird(i:float) : Line = Line(x0: 3*(sin(2*PI*i/2000)^3), y0: -cos(8*PI*i/2000) , x1: (3/2)*(sin(2*PI*i/2000)^3), y1: (-1/2)*cos(6*PI*i/2000)) 

proc butterfly1(k:float) : Circle = Circle(
  x:6/5 * cos(141*PI*k/40000)^9 * (1 - 1/2 * sin(PI*k/40000) ^ 3) * 
            (1 - 1/4 * cos(2*PI*k/40000)^30  * (1 + 2/3 * cos(30*PI*k/40000)^20) - 
            ( sin(2*PI*k/40000)^10 * sin(6*PI*k/40000)^10 * (1/5 + 4/5 * cos(24*PI*k/40000)^20) )),
          
  y:cos(2*PI*k/40000) * cos(141*PI*k/40000)^2 * (1 + 1/4 * cos(PI*k/40000)^24 * cos(3*PI*k/40000)^24 * cos(19*PI*k/40000)^24),
          
  r:1/100 + 1/40 * (cos(2820*PI*k/40000)^6+sin(141*PI*k/40000)^2) * (1 - (cos(PI*k/40000)^16) * cos(3*PI*k/40000)^16 * cos(12*PI*k/40000)^16 )
  )

proc butterfly3(k:float) : Circle = Circle(
  x:3/2 * ((cos(141*PI*k/40000))^9)*(1-(1/2)*sin(PI*k/40000))*(1-(1/4)*((cos(2*PI*k/40000))^30)*(1+(cos(32*PI*k/40000))^20)) * 
          (1-(1/2)*((sin(2*PI*k/40000))^30)*((sin(6*PI*k/40000))^10)*((1/2)+(1/2)*(sin(18*PI*k/40000))^20)),
          
  y:cos(2*PI*k/40000)*((cos(141*PI*k/40000))^2)*(1+(1/4)*((cos(PI*k/40000))^24)*((cos(3*PI*k/40000))^24)*(cos(21*PI*k/40000))^24),
          
  r:(1/100)+(1/40)*(((cos(141*PI*k/40000))^14)+(sin(141*PI*k/40000))^6)*(1-((cos(PI*k/40000))^16)*((cos(3*PI*k/40000))^16)*(cos(12*PI*k/40000))^16)
  )

# Ellipse
proc ellipse1(k:float) : Ellipse =
  proc a(k: float) : float = -3 / 2 * sin(2 * PI * k / 2500)^3  + (3 / 10) * sin(2 * PI * k / 2500)^7
  proc b(k: float) : float = sin((2 * PI * k / 1875) + (PI / 6)) + (1 / 4) * (sin((2 * PI * k / 1875) + (PI / 6)))^3
  proc c(k: float) : float = 2 / 15 - (1 / 8) * cos(PI * k / 625)
  proc d(k: float) : float = 49 / 50 - (1 / 7) * (sin(4 * PI * k / 2500))^4
  proc f0(k: float) : Complex64 = a(k) + complex64(0,1) * b(k) + c(k) * (68 * PI * complex64(0,1) * k / 2500).exp
  proc f1(k: float) : Complex64 = a(k) + complex64(0,1) * b(k) - c(k) * (68 * PI * complex64(0,1) * k / 2500).exp  

  foci_ecc_2_center_radii(f0(k), f1(k), d(k))

proc ellipse2(k:float) : Ellipse =
  proc a(k: float) : float = 3 / 4 * sin(2 * PI * k / 8000) * cos(6 * PI * k / 8000) + (1 / 4) * sin(28 * PI * k / 8000)
  proc b(k: float) : float = 3 / 4 * cos(2 * PI * k / 8000) * cos(8 * PI * k / 8000) + (1 / 4) * cos(28 * PI * k / 8000)
  proc c(k: float) : float = 1 / 18 + (1 / 20) * cos(24 * PI * k / 8000)
  proc d(k: float) : float = 49 / 50 - (1 / 7) * (sin(10 * PI * k / 8000))^4
  proc f0(k: float) : Complex64 = a(k) + complex64(0,1) * b(k) + c(k) * (300 * PI * complex64(0,1) * k / 8000).exp
  proc f1(k: float) : Complex64 = a(k) + complex64(0,1) * b(k) - c(k) * (300 * PI * complex64(0,1) * k / 8000).exp

  foci_ecc_2_center_radii(f0(k), f1(k), d(k))

proc ellipse_ring(k:float) : Ellipse =
  proc a(k: float) : float =  cos(28 * PI * k / 5600)^3
  proc b(k: float) : float =  sin(28 * PI * k / 5600)  + (1 / 4) * (cos((14 * PI * k / 5600) - (7 * PI / 4)))^18
  proc c(k: float) : float =  (1 / 70) + (1 / 6) + (1 / 6) * sin(28 * PI * k / 5600)
  proc d(k: float) : float =  (399 / 400) - (1 / 6) * (sin(28 * PI * k / 5600))^8
  proc f0(k: float) : Complex64 =  a(k) + complex64(0,1) * b(k) + c(k) * (44 * PI * complex64(0,1) * k / 5600).exp
  proc f1(k: float) : Complex64 =  a(k) + complex64(0,1) * b(k) - c(k) * (44 * PI * complex64(0,1) * k / 5600).exp

  foci_ecc_2_center_radii(f0(k), f1(k), d(k))

##################
when isMainModule:
  proc test_svg=
    echo "line_art test, svg folder must exist"

    echo "generating ellipse1..."
    write_svg("svg/ellipse1.svg", Graph[Ellipse](n : 2500, w : 4000,  scale_factor:3.5,  xoff : 3.5/2,  yoff : 0.0, foo : ellipse1 ))
    echo "generating ellipse2..."
    write_svg("svg/ellipse2.svg", Graph[Ellipse](n : 8000, w : 4000,  scale_factor:3.5,  xoff : 3.5/2,  yoff : 0.0, foo : ellipse2 ))
    echo "generating ellipse-ring..."
    write_svg("svg/ellipse_ring.svg", Graph[Ellipse](n : 5600, w : 4000,  scale_factor:3.5,  xoff : 3.5/2,  yoff : 0.0, foo : ellipse_ring ))

    echo "generating butterfly1..."
    write_svg("svg/butterfly1.svg", Graph[Circle](n : 40000, w : 4000,  scale_factor:3.0,  xoff : 0.0,  yoff : 0.0, foo : butterfly1 ))
    echo "generating butterfly3..."
    write_svg("svg/butterfly3.svg", Graph[Circle](n : 40000, w : 4000,  scale_factor:3.0,  xoff : 0.0,  yoff : 0.0, foo : butterfly3 ))

    echo "generating lines1..."
    write_svg("svg/lines1.svg", Graph[Line](n : 1000, w : 1000,  scale_factor : 4.0,  xoff : 0.0,  yoff : 0.0, foo : line1 ))
    echo "generating lines2..."
    write_svg("svg/lines2.svg", Graph[Line](n : 1000, w : 1000,  scale_factor : 4.0,  xoff : 0.0,  yoff : 0.0, foo : line2 ))
    echo "generating bird..."
    write_svg("svg/bird.svg", Graph[Line](n : 2000, w : 1000, scale_factor : 6.0, xoff:2.0, yoff:0.0, foo : bird ))
  
  test_svg()
