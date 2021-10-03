#[

slower t/mpfr

HPA 1.7 wrapper

range:  1.19*10^4932 > x > 1.68*10^-[4932].

 to set precision in hpa set
   MANTSIZE_MACRO= -DXMANTISSA_SIZE=62 (default 7)
   in GNUmakefile
   sudo make -f GNUmakefile install

The High Precision Arithmetic library (HPAlib) implements a high precision floating point arithmetic together with a comprehensive set of support functions. 
The general areas covered by these functions include:

    Extended Precision Arithmetic,
    Extended Precision Math Library,
    Applications of High Precision Computation. 

The math library support includes evaluation of trigonometric, inverse trigonometric, hyperbolic, inverse hyperbolic, logarithm, 
and exponential functions at the same precision as the floating point math itself. The HPA library also supports 
high precision complex arithmetic and includes an Extended Precision Complex Math Library. 

source: https://www.nongnu.org/hpalib/

nim hpa wrapper, requires hpalib.a / .lib & -lm

]#

{.passL: "-lhpa -lm".} # libs required

const
  HPA_VERSION* = "1.7"
  XLITTLE_ENDIAN* = 1
  #[ 
    to set precision in hpa set
   MANTSIZE_MACRO= -DXMANTISSA_SIZE=62 
   in GNUmakefile
  ]#
  XDIM* = 64 # this is for > f1024   
  XULONG_BITSIZE* = 64 # default value is 7
  XERR_DFL* = 1

type xpr* {.bycopy.} = object
    nmm*: array[XDIM + 1, cushort] # IMPORTANT check XDIM w/hpa makefile


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
proc exp*(p: ptr xpr): cint {.importc: "x_exp".}
proc xsfmod*(t: xpr; p: ptr cint): xpr {.importc: "xsfmod".}
proc xpwr*(s: xpr; n: cint): xpr {.importc: "xpwr".} 
proc xpr2*(s: xpr; n: cint): xpr {.importc: "xpr2".}
proc xneg*(s: xpr): xpr {.importc: "xneg".}
proc abs*(s: xpr): xpr {.importc: "xabs".}
proc xfrexp*(s: xpr; p: ptr cint): xpr {.importc: "xfrexp".}
proc xfmod*(s: xpr; t: xpr; q: ptr xpr): xpr {.importc: "xfmod".}
proc frac*(x: xpr): xpr {.importc: "xfrac".}
proc trunc*(x: xpr): xpr {.importc: "xtrunc".}
proc round*(x: xpr): xpr {.importc: "xround".}
proc ceil*(x: xpr): xpr {.importc: "xceil".}
proc floor*(x: xpr): xpr {.importc: "xfloor".}
proc fix*(x: xpr): xpr {.importc: "xfix".}
proc xtodbl*(s: xpr): cdouble {.importc: "xtodbl".}
proc xtoflt*(s: xpr): cfloat {.importc: "xtoflt".}
proc tan*(x: xpr): xpr {.importc: "xtan".}
proc sin*(x: xpr): xpr {.importc: "xsin".}
proc cos*(x: xpr): xpr {.importc: "xcos".}
proc atan*(a: xpr): xpr {.importc: "xatan".}
proc asin*(a: xpr): xpr {.importc: "xasin".}
proc acos*(a: xpr): xpr {.importc: "xacos".}
proc atan2*(y: xpr; x: xpr): xpr {.importc: "xatan2".}
proc sqrt*(u: xpr): xpr {.importc: "xsqrt".}
proc exp*(u: xpr): xpr {.importc: "xexp".}
proc exp2*(u: xpr): xpr {.importc: "xexp2".}
proc exp10*(u: xpr): xpr {.importc: "xexp10".}
proc log*(u: xpr): xpr {.importc: "xlog".}
proc log2*(u: xpr): xpr {.importc: "xlog2".}
proc log10*(u: xpr): xpr {.importc: "xlog10".}
proc tanh*(v: xpr): xpr {.importc: "xtanh".}
proc sinh*(v: xpr): xpr {.importc: "xsinh".}
proc cosh*(v: xpr): xpr {.importc: "xcosh".}
proc atanh*(v: xpr): xpr {.importc: "xatanh".}
proc asinh*(v: xpr): xpr {.importc: "xasinh".}
proc acosh*(v: xpr): xpr {.importc: "xacosh".}
proc pow*(x: xpr; y: xpr): xpr {.importc: "xpow".}
proc xchcof*(m: cint; xfunc: proc (a1: xpr): xpr): ptr xpr {.importc: "xchcof".}
proc xevtch*(z: xpr; a: ptr xpr; m: cint): xpr {.importc: "xevtch".}
proc xpr_asprint*(u: xpr; sc_not: cint; sign: cint; lim: cint): cstring {.importc: "xpr_asprint".}
proc xtoa*(u: xpr; lim: cint): cstring {.importc: "xtoa".}
proc xprxpr*(u: xpr; m: cint) {.importc: "xprxpr".}
proc xlshift*(i: cint; p: ptr cushort; k: cint) {.importc: "xlshift".}
proc xrshift*(i: cint; p: ptr cushort; k: cint) {.importc: "xrshift".}

