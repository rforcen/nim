# expression interpreter & llvm compiler

import patty, strutils, nimly, tables
import llvm

const funcNames* = ["sin","cos","tan","log","exp"]

var 
  jit :JIT 
  dblt : ptr Type 
  function : ptr Function
  fpow : ptr Function
  funcTable : Table[string, ptr Function]

## lexer
variant ExpressionTokens:
  PLUS
  MINUS
  MULTI
  DIVISION
  POWER
  NUM(val: float)
  LPAREN
  RPAREN
  FUNCTION(name : string)
  ARGUMENT(index : int)
  COMMA
  WAVE
  IGNORE

niml expressionLexer[ExpressionTokens]:
  r"\(":  LPAREN()
  r"\)":  RPAREN()
  r"\+":  PLUS()
  r"-":   MINUS()
  r"\*":  MULTI()
  r"/":   DIVISION()
  r"^":   POWER()
  r"," :  COMMA()
  
  r"(\d*\.)?\d+":  NUM(parseFloat(token.token))
  r"wave" : WAVE()
  r"[a..z]+" :  FUNCTION(token.token)
  r"$\d" : ARGUMENT(parseInt(token.token[1..^1]) - 1) # start on 1, i.e. $1, $2, ...

  r"\s":  IGNORE()

  setUp:   discard
  tearDown:discard

nimy expressionParser[ExpressionTokens]:
  top[ptr Value]:
    term: 
      result = $1
      discard jit.ret($1)

  term[ptr Value]:
    term PLUS factor:  jit.fadd($1, $3)
    term MINUS factor: jit.fsub($1, $3)
    factor: $1

  factor[ptr Value]:
    factor MULTI power:    jit.fmul($1, $3)
    factor DIVISION power: jit.fdiv($1, $3)
    power: $1

  power[ptr Value]:
    power POWER num: jit.fcall(fpow, @[$1,$3])
    num : $1

  num[ptr Value]:
    LPAREN term RPAREN: $2

    WAVE LPAREN term COMMA term COMMA term RPAREN:
      jit.fmul($3, jit.fcall(funcTable["sin"], @[jit.fadd($5, $7)])) # $3 * sin($5 + $7)

    FUNCTION LPAREN term RPAREN : jit.fcall(funcTable[($1).name], @[$3])      

    NUM: jit.initDbl(($1).val)

    ARGUMENT: function[($1).index] # range not checked!

##
proc compileLLVM*(funcName, expr:string):proc(x:float):float{.cdecl.}=
  jit = newJIT("expr.module")
  dblt = jit.getDoubleTy
  fpow = jit.CreateFunction(dblt, @[dblt, dblt], "pow") # pow(x,y)

  # create function table
  for f in funcNames: funcTable[f]=jit.CreateFunction(dblt, @[dblt], f.cstring)

  function = jit.CreateFunctionBlock(dblt, @[dblt], funcName)

  # compile
  var exprLexer = expressionLexer.newWithString(expr)
  exprLexer.ignoreIf = proc(r: ExpressionTokens): bool = r.kind == ExpressionTokensKind.IGNORE
  var parser = expressionParser.newParser()
 
  discard parser.parse(exprLexer)
    
  # func address
  let func_addr = jit.getFuncAddr(funcName)
  cast[proc(t: float):float {.cdecl.}] ( func_addr )

when isMainModule:
  import times, strformat

  proc testLlvmExpr=
  
    echo "benchmarking nimly-llvm"

    let
      expr = "((cos((log((1.24+$1))))+$1+$1*$1+7.97*$1*$1+$1*6.09))" # "1*$1+2+3*$1+4+5+6+7+8+9+1+2+3+4+5+6+7+8+9+$1" #"sin(( 2 - 3.45 * $1 ) / 4 * 34.56) ^ 4"
      cfunc = compileLLVM("foo",expr)
    
    jit.printIR()
    let
      t = 2.3
      n = 10_000_000
      t0 = now()

    for _ in 0..n:
      let _ = cfunc(t)
      
    echo &"llvm lap for {n}:{(now()-t0).inMilliseconds}ms, {expr}({t})={cfunc(t)}"
    
  proc testMultFunc=
    let f00=compileLLVM("f00","1+2*sin(34*$1)")
    echo f00(1.0)
    let f01=compileLLVM("f01","3+4/tan(sin($1*45))")
    echo f01(1.0)

    # jit.printIR()

  
  testMultFunc()
  # testLlvmExpr()