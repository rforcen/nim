// int128

#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <string>
#include <memory.h>

using std::string;

typedef signed __int128 int128_t;
typedef unsigned __int128 uint128_t;

// Return pointer to the end
static char *uint128toa_helper(char *dest, uint128_t x)
{
  if (x >= 10)
  {
    dest = uint128toa_helper(dest, x / 10);
  }
  *dest = (char)(x % 10 + '0');
  return ++dest;
}

string int128toa(int128_t x)
{
  string ds(41, '\0');
  char *dest = (char *)ds.c_str();

  if (x < 0)
  {
    *dest = '-';
    *uint128toa_helper(dest + 1, (uint128_t)(-1 - x) + 1) = '\0';
  }
  else
  {
    *uint128toa_helper(dest, (uint128_t)x) = '\0';
  }
  return ds;
}

string uint128toa(uint128_t x)
{
  string ds(41, '\0');
  char *dest = (char *)ds.c_str();

  *uint128toa_helper(dest, x) = '\0';
  return ds;
}

int128_t atoint128(char *s)
{
  int128_t x = 0, p = 1;

  for (int i = strlen(s) - 1; i >= 0; i--, p *= 10)
  {
    if (s[i] == '-')
      x = -x;
    else
      x += p * (s[i] - '0');
  }
  return x;
}

uint128_t atouint128(char *s)
{
  uint128_t x = 0, p = 1;

  for (int i = strlen(s) - 1; i >= 0; i--, p *= 10)
  {
    x += p * (s[i] - '0');
  }
  return x;
}

int main()
{
  uint128_t i = atouint128("170141181000009999037184105727");
  // "170141183460469231731687303715884105727";

  // for (auto n=0; n<128; n++) printf("shl %d=%s\n", n, uint128toa(dest, shl(i,n)));
  auto p = i;
  for (auto n = 0; n < 128; n++, p /= 2)
    printf("shr %3d=%s | %s (%s)\n", n, uint128toa(i >> n).c_str(), uint128toa(p).c_str(), uint128toa((i >> n) - p).c_str());

  return 0;
}