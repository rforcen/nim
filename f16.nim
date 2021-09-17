# f16 half float

{.emit: """

// f16 from float16

#define f16_tenth   11878
#define f16_fifth   12902
#define f16_third   13653
#define f16_half    14336
#define f16_one     15360
#define f16_two     16384
#define f16_three   16896
#define f16_five    17664
#define f16_ten     18688
#define f16_pi      16968
#define f16_half_pi 15944

typedef int int32_t;
typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

short f16_add(short a,short b);
short f16_sub(short a,short b);
short f16_mul(short a,short b);
short f16_div(short a,short b);
short f16_neg(short a);
short f16_from_int(int32_t v);
int32_t f16_int(short v);

int f16_gte(short a,short b);
int f16_gt(short a,short b);
int f16_eq(short a,short b);
int f16_lte(short a,short b);
int f16_lt(short a,short b);
int f16_neq(short a,short b);

#define SIGN_MASK 0x8000
#define EXP_MASK 0x7C00
#define NAN_VALUE 0x7FFF
#define IS_ZERO(x) (((x) & 0x7FFF) == 0)
#define IS_INVALID(x) (((x) & EXP_MASK) == EXP_MASK)
#define IS_NAN(x) (((x) & 0x7FFF) > 0x7C00)
#define IS_INF(x) ( ((x) & 0x7FFF) == 0x7C00)
#define MANTISSA(x) (((x) & 1023) | (((x) & 0x7C00) == 0 ? 0 : 1024))
#define EXPONENT(x) (((x) & 0x7C00) >> 10)
#define SIGNED_INF_VALUE(x)  ((x & SIGN_MASK) | 0x7C00)

short cfloat2f16(float val) {
  uint32_t bits = *((uint32_t*)&val);

  
  short sign = (bits & 0x80000000) >> 16; // Extract the sign from the float value
  uint32_t frac32 = bits & 0x7fffff; // Extract the fraction from the float value
  uint8_t exp32 = (bits & 0x7f800000) >> 23; // Extract the exponent from the float value
  int8_t exp32_diff = exp32 - 127;

  short exp16 = 0;
  short frac16 = frac32 >> 13;

  if (exp32 == 0xff || exp32_diff > 15) {
    exp16 = 0x1f;
  } else if (exp32 == 0 || exp32_diff < -14) {
    exp16 = 0;
  } else {
    exp16 = exp32_diff + 15;
  }

  if (exp32 == 0xff && frac32 != 0 && frac16 == 0) {
    // corner case 1: NaN
    // This case happens when FP32 value is NaN whose the fraction part
    // transformed to FP16 counterpart is truncated to 0. We need to flip the
    // high bit to 1 to make it distinguished from inf.
    frac16 = 0x200;
  } else if (exp32 == 0 || (exp16 == 0x1f && exp32 != 0xff)) {
    // corner case 2: subnormal
    // All FP32 subnormal values are under the range of FP16 so the fraction
    // part is set to 0.
    // corner case 3: overflow
    frac16 = 0;
  } else if ((exp16 == 0 && exp32 != 0)) {
    // corner case 4: underflow
    // We use `truncate` mode here.
    frac16 = 0x100 | (frac16 >> 2);
  }

  // Compose the final FP16 binary
  short ret = 0;
  ret |= sign;
  ret |= exp16 << 10;
  ret |= frac16;

  return ret;
}

float f16tocfloat(short val) {
  uint32_t sign = (uint32_t)(val & 0x8000) << 16; // Extract the sign from the bits
  uint8_t exp16 = (val & 0x7c00) >> 10; // Extract the exponent from the bits
  short frac16 = val & 0x3ff; // Extract the fraction from the bits
  uint32_t exp32 = 0;

  if (exp16 == 0x1f) {
    exp32 = 0xff;
  } else if (exp16 == 0) {
    exp32 = 0;
  } else {
    exp32 = (uint32_t)(exp16) + 112;
  }

  // corner case: subnormal -> normal
  // The denormal number of FP16 can be represented by FP32, therefore we need
  // to recover the exponent and recalculate the fration.
  if (exp16 == 0 && frac16 != 0) {
    uint8_t OffSet = 0;
    do {
      ++OffSet;
      frac16 <<= 1;
    } while ((frac16 & 0x400) != 0x400);
    // mask the 9th bit
    frac16 &= 0x3ff;
    exp32 = 113 - OffSet;
  }

  uint32_t frac32 = frac16 << 13;

  // Compose the final FP32 binary
  uint32_t bits = 0;

  bits |= sign;
  bits |= (exp32 << 23);
  bits |= frac32;

  return *(float*)(&bits);
}

short f16_sub(short ain,short bin)
{
    short a=ain;
    short b=bin;
    if(((a ^ b) & 0x8000) != 0)
        return f16_add(a,b ^ 0x8000);
    short sign = a & 0x8000;
    a = a << 1;
    b = b << 1;
    if(a < b) {
        short x=a;
        a=b;
        b=x;
        sign ^= 0x8000;
    }
    short ax = a & 0xF800;
    short bx = b & 0xF800;
    if(a >=0xf800 || b>=0xf800) {
        if(a > 0xF800 || b > 0xF800 || a==b)
            return 0x7FFF; 
        short res = sign | 0x7C00;
        if(a == 0xf800)
            return res;
        else
            return res ^ 0x8000;
    }
    int exp_diff = ax - bx;
    short exp_part  = ax;
    if(exp_diff != 0) {
        int shift = exp_diff >> 11;
        if(bx != 0)
            b = ((b & 2047) | 2048) >> shift;
        else
            b >>= (shift - 1);
    }
    else {
        if(bx == 0) {
            short res = (a-b) >> 1;
            if(res == 0)
                return res;
            return res | sign;
        }
        else {
            b=(b & 2047) | 2048;
        }
    }
    short r=a - b;
    if((r & 0xF800) == exp_part) {
        return (r>>1) | sign;
    }
    short am = (a & 2047) | 2048;
    short new_m = am - b;
    if(new_m == 0)
        return 0;
    while(exp_part !=0 && !(new_m & (2048))) {
        exp_part-=0x800;
        if(exp_part!=0)
            new_m<<=1;
    }
    return (((new_m & 2047) | exp_part) >> 1) | sign;
}

short f16_add(short a,short b)
{
    if (((a ^ b) & 0x8000) != 0)
        return f16_sub(a,b ^ 0x8000);
    short sign = a & 0x8000;
    a &= 0x7FFF;
    b &= 0x7FFF;
    if(a<b) {
        short x=a;
        a=b;
        b=x;
    }
    if(a >= 0x7C00 || b>=0x7C00) {
        if(a>0x7C00 || b>0x7C00)
            return 0x7FFF;
        return 0x7C00 | sign;
    }
    short ax = (a & 0x7C00);
    short bx = (b & 0x7C00);
    short exp_diff = ax - bx;
    short exp_part = ax;
    if(exp_diff != 0) {
        int shift = exp_diff >> 10;
        if(bx != 0)
            b = ((b & 1023) | 1024) >> shift;
        else
            b >>= (shift - 1);
    }
    else {
        if(bx == 0) {
            return (a + b) | sign;
        }
        else {
            b=(b & 1023) | 1024;
        }
    }
    short r=a+b;
    if ((r & 0x7C00) != exp_part) {
        short am = (a & 1023) | 1024;
        short new_m = (am + b) >> 1;
        r =( exp_part + 0x400) | (1023 & new_m);
    }
    if((short)r >= 0x7C00u) {
        return sign | 0x7C00;
    }
    return r | sign;
}


short f16_mul(short a,short b)
{
    int sign = (a ^ b) & SIGN_MASK;

    if(IS_INVALID(a) || IS_INVALID(b)) {
        if(IS_NAN(a) || IS_NAN(b) || IS_ZERO(a) || IS_ZERO(b))
            return NAN_VALUE;
        return sign | 0x7C00;
    }

    if(IS_ZERO(a) || IS_ZERO(b))
        return 0;
    short m1 = MANTISSA(a);
    short m2 = MANTISSA(b);

    uint32_t v=m1;
    v*=m2;
    int ax = EXPONENT(a);
    int bx = EXPONENT(b);
    ax += (ax==0);
    bx += (bx==0);
    int new_exp = ax + bx - 15;
    
    if(v & ((uint32_t)1<<21)) {
        v >>= 11;
        new_exp++;
    }
    else if(v & ((uint32_t)1<<20)) {
        v >>= 10;
    }
    else { // denormal
        new_exp -= 10;
        while(v >= 2048) {
            v>>=1;
            new_exp++;
        }
    }
    if(new_exp <= 0) {
        v>>=(-new_exp + 1);
        new_exp = 0;
    }
    else if(new_exp >= 31) {
        return SIGNED_INF_VALUE(sign);
    }
    return (sign) | (new_exp << 10) | (v & 1023);
}

short f16_div(short a,short b)
{
    short sign = (a ^ b) & SIGN_MASK;
    if(IS_NAN(a) || IS_NAN(b) || (IS_INVALID(a) && IS_INVALID(b)) || (IS_ZERO(a) && IS_ZERO(b)))
        return 0x7FFF;
    if(IS_INVALID(a) || IS_ZERO(b))
        return sign | 0x7C00;
    if(IS_INVALID(b))
        return 0;
    if(IS_ZERO(a))
        return 0;

    short m1 = MANTISSA(a);
    short m2 = MANTISSA(b);
    uint32_t m1_shifted = m1;
    m1_shifted <<= 10;
    uint32_t v= m1_shifted / m2;
    short rem = m1_shifted % m2;
    
    int ax = EXPONENT(a);
    int bx = EXPONENT(b);
    ax += (ax==0);
    bx += (bx==0);
    int new_exp = ax - bx + 15 ;

    if(v == 0 && rem==0)
        return 0;

    while(v < 1024 && new_exp > 0) {
        v<<=1;
        rem<<=1;
        if(rem >= m2) {
            v++;
            rem -= m2;
        }
        new_exp--;
    }
    while(v >= 2048) {
        v>>=1;
        new_exp++;
    }
    
    if(new_exp <= 0) {
        v>>=(-new_exp + 1);
        new_exp = 0;
    }
    else if(new_exp >= 31) {
        return SIGNED_INF_VALUE(sign);
    }
    return sign | (v & 1023) | (new_exp << 10);
}

short f16_neg(short v)
{
    return SIGN_MASK ^ v;
}
short f16_from_int(int32_t sv)
{
    uint32_t v;
    int sig = 0;
    if(sv < 0) {
        v=-sv;
        sig=1;
    }
    else
        v=sv;
    if(v==0)
        return 0;
    int e=25;
    while(v >= 2048) {
        v>>=1;
        e++;
    }
    while(v<1024) {
        v<<=1;
        e--;
    }
    if(e>=31)
        return SIGNED_INF_VALUE(sig << 15);
    return (sig << 15) | (e << 10) | (v & 1023);
}
int32_t f16_int(short a)
{
    short value = MANTISSA(a);
    short shift = EXPONENT(a) - 25;
    if(shift > 0)
        value <<= shift;
    else if(shift < 0)
        value >>= -shift;
    if(a & SIGN_MASK)
        return -(int32_t)(value);
    return value;
}

int f16_gte(short a,short b)
{
    if(IS_ZERO(a) && IS_ZERO(b))
        return 1;
    if(IS_NAN(a) || IS_NAN(b))
        return 0;
    if((a & SIGN_MASK) == 0) {
        if((b & SIGN_MASK) == SIGN_MASK)
            return 1;
        return a >= b;
    }
    else {
        if((b & SIGN_MASK) == 0)
            return 0;
        return (a & 0x7FFF) <= (b & 0x7FFF);
    }
}

int f16_gt(short a,short b)
{
    if(IS_NAN(a) || IS_NAN(b))
        return 0;
    if(IS_ZERO(a) && IS_ZERO(b))
        return 0;
    if((a & SIGN_MASK) == 0) {
        if((b & SIGN_MASK) == SIGN_MASK)
            return 1;
        return a > b;
    }
    else {
        if((b & SIGN_MASK) == 0)
            return 0;
        return (a & 0x7FFF) < (b & 0x7FFF);
    }
    
}
int f16_eq(short a,short b)
{
    if(IS_NAN(a) || IS_NAN(b))
        return 0;
    if(IS_ZERO(a) && IS_ZERO(b))
        return 1;
    return a==b;
}

int f16_lte(short a,short b)
{
    if(IS_NAN(a) || IS_NAN(b))
        return 0;
    return f16_gte(b,a);
}

int f16_lt(short a,short b)
{
    if(IS_NAN(a) || IS_NAN(b))
        return 0;
    return f16_gt(b,a);
}
int f16_neq(short a,short b)
{
    return !f16_eq(a,b);
}


""".}

