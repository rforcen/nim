#include <stdio.h>

#include <gmp.h>
#include <mpfr.h>

int main (void)
{
  unsigned int i;
  mpfr_t s, t, u;
  int precision=200;
  mp_rnd_t rand=MPFR_RNDD;
  int k=MPFR_NAN_KIND;

  mpfr_init2 (t, precision);
  mpfr_set_d (t, 1.0, rand);
  mpfr_init2 (s, precision);
  mpfr_set_d (s, 1.0, rand);
  mpfr_init2 (u, precision);
  for (i = 1; i <= 100; i++)
    {
      mpfr_mul_ui (t, t, i, MPFR_RNDU);
      mpfr_set_d (u, 1.0, rand);
      mpfr_div (u, u, t, rand);
      mpfr_add (s, s, u, rand);
    }
  printf ("Sum is ");
  mpfr_out_str (stdout, 10, 0, s, rand);
  putchar ('\n');
  mpfr_clear (s);
  mpfr_clear (t);
  mpfr_clear (u);
  mpfr_free_cache ();
  return 0;
}