template xsum*(a, b: untyped): untyped = xadd(a, b, 0)
template xsub*(a, b: untyped): untyped = xadd(a, b, 1)


# xpr wrapper

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

# arithmetics
proc `+`*(x, y:xpr):xpr = xsum(x,y)
proc `-`*(x, y:xpr):xpr = xsub(x,y)
proc `*`*(x, y:xpr):xpr = xmul(x,y)
proc `/`*(x, y:xpr):xpr = xdiv(x,y)
proc `+=`*(x:var xpr, y:xpr) = x=xsum(x,y)
proc `-=`*(x:var xpr, y:xpr) = x=xsub(x,y)
proc `*=`*(x:var xpr, y:xpr) = x=xmul(x,y)
proc `/=`*(x:var xpr, y:xpr) = x=xdiv(x,y)

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
proc pow*(x:xpr, n:int):xpr=xpwr(x, n.cint)
proc pow2*(x:xpr, n:int):xpr=xpr2(x, n.cint)

# complex

type
  cxpr* {.bycopy.} = object
    re*: xpr
    im*: xpr

  cxprcmp_res* {.bycopy.} = object
    re*: cint
    im*: cint


var
   cxZero*: cxpr
   cxOne*: cxpr
   cxIU*: cxpr

proc cxreset*(re: xpr; im: xpr): cxpr {.importc:"cxreset".}
proc cxconv*(x: xpr): cxpr {.importc:"cxconv".}
proc cxre*(z: cxpr): xpr {.importc:"cxre".}
proc cxim*(z: cxpr): xpr {.importc:"cxim".}
proc cxswap*(z: cxpr): cxpr {.importc:"cxswap".}
proc cxarg*(z: cxpr): xpr {.importc:"cxarg".}
proc cxrec*(z: cxpr; w: ptr cxpr): cint {.importc:"cxrec".}
proc cxadd*(z1: cxpr; z2: cxpr; k: cint): cxpr {.importc:"cxadd".}
proc cxsum*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxsum".}
proc cxsub*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxsub".}
proc cxmul*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxmul".} #  Multiplication by a real number
proc cxrmul*(c: xpr; z: cxpr): cxpr {.importc:"cxrmul".} #  Multiplication by +i
proc drot*(z: cxpr): cxpr {.importc:"cxdrot".}#  Multiplication by -i
proc rrot*(z: cxpr): cxpr {.importc:"cxrrot".}
proc cxdiv*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxdiv".}
proc cxgdiv*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxgdiv".}
proc cxidiv*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxidiv".}
proc cxgmod*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxgmod".}
proc cxmod*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxmod".}
proc cxpwr*(z: cxpr; n: cint): cxpr {.importc:"cxpwr".}
proc sqr*(z: cxpr): cxpr {.importc:"cxsqr".}
proc pow*(z1: cxpr; z2: cxpr): cxpr {.importc:"cxpow".}
proc cxroot*(z: cxpr; i: cint; n: cint): cxpr {.importc:"cxroot".}
proc sqrt*(z: cxpr): cxpr {.importc:"cxsqrt".}
proc cxprcmp*(z1: ptr cxpr; z2: ptr cxpr): cxprcmp_res {.importc:"cxprcmp".}
proc is0*(z: ptr cxpr): cint {.importc:"cxis0".}
proc not0*(z: ptr cxpr): cint {.importc:"cxnot0".}
proc cxeq*(z1: cxpr; z2: cxpr): cint {.importc:"cxeq".}
proc cxneq*(z1: cxpr; z2: cxpr): cint {.importc:"cxneg".}
proc cxgt*(z1: cxpr; z2: cxpr): cint {.importc:"cxgt".}
proc cxge*(z1: cxpr; z2: cxpr): cint {.importc:"cxge".}
proc cxlt*(z1: cxpr; z2: cxpr): cint {.importc:"cxlt".}
proc cxle*(z1: cxpr; z2: cxpr): cint {.importc:"cxle".}

