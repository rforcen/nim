#[

  mpfr wrapper (GNU MPFR 4.1.0)

  https://www.mpfr.org

]#

import math

{.passL: "-lmpfr -lgmp".} # libs required

const mpfr_header* = "<mpfr.h>"

type
  mpfr_rnd_t = enum
    MPFR_RNDNA = -1 # round to nearest, with ties away from zero (mpfr_round)

    MPFR_RNDN = 0   # round to nearest, with ties to even
    MPFR_RNDZ = 1   # round toward zero
    MPFR_RNDU = 2   # round toward +Inf
    MPFR_RNDD = 3   # round toward -Inf
    MPFR_RNDA = 4   # round away from zero
    MPFR_RNDF = 5   # faithful rounding

  mpfr_kind_t = enum
    MPFR_NAN_KIND = 0
    MPFR_INF_KIND = 1
    MPFR_ZERO_KIND = 2
    MPFR_REGULAR_KIND = 3

var
  mpfr_precision*: int = 1024 # mantissa
  mpfr_digits* = 5
  mpfr_rand* = MPFR_RNDZ      # default round method

type
  mpfr_prec_t = clong
  mpfr_sign_t = cint
  mpfr_exp_t = clong
  mp_limb_t = culong

#[
  /* Definition of the main structure */
  typedef struct {
    mpfr_prec_t  _mpfr_prec;
    mpfr_sign_t  _mpfr_sign;
    mpfr_exp_t   _mpfr_exp;
    mp_limb_t   *_mpfr_d;
  } __mpfr_struct;
]#
  mpfr* = object # {.importc: "__mpfr_struct", header : mpfr_header.} =  object
    mpfr_prec: mpfr_prec_t
    mpfr_sign: mpfr_sign_t
    mpfr_exp: mpfr_exp_t
    mpfr_d: mp_limb_t

  mpfr_t = mpfr



# https://www.mpfr.org/mpfr-current/mpfr.html#MPFR-Basics

{.push importc.}

# init
proc mpfr_init2(x: mpfr, prec: mpfr_prec_t) 
proc mpfr_clear(x: mpfr) 
proc mpfr_free_cache*() 
proc mpfr_set_prec(x: mpfr_t, prec: mpfr_prec_t) 

# exp
proc mpfr_get_emin: mpfr_exp_t 
proc mpfr_get_emax: mpfr_exp_t 

