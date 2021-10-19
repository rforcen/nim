MODULE Solve_Real_Poly
! CACM Algorithm 493 by Jenkins & Traub

! Compliments of netlib   Sat Jul 26 11:57:43 EDT 1986
 
! Code converted using TO_F90 by Alan Miller
! Date: 2003-06-02  Time: 10:42:22
use iso_fortran_env, only:  int8, int16, int32, int64, real32, real64, real128, &
input_unit, output_unit, error_unit

IMPLICIT NONE

integer, parameter :: dp        = real64

! COMMON /global/ p, qp, k, qk, svk, sr, si, u, v, a, b, c, d, a1,  &
!    a2, a3, a6, a7, e, f, g, h, szr, szi, lzr, lzi, eta, are, mre, n, nn

real (dp), ALLOCATABLE, SAVE  :: p(:), qp(:), k(:), qk(:), svk(:)
real (dp), SAVE               :: sr, si, u, v, a, b, c, d, a1, a3,  &
                                 a7, e, f, g, h, szr, szi, lzr, lzi
real, SAVE                    :: eta, are, mre
integer, SAVE                 :: n, nn

PRIVATE
PUBLIC  :: dp, rpoly


CONTAINS
! c call: 
! extern void __solve_real_poly_MOD_rpoly(double op[], int *degree, double *zeror, double *zeroi, int *fail);

subroutine rpoly(op, degree, zeror, zeroi, fail)

! Finds the zeros of a real polynomial
! op  - double precision vector of coefficients in order of
!       decreasing powers.
! degree   - integer degree of polynomial.
! zeror, zeroi - output double precision vectors of real and imaginary parts
!                of the zeros.
! fail  - output logical parameter, true only if leading coefficient is zero
!         or if rpoly has found fewer than degree zeros.
!         In the latter case degree is reset to the number of zeros found.

! To change the size of polynomials which can be solved, reset the dimensions
! of the arrays in the common area and in the following declarations.
! The subroutine uses single precision calculations for scaling, bounds and
! error calculations.  All calculations for the iterations are done in
! double precision.


real (dp), intent(IN)    :: op(degree)
integer, intent(IN OUT)  :: degree
real (dp), intent(OUT)   :: zeror(degree), zeroi(degree)
logical, intent(OUT)     :: fail

real (dp), ALLOCATABLE   :: temp(:)
real, ALLOCATABLE        :: pt(:)

real (dp) :: t, aa, bb, cc, factor
real (dp) :: lo, MAX, MIN, xx, yy, cosr, sinr, xxx, x, sc, bnd,  &
             xm, ff, df, dx, infin, smalno, base
integer   :: cnt, nz, i, j, jj, l, nm1
logical   :: zerok

! The following statements set machine constants used in various parts of the
! program.  The meaning of the four constants are...
! eta     the maximum relative representation error which can be described
!         as the smallest positive floating point number such that
!         1.d0+eta is greater than 1.
! infiny  the largest floating-point number.
! smalno  the smallest positive floating-point number if the exponent range
!         differs in single and real (dp) then smalno and infin should
!         indicate the smaller range.
! base    the base of the floating-point number system used.

! write(*, '(2g23.15)') (op(i), i=1,degree)

base = RADIX(0.0)
eta = EPSILON(1.0)
infin = HUGE(0.0)
smalno = TINY(0.0)

! write (*,*) base, eta, infin, smalno

! are and mre refer to the unit error in + and * respectively.
! They are assumed to be the same as eta.
are = eta
mre = eta
lo = smalno / eta

! Initialization of constants for shift rotation
xx = SQRT(0.5)
yy = -xx
cosr = -.069756474
sinr = .99756405
fail = .false.
n = degree
nn = n + 1

! Algorithm fails if the leading coefficient is zero.
if (op(1) == 0.d0) then
  fail = .true.
  degree = 0
  return
end if

! Remove the zeros at the origin if any
10 if (op(nn) == 0.0D0) then
  j = degree - n + 1
  zeror(j) = 0.d0
  zeroi(j) = 0.d0
  nn = nn - 1
  n = n - 1
  go to 10
end if

