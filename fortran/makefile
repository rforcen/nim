libalgebra:
	@gfortran -c -Ofast libalgebra.f90
	@nim c -r -d:release libalgebra

493:
	@gfortran -c -Ofast -fdefault-real-8 493.f
	@nim c -r -d:release n493

param: param.nim 493.f param.f
	@gfortran -c -Ofast -fdefault-real-8 param.f 493.f paramf90.f90 libalgebra.f90
	@rm -f param
	@nim c -r param -verbosity:0