# assignment
proc mpfr_set(rop: mpfr_t, op: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_set_zero(x: mpfr, sign: cint = 0) 
proc mpfr_swap(x, y: mpfr_t) 
proc mpfr_set_ui (rop: mpfr_t, op: culong, rnd: mpfr_rnd_t): cint 
proc mpfr_set_d(rop: mpfr_t, op: cdouble, rnd: mpfr_rnd_t): cint 
proc mpfr_set_str (rop: mpfr_t, s: cstring, base: cint,
    rnd: mpfr_rnd_t): cint 

# conversion
proc mpfr_get_flt(rop: mpfr_t, rnd: mpfr_rnd_t): cfloat 
proc mpfr_get_d(rop: mpfr_t, rnd: mpfr_rnd_t): cdouble 
proc mpfr_get_str (str: cstring, expptr: ptr mpfr_exp_t, base: cint, n: csize_t,
    op: mpfr_t, rnd: mpfr_rnd_t): cstring 

# arithmetics
proc mpfr_add (rop, op1, op2: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_sub (rop, op1, op2: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_neg (rop, op1: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_mul (rop, op1, op2: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_div (rop, op1, op2: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_add_d (rop, op1: mpfr_t, op2: cdouble, rnd: mpfr_rnd_t): cint 
proc mpfr_sub_d (rop, op1: mpfr_t, op2: cdouble, rnd: mpfr_rnd_t): cint 
proc mpfr_mul_d (rop, op1: mpfr_t, op2: cdouble, rnd: mpfr_rnd_t): cint 
proc mpfr_div_d (rop, op1: mpfr_t, op2: cdouble, rnd: mpfr_rnd_t): cint 

proc mpfr_signbit (rop: mpfr_t): cint 

# comparision
proc mpfr_cmp(op1, op2: mpfr_t): cint 
proc mpfr_cmp_d(op1: mpfr_t, op2: cdouble): cint 

# funcs
proc mpfr_sqrt (rop, op: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_rootn_ui (rop, op: mpfr_t, n: culong, rnd: mpfr_rnd_t): cint  # x ^ y
proc mpfr_fac_ui (rop: mpfr_t, op: culong, rnd: mpfr_rnd_t): cint 
proc mpfr_atan2 (rop, y, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_pow (rop, x, y: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_sin (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_cos (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_sinh (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_cosh (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_tan (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_log (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_exp (rop, x: mpfr_t, rnd: mpfr_rnd_t): cint 

# constants
proc mpfr_const_log2(rop: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_const_euler(rop: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_const_catalan(rop: mpfr_t, rnd: mpfr_rnd_t): cint 
proc mpfr_const_pi(rop: mpfr_t, rnd: mpfr_rnd_t): cint 

# custom interface
proc mpfr_custom_get_size (prec: mpfr_prec_t): csize_t 
proc mpfr_custom_init (significand: pointer, prec: mpfr_prec_t) 
proc mpfr_custom_init_set (x: mpfr_t, kind: mpfr_kind_t, exp: mpfr_exp_t,
    prec: mpfr_prec_t, significand: pointer) 
proc mpfr_custom_get_kind (x: mpfr_t): cint 
proc mpfr_custom_get_significand (x: mpfr_t): pointer 
proc mpfr_custom_get_exp (x: mpfr_t): mpfr_exp_t 
proc mpfr_custom_move (x: mpfr_t, new_position: pointer) 

{.pop.}

#[
  nim wrapper
]#

proc set_precision*(prec_in_bits: int) = mpfr_precision = prec_in_bits
proc get_precision* : int = mpfr_precision
proc set_digits*(n: int) = mpfr_digits = n

proc init_val(x: mpfr_t, v: float) =
  mpfr_init2(x, mpfr_precision)
  discard mpfr_set_d(x, v.cdouble, mpfr_rand)
proc init_val(x: mpfr_t, v: string) =
  mpfr_init2(x, mpfr_precision)
  discard mpfr_set_str(x, v.cstring, 10, mpfr_rand)

proc is_init*(x: mpfr): bool = x.mpfr_prec != 0
proc reset*(x: var mpfr) = x.mpfr_prec = 0
proc is_notinit*(x: mpfr): bool = x.mpfr_prec == 0

proc with_val*(x: mpfr, value: float = 0.0): mpfr = discard mpfr_set_d(x,
    value.cdouble, mpfr_rand)
proc set*(x: var mpfr, y: mpfr) = discard mpfr_set(x, y, mpfr_rand)
proc zero*(x: var mpfr) = mpfr_set_zero(x) # x=0
proc swap*(x, y: mpfr) = mpfr_swap(x, y)
proc `:=`*(x: var mpfr, y: mpfr) = discard mpfr_set(x, y, mpfr_rand)

proc newMpfr*(): mpfr = init_val(result, 0.0)

proc `=destroy`(x: var mpfr) =
  if x.is_init(): mpfr_clear(x)
  else: discard # raise "attempt destroy not init!"

proc `=copy`(a: var mpfr, b: mpfr) =
  if a.mpfr_d == b.mpfr_d or b.is_notinit(): return # do nothing if (a==b or b.not_init)
  if a.is_notinit(): a = newMpfr()
  a.set b

proc newMpfr*(value: string): mpfr = init_val(result, value)
proc newMpfr*(value: float): mpfr = init_val(result, value)
proc newMpfr*(x: mpfr): mpfr = result = x

proc set_prec*(x: var mpfr, prec: int) = mpfr_set_prec(x, prec.mpfr_prec_t)

proc get_exp_range*: (int, int) = (mpfr_get_emin().int, mpfr_get_emax().int)

converter itom*(i: int): mpfr = result = newMpfr(); discard mpfr_set_ui(result,
    i.culong, mpfr_rand)
converter ftom*(f: float): mpfr = result = newMpfr(); discard mpfr_set_d(result,
    f.cdouble, mpfr_rand)
converter stom*(s: string): mpfr = result = newMpfr(); discard mpfr_set_str(
    result, s.cstring, 10, mpfr_rand)
converter mtof*(x: mpfr): float = mpfr_get_d(x, mpfr_rand).float
converter mtof32*(x: mpfr): float32 = mpfr_get_flt(x, mpfr_rand).float32

proc `$`*(x: mpfr): string =
  if x.is_init():
    var
      str: array[1024, char]
      exp: mpfr_exp_t

    discard mpfr_get_str(str.unsafeAddr, exp.unsafeAddr, 10.cint,
        mpfr_digits.csize_t, x, mpfr_rand)
    for i, c in str: result.add(c)
    result.insert("0.", 0)
    result &= "e" & $exp
  else:
    result = "**not init**"

proc dump*(x: mpfr) =
  echo "prec:", x.mpfr_prec, ", sign:", x.mpfr_sign, ", exp:", x.mpfr_exp,
      ", limb:", x.mpfr_d

# custom
proc cinit*(x: var mpfr) =
  let p = alloc0(mpfr_custom_get_size(mpfr_precision))
  mpfr_custom_init(p, mpfr_precision)
  mpfr_custom_init_set(x, MPFR_ZERO_KIND, 0, mpfr_precision, p)

proc cfree*(x: var mpfr) =
  x.reset # so it's not destroyed
  dealloc(mpfr_custom_get_significand(x))


# arithmetics
proc `+`*(x, y: mpfr): mpfr = result = newMpfr(); discard mpfr_add(result, x, y, mpfr_rand)
proc `-`*(x, y: mpfr): mpfr = result = newMpfr(); discard mpfr_sub(result, x, y, mpfr_rand)
proc `-`*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_neg(result, x, mpfr_rand)
proc `*`*(x, y: mpfr): mpfr = result = newMpfr(); discard mpfr_mul(result, x, y, mpfr_rand)
proc `/`*(x, y: mpfr): mpfr = result = newMpfr(); discard mpfr_div(result, x, y, mpfr_rand)

proc `+`*(x: mpfr, y: float): mpfr =
  result = newMpfr(); discard mpfr_add_d(result, x, y, mpfr_rand)
proc `-`*(x: mpfr, y: float): mpfr =
  result = newMpfr(); discard mpfr_sub_d(result, x, y, mpfr_rand)
proc `*`*(x: mpfr, y: float): mpfr =
  result = newMpfr(); discard mpfr_mul_d(result, x, y, mpfr_rand)
proc `/`*(x: mpfr, y: float): mpfr =
  result = newMpfr(); discard mpfr_div_d(result, x, y, mpfr_rand)

proc `+`*(x: mpfr, y: string): mpfr =
  result = newMpfr(); discard mpfr_add(result, x, y.stom, mpfr_rand)
proc `-`*(x: mpfr, y: string): mpfr =
  result = newMpfr(); discard mpfr_sub(result, x, y.stom, mpfr_rand)
proc `*`*(x: mpfr, y: string): mpfr =
  result = newMpfr(); discard mpfr_mul(result, x, y.stom, mpfr_rand)
proc `/`*(x: mpfr, y: string): mpfr =
  result = newMpfr(); discard mpfr_div(result, x, y.stom, mpfr_rand)

proc `+=`*(x: var mpfr, y: mpfr) = discard mpfr_add(x, x, y, mpfr_rand)
proc `-=`*(x: var mpfr, y: mpfr) = discard mpfr_sub(x, x, y, mpfr_rand)
proc `*=`*(x: var mpfr, y: mpfr) = discard mpfr_mul(x, x, y, mpfr_rand)
proc `/=`*(x: var mpfr, y: mpfr) = discard mpfr_div(x, x, y, mpfr_rand)

proc `+=`*(x: var mpfr, y: float) = discard mpfr_add_d(x, x, y, mpfr_rand)
proc `-=`*(x: var mpfr, y: float) = discard mpfr_sub_d(x, x, y, mpfr_rand)
proc `*=`*(x: var mpfr, y: float) = discard mpfr_mul_d(x, x, y, mpfr_rand)
proc `/=`*(x: var mpfr, y: float) = discard mpfr_div_d(x, x, y, mpfr_rand)

proc `+=`*(x: var mpfr, y: string) = discard mpfr_add(x, x, y.stom, mpfr_rand)
proc `-=`*(x: var mpfr, y: string) = discard mpfr_sub(x, x, y.stom, mpfr_rand)
proc `*=`*(x: var mpfr, y: string) = discard mpfr_mul(x, x, y.stom, mpfr_rand)
proc `/=`*(x: var mpfr, y: string) = discard mpfr_div(x, x, y.stom, mpfr_rand)

# comparision
proc `==`*(x, y: mpfr): bool = mpfr_cmp(x, y) == 0
proc `!=`*(x, y: mpfr): bool = mpfr_cmp(x, y) != 0
proc `>=`*(x, y: mpfr): bool = mpfr_cmp(x, y) >= 0
proc `<=`*(x, y: mpfr): bool = mpfr_cmp(x, y) <= 0
proc `>`*(x, y: mpfr): bool = mpfr_cmp(x, y) > 0
proc `<`*(x, y: mpfr): bool = mpfr_cmp(x, y) < 0
proc cmp*(x, y: mpfr): int = mpfr_cmp(x, y).int

proc `==`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) == 0
proc `!=`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) != 0
proc `>=`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) >= 0
proc `<=`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) <= 0
proc `>`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) > 0
proc `<`*(x: mpfr, y: float): bool = mpfr_cmp_d(x, y) < 0

proc `==`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) == 0
proc `!=`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) != 0
proc `>=`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) >= 0
proc `<=`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) <= 0
proc `>`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) > 0
proc `<`*(x: mpfr, y: string): bool = mpfr_cmp(x, y.stom) < 0

# funcs
proc `!`*(n: uint): mpfr =
  result = newMpfr(); discard mpfr_fac_ui(result, n.culong, mpfr_rand)
proc sqrt*(x: mpfr): mpfr =
  result = newMpfr(); discard mpfr_sqrt(result, x, mpfr_rand)
proc root*(x: mpfr, n: int): mpfr =
  result = newMpfr(); discard mpfr_rootn_ui(result, x, n.culong, mpfr_rand)
proc atan2*(y, x: mpfr): mpfr = result = newMpfr(); discard mpfr_atan2(result,
    x, y, mpfr_rand)
proc pow*(x, y: mpfr): mpfr = result = newMpfr(); discard mpfr_pow(result, x, y, mpfr_rand)
proc sin*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_sin(result, x, mpfr_rand)
proc sinh*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_sinh(result, x, mpfr_rand)
proc cos*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_cos(result, x, mpfr_rand)
proc cosh*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_cosh(result, x, mpfr_rand)
proc tan*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_tan(result, x, mpfr_rand)
proc log*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_log(result, x, mpfr_rand)
proc exp*(x: mpfr): mpfr = result = newMpfr(); discard mpfr_exp(result, x, mpfr_rand)
proc sign*(x: mpfr): cint = mpfr_signbit(x)

# consts
proc log2*(): mpfr = result = newMpfr(); discard mpfr_const_log2(result, mpfr_rand)
proc e*(): mpfr = result = newMpfr(); discard mpfr_const_euler(result, mpfr_rand)
proc catalan*(): mpfr = result = newMpfr(); discard mpfr_const_catalan(result, mpfr_rand)
proc pi*(): mpfr = result = newMpfr(); discard mpfr_const_pi(result, mpfr_rand)


## complex
type cmpfr* = object # complex mpfr
  re*, im*: mpfr

proc newCmpfr*(): cmpfr = cmpfr(re: newMpfr(), im: newMpfr())
proc newCmpfr*(re, im: mpfr): cmpfr = result = cmpfr(re: re, im: im)
proc newCmpfr*(z: cmpfr): cmpfr = newCmpfr(z.re, z.im)

proc dump*(z: cmpfr) =
  z.re.dump()
  z.im.dump()

proc arg*(z: cmpfr): mpfr = atan2(z.im, z.re)
proc sqmag*(z: cmpfr): mpfr = z.re*z.re + z.im*z.im
proc abs2*(z: cmpfr): mpfr = z.sqmag
proc abs*(z: cmpfr): mpfr = z.sqmag.sqrt

proc `+`*(x, y: cmpfr): cmpfr = cmpfr(re: x.re + y.re, im: x.im + y.im)
proc `-`*(x, y: cmpfr): cmpfr = cmpfr(re: x.re - y.re, im: x.im - y.im)
proc `-`*(x: cmpfr): cmpfr = cmpfr(re: -x.re, im: -x.im)
proc `*`*(x, y: cmpfr): cmpfr = cmpfr(re: x.re*y.re - x.im*y.im, im: x.re*y.im + x.im*y.re)
proc `/`*(x, y: cmpfr): cmpfr =
  let d = (y.re*y.re) + (y.im*y.im)
  result.re = (x.re*y.re)+(x.im*y.im)
  result.re/=d
  result.im = (x.im*y.re)-(x.re*y.im)
  result.im/=d

proc `+`*(x: cmpfr, y: float): cmpfr = cmpfr(re: x.re + y, im: x.im + y)
proc `-`*(x: cmpfr, y: float): cmpfr = cmpfr(re: x.re - y, im: x.im - y)
proc `*`*(x: cmpfr, y: float): cmpfr = cmpfr(re: x.re * y, im: x.im * y)
proc `/`*(x: cmpfr, y: float): cmpfr = cmpfr(re: x.re / y, im: x.im / y)

proc `+=`*(x: var cmpfr, y: cmpfr) = x = x+y
proc `-=`*(x: var cmpfr, y: cmpfr) = x = x-y
proc `*=`*(x: var cmpfr, y: cmpfr) = x = x*y
proc `/=`*(x: var cmpfr, y: cmpfr) = x = x/y

proc `+=`*(x: var cmpfr, y: float) = x.re+=y; x.im+=y
proc `-=`*(x: var cmpfr, y: float) = x.re-=y; x.im-=y
proc `*=`*(x: var cmpfr, y: float) = x.re*=y; x.im*=y
proc `/=`*(x: var cmpfr, y: float) = x.re/=y; x.im/=y

proc sqr*(z: cmpfr): cmpfr = z*z
proc pow3*(z: cmpfr): cmpfr = z*z*z
proc pow4*(z: cmpfr): cmpfr = z*z*z*z
proc pow5*(z: cmpfr): cmpfr = z*z*z*z*z
proc pown*(z: cmpfr, n: int): cmpfr =
  result = z
  for i in 1..n: result*=z

proc pow*(z: cmpfr, n: int): cmpfr =
  let
    rn = z.abs().pow(n)
    na = z.arg() * n.itom
  cmpfr(re: rn * cos(na), im: rn * sin(na))

proc pow*(s, z: cmpfr): cmpfr = # s^z
  let
    c = z.re
    d = z.im
    m = pow(s.sqmag, c/2.0) * exp(-d * s.arg)

  result = cmpfr(re: m * cos(c * s.arg + 0.5 * d * log(s.sqmag)), im: m * sin(
      c * s.arg + 0.5 * d * log(s.sqmag)))

proc sqrt*(z: cmpfr): cmpfr =
  let a = z.abs()
  cmpfr(re: sqrt((a+z.re)/2.0), im: sqrt((a-z.re)/2.0) * sign(z.im).float)

proc log*(z: cmpfr): cmpfr = cmpfr(re: z.abs.log, im: z.arg)
proc exp*(z: cmpfr): cmpfr = cmpfr(re: E, im: 0.0).pow(z)

proc cosh*(z: cmpfr): cmpfr = cmpfr(re: cosh(z.re) * cos(z.im), im: sinh(z.re) * sin(z.im))
proc sinh*(z: cmpfr): cmpfr = cmpfr(re: sinh(z.re) * cos(z.im), im: cosh(z.re) * sin(z.im))
proc sin*(z: cmpfr): cmpfr = cmpfr(re: sin(z.re) * cosh(z.im), im: cos(z.re) *
    sinh(z.im))
proc cos*(z: cmpfr): cmpfr = cmpfr(re: cos(z.re) * cosh(z.im), im: -sin(z.re) *
    sinh(z.im))
proc tan*(z: cmpfr): cmpfr = z.sin()/z.cos()

proc asinh*(z: cmpfr): cmpfr =
  let t = cmpfr(re: (z.re-z.im) * (z.re+z.im)+1.0, im: 2.0*z.re*z.im).sqrt
  (t + z).log

proc asin*(z: cmpfr): cmpfr =
  let t = cmpfr(re: -z.im, im: z.re).asinh
  cmpfr(re: t.im, im: -t.re)

proc acos*(z: cmpfr): cmpfr =
  let
    t = z.asin()
    pi_2 = 1.7514
  cmpfr(re: pi_2 - t.re, im: -t.im)

proc atan*(z: cmpfr): cmpfr =
  cmpfr(
    re: 0.50 * atan2(2.0*z.re, 1.0 - z.re*z.re - z.im*z.im),
    im: 0.25 * log((z.re*z.re + (z.im+1.0)*(z.im+1.0)) / (z.re*z.re + (
        z.im-1.0)*(z.im-1.0)))
  )

# test

when isMainModule:
  proc test_mpfr =
    echo "testing mpfr"

    var
      x1 = newMpfr(123.0)
      x2 = newMpfr("345.67e3456")
      xx1 = newMpfr(x1)

    echo "x1=", x1, ", x2=", x2
    x1 = "123.456"
    let x11 = x1+x2
    echo x11
    var x3 = newMpfr()

    let xxx4 = x1+x2.cos.tan
    echo xxx4
    for i in 0..10000: x3 = x1.sin.cos.tan

    echo "x3=", $x3, ", x1=", $x1
    echo x1+x3-x2*x1/x3

    var
      x4 = x1*x1
      x5 = x1*x1*x1*x1

    echo x1, ",", x4.sqrt, ",", x5.root(4)

    # factorials
    for i in 0..4000000:
      if i %% 500000 == 0:
        echo i, "! = ", !i.uint

    x1 = 1
    var i = 0

    while x1 > "1e-45000":
      i.inc
      x1 /= 1.2e90
      if i %% 100 == 0: echo i, ":", x1

  import times, complex, sugar

  proc test_cmpfr =

    var
      c0 = newCmpfr(1, 0)
      z = newCmpfr(c0)
      zv = newSeq[cmpfr](100)

    # init all items in vect, notice that z=c0 will not work
    for z in zv.mitems: z = newCmpfr(c0)

    let zzv = collect(newSeq):
      for i in 0..100:
        newCmpfr(z)
    for zz in zzv: z+=zz
    echo "z=", z
    z = c0

    c0+=123.67
    let n = 500
    echo "generating mpfr ", n*n, " iters, @", mpfr_precision, " bit precision"

    var t0 = now()
    for i in 0..n*n: # simulate mandelbrot fractal generation
      z = c0
      for it in 0..200:
        z = z*z+c0
        if z.abs > 4.0: break
    echo z
    echo "lap mpfr:", (now()-t0).inMilliseconds, "ms"

    var
      dz = complex64(1, 0)
      dc0 = dz

    dc0 += complex64(123.67, 123.67)

    t0 = now()
    for i in 0..n*n:
      dz = dc0
      for it in 0..200:
        dz = dz*dz+dc0
        if dz.abs > 4.0: break
    echo dz
    echo "lap complex 64:", (now()-t0).inMilliseconds, "ms"

  proc test_cmpfr_init =
    var z, z0: cmpfr # not init

    for i in 0..100000: z = z0 # ok, but does nothing
    z = z0 # same

    echo z, z0 # not init

    for i in 0..100000: z0 = newCmpfr(1.0, 2.0)
    z0 = newCmpfr(1.0, 2.0)
    for i in 0..1000: z = z0.sin.cos.tan.acos.asin.asinh
    for i in 0..100000: z+=z0+z0
    echo z, z0


  proc test_mpfr_init =
    var
      x0 = newMpfr(0.0)
      x = newMpfr(1.0)
      xx, xx0, xx1: mpfr

    x0 = x # both init: ok
    xx = xx0 # xx0 not init: ok, but do nothing
    xx = x # xx not init: ok

    echo "x=", x, ", x0=", x0, ", xx=", xx

    xx = xx0
    echo xx

    for i in 0..100: xx = x0
    xx = x0

    echo xx, xx0, xx1

    echo "pi=", pi(), ", e=", e(), ", catalan=", catalan(), ", log2=", log2()

    echo "end"

  import strutils
  proc test_custom =

    echo "need ", mpfr_custom_get_size(mpfr_precision), " bytes, for a ",
        mpfr_precision, " bit precision"
    var x, y, z: mpfr

    echo "before init, x is init:", x.is_init

    cinit(x)
    cinit(y)

    echo "after cust init x is init:", x.is_init
    x := pi()*200.0 # set not =copy
    y := 678.89

    x+=y
    z = x # z is not custom so it can be assigned

    echo "z=", z, ", z==x:", z == x
    echo "x=", x, ", y=", y, ", kind=", mpfr_custom_get_kind(x), ", pointer=",
        cast[uint](mpfr_custom_get_significand(x)).toHex

    cfree(x)
    cfree(y)

  echo "-------------------- mpfr test"
  test_custom()
  test_mpfr()
  test_mpfr_init()
  test_cmpfr()
  test_cmpfr_init()

  echo "-------------------- ok"
