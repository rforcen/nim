// Domain Coloring unsing zvm
// dc_zvm.cl

// complex arithmetics: +,-, neg direct float2 support
float2 mul(float2 a, float2 b) {
  return (float2)(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}
float2 div(float2 a, float2 b) {
  float _div = (b.x * b.x) + (b.y * b.y);

  return _div != 0 ? (float2)(((a.x * b.x) + (a.y * b.y)) / _div,
                              ((a.y * b.x) - (a.x * b.y)) / _div)
                   : (float2)(0, 0);
}

float cabs(float2 a) { return dot(a, a); }
float sqmag(float2 a) { return dot(a, a); }
float arg(float2 a) { return atan2(a.y, a.x); }

float2 cnpow(float2 a, float n) {
  float rn = pow(length(a), n), na = n * arg(a);
  return (float2)(rn * cos(na), rn * sin(na));
}

float2 cpow(float2 a, float2 z) {
  float c = z.x, d = z.y;
  float m = pow(sqmag(a), c / 2) * exp(-d * arg(a));
  float _re = m * cos(c * arg(a) + 1 / 2 * d * log(sqmag(a))),
        _im = m * sin(c * arg(a) + 1 / 2 * d * log(sqmag(a)));
  return (float2)(_re, _im);
}

float2 csqrt(float2 z) {
  float a = length(z);
  return (float2)(sqrt((a + z.x) / 2), sign(z.y) * sqrt((a - z.x) / 2));
}

float2 clog(float2 z) { return (float2)(log(length(z)), arg(z)); }

float2 ccosh(float2 z) {
  return (float2)(cosh(z.x) * cos(z.y), sinh(z.x) * sin(z.y));
}
float2 csinh(float2 z) {
  return (float2)(sinh(z.x) * cos(z.y), cosh(z.x) * sin(z.y));
}
float2 csin(float2 z) {
  return (float2)(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y));
}
float2 ccos(float2 z) {
  return (float2)(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y));
}
float2 ctan(float2 z) { return div(sin(z), cos(z)); }

float2 casinh(float2 z) {
  float2 t = (float2)((z.x - z.y) * (z.x + z.y) + 1, 2 * z.x * z.y);
  return log(sqrt(t) + z);
}

float2 casin(float2 z) {
  float2 t = asinh((float2)(-z.y, z.x));
  return (float2)(t.y, -t.x);
}
float2 cacos(float2 z) {
  float2 t = asin(z);
  return (float2)(1.7514f - t.x, -t.y);
}

////////////////////////

uint argbf2uint(uint alpha, float r, float g, float b) {
  return (alpha << 24) | ((uint)(255.f * r) & 0xffu) |
         (((uint)(255.f * g) & 0xffu) << 8) |
         (((uint)(255.f * b) & 0xffu) << 16);
}

uint rgbf2uint(float r, float g, float b) {
  return 0xff000000u | // alpha 0xff
         ((uint)(r * 255) & 0xffu) | (((uint)(g * 255) & 0xffu) << 8) |
         (((uint)(b * 255) & 0xffu) << 16);
}

uint HSV2RGB(float h, float s, float v) { // convert hsv to rgb,1
  float3 res;

  if (s == 0) {
    res = (float3)(v, v, v);
  } else {
    if (h == 1)
      h = 0;

    float z = floor(h * 6), f = h * 6 - z, p = v * (1 - s), q = v * (1 - s * f),
          t = v * (1 - s * (1 - f));

    switch ((int)(z) % 6) {
    case 0:
      res = (float3)(v, t, p);
      break;
    case 1:
      res = (float3)(q, v, p);
      break;
    case 2:
      res = (float3)(p, v, t);
      break;
    case 3:
      res = (float3)(p, q, v);
      break;
    case 4:
      res = (float3)(t, p, v);
      break;
    case 5:
      res = (float3)(v, p, q);
      break;
    }
  }
  return rgbf2uint(res.x, res.y, res.z);
}

float2 domain_color_func(float2); // domain coloring func

