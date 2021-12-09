# implicit func's
import math

proc sqr(x:float32):float32=x*x
proc cube(x:float32):float32=x*x*x
proc sqr3(x:float32):float32=x*x*x
proc sqr4(x:float32):float32=x*x*x*x
proc sphere(x,y,z:float32):float32= 
  let rsq = x*x+y*y+z*z
  1.0 / (if rsq < 0.00001: 0.00001 else: rsq)
  
proc NordstarndWeird*(x,y,z:float32):float32=
  25*(x*x*x*(y + z) + y*y*y*(x + z) + z*z*z*(x + y)) + 50*(x*x*y*y + x*x*z*z + y*y*z*z) - 125*(x*x*y*z + y*y*x*z + z*z*x*y) + 60*x*y*z - 4*(x*y + y*z + z*x)

proc DecoCube*(x,y,z:float32):float32 =
  let 
    a = 0.95
    b = 0.01
  (sqr(x*x + y*y - a*a) + sqr(z*z - 1))*(sqr(y*y + z*z - a*a) + sqr(x*x - 1))*(sqr(z*z + x*x - a*a) + sqr(y*y - 1)) - b

proc Cassini*(x,y,z:float32):float32 =
  let a = 0.3
  (sqr((x - a)) + z*z) * (sqr((x + a)) + z*z) - y^4 # ( (x-a)^2 + y^2) ((x+a)^2 + y^2) = z^4 a = 0.5
    
proc Orth*(x,y,z:float32):float32=
  let 
    a = 0.06
    b = 2.0
  (sqr(x*x + y*y - 1) + z*z)*(sqr(y*y + z*z - 1) + x*x)*(sqr(z*z + x*x - 1) + y*y)-a*a*(1 + b*(x*x + y*y + z*z))

proc Orthogonal*(x,y,z:float32):float32 =
  # let (a,b) = (0.06, 2)
  Orth(x,y,z)

proc Orth3*(x,y,z:float32):float32 =
  4.0 - Orth(x + 0.5, y - 0.5, z - 0.5) - Orth(x - 0.5, y + 0.5, z - 0.5) - Orth(x - 0.5, y - 0.5, z + 0.5)
    
proc Pretzel*(x,y,z:float32):float32 =
  let aa = 1.6
  sqr( ((x - 1)*(x - 1) + y*y - aa*aa) * ((x + 1)*(x + 1) + y*y - aa*aa)) + z*z*10 - 1
    
proc Tooth*(x,y,z:float32):float32 =
  sqr4(x) + sqr4(y) + sqr4(z) - sqr(x) - sqr(y) - sqr(z)
    
proc Pilz*(x,y,z:float32):float32 =
  let (a,b) = (0.05, -0.1)
  sqr( sqr(x*x + y*y - 1) + sqr(z - 0.5)) * ( sqr(y*y / a*a + sqr(z + b) - 1.0) + x*x) - a * (1.0 + a*sqr(z - 0.5))
    
proc Bretzel*(x,y,z:float32):float32 =
  let 
    a = 0.003
    b = 0.7
  sqr(x*x*(1 - x*x) - y*y)  + 0.5*z*z - a*(1 + b*(x*x + y*y + z*z))

proc BarthDecic*(x,y,z:float32):float32 =
  let 
    GR = 1.6180339887 # Golden ratio
    GR2 = GR * GR
    GR4 = GR2 * GR2
    w = 0.3
    
  8*(x*x - GR4*y*y)*(y*y - GR4*z*z)*(z*z - GR4*x*x)*(x*x*x*x + y*y*y*y + z*z*z*z - 2*x*x*y*y - 2*x*x*z*z - 2*y*y*z*z)+
  (3 + 5*GR)*sqr((x*x + y*y + z*z - w*w))*sqr((x*x + y*y + z*z - (2 - GR)*w*w))*w*w
    
proc Clebsch0 *(x,y,z:float32):float32 =
  81*(cube(x) + cube(y) + cube(z)) - 189*(sqr(x)*y + sqr(x)*z + sqr(y)*x + sqr(y)*z + sqr(z)*x + sqr(z)*y) + 54*(x*y*z) + 126*(x*y + x*z + y*z) - 9*(sqr(x) + sqr(y) + sqr(z)) - 9*(x + y + z) + 1
    
proc Clebsch*(x,y,z:float32):float32 =
  16 * cube(x) + 16 * cube(y) - 31 * cube(z) + 24 * sqr(x) * z - 48 * sqr(x) * y - 48 * x * sqr(y) + 24 * sqr(y) * z - 54 * sqrt(3.0) * sqr(z) - 72 * z
    
proc Chubs*(x,y,z:float32):float32 =
  x^4 + y^4 + z^4 - sqr(x) - sqr(y) - sqr(z) + 0.5 # x^4 + y^4 + z^4 - x^2 - y^2 - z^2 + 0.5 = 0
    
proc Chair*(x,y,z:float32):float32 =
  let 
    k = 5.0
    a = 0.95
    b = 0.8
  sqr(sqr(x) + sqr(y) + sqr(z) - a*sqr(k)) - b*((sqr((z - k)) - 2*sqr(x))*(sqr((z + k)) - 2*sqr(y)))
  # (x^2+y^2+z^2-a*k^2)^2-b*((z-k)^2-2*x^2)*((z+k)^2-2*y^2)=0, 	  with k=5, a=0.95 and b=0.8.

proc Roman*(x,y,z:float32):float32 =
  let r=2.0
  sqr(x)*sqr(y) + sqr(y)*sqr(z) + sqr(z)*sqr(x) - r*x*y*z

proc Sinxyz*(x,y,z:float32):float32 =
  sin(x)*sin(y)*sin(z)
    
proc F001*(x,y,z:float32):float32 =
  sqr3(x)+sqr3(y)+sqr4(z)-10 # x^3 + y^3 + z^4 -10 = 0
    
proc TangleCube*(x,y,z:float32):float32 =
  sqr4(x) - 5*sqr(x) + sqr4(y) - 5*sqr(y) + sqr4(z) - 5*sqr(z) + 11.8

proc Goursat*(x,y,z:float32):float32 = # (x^4 + y^4 + z^4) + a * (x^2 + y^2 + z^2)^2 + b * (x^2 + y^2 + z^2) + c = 0 	
  let (a,b,c)=(0.0,0.0,-1.0)
  sqr4(x)+sqr4(y)+sqr4(z) + a*sqr(sqr(x)+sqr(y)+sqr(z)) + b*(sqr(x)+sqr(y)+sqr(z)) + c
    
proc Blob*(x,y,z:float32):float32=
  4 - sphere(x + 0.5, y - 0.5, z - 0.5) - sphere(x - 0.5, y + 0.5, z - 0.5) - sphere(x - 0.5, y - 0.5, z + 0.5)

proc Sphere*(x,y,z:float32):float32= sphere(x,y,z)-1


let ImplicitFuncs* = [
  Sphere, Blob, NordstarndWeird, DecoCube, Cassini, Orth, Orth3, 
  Pretzel, Tooth, Pilz, Bretzel , BarthDecic, Clebsch0, Clebsch,
  Chubs, Chair, Roman, TangleCube, Goursat, Sinxyz
]
