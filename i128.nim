# int128 nim support

{.emit: """

#include <stdio.h>
#include <string>

using std::string;

typedef signed __int128 int128_t;
typedef unsigned __int128 uint128_t;

#define INT128_MAX (__int128) (((unsigned __int128) 1 << ((__SIZEOF_INT128__ * __CHAR_BIT__) - 1)) - 1)
#define INT128_MIN (-INT128_MAX - 1)
#define UINT128_MAX ((2 * (unsigned __int128) INT128_MAX) + 1)

// Return pointer to the end
char *uint128toa_helper(char *dest, uint128_t x)
{
  if (x >= 10)
  {
    dest = uint128toa_helper(dest, x / 10);
  }
  *dest = (char)(x % 10 + '0');
  return ++dest;
}

char dest[41];
char* int128tos(int128_t x)
{
  if (x < 0)
  {
    *dest = '-';
    *uint128toa_helper(dest + 1, (uint128_t)(-1 - x) + 1) = '\0';
  }
  else
  {
    *uint128toa_helper(dest, (uint128_t)x) = '\0';
  }
  return dest;
}

char* uint128tos(uint128_t x)
{
  *uint128toa_helper(dest, x) = '\0';
  return dest;
}

// string > u/int128
int128_t stoint128(string s)
{
  int128_t x = 0, p = 1;

  for (int i = s.size() - 1; i >= 0; i--, p *= 10)
  {
    if (s[i] == '-')
      x = -x;
    else
      x += p * (s[i] - '0');
  }
  return x;
}

uint128_t stouint128(string s)
{
  uint128_t x = 0, p = 1;

  for (int i = s.size() - 1; i >= 0; i--, p *= 10)
  {
    x += p * (s[i] - '0');
  }
  return x;
}
""".}


type i128* {.header: "<stdint.h>", importcpp: "__int128".} = object
type u128* {.header: "<stdint.h>", importcpp: "unsigned __int128".} = object

# i <-> string converters
proc stouint128(s: cstring): u128 {.importcpp: "stouint128(@)".}
proc stoint128(s: cstring): i128 {.importcpp: "stoint128(@)".}

proc int128tos(i: i128): cstring {.importcpp: "int128tos(@)".}
proc uint128tos(i: u128): cstring {.importcpp: "uint128tos(@)".}

converter ito128*(i: int): i128 {.importcpp: "(__int128)#".}
converter itou128*(i: int): u128 {.importcpp: "(unsigned __int128)#".}
converter fto128*(f: float): i128 {.importcpp: "(__int128)#".}
converter uto128*(u: u128): i128 {.importcpp: "(__int128)#".}
converter ito128*(i: i128): u128 {.importcpp: "(unsigned __int128)#".}
converter i128toi*(i: i128): cint {.importcpp: "(int)#".}
converter u128toi*(i: u128): cint {.importcpp: "(int)#".}
converter ftou128*(f: float): u128 {.importcpp: "(unsigned __int128)#".}

# arithmetics
proc `+`*[t: i128|u128](x, y: t): t{.importcpp: "# + #".}
proc `-`*[t: i128|u128](x, y: t): t{.importcpp: "# - #".}
proc `*`*[t: i128|u128](x, y: t): t{.importcpp: "# * #".}
proc `div`*[t: i128|u128](x, y: t): t{.importcpp: "# / #".}
proc `/`*[t: i128|u128](x, y: t): float{.importcpp: "(double)# / #".}

proc `+=`*[t: i128|u128](x, y: t){.importcpp: "# += #".}
proc `-=`*[t: i128|u128](x, y: t){.importcpp: "# -= #".}
proc `*=`*[t: i128|u128](x, y: t){.importcpp: "# *= #".}
proc `/=`*[t: i128|u128](x, y: t){.importcpp: "# /= #".}

proc `%%`*[t: i128|u128](x, y: t): t{.importcpp: "# % #".}

proc inc*[t: i128|u128](x: t) {.importcpp: "++ #".}
proc dec*[t: i128|u128](x: t) {.importcpp: "-- #".}
proc `<<`*[t: i128|u128](x: t, n: int): t {.importcpp: "# << #".}
proc `>>`*[t: i128|u128](x: t, n: int): t {.importcpp: "# >> #".}

# comparision
proc `==`*[t: i128|u128](x, y: t):bool {.importcpp: "# == #".}
proc `!=`*[t: i128|u128](x, y: t):bool {.importcpp: "# != #".}
proc `>=`*[t: i128|u128](x, y: t):bool {.importcpp: "# >= #".}
proc `<=`*[t: i128|u128](x, y: t):bool {.importcpp: "# <= #".}
proc `>`*[t: i128|u128](x, y: t):bool {.importcpp: "# > #".}
proc `<`*[t: i128|u128](x, y: t):bool {.importcpp: "# < #".}

proc `=copy`*(x: var i128, y: i128) {.importcpp: "# = #".}

converter stoi128*(s: string): i128 = stoint128(s.cstring)
converter stou128*(s: string): u128 = stouint128(s.cstring)

proc high*[t: i128|u128](): t =
  if t is i128: (1.ito128 << 127) - 1
  else: (((1.itou128 << 127) - 1.itou128) * 2.itou128) + 1.itou128

proc `$`*[t: i128|u128](i: t): string =
  if t is i128: $int128tos(i)
  else: $uint128tos(i)

when isMainModule:
  var
    i: i128 = 123456
    j: i128 = 70000003.456
  j += i*j

  echo i==i, i!=i, i<0, i<=i, i>=i, i>0
  echo "i=", i
  i = "123456678678".stoi128
  echo "123456678678".stou128

  echo i, ",", j %% 1000
  echo "h u128=", high[u128]()
  echo "h i128=", high[i128]()
  i = 1
  i = (i << 127)-1
  echo i
  i.dec
  echo i
  i.inc
  echo i
