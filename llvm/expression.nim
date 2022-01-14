# expression interpreter & vm compiler run time

import math, patty, strutils, nimly

# vm
type 
  pCode = enum pNIL, pPUSH, pPLUS, pMINUS, pNUM, pMULT, pDIV, pPOWER, pSIN, pCOS, pTAN, pLOG, pEXP, pARG

  Code = seq[int64]
  
var code:Code

proc push(code:var Code, p:pCode) = code.add(cast[int64](p))
proc push(code:var Code, f:float) = 
  code.push(pPUSH)
  code.add(cast[int64](f))
proc push(code:var Code, i:int) = 
  code.push(pARG)
  code.add(cast[int64](i))

proc init(code:var Code)=code.setLen 0

proc print(code:var Code)=
  echo "-----------------------------------"
  var i = 0
  while i<code.len:
    case cast[pCode](code[i]):
    of pPUSH:
      i.inc
      echo "push #",cast[float](code[i])
    of pARG:
      i.inc
      echo "push arg",cast[int](code[i])
    of pPLUS: echo "+"
    of pMINUS: echo "-"
    of pMULT: echo "*"
    of pDIV: echo "/"
    of pPOWER: echo "^"
    of pSIN: echo "sin"
    of pCOS: echo "cos"
    of pTAN: echo "tan"
    of pLOG: echo "log"
    of pEXP: echo "exp"
    else : echo i,"<err>",code[i]

    i.inc
  echo "-----------------------------------"

proc run(code:var Code, args:varargs[float]):float=
  var 
    stack:array[256,float]
    sp=0
    i=0

  while i<code.len:
    case cast[pCode](code[i]):
    of pPUSH: i.inc; stack[sp] = cast[float](code[i]); sp.inc
    of pARG: i.inc; stack[sp] = args[cast[int](code[i])]; sp.inc
    of pPLUS:  sp.dec; stack[sp-1]+=stack[sp]
    of pMINUS: sp.dec; stack[sp-1]-=stack[sp]
    of pMULT:  sp.dec; stack[sp-1]*=stack[sp]
    of pDIV:   sp.dec; stack[sp-1]/=stack[sp]
    of pPOWER: sp.dec; stack[sp-1]=pow(stack[sp-1],stack[sp])
    of pSIN: stack[sp-1]=stack[sp-1].sin
    of pCOS: stack[sp-1]=stack[sp-1].cos
    of pTAN: stack[sp-1]=stack[sp-1].tan
    of pLOG: stack[sp-1]=stack[sp-1].ln
    of pEXP: stack[sp-1]=stack[sp-1].exp
    else : echo i,"<err>",code[i]

    i.inc
  stack[sp-1]

#########################
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
  r"\(":  return LPAREN()
  r"\)":  return RPAREN()
  r"\+":  return PLUS()
  r"-":   return MINUS()
  r"\*":  return MULTI()
  r"/":   return DIVISION()
  r"^":   return POWER()
  r"," :  return COMMA()
  
  r"(\d*\.)?\d+":  return NUM(parseFloat(token.token))
  r"wave" : return WAVE()
  r"[a..z]+" : return FUNCTION(token.token)
  r"$\d" : ARGUMENT(parseInt(token.token[1..^1]) - 1) # start on 1, i.e. $1, $2, ...

  r"\s":  return IGNORE()

  setUp:
    code.init()
  tearDown:
    discard

nimy expressionParser[ExpressionTokens]:
  top[float]:
    term: return $1

  term[float]:
    term PLUS factor:  
      result = $1 + $3
      code.push(pPLUS)
    term MINUS factor:
      result = $1 - $3
      code.push(pMINUS)
    factor: $1

  factor[float]:
    factor MULTI power:    
      result = $1 * $3
      code.push(pMULT)
    factor DIVISION power:
      result = $1 / $3
      code.push(pDIV)
    power: $1

  power[float]:
    power POWER num:
      result = pow($1,$3)
      code.push(pPOWER)
    num : $1

  num[float]:
    LPAREN term RPAREN: $2

    WAVE LPAREN term COMMA term COMMA term RPAREN:
      result = $3 * sin($5 + $7)
      code.push(pPLUS)
      code.push(pSIN)
      code.push(pMULT)

    FUNCTION LPAREN term RPAREN : 
      case ($1).name:
       of "sin": result = sin($3); code.push(pSIN)
       of "cos": result = cos($3); code.push(pCOS)
       of "tan": result = tan($3); code.push(pTAN)
       of "log": result = ln($3);  code.push(pLOG)
       of "ln":  result = ln($3);  code.push(pLOG)
       of "exp": result = exp($3); code.push(pEXP)
       else: result = $3

    NUM: 
      result = ($1).val
      code.push(($1).val)

    ARGUMENT: 
      result = 0
      code.push(($1).index) # range not checked!


when isMainModule:
  import times, strformat
  proc test_misc=
    let expressions = ["wave(100,cos(2),3+34/5)*$1", "(sin(tan(cos(12))))", "sin(1) * cos(12)","sin(( 2 - 3.45 ) / 4 * 34.56) ^ 4"]

    for expression in expressions:
      var exprLexer = expressionLexer.newWithString(expression)
      exprLexer.ignoreIf = proc(r: ExpressionTokens): bool = r.kind == ExpressionTokensKind.IGNORE

      var parser = expressionParser.newParser()

      echo expression, "=", parser.parse(exprLexer), "vm=", code.run(1.0)
      # printCode()

  proc bench=
    var 
      t0 = now()
      n = 10_000_000
  
    echo "benchmarking nimly - nimvm"

    let expr = "1*$1+2+3*$1+4+5+6+7+8+9+1+2+3+4+5+6+7+8+9+$1" #"sin(( 2 - 3.45 * $1) / 4 * 34.56) ^ 4"
    var exprLexer = expressionLexer.newWithString(expr)
    exprLexer.ignoreIf = proc(r: ExpressionTokens): bool = r.kind == ExpressionTokensKind.IGNORE
    var parser = expressionParser.newParser()
    discard parser.parse(exprLexer)
  
    t0=now()
    for i in 0..n:
      let _ = code.run(2.3)

    echo &"nimvm: lap for:{n}:, {(now()-t0).inMilliseconds}ms, result={code.run(2.3)}, code len:{code.len}"
  
  bench()