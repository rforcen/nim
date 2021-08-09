#
# vsl compiler
#

import sets, math, random
import vsl_scanner

{.experimental: "parallel".}


type NotationType = enum Notation_Algebraic, Notation_RPN
type TypesVar = enum NUM_ID, STRING_ID, PARAM_ID, FUNC_ID

type TableValues* = object
  id*: wstring
  its_type*: TypesVar
  str_ix: int
  di*: float
  address, param_ix, n_params: int

# Block Address

type AddrRange* = object
  frm*, to*: pcode

const max_chan = 128
type BlockAddr = object
  a_const, a_let, a_func: AddrRange
  a_code: array[max_chan, AddrRange]
  last_to: int

proc set_const(ba: var BlockAddr, f, t: int) =
  ba.a_const = AddrRange(frm: f, to: t)
  ba.last_to = t

proc set_let(ba: var BlockAddr, t: int) =
  ba.a_let = AddrRange(frm: ba.last_to, to: t)
  ba.last_to = t

proc set_func(ba: var BlockAddr, t: int) =
  ba.a_func = AddrRange(frm: ba.last_to, to: t)
  ba.last_to = t

proc set_code(ba: var BlockAddr, ch, t: int) =
  ba.a_code[ch] = AddrRange(frm: ba.last_to, to: t)
  ba.last_to = t

proc get_const*(ba: BlockAddr): AddrRange = ba.a_const
proc get_let*(ba: BlockAddr): AddrRange = ba.a_let
proc get_func*(ba: BlockAddr): AddrRange = ba.a_func
proc get_code*(ba: BlockAddr, i: int): AddrRange = ba.a_code[i]


type Compiler* = object
  scanner*: Scanner
  err*: bool
  notation: NotationType
  tab_values*: seq[TableValues]
  nid: int
  ch*: int
  blk_addr*: BlockAddr
  code*: seq[pcode]

# fwd decls
proc expr_0(c: var Compiler)
proc expr_1(c: var Compiler)
proc expr_2(c: var Compiler)
proc expr_3(c: var Compiler)
proc parse_id_eq_expr(c: var Compiler)
proc rpn_expr(c: var Compiler)
proc generate(c: var Compiler, token: Symbols)
proc generate_i(c: var Compiler, token: Symbols, i: int)
proc generate_2i(c: var Compiler, token: Symbols, p0: int, p1: int)
proc generate_f(c: var Compiler, token: Symbols, f: float)
proc compile_algebraic(c: var Compiler)
proc compile_rpn(c: var Compiler)
proc parse_const(c: var Compiler)
proc parse_let(c: var Compiler)
proc parse_funcs(c: var Compiler)

func get_id*(c: Compiler, id: wstring): int =
  var rv: int = (-1)
  for i in 0..<c.tab_values.len:
    if id == c.tab_values[i].id:
      return i
  rv
proc get_ident_index(c: Compiler): int =
  c.get_id(c.scanner.get_id())
func get_pc(c: var Compiler): int = c.code.len
proc getsym(c: var Compiler) = discard c.scanner.getsym()
proc getsymr(c: var Compiler): Symbols = c.scanner.getsym()
proc getsym_check(c: var Compiler, sym: Symbols): Symbols =
  c.err = c.getsymr() != sym
  c.scanner.sym
proc check_sym(c: var Compiler, sym: Symbols) = c.err = sym != c.scanner.sym
proc check_getsym(c: var Compiler, check_symbol: Symbols): Symbols =
  c.check_sym(check_symbol)
  c.getsym()


proc newCompiler*(expr: string): Compiler =
  Compiler(scanner: newScanner(expr), err: false, notation: Notation_Algebraic,
      tab_values: @[], nid: 0)

proc compile*(c: var Compiler): bool =
  case c.getsymr():
  of ALGEBRAIC:
    c.notation = Notation_Algebraic
    discard c.getsym_check(SEMICOLON)
    c.getsym()
    c.compile_algebraic()
  of RPN:
    c.notation = Notation_RPN
    discard c.getsym_check(SEMICOLON)
    c.getsym()
    c.compile_rpn()
  else:
    c.notation = Notation_Algebraic
    c.compile_algebraic()

  not c.err