! Allocate various arrays

if (ALLOCATED(p)) DEALLOCATE(p, qp, k, qk, svk)
ALLOCATE( p(nn), qp(nn), k(nn), qk(nn), svk(nn), temp(nn), pt(nn) )

! Make a copy of the coefficients
p(1:nn) = op(1:nn)

! Start the algorithm for one zero
30 if (n <= 2) then
  if (n < 1) return

! calculate the final zero or pair of zeros
  if (n /= 2) then
    zeror(degree) = -p(2) / p(1)
    zeroi(degree) = 0.0D0
    return
  end if
  call quad(p(1), p(2), p(3), zeror(degree-1), zeroi(degree-1),  &
            zeror(degree), zeroi(degree))
  return
end if

! Find largest and smallest moduli of coefficients.
MAX = 0.
MIN = infin
do  i = 1, nn
  x = abs( real(p(i)) )
  if (x > MAX) MAX = x
  if (x /= 0. .and. x < MIN) MIN = x
end do

! Scale if there are large or very small coefficients computes a scale
! factor to multiply the coefficients of the polynomial.
! The scaling is done to avoid overflow and to avoid undetected underflow
! interfering with the convergence criterion.
! The factor is a power of the base
sc = lo / MIN
if (sc <= 1.0) then
  if (MAX < 10.) go to 60
  if (sc == 0.) sc = smalno
else
  if (infin/sc < MAX) go to 60
end if
l = int(LOG(sc) / LOG(base) + .5)
factor = (base*1.0D0) ** l
if (factor /= 1.d0) then
  p(1:nn) = factor * p(1:nn)
end if

! compute lower bound on moduli of zeros.
60 pt(1:nn) = real(abs(p(1:nn)))
pt(nn) = -pt(nn)

! compute upper estimate of bound
x = EXP((LOG(-pt(nn)) - LOG(pt(1))) / n)
if (pt(n) /= 0.) then
! if newton step at the origin is better, use it.
  xm = -pt(nn) / pt(n)
  if (xm < x) x = xm
end if

! chop the interval (0,x) until ff .le. 0
80 xm = x * .1
ff = pt(1)
do  i = 2, nn
  ff = ff * xm + pt(i)
end do
if (ff > 0.) then
  x = xm
  go to 80
end if
dx = x

! do newton iteration until x converges to two decimal places
100 if (abs(dx/x) > .005) then
  ff = pt(1)
  df = ff
  do  i = 2, n
    ff = ff * x + pt(i)
    df = df * x + ff
  end do
  ff = ff * x + pt(nn)
  dx = ff / df
  x = x - dx
  go to 100
end if
bnd = x

! compute the derivative as the intial k polynomial
! and do 5 steps with no shift
nm1 = n - 1
do  i = 2, n
  k(i) = (nn-i) * p(i) / n
end do
k(1) = p(1)
aa = p(nn)
bb = p(n)
zerok = k(n) == 0.d0
do  jj = 1, 5
  cc = k(n)
  if (.not.zerok) then
! use scaled form of recurrence if value of k at 0 is nonzero
    t = -aa / cc
    do  i = 1, nm1
      j = nn - i
      k(j) = t * k(j-1) + p(j)
    end do
    k(1) = p(1)
    zerok = abs(k(n)) <= abs(bb) * eta * 10.
  else
! use unscaled form of recurrence
    do  i = 1, nm1
      j = nn - i
      k(j) = k(j-1)
    end do
    k(1) = 0.d0
    zerok = k(n) == 0.d0
  end if
end do

! save k for restarts with new shifts
temp(1:n) = k(1:n)

! loop to select the quadratic  corresponding to each
! new shift
do  cnt = 1, 20
! Quadratic corresponds to a double shift to a non-real point and its complex
! conjugate.  The point has modulus bnd and amplitude rotated by 94 degrees
! from the previous shift
  xxx = cosr * xx - sinr * yy
  yy = sinr * xx + cosr * yy
  xx = xxx
  sr = bnd * xx
  si = bnd * yy
  u = -2.0D0 * sr
  v = bnd

! second stage calculation, fixed quadratic
  call fxshfr(20*cnt,nz)
  if (nz /= 0) then

