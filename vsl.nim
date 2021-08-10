# VSL

import strutils, strformat, unicode, math,
       streams, sugar, sequtils, times, threadpool, cpuinfo, os

import vsl_scanner, vsl_compiler;


type VSL = object
  sample_rate, bits_sample, floating_point: int
  seconds, volume: float

  compiler: Compiler
  tv: seq[float]
  samples: seq[float32]

proc newVSL*(): VSL =
  VSL(sample_rate: 44100, bits_sample: 32, floating_point: 1,
      seconds: 5.0, volume: 0.3, samples: @[])


# execute
func n_chan*(v: VSL): int = v.compiler.ch

func n_samples*(v: VSL): int = int(v.sample_rate.float * v.seconds)
func n_tot_samples*(v: VSL): int = int(v.sample_rate.float * v.seconds) * v.n_chan

func time_inc*(v: VSL): float = PI*2.0/v.sample_rate.float

proc execute_chan*(vsl: var VSL, chan: int, t: float): float

proc execute_let(vsl: var VSL, t: float)

proc execute*(vsl: var VSL, t: float, ar: AddrRange): float =
  var
    err_calc = false
    stack: array[32, float]
    sp: pcode = 0
    pc = ar.frm

    n_params = newSeq[pcode](32)
    sp_base = newSeq[pcode](32)
  let
    code = vsl.compiler.code

  while pc < ar.to:
    case cast[Symbols](code[pc]):
      of PUSH_CONST:
        inc pc
        stack[sp] = cast[float](code[pc])
        inc sp
      of PUSH_T:
        stack[sp] = t
        inc sp
      of PUSH_ID:
        inc pc
        stack[sp] = vsl.tv[code[pc]]
        inc sp
      of POP:
        inc pc
        vsl.tv[code[pc]] = stack[sp-1]
        dec sp

      of PARAM: # push param
        inc pc
        stack[sp] = stack[sp_base[^1] - 1 - n_params[^1] + code[pc]]
        inc sp
      of FUNC: # call address n.params
        stack[sp] = (pc + 3).float
        inc sp
        n_params.add(code[pc + 2])
        sp_base.add(sp)
        pc = code[pc + 1].int
        continue # jump to func call
      of RET: # ret n.params
        let nr = cast[pcode](code[pc + 1]).int
        pc = (stack[sp-2]).pcode
        stack[sp-(nr + 2)] = stack[sp-1]
        sp -= nr + 2 - 1
        discard sp_base.pop()
        discard n_params.pop()
        continue

      of PLUS: dec sp; stack[sp-1]+=stack[sp]
      of MINUS: dec sp; stack[sp-1]-=stack[sp]
      of MULT: dec sp; stack[sp-1]*=stack[sp]
      of DIV: dec sp; stack[sp-1]/=stack[sp]

      of EQ, NE, GT, GE, LT, LE: discard

      of POWER: dec sp; stack[sp-1] = pow(stack[sp-1], stack[sp])

      of FACT: 
        func factorial(n:int) : float=
          if n>1: n.float * factorial(n-1)
          else: 1.float
          
        stack[sp-1] = factorial(stack[sp-1].int)

      of NEG: stack[sp-1] = -stack[sp-1]

      of FSIN: stack[sp-1] = sin(stack[sp-1])
      of FCOS: stack[sp-1] = cos(stack[sp-1])
      of FTAN: stack[sp-1] = tan(stack[sp-1])
      of FASIN: stack[sp-1] = arcsin(stack[sp-1])
      of FACOS: stack[sp-1] = arccos(stack[sp-1])
      of FATAN: stack[sp-1] = arctan(stack[sp-1])
      of FEXP: stack[sp-1] = exp(stack[sp-1])
      of FINT: stack[sp-1] = floor(stack[sp-1])
      of FABS, ABS: stack[sp-1] = abs(stack[sp-1])
      of FLOG: stack[sp-1] = ln(stack[sp-1])
      of FLOG10: stack[sp-1] = log10(stack[sp-1])

      of FSQRT: stack[sp-1] = sqrt(stack[sp-1])
      of SEC: stack[sp-1]*=2.0 * PI
      of OSC: stack[sp-1] = sin(t*stack[sp-1])

      of NOTE_CONST:
        const
          note_val = [0, 2, 4, 5, 7, 9, 11]
          central_do = 261.626
          temperate_inc = 0.166666667 # 2^(1/12)
        inc pc
        stack[sp] = central_do * temperate_inc *
           (note_val[code[pc] - N_DO.pcode]).float # central is 0
        inc sp

      of SWAVE1: stack[sp-1] = sin(t*stack[sp-1])
      of SWAVE2:
        stack[sp-2] *= sin(t*stack[sp-1])
        dec sp
      of SWAVE:
        stack[sp-3] *= sin(t*stack[sp-2] + stack[sp-1])
        dec sp
        dec sp

      else:
        err_calc = true
        break

    inc pc

  if err_calc or sp != 1:
    0.0
  else:
    stack[sp-1]

