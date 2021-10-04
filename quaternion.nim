# Quaternion
import math, complex

type Quaternion*[T: SomeFloat] = object
  r, i, j, k: T

const
  qZero* = Quaternion[float](r: 0.0, i: 0.0, j: 0.0, k: 0.0)
  qOne* = Quaternion[float](r: 1.0, i: 0.0, j: 0.0, k: 0.0)
  qI* = Quaternion[float](r: 0.0, i: 1.0, j: 0.0, k: 0.0)
  qJ* = Quaternion[float](r: 0.0, i: 0.0, j: 1.0, k: 0.0)
  qK* = Quaternion[float](r: 0.0, i: 0.0, j: 0.0, k: 1.0)

{.push checks: off, line_dir: off, stack_trace: off, debugger: off, inline:on.}

# constructors
proc newQ*[T: SomeFloat](): Quaternion[T] = Quaternion[T](r: 0.0, i: 0.0,
    j: 0.0, k: 0.0)
proc newQ*[T: SomeFloat](r: T): Quaternion[T] = Quaternion[T](r: r, i: 0.0,
    j: 0.0, k: 0.0)
proc newQ*[T: SomeFloat](r, i, j, k: T): Quaternion[T] = Quaternion[T](r: r,
    i: i, j: j, k: k)

# arithmetic operators
proc `+`*[T: SomeFloat](s, q: Quaternion[T]): Quaternion[T] = newQ(s.r + q.r,
    s.i + q.i, s.j + q.j, s.k + q.k)
proc `-`*[T: SomeFloat](s, q: Quaternion[T]): Quaternion[T] = newQ(s.r - q.r,
    s.i - q.i, s.j - q.j, s.k - q.k)
proc `*`*[T: SomeFloat](s, q: Quaternion[T]): Quaternion[T] =
  let
    RE = s.r
    I = s.i
    J = s.j

  newQ(RE*q.r - I*q.i - J*q.j - s.k*q.k,
        RE*q.i + I*q.r + J*q.k - s.k*q.j,
        RE*q.j - I*q.k + J*q.r + s.k*q.i,
        RE*q.k + I*q.j - J*q.i + s.k*q.r)

proc `/`*[T: SomeFloat](s, q: var Quaternion[T]) =
  let
    denom = q.norm()
    RE = s.r
    I = s.i
    J = s.j

  newQ( (RE*q.r + I*q.i + J*q.j + s.k*q.k)/denom,
        (-RE*q.i + I*q.r - J*q.k + s.k*q.j)/denom,
        (-RE*q.j + I*q.k + J*q.r - s.k*q.i)/denom,
        (-RE*q.k - I*q.j + J*q.i + s.k*q.r)/denom)

proc `+=`*[T: SomeFloat](s: var Quaternion[T], r: T) = s.r += r
proc `-=`*[T: SomeFloat](s: var Quaternion[T], r: T) = s.r -= r
proc `*=`*[T: SomeFloat](s: var Quaternion[T], r: T) =
  s.r *= r
  s.i *= r
  s.j *= r
  s.k *= r
proc `/=`*[T: SomeFloat](s: var Quaternion[T], r: T) =
  s.r /= r
  s.i /= r
  s.j /= r
  s.k /= r
proc inc*[T: SomeFloat](s: var Quaternion) = s.r.inc
proc dec*[T: SomeFloat](s: var Quaternion) = s.r.dec

proc `+=`*[T: SomeFloat](s: var Quaternion[T], q: Quaternion[T]) =
  s.r += q.r
  s.i += q.i
  s.j += q.j
  s.k += q.k

proc `-=`*[T: SomeFloat](s: var Quaternion[T], q: Quaternion[T]) =
  s.r += q.r
  s.i += q.i
  s.j += q.j
  s.k += q.k

proc `*=`*[T: SomeFloat](s: var Quaternion[T], q: Quaternion[T]) =
  let
    RE = s.r
    I = s.i
    J = s.j

  s.r = RE*q.r - I*q.i - J*q.j - s.k*q.k
  s.i = RE*q.i + I*q.r + J*q.k - s.k*q.j
  s.j = RE*q.j - I*q.k + J*q.r + s.k*q.i
  s.k = RE*q.k + I*q.j - J*q.i + s.k*q.r

proc `/=`*[T: SomeFloat](s: var Quaternion[T], q: Quaternion[T]) =
  let
    denom = q.norm()
    RE = s.r
    I = s.i
    J = s.j

  s.r = (RE*q.r + I*q.i + J*q.j + s.k*q.k)/denom
  s.i = (-RE*q.i + I*q.r - J*q.k + s.k*q.j)/denom
  s.j = (-RE*q.j + I*q.k + J*q.r - s.k*q.i)/denom
  s.k = (-RE*q.k - I*q.j + J*q.i + s.k*q.r)/denom

# comparisions
proc `==`*[T: SomeFloat](s, q: Quaternion[T]): bool = s.r == q.r and s.i ==
    q.i and s.j == q.j and s.k == q.k