proc compile_rpn(c: var Compiler) =
  c.parse_const() # const let var0=expr, var1=expr

  if not c.err:
    c.parse_let()
    c.parse_funcs()

    Do:
      c.rpn_expr()

      discard c.check_getsym(SEMICOLON)
      c.blk_addr.set_code(c.ch, c.get_pc())
      inc c.ch

      While c.scanner.sym != SNULL and not c.err

proc compile_algebraic(c: var Compiler) =
  c.parse_const() # const let var0=expr, var1=expr

  if not c.err:
    c.parse_let()
    c.parse_funcs()

    Do:
      c.expr_0() #  expr per channel

      let ls = c.scanner.sym

      if not c.err and c.scanner.sym == SEMICOLON:
        c.blk_addr.set_code(c.ch, c.get_pc())
        inc c.ch
        c.check_sym(SEMICOLON)
        c.getsym()

      While ls == SEMICOLON and not c.err

proc parse_const(c: var Compiler) =
  if c.scanner.sym == CONST: # const sample_rate=expr, bits_sample=expr
    c.parse_id_eq_expr()
    c.blk_addr.set_const(0, c.get_pc())


proc parse_let(c: var Compiler) =
  if c.scanner.sym == LET:
    c.parse_id_eq_expr()
    c.blk_addr.set_let(c.get_pc())


proc parse_funcs(c: var Compiler) =
  while c.scanner.sym == FUNC:
    discard c.getsym_check(IDENT)

    c.tab_values.add(TableValues(id: c.scanner.get_id(), its_type: FUNC_ID,
        address: c.get_pc(), n_params: 0))

    var
      ixtv = c.tab_values.len
      param_ix = 0

    if c.getsymr() == OPAREN:

      Do:
        discard c.getsym_check(IDENT)
        c.tab_values.add(Table_Values(id: c.scanner.get_id(),
            its_type: PARAM_ID, param_ix: param_ix))
        inc param_ix
        While c.getsymr() == COMMA and not c.err
      discard c.check_getsym(CPAREN)

    discard c.check_getsym(RET) # ->

    case c.notation:
      of Notation_RPN:
        c.rpn_expr()
      of Notation_Algebraic:
        c.expr_0()

    discard c.check_getsym(SEMICOLON)

    c.tab_values.setLen(ixtv) # remove refs. to parameters
    c.tab_values[^1].n_params = param_ix # save # of args in last item

    c.generate_i(RET, param_ix)

  c.blk_addr.set_func(c.get_pc()) # jump over fun def

proc parse_id_eq_expr(c: var Compiler) = # id=expr, id=expr
  Do:
    if c.getsymr() == IDENT:
      let id = c.scanner.get_id()
      if c.getsymr() == EQ:
        c.getsym()

        case c.notation:
        of Notation_Algebraic:
          c.expr_0()
        of Notation_RPN:
          c.rpn_expr()

        c.tab_values.add(TableValues(id: id, its_type: NUM_ID))

        c.generate_i(POP, c.nid)
        inc c.nid
      else:
        c.err = true
    else:
      c.err = true

    While c.scanner.sym == COMMA and not c.err

  if c.scanner.sym == SEMICOLON:
    c.getsym()
  else:
    c.err = true

proc starts_implicit_mult(c: var Compiler): bool =
  const implicit_mult_start = toHashSet([
        IDENT, IDENT_t, OCURL, OSQARE, OLQUOTE, OPAREN,
        SPI, SPHI, NUMBER, RANDOM, TILDE])
  implicit_mult_start.contains(c.scanner.sym) or (c.scanner.sym >= FSIN and
      c.scanner.sym <= MAGNETICRING)

# code generation
proc generatef(c: var Compiler, token: Symbols, f: float) =
  c.code.add(token.pcode)
  c.code.add(cast[pcode](f))

proc generate_i(c: var Compiler, token: Symbols, i: int) =
  c.code.add(token.pcode)
  c.code.add(i.pcode)

proc generate_2i(c: var Compiler, token: Symbols, p0: int, p1: int) =
  c.code.add(token.pcode)
  c.code.add(p0.pcode)
  c.code.add(p1.pcode)

proc generate(c: var Compiler, token: Symbols) =
  c.code.add(token.pcode)