proc set_value(vsl: var VSL, id: string) =
  let ix = vsl.compiler.get_id(us id)
  if ix != -1:
    case id:
    of "seconds": vsl.seconds = vsl.tv[ix]
    of "volume": vsl.volume = vsl.tv[ix]
    of "sample_rate": vsl.sample_rate = vsl.tv[ix].int

proc execute_chan*(vsl: var VSL, chan: int, t: float): float =
  vsl.execute(t, vsl.compiler.blk_addr.get_code(chan))

proc execute_let(vsl: var VSL, t: float) =
  discard vsl.execute(t, vsl.compiler.blk_addr.get_let())

proc execute_const(vsl: var VSL) =
  vsl.tv = collect(newSeq): # copy table values, vsl.tv = vsl.compiler.tab_values.di
    for tv in vsl.compiler.tab_values: tv.di

  discard vsl.execute(0.0, vsl.compiler.blk_addr.get_const())

  vsl.set_value("seconds")
  vsl.set_value("volume")
  vsl.set_value("sample_rate")

  # echo "tv=", vsl.tv

proc generate_st*(vsl: var VSL, expr: string): bool =
  vsl.compiler = newCompiler(expr)
  if vsl.compiler.compile():

    vsl.execute_const() # const & assign vsl wave values

    var (maxv, minv) = (-high(float32), high(float32))

    vsl.samples = collect(newSeq): # generate all sample values
      for ns in 0..<vsl.n_samples:
        let t = ns.float * vsl.time_inc

        vsl.execute_let(t)

        for chan in 0..<vsl.n_chan:
          let samp = vsl.execute_chan(chan, t).float32

          (minv, maxv) = (min(minv, samp), max(maxv, samp))

          samp

    # normalize
    let diff = (maxv-minv).abs
    if diff != 0.0: vsl.samples.applyIt(vsl.volume.float32 * it / diff)

    true
  else:
    false

# multithread mt support
proc gen_chunk(vsl: var VSL, i, n: int, samples: var seq[float32],
    min_max: var seq[(float32, float32)]) = # min, max
  let
    size = samples.len
    chunk_sz = size div n
    rfrom = i * chunk_sz
    rto = if (i+1) * chunk_sz > size: size else: (i+1) * chunk_sz

  var (maxv, minv) = (-high(float32), high(float32))

  for index in rfrom..<rto:
    let
      t = (index div vsl.n_chan).float * vsl.time_inc
      chan = index %% vsl.n_chan

    vsl.execute_let(t)
    let samp = vsl.execute_chan(chan, t).float32

    (minv, maxv) = (min(minv, samp), max(maxv, samp))

    samples[index] = samp

  min_max[i] = (minv, maxv) # min max of this chunk


proc generate_mt*(vsl: var VSL, expr: string): bool =

  proc normalize(samples: var seq[float32], min_max: seq[(float32, float32)],
      volume: float32) = # normalize w/min_max from chunks
    var gmm = min_max[0]

    for mm in min_max:
      gmm[0] = gmm[0].min(mm[0])
      gmm[1] = gmm[1].max(mm[1])

    let diff = (gmm[1]-gmm[0]).abs
    if diff != 0.0: samples.applyIt(volume * it / diff)


  vsl.compiler = newCompiler(expr)
  if vsl.compiler.compile():

    vsl.execute_const() # const & assign vsl wave values

    let nth = countProcessors()
    var
      vs = vsl.repeat(nth) # nth instances of vsl
      samples = newSeq[float32](vsl.n_tot_samples)
      min_max = newSeq[(float32, float32)](nth)

    parallel:
      for i in 0..<nth:
        spawn vs[i].gen_chunk(i, nth, samples, min_max)

    normalize(samples, min_max, vsl.volume.float32)

    vsl.samples = samples
    true
  else:
    false

proc write*(v: VSL, fn: string) = # write image to binary file
  var f = newFileStream(fn, fmWrite)
  if not f.isNil:
    f.writeData(v.samples[0].unsafeAddr, v.samples.len * sizeof(v.samples[0]))
    f.close()

# test cases

when isMainModule:

  proc main =

    let source = if paramCount() == 1: readFile(paramStr(1)) else:  readFile("test.vsl")

    # echo source

    var vsl = newVSL()

    let t0 = now()
    if vsl.generate_mt(source):

      let lap = (now()-t0).inMilliseconds()

      vsl.write("vsl.fbw")
      echo fmt("generated, lap:{lap}ms, vsl.fbw file, channels:{vsl.n_chan}, sample rate:{vsl.sample_rate}, seconds:{vsl.seconds}, 32 bits float ")

    else: echo vsl.compiler.get_error()

  
  main()
