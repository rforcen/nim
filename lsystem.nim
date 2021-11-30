# Lindermayer - lsystem svg generator based on fractint.l partial syntax
# syntax from: http://www.fractalsciencekit.com/lsysprog/lsysprog.htm
# examples from : http://spanky.triumf.ca/pub/fractals/lsystems/FRACTINT.L

import tables, math, strformat

proc ltransform(axiom:string, rules:Table[char, string], niters:int):string =
  result=axiom
  for i in 0..<niters:
    var next=""
    for c in result: next.add rules.getOrDefault(c, $c)
    result=move(next)

# pangle is in .l syntax, i.e. deg = 360/angle
proc turtle_svg(lsystem, file_name:string, size=2000.0,xdiv, ydiv:float,angle:int,fwd_len:float)=
  # l language angle to rad 
  proc angleToRad(angle : int) : float = (360.0/angle.float).degToRad

  var 
    ang = angle.angleToRad
    alpha = ang
    (x,y)=(size/xdiv, size/ydiv)
    stack : seq[(float,float,float)]

  let svgFile = file_name.open(fmWrite)
  svgFile.write &"""
<svg xmlns="http://www.w3.org/2000/svg" height='{size}' width='{size}' fill='none' stroke='blue' stroke-width='{1}'>
<rect height="100%%" width="100%%" style="fill:white" />
  """

  for c in lsystem:
    case c:
    of 'F':
      let (nx, ny) = (x + fwd_len * cos(alpha), y + fwd_len * sin(alpha))
      svgFile.write  &"<line x1='{x:.1f}' y1='{y:.1f}' x2='{nx:.1f}' y2='{ny:.1f}'/>\n"
      (x, y) = (nx, ny)

    of '-': alpha-=ang
    of '+': alpha+=ang

    of '[': stack.add (x,y,alpha)
    of ']': (x,y,alpha) = stack.pop 

    else: discard

  
  svgFile.write "</svg>"
  svgFile.close()


proc lsystem*(axiom:string, rules:Table[char, string], file_name:string, angle, niters:int, size, fwd_len:float, xdiv, ydiv:float)=
  ltransform(axiom, rules, niters).turtle_svg(file_name, size, size/xdiv, size/ydiv, angle, fwd_len)

# examples
proc koch1=
  ltransform(axiom="F--F--F", rules={'F':"F+F--F+F"}.toTable, niters=7).
    turtle_svg(file_name="svg/koch1.svg",  angle=6,  fwd_len=0.7,  xdiv=8,  ydiv=4)

proc koch2=
  ltransform(axiom="F---F---F---F", rules={'F':"-F+++F---F+"}.toTable, niters=6).
    turtle_svg(file_name="svg/koch2.svg",  angle=12,  fwd_len=8,  xdiv=6,  ydiv=1.5)
  
proc dragon=
  ltransform(axiom="FX", rules={'F':"", 'X':"-FX++FY-", 'Y':"+FX--FY+"}.toTable, niters=15).
    turtle_svg(file_name="svg/dragon.svg",  angle=8,  fwd_len=6,  xdiv=3,  ydiv=3)
  
proc peano1=
  ltransform(axiom="F-F-F-F", rules={'F':"F-F+F+F+F-F-F-F+F"}.toTable, niters=4).
    turtle_svg(file_name="svg/peano1.svg",  angle=4,  fwd_len=8,  xdiv=3,  ydiv=6.0)
  
proc flowsnake=
  ltransform(axiom="FL", rules={'F':"", 'L':"FL-FR--FR+FL++FLFL+FR-", 'R':"+FL-FRFR--FR-FL++FL+FR"}.toTable, niters=5).
    turtle_svg(file_name="svg/flowsnake.svg",  angle=6,  fwd_len=12, xdiv=3,   ydiv=1.1)

const 
  Lsystem_samples* = [koch1, koch2, dragon, peano1, flowsnake]
  Lsystem_names* = ["koch1", "koch2", "dragon", "peano1", "flowsnake"]

when isMainModule:
  import sequtils
  echo "generating lsystem samples"
  for (l,n) in zip(Lsystem_samples, Lsystem_names):  
    echo n
    l()
  
