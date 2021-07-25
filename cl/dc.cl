// Domain Coloring
// dc.cl

#define vec2 float2
#define vec3 float3
#define vec4 float4

// complex arithmetics: +,-, neg direct vec2 support
vec2 mul(vec2 a, vec2 b) {
  return (vec2)(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}
vec2 div(vec2 a, vec2 b) {
  float _div = (b.x * b.x) + (b.y * b.y);
  return (vec2)(((a.x * b.x) + (a.y * b.y)) / _div,
                ((a.y * b.x) - (a.x * b.y)) / _div);
}

float cabs(vec2 a) { return dot(a, a); }
float sqmag(vec2 a) { return dot(a, a); }
float arg(vec2 a) { return atan2(a.y, a.x); }

vec2 cnpow(vec2 a, float n) {
  float rn = pow(length(a), n), na = n * arg(a);
  return (vec2)(rn * cos(na), rn * sin(na));
}

vec2 cpow(vec2 a, vec2 z) {
  float c = z.x, d = z.y;
  float m = pow(sqmag(a), c / 2) * exp(-d * arg(a));
  float _re = m * cos(c * arg(a) + 1 / 2 * d * log(sqmag(a))),
        _im = m * sin(c * arg(a) + 1 / 2 * d * log(sqmag(a)));
  return (vec2)(_re, _im);
}

vec2 csqrt(vec2 z) {
  float a = length(z);
  return (vec2)(sqrt((a + z.x) / 2), sign(z.y) * sqrt((a - z.x) / 2));
}

vec2 clog(vec2 z) { return (vec2)(log(length(z)), arg(z)); }

vec2 ccosh(vec2 z) {
  return (vec2)(cosh(z.x) * cos(z.y), sinh(z.x) * sin(z.y));
}
vec2 csinh(vec2 z) {
  return (vec2)(sinh(z.x) * cos(z.y), cosh(z.x) * sin(z.y));
}
vec2 csin(vec2 z) { return (vec2)(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y)); }
vec2 ccos(vec2 z) {
  return (vec2)(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y));
}
vec2 ctan(vec2 z) { return div(sin(z), cos(z)); }

vec2 casinh(vec2 z) {
  vec2 t = (vec2)((z.x - z.y) * (z.x + z.y) + 1, 2 * z.x * z.y);
  return log(sqrt(t) + z);
}

vec2 casin(vec2 z) {
  vec2 t = asinh((vec2)(-z.y, z.x));
  return (vec2)(t.y, -t.x);
}
vec2 cacos(vec2 z) {
  vec2 t = asin(z);
  return (vec2)(1.7514f - t.x, -t.y);
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
  vec3 res;

  if (s == 0) {
    res = (vec3)(v, v, v);
  } else {
    if (h == 1)
      h = 0;

    float z = floor(h * 6), f = h * 6 - z, p = v * (1 - s), q = v * (1 - s * f),
          t = v * (1 - s * (1 - f));

    switch ((int)(z) % 6) {
    case 0:
      res = (vec3)(v, t, p);
      break;
    case 1:
      res = (vec3)(q, v, p);
      break;
    case 2:
      res = (vec3)(p, v, t);
      break;
    case 3:
      res = (vec3)(p, q, v);
      break;
    case 4:
      res = (vec3)(t, p, v);
      break;
    case 5:
      res = (vec3)(v, p, q);
      break;
    }
  }
  return rgbf2uint(res.x, res.y, res.z);
}

vec2 domain_color_func(vec2); // domain coloring func

uint dc_get_color(int x, int y, int w, int h) {

  float E = 2.7182818284f, PI = 3.141592653f, PI2 = PI * 2;
  float limit = PI, rmi = -limit, rma = limit, imi = -limit, ima = limit;

  vec2 z =
      (vec2)(ima - (ima - imi) * y / (h - 1), rma - (rma - rmi) * x / (w - 1));

  vec2 v = domain_color_func(z); // evaluate domain coloring func

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

/////////////////////// the domain coloring func

vec2 domain_color_func(vec2 z) { // f(z)
  // return mul(z, z);
  vec2 z1 = div(cnpow(z, 4) + 1, cnpow(z, 3) - 1);
  // vec2 z1 = mul(cnpow(z, 4), cos(z)) + cnpow(z, 4);
  z1 += mul(z / 5, csin(z));
  return z1;
}

kernel void domain_coloring(global uint *image) {
  size_t index = get_global_id(0);
  int width = (int)sqrt((float)get_global_size(0)); // w x w = n

  int x = (int)(index / width),
      y = (int)(index % width); // point(x,y)

  image[index] = dc_get_color(x, y, width, width);
}