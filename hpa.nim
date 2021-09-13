#[

HPA 1.7 wrapper

range:  1.19*10^4932 > x > 1.68*10^-[4932].
so it's basically  a c long double

The High Precision Arithmetic library (HPAlib) implements a high precision floating point arithmetic together with a comprehensive set of support functions. 
The general areas covered by these functions include:

    Extended Precision Arithmetic,
    Extended Precision Math Library,
    Applications of High Precision Computation. 

The math library support includes evaluation of trigonometric, inverse trigonometric, hyperbolic, inverse hyperbolic, logarithm, 
and exponential functions at the same precision as the floating point math itself. The HPA library also supports 
high precision complex arithmetic and includes an Extended Precision Complex Math Library. 

source: https://www.nongnu.org/hpalib/

nim hpa wrapper, requires hpalib.a / .lib

 make -f GNUmakefile
 sudo make -f GNUmakefile install 

compile:

 nim c --passL:-lhpa hpa

]#

const
  HPA_VERSION* = "1.7"
  XLITTLE_ENDIAN* = 1
  XDIM* = 7
  XULONG_BITSIZE* = 64
  XERR_DFL* = 1

  XMAX_10EX* = 4931
  XMAX_DEGREE* = 50


when not defined(XERR_IGN):
  const
    XENONE* = 0
    XEDIV* = 1
    XEDOM* = 2
    XEBADEXP* = 3
    XFPOFLOW* = 4
    XNERR* = 4
    XEINV* = 5


type xpr* {.bycopy.} = object
    nmm*: array[XDIM + 1, cushort]