proc abs*(z: cxpr): xpr {.importc:"cxabs".}
proc conj*(z: cxpr): cxpr {.importc:"cxconj".}
proc neg*(z: cxpr): cxpr {.importc:"cxneg".}
proc inv*(z: cxpr): cxpr {.importc:"cxinv".}

proc exp*(z: cxpr): cxpr {.importc:"cxexp".}
proc exp10*(z: cxpr): cxpr {.importc:"cxexp10".}
proc exp2*(z: cxpr): cxpr {.importc:"cxexp2".}

proc log*(z: cxpr): cxpr {.importc:"cxlog".}
proc log10*(z: cxpr): cxpr {.importc:"cxlog10".}
proc log2*(z: cxpr): cxpr {.importc:"cxlog2".}
proc log_sqrt*(z: cxpr): cxpr {.importc:"cxlog_sqrt".}
proc sin*(z: cxpr): cxpr {.importc:"cxsin".}
proc cos*(z: cxpr): cxpr {.importc:"cxcos".}
proc tan*(z: cxpr): cxpr {.importc:"cxtan".}
proc sinh*(z: cxpr): cxpr {.importc:"cxsinh".}
proc cosh*(z: cxpr): cxpr {.importc:"cxcosh".}
proc tanh*(z: cxpr): cxpr {.importc:"cxtanh".}
proc asin*(z: cxpr): cxpr {.importc:"cxasin".}
proc acos*(z: cxpr): cxpr {.importc:"cxacos".}
proc atan*(z: cxpr): cxpr {.importc:"cxatan".}
proc asinh*(z: cxpr): cxpr {.importc:"cxasinh".}
proc acosh*(z: cxpr): cxpr {.importc:"cxacosh".}
proc atanh*(z: cxpr): cxpr {.importc:"cxatanh".}
proc floor*(z: cxpr): cxpr {.importc:"cxfloor".}
proc ceil*(z: cxpr): cxpr {.importc:"cxceil".}
proc round*(z: cxpr): cxpr {.importc:"cxround".}
proc trunc*(z: cxpr): cxpr {.importc:"cxtrunc".}
proc frac*(z: cxpr): cxpr {.importc:"cxfrac".}
proc fix*(z: cxpr): cxpr {.importc:"cxfix".}

#  Conversion's functions

proc strtocx*(q: cstring; endptr: cstringArray): cxpr  {.importc:"strtocx".}
proc atocx*(s: cstring): cxpr {.importc:"atocx".}
proc cxpr_asprint*(z: cxpr; sc_not: cint; sign: cint; lim: cint): cstring {.importc:"cxpr_asprint".}
proc cxtoa*(z: cxpr; lim: cint): cstring {.importc:"cxtoa".}
proc dctocx*(re: cdouble; im: cdouble): cxpr {.importc:"dctocx".}
proc fctocx*(re: cfloat; im: cfloat): cxpr {.importc:"fctocx".}
proc ictocx*(re: clong; im: clong): cxpr {.importc:"ictocx".}
proc uctocx*(re: culong; im: culong): cxpr {.importc:"uctocx".}
proc cxtodc*(z: ptr cxpr; re: ptr cdouble; im: ptr cdouble) {.importc:"cxtodc".}
proc cxtofc*(z: ptr cxpr; re: ptr cfloat; im: ptr cfloat) {.importc:"cxtofc".}