# nim wrap
type
  f16 = cshort
  i32 = cint

const
  f16_tenth* = 11878.f16
  f16_fifth* = 12902.f16
  f16_third* = 13653.f16
  f16_half* = 14336.f16
  f16_one* = 15360.f16
  f16_two* = 16384.f16
  f16_three* = 16896.f16
  f16_five* = 17664.f16
  f16_ten* = 18688.f16
  f16_pi* = 16968.f16
  f16_half_pi* = 15944.f16

const
  SIGN_MASK* = 0x8000
  EXP_MASK* = 0x7C00
  NAN_VALUE* = 0x7FFF

template IS_ZERO*(x: untyped): untyped =
  (((x) and 0x7FFF) == 0)

template IS_INVALID*(x: untyped): untyped =
  (((x) and EXP_MASK) == EXP_MASK)

template IS_NAN*(x: untyped): untyped =
  (((x) and 0x7FFF) > 0x7C00)

template IS_INF*(x: untyped): untyped =
  (((x) and 0x7FFF) == 0x7C00)

proc f16_add(a, b: f16): f16 {.importc: "f16_add".}
proc f16_sub(a, b: f16): f16 {.importc: "f16_sub".}
proc f16_neg(a: f16): f16 {.importc: "f16_neg".}
proc f16_mul(a, b: f16): f16 {.importc: "f16_mul".}
proc f16_div(a, b: f16): f16 {.importc: "f16_div".}
proc f16_int(a: f16): int32 {.importc: "f16_int".}
proc f16_from_int(a: int32): f16 {.importc: "f16_from_int".}

