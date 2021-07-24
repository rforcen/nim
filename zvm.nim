#
# scanner lexical analizer z-machine expressions
# parser & compiler
#
# zvm.nim

import math, complex, strutils

type Symbols* = enum
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

    # function names
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
    END = 200

const Predef_funcs* = [
        "acos(c(1,2)*log(sin(z^3-1)/z))",
        "c(1,1)*log(sin(z^3-1)/z)",
        "c(1,1)*sin(z)",
        "z + z^2/sin(z^4-1)",
        "log(sin(z)+1)",
        "cos(z)/(sin(z^4-1))",
        "z^6-1",
        "(z^2-1) * (z-c(2,1))^2 / (z^2+c(2,1))",
        "sin(z)*c(1,2)",
        "sin(1/z)",
        "sin(z)*sin(1/z)",
        "1/sin(1/sin(z))",
        "z",
        "(z^2+1)/(z^2-1)",
        "(z^2+1)/z",
        "(z+3)*(z+1)^2",
        "(z/2)^2*(z+c(1,2))*(z+c(2,2))/z^3",
        "(z^2)-0.75-c(0,0.2)",
        "z * sin( c(1,1)/cos(3/z) + tan(1/z+1) )"
    ]

const Function_names = ["sin", "cos", "tan", "exp", "log", "log10", "int",
        "sqrt", "asin", "acos", "atan", "abs", "c", "pi", "phi"]
const PHI* = 0.618033988

type Zvm* = object
    source: string
    ch: char
    ixs: int
    sym: Symbols
    ident: string
    nval: float
    err: bool
    code: seq[int]



proc getch(z: var Zvm): char =
    z.ch = '\0'
    if z.ixs < z.source.len:
        z.ch = z.source[z.ixs]
        inc z.ixs
    result = z.ch

proc getsym*(z: var Zvm): Symbols =
    z.sym = SNULL
    z.ident = ""
    z.nval = 0.0

    # skip whites
    while z.ch != '\0' and z.ch <= ' ':
        discard z.getch()

    # scan symbol
    if z.ch.isAlphaAscii(): # ident
        while z.ch.isAlphaNumeric() or z.ch == '_':
            z.ident.add(z.ch)
            discard z.getch()

        if z.ident == "z":
            z.sym = IDENTz
        elif z.ident == "i":
            z.sym = IDENTi
        else:
            # func ?
            let index = Function_names.find(z.ident)
            if index != -1: # sym = FSIN + index
                z.sym = Symbols(int(FSIN) + index)
            else: # error
                z.sym = SNULL

    elif z.ch.isDigit():
        # number
        while z.ch.isDigit() or z.ch == '.' or z.ch == 'e' or z.ch == 'E':
            z.ident.add(z.ch)
            discard z.getch()

        z.sym = NUMBER
        try:
            z.nval = parseFloat(z.ident) # atof
        except ValueError:
            z.nval = 0.0
            z.sym = SNULL

    else:
        z.sym = case z.ch
            of '+': PLUS
            of '-': MINUS
            of '*': MULT
            of '/': DIV
            of '(': OPAREN
            of ')': CPAREN
            of '^': POWER
            of '.': PERIOD
            of ',': COMMA
            else: SNULL

        discard z.getch()

    z.sym

# parser & compiler

proc gen(z: var Zvm, s: Symbols) = # code generator
    z.code.add(int(s))
    if s == PUSHC:
        z.code.add(cast[int](z.nval))

proc getsym_check(z: var Zvm, chk_sym: Symbols): Symbols = # getsym & check
    if z.getsym() != chk_sym:
        z.err = true
        z.sym = SNULL

    result = z.sym

proc sym_check(z: var Zvm, chk_sym: Symbols): Symbols = # check & getsym
    if z.sym != chk_sym:
        z.err = true
        z.sym = SNULL
    else:
        discard z.getsym()

    result = z.sym

proc getsym_not_null(z: var Zvm): Symbols =
    if z.getsym() == SNULL:
        z.err = true
    result = z.sym

# fwd declaration
proc c_e0(z: var Zvm)
proc c_e1(z: var Zvm)
proc c_e2(z: var Zvm)

proc c_e3(z: var Zvm) = # deeper expression term
    if not z.err:
        case z.sym:
            of OPAREN:
                discard z.getsym()
                z.c_e0()
                discard z.sym_check(CPAREN)

            of NUMBER:
                z.gen(PUSHC) # nval
                discard z.getsym()

            of IDENTi:
                z.gen(PUSHI)
                discard z.getsym()

            of IDENTz:
                z.gen(PUSHZ)
                discard z.getsym()

            of PLUS:
                discard z.getsym()
                z.c_e3()

            of MINUS:
                discard z.getsym()
                z.c_e3()
                z.gen(NEG)

            of FSIN, FCOS, FTAN, FASIN, FACOS, FATAN, FEXP, FINT, FABS, FLOG,
                    FLOG10, FSQRT:
                let tsym = z.sym
                discard z.getsym_check(OPAREN)
                z.c_e3()
                z.gen(tsym)

            of FC:
                discard z.getsym_check(OPAREN)
                discard z.getsym()
                z.c_e3()
                discard z.sym_check(COMMA)
                z.c_e3()
                discard z.sym_check(CPAREN)
                z.gen(FC)

            of SPI:
                discard z.getsym()
                z.nval = PI
                z.gen(PUSHC)

            of SPHI:
                discard z.getsym()
                z.nval = PHI
                z.gen(PUSHC)

            of SNULL: z.err = true
            else: z.err = true