template CXRESET*(re, im: untyped): untyped =
  cast[cxpr]((re, im))

template CXCONV*(x: untyped): untyped =
  cast[cxpr]((x, xZero))

template CXRE*(z: untyped): untyped =
  (z).re

template CXIM*(z: untyped): untyped =
  (z).im

template CXSWAP*(z: untyped): untyped =
  cast[cxpr](((z).im, (z).re))

# cxpr wrapper

converter ftoc*(f:float):cxpr=cxpr(re:f, im:0)
converter itoc*(i:int):cxpr=cxpr(re:i, im:0)

# arithmetics
proc `+`*(x, y:cxpr):cxpr = cxsum(x,y)
proc `-`*(x, y:cxpr):cxpr = cxsub(x,y)
proc `*`*(x, y:cxpr):cxpr = cxmul(x,y)
proc `/`*(x, y:cxpr):cxpr = cxdiv(x,y)

proc `+=`*(x:var cxpr, y:cxpr) = x = cxsum(x,y)
proc `-=`*(x:var cxpr, y:cxpr) = x = cxsub(x,y)
proc `*=`*(x:var cxpr, y:cxpr) = x = cxmul(x,y)
proc `/=`*(x:var cxpr, y:cxpr) = x = cxdiv(x,y)
 
# compare
proc `==`*(x, y:cxpr):bool = cxeq(x,y)!=0
proc `!=`*(x, y:cxpr):bool = cxeq(x,y)==0 # cxneq freezes echo ??
proc `>`*(x, y:cxpr):bool = cxgt(x,y)!=0
proc `<`*(x, y:cxpr):bool = cxlt(x,y)!=0
proc `>=`*(x, y:cxpr):bool = cxge(x,y)!=0
proc `<=`*(x, y:cxpr):bool = cxle(x,y)!=0

# test


when isMainModule:

  type 
    f1024=xpr
    c1024=cxpr

  proc test_xpr* = 
    var 
      f0="123.56".f1024
      f1=(345.67).f1024
      f2=123456.f1024
      f3=0

    if f0==0:  echo f0, " is zero"
    if f0==f0:  echo f0, " f0==f0"
    if f0!=0:  echo f0, " is NOT zero"
    echo f3,", f3==0 -> ", f3==0
      
    if f1>f0: echo f1, " > ", f0
    if f0<f1: echo f0, " < ", f1

    echo "f0^f1:", f0.pow(f1)

    f0="123.456".f1024
    for i in 0..1530:
      f1=f1*345.67
      f0=f0*f0

    echo f1, ",", f2.sin.tostr(7)

    # divide 1 / 2 until 0
    var 
      fd1=1.f1024
      i=0
    while fd1!=0:
      echo i,":",fd1
      fd1 /= 2
      i.inc
    echo i,":",fd1


  proc test_cxpr = 
    var 
      c0=c1024(re:2.9, im:1.89)
      c1=c0+1

    echo c0, ",", c1, ", c0+c1=", c0+c1
    echo c0*c1
    echo c1/c0
    echo c0 == c1
    echo c0 != 0
    echo c0 <= c1
    echo c0 < c1
    echo c0 >= c1
    echo c0 > c1
    echo c1 != c0
    echo c1.sin.cos.log.sinh
    echo "using f",xpr.sizeof*8

  import times
  proc test_mandel=

    var 
      c0=c1024(re:1, im:0)
      z=c0
    c0+=c1024(re:123.67, im:123.67)
    let n=1900
    echo "generating hpa ",n*n, " iters, @",XDIM*16,"bit precision"

    var t0=now()
    let four=f1024(4.0)
    for i in 0..n*n:  # simulate mandelbrot fractal generation
      z=c0
      for it in 0..200:
        z=z*z+c0
        if z.abs > four: break
    echo z
    echo "lap mpfr:",(now()-t0).inMilliseconds

  # test_xpr()
  # test_cxpr()
  test_mandel()