proc xadd*(a: xpr; b: xpr; k: cint): xpr {.importc: "xadd".}
proc xmul*(s: xpr; t: xpr): xpr {.importc: "xmul".}
proc xdiv*(s: xpr; t: xpr): xpr {.importc: "xdiv".}
proc atox*(s: cstring): xpr {.importc: "atox".}
proc dbltox*(y: cdouble): xpr {.importc: "dbltox".}
proc flttox*(y: cfloat): xpr {.importc: "flttox".}
proc inttox*(n: clong): xpr {.importc: "inttox".}
proc uinttox*(n: culong): xpr {.importc: "uinttox".}
proc xprcmp*(p: ptr xpr; q: ptr xpr): cint {.importc: "xprcmp".}
proc xeq*(x1: xpr; x2: xpr): cint {.importc: "xeq".}
proc xneq*(x1: xpr; x2: xpr): cint {.importc: "xneq".}
proc xgt*(x1: xpr; x2: xpr): cint {.importc: "xgt".}
proc xge*(x1: xpr; x2: xpr): cint {.importc: "xge".}
proc xlt*(x1: xpr; x2: xpr): cint {.importc: "xlt".}
proc xle*(x1: xpr; x2: xpr): cint {.importc: "xle".}
proc xisNaN*(u: ptr xpr): cint {.importc: "xisNaN".}
proc xisPinf*(u: ptr xpr): cint {.importc: "xisPinf".}
proc xisMinf*(u: ptr xpr): cint {.importc: "xisMinf".}
proc xisordnumb*(u: ptr xpr): cint {.importc: "xisordnumb".}
proc xis0*(u: ptr xpr): cint {.importc: "xis0".}
proc xnot0*(u: ptr xpr): cint {.importc: "xnot0".}
proc xsgn*(u: ptr xpr): cint {.importc: "xsgn".}
proc x_neg*(p: ptr xpr): cint {.importc: "x_neg".}
proc x_exp*(p: ptr xpr): cint {.importc: "x_exp".}
proc xsfmod*(t: xpr; p: ptr cint): xpr {.importc: "xsfmod".}
proc xpwr*(s: xpr; n: cint): xpr {.importc: "xpwr".} 
proc xpr2*(s: xpr; n: cint): xpr {.importc: "xpr2".}
proc xneg*(s: xpr): xpr {.importc: "xneg".}
proc xabs*(s: xpr): xpr {.importc: "xabs".}
proc xfrexp*(s: xpr; p: ptr cint): xpr {.importc: "xfrexp".}
proc xfmod*(s: xpr; t: xpr; q: ptr xpr): xpr {.importc: "xfmod".}
proc xfrac*(x: xpr): xpr {.importc: "xfrac".}
proc xtrunc*(x: xpr): xpr {.importc: "xtrunc".}
proc xround*(x: xpr): xpr {.importc: "xround".}
proc xceil*(x: xpr): xpr {.importc: "xceil".}
proc xfloor*(x: xpr): xpr {.importc: "xfloor".}
proc xfix*(x: xpr): xpr {.importc: "xfix".}
proc xtodbl*(s: xpr): cdouble {.importc: "xtodbl".}
proc xtoflt*(s: xpr): cfloat {.importc: "xtoflt".}
proc xtan*(x: xpr): xpr {.importc: "xtan".}
proc xsin*(x: xpr): xpr {.importc: "xsin".}
proc xcos*(x: xpr): xpr {.importc: "xcos".}
proc xatan*(a: xpr): xpr {.importc: "xatan".}
proc xasin*(a: xpr): xpr {.importc: "xasin".}
proc xacos*(a: xpr): xpr {.importc: "xacos".}
proc xatan2*(y: xpr; x: xpr): xpr {.importc: "xatan2".}
proc xsqrt*(u: xpr): xpr {.importc: "xsqrt".}
proc xexp*(u: xpr): xpr {.importc: "xexp".}
proc xexp2*(u: xpr): xpr {.importc: "xexp2".}
proc xexp10*(u: xpr): xpr {.importc: "xexp10".}
proc xlog*(u: xpr): xpr {.importc: "xlog".}
proc xlog2*(u: xpr): xpr {.importc: "xlog2".}
proc xlog10*(u: xpr): xpr {.importc: "xlog10".}
proc xtanh*(v: xpr): xpr {.importc: "xtanh".}
proc xsinh*(v: xpr): xpr {.importc: "xsinh".}
proc xcosh*(v: xpr): xpr {.importc: "xcosh".}
proc xatanh*(v: xpr): xpr {.importc: "xatanh".}
proc xasinh*(v: xpr): xpr {.importc: "xasinh".}
proc xacosh*(v: xpr): xpr {.importc: "xacosh".}
proc xpow*(x: xpr; y: xpr): xpr {.importc: "xpow".}
proc xchcof*(m: cint; xfunc: proc (a1: xpr): xpr): ptr xpr {.importc: "xchcof".}
proc xevtch*(z: xpr; a: ptr xpr; m: cint): xpr {.importc: "xevtch".}
proc xpr_asprint*(u: xpr; sc_not: cint; sign: cint; lim: cint): cstring {.importc: "xpr_asprint".}
proc xtoa*(u: xpr; lim: cint): cstring {.importc: "xtoa".}
proc xprxpr*(u: xpr; m: cint) {.importc: "xprxpr".}
proc xlshift*(i: cint; p: ptr cushort; k: cint) {.importc: "xlshift".}
proc xrshift*(i: cint; p: ptr cushort; k: cint) {.importc: "xrshift".}

template xsum*(a, b: untyped): untyped = xadd(a, b, 0)
template xsub*(a, b: untyped): untyped = xadd(a, b, 1)

# wrapper

# conv's
var int_limit=20 # default # of digitid to output

# xpr -> nim
proc set_intlimit*(il:int)=int_limit=il
converter tostr*(x:xpr):string = $xtoa(x, int_limit.cint)
proc tostr*(x:xpr, il:int):string = $xtoa(x, il.cint)
proc `$`*(x:xpr):string = $xtoa(x, int_limit.cint)
converter tof*(x:xpr):float = xtodbl(x)
converter toi*(x:xpr):int = xtodbl(x).int