proc `!=`*[T: SomeFloat](s, q: Quaternion[T]): bool = s.r != q.r or s.i !=
    q.i or s.j != q.j or s.k == q.k

# func template
template qfunc(q, qf: untyped): untyped =
  let
    absIm = q.abs_imag()
    z = complex(q.r, absIm).qf
    mltplr = if absIm == 0.0: z.im else: z.im / absIm
  q.multiplier(z.re, mltplr)

template qfunc1(q, qf, x: untyped): untyped =
  let
    absIm = q.abs_imag()
    z = complex(q.r, absIm).qf(x)
    mltplr = if absIm == 0.0: z.im else: z.im / absIm
  q.multiplier(z.re, mltplr)

# funcs
proc multiplier*[T: SomeFloat](q: Quaternion[T], r, mltplr: T): Quaternion[
    T] = newQ[T](r, mltplr*q.i, mltplr*q.j, mltplr*q.k)
proc norm*[T: SomeFloat](q: Quaternion[T]): T = q.r*q.r + q.i*q.i + q.j*q.j + q.k*q.k
proc real*[T: SomeFloat](q: Quaternion[T]): T = q.r
proc abs2*[T: SomeFloat](q: Quaternion[T]): T = q.norm
proc abs*[T: SomeFloat](q: Quaternion[T]): T = q.norm.sqrt
proc abs_imag*[T: SomeFloat](q: Quaternion[T]): T = (q.i*q.i + q.j*q.j + q.k*q.k).sqrt
proc norm_imag*[T: SomeFloat](q: Quaternion[T]): T = q.i*q.i + q.j*q.j + q.k*q.k
proc arg*[T: SomeFloat](q: Quaternion[T]): T = arctan2(q.abs_imag, q.r)
proc imag*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = newQ[T](0.0, q.i, q.j, q.k)
proc conj*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = newQ[T](q.r, -q.i,
    -q.j, -q.k)
proc signum*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] =
  let absq = q.abs
  Quaternion[T](q.r/absq, q.i/absq, q.j/absq, q.k/absq)
proc sqr*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = newQ[T](q.r*q.r -
    q.i*q.i - q.j*q.j - q.k*q.k, 2*q.r*q.i, 2*q.r*q.j, 2*q.r*q.k)
proc sqrt*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q,sqrt)
proc rotate*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] =
  # the assumption is that |q| = 1
  # in this case, q.inverse() == q.conj()

  let
    rr = q.r*q.r
    ii = q.i*q.i
    jj = q.j*q.j
    kk = q.k*q.k

    ri = q.r*q.i
    ij = q.i*q.j
    ik = q.i*q.k

    rj = q.r*q.j
    jk = q.j*q.k

    rk = q.r*q.k

  newQ[T](
    (if q.r == 0: q.r else: q.r*(rr + ii + jj + kk)),
    q.i*(rr + ii - jj - kk) + 2*(q.j*(-rk + ij) + q.k*(rj + ik)),
    q.j*(rr - ii + jj - kk) + 2*(q.i*(rk + ij) + q.k*(-ri + jk)),
    q.k*(rr - ii - jj + kk) + 2*(q.i*(-rj + ik) + q.j*(ri + jk))
  )

proc is_imag*[T: SomeFloat](q: Quaternion[T]): bool = q.r == 0.0
proc is_real*[T: SomeFloat](q: Quaternion[T]): bool = q.i == 0.0 and q.j ==
    0.0 and q.k == 0.0
proc is_zero*[T: SomeFloat](q: Quaternion[T]): bool = q.r == 0.0 and q.i ==
    0.0 and q.j == 0.0 and q.k == 0.0

# trascendentals
proc exp*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, exp)
proc log*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, ln)
proc log10*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, log10)
proc pow*[T: SomeFloat](s, q: Quaternion[T]): Quaternion[T] = (s.log * q).exp
proc pow*[T: SomeFloat](q: Quaternion[T], r: T): Quaternion[T] = qfunc1(q, pow, r)

# trigs
proc sin*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, sin)
proc cos*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, cos)
proc tan*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, tan)
proc sec*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, sec)
proc csc*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, csc)
proc cot*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, cot)
proc sinh*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, sinh)
proc cosh*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, cosh)
proc tanh*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, tanh)
proc sech*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, sech)
proc csch*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, csch)
proc coth*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, coth)
proc asin*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, arcsin)
proc acos*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, arccos)
proc atan*[T: SomeFloat](q: Quaternion[T]): Quaternion[T] = qfunc(q, arctan)

{.pop.}

#################
when isMainModule:
  var
    q = newQ[float](12.0)
    q1 = newQ[float](1.0, 2.0, 3.0, 4.0)
    q2 = qOne

  q += q1
  q1*=q
  q/=q1+q2
  echo q==q1, q!=q1
  echo q, q1, q.abs, q1.sqrt.sqr, q.rotate, q.exp.log.pow(q), q1.sec
  echo q.atan

  for i in 0..100000:  q+=q1
  echo q.log.sin.cos.tan.asin.acos.atan