proc f16_eq(a, b: f16): f16 {.importc: "f16_eq".}
proc f16_neq(a, b: f16): f16 {.importc: "f16_neq".}
proc f16_gte(a, b: f16): f16 {.importc: "f16_gte".}
proc f16_gt(a, b: f16): f16 {.importc: "f16_gt".}
proc f16_lt(a, b: f16): f16 {.importc: "f16_lt".}
proc f16_lte(a, b: f16): f16 {.importc: "f16_lte".}
proc cfloat2f16(a: cfloat): f16 {.importc: "cfloat2f16".}
proc f16tocfloat(a: f16): cfloat {.importc: "f16tocfloat".}

# conversions
converter ftoi*(f: f16): int = f16_int(f).int
converter itof*(i: int): f16 = f16_from_int(i.int32)
converter floattof16*(f: float): f16 = cfloat2f16(f.cfloat)
converter f16tofloat*(f: f16): float = f16tocfloat(f).float

proc `$` *(f: f16): string =
  if f.IS_NAN: result = "Nan"
  elif f.IS_INF: result = "Inf"
  elif f.IS_INVALID: result = "Inv"
  else:
    result = $f.f16tocfloat

# arithmetics
proc `+`*(a, b: f16): f16 = f16_add(a, b)
proc `-`*(a, b: f16): f16 = f16_sub(a, b)
proc `-`*(a: f16): f16 = f16_neg(a)
proc `*`*(a, b: f16): f16 = f16_mul(a, b)
proc `/`*(a, b: f16): f16 = f16_div(a, b)