proc expr_0(c: var Compiler) =

  if not c.err:

    let is_neg = (c.scanner.sym == MINUS)
    if is_neg: c.getsym()

    c.expr_1()

    if is_neg:
      c.generate(NEG)

    const op_set = toHashSet([EQ, NE, LT, LE, GT, GE, PLUS, MINUS])

    Do:
      let sym_op = c.scanner.sym
      if op_set.contains(sym_op):
        c.getsym()
        c.expr_1()
        c.generate(sym_op)

      While op_set.contains(c.scanner.sym) and not c.err


proc expr_1(c: var Compiler) =

  if not c.err:
    c.expr_2()
    Do:

      let sym_op = c.scanner.sym
      if c.starts_implicit_mult(): # not operator-> implicit *, i,e. 2{440}
        c.expr_2()
        c.generate(MULT)
      else:
        case c.scanner.sym:

        of MULT, DIV:
          c.getsym()
          c.expr_2()
          c.generate(sym_op)

        else: discard


      While (c.scanner.sym == MULT or c.scanner.sym == DIV or
          c.starts_implicit_mult()) and not c.err

proc expr_2(c: var Compiler) =

  if not c.err:

    c.expr_3()
    Do:

      if c.scanner.sym == POWER:

        c.getsym()
        c.expr_3()
        c.generate(POWER)

      While (c.scanner.sym == POWER) and not c.err

proc expr_3(c: var Compiler) =

  if not c.err:

    case c.scanner.sym:

    of OPAREN:
      c.getsym()
      c.expr_0()
      c.check_sym(CPAREN)
      c.getsym()
    of NUMBER:
      c.generate_f(PUSH_CONST, c.scanner.get_num())
      c.getsym()
    of FLOAT:
      c.generate_f(PUSH_CONST, -32.0) # this is the floating_point=true value
      c.getsym()
    of IDENT_t: #  't' special var is the parameter in eval call
      c.generate(PUSH_T)
      c.getsym()
    of IDENT:

      let idix = c.get_ident_index()
      if idix != -1:
        var tv = c.tab_values[idix]
        case tv.its_type:

        of NUM_ID: c.generate_i(PUSH_ID, idix)
        of PARAM_ID: c.generate_i(PARAM, tv.param_ix)
        of FUNC_ID:
          if tv.n_params != 0:
            discard c.getsym_check(OPAREN)
            c.getsym()
            for np in 0..<tv.n_params - 1:
              c.expr_0()
              discard c.check_getsym(COMMA)

            c.expr_0()
            c.check_sym(CPAREN)

          c.generate_2i(FUNC, tv.address, tv.n_params)
        else: c.err = true
      else:
        c.err = true

      c.getsym()
    of MINUS:
      c.getsym()
      c.expr_3()
      c.generate(NEG)
    of PLUS:
      c.getsym()
      c.expr_3() # +expr nothing to generate
    of FACT:
      c.getsym()
      c.expr_3()
      c.generate(FACT)
    of TILDE:
      c.getsym()
      c.expr_3()
      c.generate(SWAVE1)

    of RANDOM:
      c.generate_f(PUSH_CONST, rand(1.0))
      c.getsym()
    of OCURL: # hz, amp,hz, amp, hz, phase
      c.getsym()
      c.expr_0()
      if c.scanner.sym == COMMA:
        c.getsym()
        c.expr_0()
        if c.scanner.sym == COMMA:
          c.getsym()
          c.expr_0()
          c.generate(SWAVE)
        else:
          c.generate(SWAVE2)
      else:
        c.generate(SWAVE1)
      discard c.check_getsym(CCURL)
    of OSQARE: # []==sec
      c.getsym()
      c.expr_0()

      c.generate(SEC)
      discard c.check_getsym(CSQUARE)

    of VERT_LINE: # |abs|
      c.getsym()
      c.expr_0()

      c.generate(ABS)
      discard c.check_getsym(VERT_LINE)

    of OLQUOTE: # «f»  -> exp(f*t)
      c.getsym()
      c.expr_0()
      discard c.check_getsym(CLQUOTE)

      c.generate(PUSH_T)
      c.generate(MULT)
      c.generate(FEXP)

    of BACKSLASH: # \s:e\ -> lap(start, end)
      c.getsym()
      if c.scanner.sym == COLON: # \:e\ -> lap(0, end)
        c.generate_f(PUSH_CONST, 0.0)
      else:
        c.expr_0()
      c.getsym() # :
      c.expr_0()
      discard c.check_getsym(BACKSLASH) # '\'
      c.generate(LAP)
    of FSIN, FCOS, FTAN, FASIN, FACOS, FATAN, FEXP, FINT, FABS, FLOG,
        FLOG10, FSQRT, SEC, OSC, ABS:
      let tsym = c.scanner.sym
      c.getsym()
      c.expr_3()
      c.generate(tsym)
    of SPI:
      c.getsym()
      c.generate_f(PUSH_CONST, PI)
    of SPHI:
      c.getsym()
      c.generate_f(PUSH_CONST, phi)
    of SWAVE: # wave(amp, hz, phase)
      discard c.getsym_check(OPAREN)
      c.getsym()
      c.expr_0()
      discard c.check_getsym(COMMA)
      c.expr_0()
      discard c.check_getsym(COMMA)
      c.expr_0()
      discard c.check_getsym(CPAREN)

      c.generate(SWAVE)

    of N_DO..N_SI:
      c.generate_i(NOTE_CONST, c.scanner.sym.int)
      c.getsym()

    # 2 parameter procs.
    of NOTE, # note(note#,oct)
      TONE, # tone(note#,oct)
      LAP, # lap(time1,time2)
      HZ2OCT: # hz2oct(hz,oct)

        let tsym = c.scanner.sym
        discard c.getsym_check(OPAREN)
        c.getsym()
        c.expr_0()
        discard c.check_getsym(COMMA)
        c.expr_0()
        discard c.check_getsym(CPAREN)
        c.generate(tsym)
    of SAW: # saw(freq, alpha)
      c.getsym()
      c.getsym()
      c.expr_0()
      if c.scanner.sym == COMMA:
        c.getsym()
        c.expr_0()
        c.getsym()
        c.generate(SAW)
      else:
        c.getsym()
        c.generate(SAW1)

    of MAGNETICRING: # MagnetRing(Vol, Hz, Phase, on_count,
                           # off_count)
      c.getsym()
      c.getsym()
      c.expr_0()
      c.getsym()
      c.expr_0()
      c.getsym()
      c.expr_0()
      c.getsym()
      c.expr_0()
      c.getsym()
      c.expr_0()
      c.getsym()
      c.generate(MAGNETICRING)

    of SNULL: discard

    else: c.err = true # syntax error