# nim -> xpr 
converter stoxpr*(s:string):xpr = atox(s.cstring)
converter ftoxpr*(f:float):xpr = dbltox(f.cdouble)
converter ftoxpr*(f:float32):xpr = flttox(f.cfloat)
converter itoxpr*(i:int):xpr = inttox(i.clong)
converter utoxpr*(i:uint):xpr = uinttox(i.culong)

# aritmetics
proc `+`*(x, y:xpr):xpr = xsum(x,y)
proc `-`*(x, y:xpr):xpr = xsub(x,y)
proc `*`*(x, y:xpr):xpr = xmul(x,y)
proc `/`*(x, y:xpr):xpr = xdiv(x,y)

# compare
proc `==`*(x, y:xpr):bool = xeq(x,y)!=0
proc `!=`*(x, y:xpr):bool = xneq(x,y)!=0
proc `>`*(x, y:xpr):bool = xgt(x,y)!=0
proc `<`*(x, y:xpr):bool = xlt(x,y)!=0
proc `>=`*(x, y:xpr):bool = xge(x,y)!=0
proc `<=`*(x, y:xpr):bool = xle(x,y)!=0

# misc
proc isNan*(x:xpr):bool = xisNaN(x.unsafeAddr)!=0
proc isInf*(x:xpr):bool = xisPinf(x.unsafeAddr)==1 or xisMinf(x.unsafeAddr)==1
proc isNormal*(x:xpr):bool = xisordnumb(x.unsafeAddr)==1

# funcs
proc sgn*(x:xpr):int = xsgn(x.unsafeAddr).int
proc `%%`*(x,y:xpr) : xpr = 
  var r:xpr
  xfmod(x,y,r.unsafeAddr)
proc frac*(x:xpr):xpr=xfrac(x)
proc floor*(x:xpr):xpr=xfloor(x)
proc trunc*(x:xpr):xpr=xtrunc(x)
proc pow*(x:xpr, n:int):xpr=xpwr(x, n.cint)
proc pow*(x, y:xpr):xpr=xpow(x, y)
proc pow2*(x:xpr, n:int):xpr=xpr2(x, n.cint)
proc abs*(x:xpr):xpr=xabs(x)

proc log*(x:xpr):xpr=xlog(x)
proc log2*(x:xpr):xpr=xlog2(x)
proc log10*(x:xpr):xpr=xlog10(x)
proc exp*(x:xpr):xpr=xexp(x)
proc exp2*(x:xpr):xpr=xexp2(x)
proc exp10*(x:xpr):xpr=xexp10(x)

# trings / arc / hyperbolics
proc sin*(x:xpr):xpr=xsin(x)
proc cos*(x:xpr):xpr=xcos(x)
proc tan*(x:xpr):xpr=xtan(x)

proc asin*(x:xpr):xpr=xasin(x)
proc acos*(x:xpr):xpr=xacos(x)
proc atan*(x:xpr):xpr=xatan(x)

proc sinh*(x:xpr):xpr=xsinh(x)
proc cosh*(x:xpr):xpr=xcosh(x)
proc tanh*(x:xpr):xpr=xtanh(x)

# test


when isMainModule:
  var 
    f0="123.56".xpr
    f1=(345.67).xpr
    f2=123456.xpr
    f3=0

  if f0==0:  echo f0, " is zero"
  if f0==f0:  echo f0, " f0==f0"
  if f0!=0:  echo f0, " is NOT zero"
  echo f3,", f3==0 -> ", f3==0
    
  if f1>f0: echo f1, " > ", f0
  if f0<f1: echo f0, " < ", f1

  echo "f0^f1:", f0.pow(f1)

  f0="123.456".xpr
  for i in 0..1530:
    f1=f1*345.67
    f0=f0*f0

  echo f1, ",", f2.sin.tostr(7)