! The second stage jumps directly to one of the third stage iterations and
! returns here if successful.
! Deflate the polynomial, store the zero or zeros and return to the main
! algorithm.
    j = degree - n + 1
    zeror(j) = szr
    zeroi(j) = szi
    nn = nn - nz
    n = nn - 1
    p(1:nn) = qp(1:nn)
    if (nz == 1) go to 30
    zeror(j+1) = lzr
    zeroi(j+1) = lzi
    go to 30
  end if

! If the iteration is unsuccessful another quadratic
! is chosen after restoring k
  k(1:nn) = temp(1:nn)
end do

! return with failure if no convergence with 20 shifts
fail = .true.
degree = degree - n
return
end subroutine rpoly


subroutine fxshfr(l2, nz)

! Computes up to  l2  fixed shift k-polynomials, testing for convergence in
! the linear or quadratic case.  Initiates one of the variable shift
! iterations and returns with the number of zeros found.
! l2 - limit of fixed shift steps
! nz - number of zeros found

integer, intent(IN)   :: l2
integer, intent(OUT)  :: nz

real (dp) :: svu, svv, ui, vi, s
real      :: betas, betav, oss, ovv, ss, vv, ts, tv, ots, otv, tvv, tss
integer   :: TYPE, j, iflag
logical   :: vpass, spass, vtry, stry

nz = 0
betav = .25
betas = .25
oss = real(sr)
ovv = real(v)

! Evaluate polynomial by synthetic division
call quadsd(nn, u, v, p, qp, a, b)
call calcsc(TYPE)
do  j = 1, l2
! calculate next k polynomial and estimate v
  call nextk(TYPE)
  call calcsc(TYPE)
  call newest(TYPE, ui, vi)
  vv = real(vi)

! Estimate s
  ss = 0.
  if (k(n) /= 0.d0) ss = real(-p(nn) / k(n))
  tv = 1.
  ts = 1.
  if (j /= 1 .and. TYPE /= 3) then
! Compute relative measures of convergence of s and v sequences
    if (vv /= 0.) tv = abs((vv-ovv)/vv)
    if (ss /= 0.) ts = abs((ss-oss)/ss)

! If decreasing, multiply two most recent convergence measures
    tvv = 1.
    if (tv < otv) tvv = tv * otv
    tss = 1.
    if (ts < ots) tss = ts * ots

! Compare with convergence criteria
    vpass = tvv < betav
    spass = tss < betas
    if (spass .or. vpass) then

! At least one sequence has passed the convergence test.
! Store variables before iterating
      svu = u
      svv = v
      svk(1:n) = k(1:n)
      s = ss

! Choose iteration according to the fastest converging sequence
      vtry = .false.
      stry = .false.
      if (spass .and. ((.not.vpass) .or. tss < tvv)) go to 40
      20 call quadit(ui, vi, nz)
      if (nz > 0) return

! Quadratic iteration has failed. flag that it has
! been tried and decrease the convergence criterion.
      vtry = .true.
      betav = betav * .25

! Try linear iteration if it has not been tried and
! the s sequence is converging
      if (stry.or.(.not.spass)) go to 50
      k(1:n) = svk(1:n)
      40 call realit(s, nz, iflag)
      if (nz > 0) return

! Linear iteration has failed.  Flag that it has been
! tried and decrease the convergence criterion
      stry = .true.
      betas = betas * .25
      if (iflag /= 0) then

! If linear iteration signals an almost double real
! zero attempt quadratic interation
        ui = -(s+s)
        vi = s * s
        go to 20
      end if

! Restore variables
      50 u = svu
      v = svv
      k(1:n) = svk(1:n)

! Try quadratic iteration if it has not been tried
! and the v sequence is converging
      if (vpass .and. (.not.vtry)) go to 20

! Recompute qp and scalar values to continue the second stage
      call quadsd(nn, u, v, p, qp, a, b)
      call calcsc(TYPE)
    end if
  end if
  ovv = vv
  oss = ss
  otv = tv
  ots = ts
end do
return
end subroutine fxshfr