// zvm evaluator
float2 eval_zvn(float2 z, global ulong *code) {
  enum Symbols {
    SNULL = 0,
    NUMBER = 1,
    IDENTi = 2,
    IDENTz = 3,
    PLUS = 5,
    MINUS = 6,
    MULT = 7,
    DIV = 8,
    OPAREN = 9,
    CPAREN = 10,
    POWER = 12,
    PERIOD = 13,
    COMMA = 14,

    // function names
    FSIN = 90,
    FCOS = 91,
    FTAN = 92,
    FEXP = 93,
    FLOG = 94,
    FLOG10 = 95,
    FINT = 96,
    FSQRT = 97,
    FASIN = 98,
    FACOS = 99,
    FATAN = 100,
    FABS = 101,
    FC = 102,
    SPI = 103,
    SPHI = 104,
    PUSHC = 112,
    PUSHZ = 113,
    PUSHI = 114,
    PUSHCC = 115,
    NEG = 116,

    END = 200,
  };
  int pc = 0, sp = 0;
#define MAX_STACK 128
  float2 stack[MAX_STACK];

  for (;;) {
    switch (code[pc]) {
    case PUSHC:
      stack[sp++] = (float2)(*(global double *)(code + (++pc)), 0);
      break;
    case PUSHZ:
      stack[sp++] = z;
      break;
    case PUSHI:
      stack[sp++] = (float2)(1, 0);
      break;
    case PLUS:
      sp--;
      stack[sp - 1] += stack[sp];
      break;
    case MINUS:
      sp--;
      stack[sp - 1] -= stack[sp];
      break;
    case MULT:
      sp--;
      stack[sp - 1] = mul(stack[sp - 1], stack[sp]);
      break;
    case DIV:
      sp--;
      stack[sp - 1] = div(stack[sp - 1], stack[sp]);
      break;

    case POWER:
      sp--;
      stack[sp - 1] = stack[sp].y == 0 ? cnpow(stack[sp - 1], stack[sp].x)
                                       : cpow(stack[sp - 1], stack[sp]);
      break;

    case NEG:
      stack[sp - 1] = -stack[sp - 1];
      break;

    case FSQRT:
      stack[sp - 1] = csqrt(stack[sp - 1]);
      break;

    case FSIN:
      stack[sp - 1] = csin(stack[sp - 1]);
      break;
    case FCOS:
      stack[sp - 1] = ccos(stack[sp - 1]);
      break;
    case FTAN:
      stack[sp - 1] = ctan(stack[sp - 1]);
      break;
    case FASIN:
      stack[sp - 1] = casin(stack[sp - 1]);
      break;
    case FACOS:
      stack[sp - 1] = cacos(stack[sp - 1]);
      break;

    case FLOG:
      stack[sp - 1] = clog(stack[sp - 1]);
      break;
    case FLOG10:
      break;
    case FEXP:
      break;

    case FC:
      sp--;
      stack[sp - 1] = (float2)(stack[sp - 1].x, stack[sp].x);
      break;

    case END:
      goto finished;
      break;
    }
    pc++;
  }

finished:
  return sp != 0 ? stack[sp - 1] : (float2)(0, 0);
}

uint dc_get_color(int x, int y, int w, int h, global ulong *code) {

  float E = 2.7182818284f, PI = 3.141592653f, PI2 = PI * 2;
  float limit = PI, rmi = -limit, rma = limit, imi = -limit, ima = limit;

  float2 z = (float2)(ima - (ima - imi) * y / (h - 1),
                      rma - (rma - rmi) * x / (w - 1));

  // float2 v = domain_color_func(z); // fixed evaluate domain coloring func
  float2 v = eval_zvn(z, code); // evaluate ZVM domain coloring func

  float m, ranges, rangee; //  prop. e^n < m < e^(n-1)
  for (m = length(v), ranges = 0, rangee = 1; m > rangee; rangee *= E)
    ranges = rangee;

  float k = (m - ranges) / (rangee - ranges),
        kk = (k < 0.5f ? k * 2 : 1 - (k - 0.5f) * 2);

  float ang = fmod(fabs(arg(v)), PI2) / PI2, // -> hsv
      sat = 0.4f + (1 - pow(1 - kk, 3)) * 0.6f,
        val = 0.6f + (1 - pow(1 - (1 - kk), 3)) * 0.4f;

  return HSV2RGB(ang, sat, val);
}

/////////////////////// example of fixed domain coloring func

float2 domain_color_func(float2 z) { // f(z)
  // return mul(z, z);
  float2 z1 = div(cnpow(z, 4) + 1, cnpow(z, 3) - 1);
  // float2 z1 = mul(cnpow(z, 4), cos(z)) + cnpow(z, 4);
  z1 += mul(z / 5, csin(z));
  return z1;
}

kernel void domain_coloring(global uint *image, // 0: image
                            global ulong *code   // 1: code (END), int in nim is 64 bit -> ulong
) {
  size_t index = get_global_id(0);
  int width = (int)sqrt((float)get_global_size(0)); // w x w = n

  int x = (int)(index / width),
      y = (int)(index % width); // point(x,y)

  image[index] = dc_get_color(x, y, width, width, code);
}