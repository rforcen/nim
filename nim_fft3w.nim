# fftw3 wrapper

import complex

{.passL:"-lfftw3 -lm".}

const 
  fftw3_header="<fftw3.h>"
  
  FFTW_FORWARD* = -1
  FFTW_BACKWARD* = 1

  FFTW_MEASURE* = 0 
  FFTW_ESTIMATE* = 1 shl 6
  FFTW_PATIENT* = 1 shl 5      
  FFTW_EXHAUSTIVE* = 1 shl 3 # optimal plan

type 
  fftw_plan* = pointer
  fftw_complex = array[2, cdouble] 

# plan creation
proc fftw_plan_dft_1d*(n: cint, inptr: ptr UncheckedArray[fftw_complex], outptr: ptr UncheckedArray[fftw_complex], sign: cint,
        flags: cuint): fftw_plan {.cdecl, importc: "fftw_plan_dft_1d", header:fftw3_header.}

# clean up
proc fftw_destroy_plan*(p: fftw_plan) {.cdecl, importc: "fftw_destroy_plan", header:fftw3_header.}
proc fftw_cleanup*() {.cdecl, importc: "fftw_cleanup", header:fftw3_header.}

# exec
proc fftw_execute*(p: fftw_plan) {.cdecl, importc: "fftw_execute", header:fftw3_header.}

# converters
converter fc2c*(c:fftw_complex) : Complex64 = complex64(c[0], c[1])
converter c2fc*(c:Complex64) : fftw_complex = [c.re, c.im]
converter s2p(c:seq[Complex64]):ptr UncheckedArray[fftw_complex] = cast[ptr UncheckedArray[fftw_complex]](c[0].unsafeAddr)
converter i2ci(i:int):cint=i.cint

# nim wrapper for a simple fwd complex fft
type FFT = object
  n* : int
  plan* : fftw_plan
  cin*, cout* : seq[Complex64]

proc `=destroy`*(fft:var FFT) =
  if fft.plan!=nil: fftw_destroy_plan(fft.plan)
  fft.plan=nil

proc fft*(n:int) : FFT = 
  result = FFT(n:n, cin:newSeq[Complex64](n), cout:newSeq[Complex64](n))
  result.plan = fftw_plan_dft_1d(n, result.cin, result.cout , FFTW_FORWARD, FFTW_MEASURE)

proc exec*(fft:var FFT) = fftw_execute(fft.plan)

##################
when isMainModule:
  import times

  proc test_fft=
    let n = 1024 * 16
    var fft = fft(n)

    for i in 0..1000:  
      for j in 0..<n: fft.cin[j]=complex64((i+j).float / n.float, 0.0)
      fft.exec()
    
    echo fft.cout[0..3]
    echo fft.cout[^3..^1]
    

  proc test_nimw=

    let n = 1024 * 16
    var
      cin = newSeq[Complex64](n)
      cout = cin

    var t0 = now()
    write stdout, "creating plan..."
    var plan = fftw_plan_dft_1d(n, cin, cout , FFTW_FORWARD, FFTW_MEASURE)
    echo "lap:", (now()-t0).inMilliseconds

    write stdout, "evaluating set of inputs.."
    t0=now()
    for i in 0..1000:  
      for j in 0..<n: cin[j]=complex64((i+j).float / n.float, 0.0)
      fftw_execute(plan)
    echo "lap:", (now()-t0).inMilliSeconds

    echo "done"
    fftw_destroy_plan(plan)
    echo cout[0..3]
    echo cout[^3..^1]

  test_nimw()
  test_fft()
  echo "ok"