subroutine quadit(uu, vv, nz)

! Variable-shift k-polynomial iteration for a quadratic factor, converges
! only if the zeros are equimodular or nearly so.
! uu,vv - coefficients of starting quadratic
! nz - number of zero found

real (dp), intent(IN)  :: uu
real (dp), intent(IN)  :: vv
integer, intent(OUT)   :: nz

real (dp) :: ui, vi, one
real (dp) :: mp, omp, ee, relstp, t, zm
integer   :: TYPE, i, j
logical   :: tried

nz = 0
tried = .false.
u = uu
v = vv
j = 0

! Main loop
one = 1
10 call quad(one, u, v, szr, szi, lzr, lzi)

! return if roots of the quadratic are real and not
! close to multiple or nearly equal and  of opposite sign.
if (abs(abs(szr)-abs(lzr)) > .01D0*abs(lzr)) return

! Evaluate polynomial by quadratic synthetic division
call quadsd(nn, u, v, p, qp, a, b)
mp = abs(a-szr*b) + abs(szi*b)

! Compute a rigorous  bound on the rounding error in evaluting p
zm = SQRT(abs( real(v)))
ee = 2. * abs( real(qp(1)))
t = -szr * b
do  i = 2, n
  ee = ee * zm + abs( real(qp(i)) )
end do
ee = ee * zm + abs( real(a) + t)
ee = (5.*mre+4.*are) * ee - (5.*mre+2.*are) * (abs( real(a)  + t) +  &
     abs( real(b))*zm) + 2. * are * abs(t)

! Iteration has converged sufficiently if the
! polynomial value is less than 20 times this bound
if (mp <= 20.*ee) then
  nz = 2
  return
end if
j = j + 1

! Stop iteration after 20 steps
if (j > 20) return
if (j >= 2) then
  if (.not.(relstp > .01 .or. mp < omp .or. tried)) then

! A cluster appears to be stalling the convergence.
! five fixed shift steps are taken with a u,v close to the cluster
    if (relstp < eta) relstp = eta
    relstp = SQRT(relstp)
    u = u - u * relstp
    v = v + v * relstp
    call quadsd(nn, u, v, p, qp, a, b)
    do  i = 1, 5
      call calcsc(TYPE)
      call nextk(TYPE)
    end do
    tried = .true.
    j = 0
  end if
end if
omp = mp

! Calculate next k polynomial and new u and v
call calcsc(TYPE)
call nextk(TYPE)
call calcsc(TYPE)
call newest(TYPE,ui,vi)

! If vi is zero the iteration is not converging
if (vi == 0.d0) return
relstp = abs((vi-v)/vi)
u = ui
v = vi
go to 10
end subroutine quadit




subroutine realit(sss,nz,iflag)

! Variable-shift h polynomial iteration for a real
! zero.
! sss   - starting iterate
! nz    - number of zero found
! iflag - flag to indicate a pair of zeros near real axis.

real (dp), intent(IN OUT)  :: sss
integer, intent(OUT)       :: nz, iflag

real (dp) :: pv, kv, t, s
real      :: ms, mp, omp, ee
integer   :: i, j

nz = 0
s = sss
iflag = 0
j = 0

! Main loop
10 pv = p(1)

! Evaluate p at s
qp(1) = pv
do  i = 2, nn
  pv = pv * s + p(i)
  qp(i) = pv
end do
mp = real(abs(pv))

! Compute a rigorous bound on the error in evaluating p
ms = real(abs(s))
ee = (mre/(are+mre)) * abs( real(qp(1)))
do  i = 2, nn
  ee = ee * ms + abs( real(qp(i)))
end do

! Iteration has converged sufficiently if the
! polynomial value is less than 20 times this bound
if (mp <= 20.*((are+mre)*ee - mre*mp)) then
  nz = 1
  szr = s
  szi = 0.d0
  return
end if
j = j + 1

! Stop iteration after 10 steps
if (j > 10) return
if (j >= 2) then
  if (abs(t) <= .001*abs(s-t) .and. mp > omp) then
! A cluster of zeros near the real axis has been encountered,
! return with iflag set to initiate a quadratic iteration
    iflag = 1
    sss = s
    return
  end if
