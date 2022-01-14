# funcs.nim
import math

# nim c -d:danger -d:release --noMain --app:lib --out:libfuncs.so funcs

proc foo*(t:float):float {.exportc, dynlib.} = t
proc wave*(x,a,hz,p:float):float {.exportc, dynlib.} = a*sin(x*hz+p)