proc c_e2(z: var Zvm) = # t ^ t
    if not z.err:
        z.c_e3()

        while true:
            case z.sym:
                of POWER:
                    discard z.getsym_not_null()
                    z.c_e2()
                    z.gen(POWER)
                else: break

proc c_e1(z: var Zvm) = # t {*/} t
    if not z.err:
        z.c_e2()
        while true:
            case z.sym:
                of MULT:
                    discard z.getsym_not_null()
                    z.c_e2()
                    z.gen(MULT)

                of DIV:
                    discard z.getsym_not_null()
                    z.c_e2()
                    z.gen(DIV)

                else: break

proc c_e0(z: var Zvm) = # t {+-} t
    if not z.err:
        z.c_e1()
        while true:
            case z.sym
                of PLUS:
                    discard z.getsym_not_null()
                    z.c_e1()
                    z.gen(PLUS)

                of MINUS:
                    discard z.getsym_not_null()
                    z.c_e1()
                    z.gen(MINUS)

                else: break

proc compile*(z: var Zvm) : bool = # compiler
    z.err = false
    z.ixs = 0
    z.ch = ' '
    z.sym = SNULL
    z.code = @[]

    discard z.getsym()
    z.c_e0()

    if z.err: z.code = @[]
    z.gen(END)

    result = not z.err

proc eval*(z: Zvm, zv: Complex): Complex =
    if z.err:
        return complex(0.0, 0.0)

    var
        pc: int = 0
        sp: int = 0
        stack = newSeq[Complex](16)

    while true:
        case cast[Symbols](z.code[pc]):
            of PUSHC:
                inc pc
                stack[sp] = complex(cast[float](z.code[pc]), 0.0)
                inc sp

            of PUSHZ:
                stack[sp] = zv
                inc sp

            of PUSHI:
                stack[sp] = complex(0.0, 1.0)
                inc sp

            of PLUS:
                dec sp
                stack[sp - 1] += stack[sp]

            of MINUS:
                dec sp
                stack[sp - 1] -= stack[sp]

            of MULT:
                dec sp
                stack[sp - 1] *= stack[sp]

            of DIV:
                dec sp
                stack[sp - 1] /= stack[sp]

            of POWER:
                dec sp
                stack[sp - 1] += stack[sp - 1].pow(stack[sp])

            of NEG:
                dec sp
                stack[sp - 1] = -stack[sp - 1]


            of FSIN: stack[sp - 1] = stack[sp - 1].sin()
            of FCOS: stack[sp - 1] = stack[sp - 1].cos()
            of FTAN: stack[sp - 1] = stack[sp - 1].tan()

            of FASIN: stack[sp - 1] = stack[sp - 1].arcsin()
            of FACOS: stack[sp - 1] = stack[sp - 1].arccos()
            of FATAN: stack[sp - 1] = stack[sp - 1].arctan()

            of FEXP: stack[sp - 1] = stack[sp - 1].exp()
            of FLOG: stack[sp - 1] = stack[sp - 1].ln()
            of FLOG10: stack[sp - 1] = stack[sp - 1].log10()
            of FSQRT: stack[sp - 1] = stack[sp - 1].sqrt()

            of FABS: stack[sp - 1] = complex(stack[sp - 1].abs(), 0.0)

            of FC:
                dec sp
                stack[sp - 1] = complex(stack[sp - 1].re, stack[sp].re)

            of END: break
            else: break

        inc pc


    result = if sp != 0: stack[sp - 1] else: complex(0.0, 0.0)

proc newZvm*(source: string): Zvm =
    result = Zvm(source: source, ch: ' ', ixs: 0, sym: SNULL, ident: "",
            nval: 0.0, err: false, code: @[])
    discard result.compile()

when isMainModule:
    
    {.warnings: off.}
    proc test_scan =
        for s in Predef_funcs:
            var zvm = newZvm(s)
            echo zvm.source
            while zvm.getsym() != SNULL: write(stdout, zvm.sym, " ")
            echo ""
    proc test_compile_eval =
        for s in Predef_funcs:
            var zvm = newZvm(s)
            echo zvm.source
            if zvm.compile():
                for c in zvm.code:
                    if c in int(SNULL)..int(END): write(stdout, Symbols(c), " ")
                    else: write(stdout, cast[float](c), " ")
                echo "\n------------------"
                for i in 0..10: write(stdout, zvm.eval(complex(float(i)/10.0, float(i)/20.0)))
                echo "\n------------------"

    import times
    proc benchmark_eval =
        let n = 1000000
        echo "zvm benchmark ", n, " iters"

        for zexpr in Predef_funcs:
            var zvm = newZvm(zexpr)
            if zvm.compile():
                let t0 = now()

                for i in 0..n:
                    let z = zvm.eval(complex(float(i)/10.0, float(i)/20.0))
                echo (now()-t0).inMilliseconds(), "ms: ", zexpr

    # test_scan()
    # echo int2flt(flt2int(123.456e23))
    # let c  = complex(0.0, 0.0)
    # echo sizeof(c) # 8+8 = 16
    # test_compile_eval()
    benchmark_eval()
    # let f = 123.456e3
    # echo f, ",", cast[float](cast[int](f))
