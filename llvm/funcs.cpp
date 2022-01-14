// functions included in llvm must be compiled w/ -fPIC and stored in .so

// g++ -shared -o libfuncs.so -fPIC funcs.cpp

#include <math.h>

extern "C"
{
  double foo(double t)
  {
    return t;
  }

  double wave(double t, double a, double hz, double phase)
  {
    return a * sin(t * hz + phase);
  }
}