end if

! return if the polynomial value has increased significantly
omp = mp

! Compute t, the next polynomial, and the new iterate
kv = k(1)
qk(1) = kv
do  i = 2, n
  kv = kv * s + k(i)
  qk(i) = kv
end do
if (abs(kv) > abs(k(n))*10.*eta) then
! Use the scaled form of the recurrence if the value of k at s is nonzero
  t = -pv / kv
  k(1) = qp(1)
  do  i = 2, n
    k(i) = t * qk(i-1) + qp(i)
  end do
else
! Use unscaled form
  k(1) = 0.0D0
  do  i = 2, n
    k(i) = qk(i-1)
  end do
end if
kv = k(1)
do  i = 2, n
  kv = kv * s + k(i)
end do
t = 0.d0
if (abs(kv) > abs(k(n))*10.*eta) t = -pv / kv
s = s + t
go to 10
end subroutine realit




subroutine calcsc(TYPE)

! This routine calculates scalar quantities used to
! compute the next k polynomial and new estimates of
! the quadratic coefficients.
! type - integer variable set here indicating how the
! calculations are normalized to avoid overflow

integer, intent(OUT)  :: TYPE

! Synthetic division of k by the quadratic 1,u,v
call quadsd(n, u, v, k, qk, c, d)
if (abs(c) <= abs(k(n))*100.*eta) then
  if (abs(d) <= abs(k(n-1))*100.*eta) then
    TYPE = 3
! type=3 indicates the quadratic is almost a factor of k
    return
  end if
end if

if (abs(d) >= abs(c)) then
  TYPE = 2
! type=2 indicates that all formulas are divided by d
  e = a / d
  f = c / d
  g = u * b
  h = v * b
  a3 = (a+g) * e + h * (b/d)
  a1 = b * f - a
  a7 = (f+u) * a + h
  return
end if
TYPE = 1
! type=1 indicates that all formulas are divided by c
e = a / c
f = d / c
g = u * e
h = v * b
a3 = a * e + (h/c+g) * b
a1 = b - a * (d/c)
a7 = a + g * d + h * f
return
end subroutine calcsc




subroutine nextk(TYPE)

! Computes the next k polynomials using scalars computed in calcsc.

integer, intent(IN)  :: TYPE

real (dp) :: temp
integer   :: i

if (TYPE /= 3) then
  temp = a
  if (TYPE == 1) temp = b
  if (abs(a1) <= abs(temp)*eta*10.) then
! If a1 is nearly zero then use a special form of the recurrence
    k(1) = 0.d0
    k(2) = -a7 * qp(1)
    do  i = 3, n
      k(i) = a3 * qk(i-2) - a7 * qp(i-1)
    end do
    return
  end if

! Use scaled form of the recurrence
  a7 = a7 / a1
  a3 = a3 / a1
  k(1) = qp(1)
  k(2) = qp(2) - a7 * qp(1)
  do  i = 3, n
    k(i) = a3 * qk(i-2) - a7 * qp(i-1) + qp(i)
  end do
  return
end if

! Use unscaled form of the recurrence if type is 3
k(1) = 0.d0
k(2) = 0.d0
do  i = 3, n
  k(i) = qk(i-2)
end do
return
end subroutine nextk




subroutine newest(TYPE,uu,vv)

! Compute new estimates of the quadratic coefficients
! using the scalars computed in calcsc.

integer, intent(IN)     :: TYPE
real (dp), intent(OUT)  :: uu
real (dp), intent(OUT)  :: vv

real (dp) :: a4, a5, b1, b2, c1, c2, c3, c4, temp

! Use formulas appropriate to setting of type.
if (TYPE /= 3) then
  if (TYPE /= 2) then
    a4 = a + u * b + h * f
    a5 = c + (u+v*f) * d
  else
    a4 = (a+g) * f + h
    a5 = (f+u) * c + v * d
  end if

