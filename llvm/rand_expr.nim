# random expression generator
import random, expression, expression_llvm, strformat, math

proc rand_expression(n:int):string=
  proc rand_const():string = 
    if rand(1)==0: ($rand(10.0))[0..3] else: "$1"

  if n!=0:
    case rand(3):
    of 0: &"{rand_expression(n-1)}+{rand_expression(n-1)}"
    of 1: &"{rand_expression(n-1)}*{rand_expression(n-1)}"
    of 2: &"({rand_expression(n-1)})"
    of 3: &"{funcNames.sample}({rand_expression(n)})"

    else: ""
  else: rand_const()

when isMainModule:
  import strformat
  proc test_expression_pcode* =
    randomize()
    for i in 0..1000:
      let 
        expr = rand_expression(6)
        code = expr.compile()
        x = rand(1.0)
        y = code.run([x])
      
      echo &"{expr}({x})={y}"

  proc test_expression_llvm* =
      randomize()
      for i in 0..100:
        let xpr = rand_expression(7)
        let
          cfunc = compileLLVM("func" & $i, xpr)
          code = xpr.compile()
          x = rand(1.0)*1e-10
          y = cfunc(x)
        # echo &"{xpr}({x})={y}=={code.run([x])}"
        if y.classify != fcNan:
          echo &"{i}:{y}=={code.run([x])}, {xpr}"

  test_expression_llvm()