proc rpn_expr(c: var Compiler) =

  Do:

    case c.scanner.sym:

    of NUMBER:
      c.generate_f(PUSH_CONST, c.scanner.get_num())
    #  't' special var is the parameter in eval call
    of IDENT_t:
      c.generate(PUSH_T)
    of IDENT:

      let idix = c.get_ident_index()
      if idix != -1:

        let tv = c.tab_values[idix]
        case tv.its_type:

        of NUM_ID: c.generate_i(PUSH_ID, idix)
        of PARAM_ID: c.generate_i(PARAM, tv.param_ix)
        of FUNC_ID: c.generate_2i(FUNC, tv.address, tv.n_params)

        else: c.err = true
    of SPI:
      c.generate_f(PUSH_CONST, PI)
    of SPHI:
      c.generate_f(PUSH_CONST, phi)
    of TILDE:
      c.generate(SWAVE1)


    of MINUS, PLUS, DIV, MULT,
      FSIN, FCOS, FTAN, FASIN, FACOS, FATAN, FEXP, FINT, FABS, FLOG,
          FLOG10, FSQRT, SEC, OSC, ABS:
      c.generate(c.scanner.sym)

    of N_DO..N_SI:
      c.generate_i(NOTE_CONST, c.scanner.sym.int) #c.scanner.get_i0(), c.scanner.get_i1())

    of SNULL: discard
    else:
      c.err = true

    c.getsym()
    if not (c.scanner.sym != SEMICOLON and c.scanner.sym != COMMA and
        c.scanner.sym != SNULL): break

proc get_error*(c: Compiler): string = c.scanner.get_error()