! Evaluate new quadratic coefficients.
  b1 = -k(n) / p(nn)
  b2 = -(k(n-1)+b1*p(n)) / p(nn)
  c1 = v * b2 * a1
  c2 = b1 * a7
  c3 = b1 * b1 * a3
  c4 = c1 - c2 - c3
  temp = a5 + b1 * a4 - c4
  if (temp /= 0.d0) then
    uu = u - (u*(c3+c2)+v*(b1*a1+b2*a7)) / temp
    vv = v * (1.+c4/temp)
    return
  end if
end if

! If type=3 the quadratic is zeroed
uu = 0.d0
vv = 0.d0
return
end subroutine newest




subroutine quadsd(nn, u, v, p, q, a, b)

! Divides p by the quadratic  1,u,v  placing the
! quotient in q and the remainder in a,b.

integer, intent(IN)     :: nn
real (dp), intent(IN)   :: u, v, p(nn)
real (dp), intent(OUT)  :: q(nn), a, b

real (dp)  :: c
integer    :: i

b = p(1)
q(1) = b
a = p(2) - u * b
q(2) = a
do  i = 3, nn
  c = p(i) - u * a - v * b
  q(i) = c
  b = a
  a = c
end do
return
end subroutine quadsd




subroutine quad(a, b1, c, sr, si, lr, li)

! Calculate the zeros of the quadratic a*z**2+b1*z+c.
! The quadratic formula, modified to avoid overflow, is used to find the
! larger zero if the zeros are real and both zeros are complex.
! The smaller real zero is found directly from the product of the zeros c/a.

real (dp), intent(IN)             :: a, b1, c
real (dp), intent(OUT)            :: sr, si, lr, li

real (dp) :: b, d, e

if (a /= 0.d0) go to 20
sr = 0.d0
if (b1 /= 0.d0) sr = -c / b1
lr = 0.d0
10 si = 0.d0
li = 0.d0
return

20 if (c == 0.d0) then
  sr = 0.d0
  lr = -b1 / a
  go to 10
end if

! Compute discriminant avoiding overflow
b = b1 / 2.d0
if (abs(b) >= abs(c)) then
  e = 1.d0 - (a/b) * (c/b)
  d = SQRT(abs(e)) * abs(b)
else
  e = a
  if (c < 0.d0) e = -a
  e = b * (b/abs(c)) - e
  d = SQRT(abs(e)) * SQRT(abs(c))
end if
if (e >= 0.d0) then

! Real zeros
  if (b >= 0.d0) d = -d
  lr = (-b+d) / a
  sr = 0.d0
  if (lr /= 0.d0) sr = (c/lr) / a
  go to 10
end if
! complex conjugate zeros
sr = -b / a
lr = sr
si = abs(d/a)
li = -si
return
end subroutine quad

end MODULE Solve_Real_Poly



PROGRAM test_rpoly
  USE Solve_Real_Poly
  IMPLICIT NONE
  
real (dp) :: dat(64)
DATA dat(1:64) / 64*0/

real (dp)  :: p(50), zr(50), zi(50)
integer    :: degree, i
logical    :: fail

write(*, 5000)
degree = 10

data p(1:11) /1._dp, -55._dp, 1320._dp,-18150._dp,157773._dp, &
  -902055._dp,3416930._dp,-8409500._dp,12753576._dp,          &
  -10628640._dp, 3628800._dp/ 

call rpoly(p, degree, zr, zi, fail)
if (fail) then
  write(*, *) ' ** Failure by RPOLY **'
else
  write(*, '(a/ (2g23.4))') ' Real part           Imaginary part',  &
                             (zr(i), zi(i), i=1,degree)
end if

! This test provided by Larry Wigton

write(*, *)
write(*, *) "Now try case where 1 is an obvious root"

degree = 5
data p(1:6) /8.D0,-8.D0,16.D0,-16.D0,8.D0,-8.D0/

call rpoly(p, degree, zr, zi, fail)

if (fail) then
  write(*, *) ' ** Failure by RPOLY **'
else
  write(*, *) ' Real part           Imaginary part'
  write(*, '(2g23.4)') (zr(i), zi(i), i=1,degree)
end if

stop

5000 FORMAT (' EXAMPLE 1. POLYNOMIAL WITH ZEROS 1,2,...,10.')

end PROGRAM test_rpoly