proc `+`*(a: f16, b: int): f16 = f16_add(a, b.itof)
proc `-`*(a: f16, b: int): f16 = f16_sub(a, b.itof)
proc `*`*(a: f16, b: int): f16 = f16_mul(a, b.itof)
proc `/`*(a: f16, b: int): f16 = f16_div(a, b.itof)

proc `==`*(a, b: f16): f16 = f16_eq(a, b)
proc `=!`*(a, b: f16): f16 = f16_neq(a, b)
proc `>=`*(a, b: f16): f16 = f16_gte(a, b)
proc `<=`*(a, b: f16): f16 = f16_lte(a, b)
proc `>`*(a, b: f16): f16 = f16_gt(a, b)
proc `<`*(a, b: f16): f16 = f16_lt(a, b)

when isMainModule:
    import times

    var
        f0 = f16_ten
        f1 = f16_pi * 2
        f2 = f0+f1
        f3 = 1.itof

    echo "f3=(1.0) ",f3
    echo "f0=", f0, ", f1=", f1, ", f2=", f2

    let n=10000
    echo f0+f1*f2/f3

    var t0=now()
    for i in 0..n*n:
        f2 = f0+f1*f2/f3
    echo "lap f16:", (now()-t0).inMilliseconds

    var 
        ff0=f0.f16tofloat
        ff1=f1.f16tofloat
        ff2=ff0+ff1
        ff3=f3.f16tofloat

    echo ff0+ff1*ff2/ff3

    t0=now()
    for i in 0..n*n:
        ff2 = ff0+ff1*ff2/ff3
    echo "lap float:", (now()-t0).inMilliseconds
