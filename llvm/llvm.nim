# llvm wrapper, cpp backend

import cppstl

# export LD_LIBRARY_PATH=".:llvm" 
# llvm-config --cxxflags
{.passC:"-I/usr/lib/llvm-10/include -Illvm  -std=c++14 -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS".}
{.passL:"-lLLVM-10 -L. -Lllvm -lfuncs".} # llvm-config --libs

const llvm_header="llvm.h"
type 
  unique_ptr*[T]{.header:llvm_header, importcpp:"unique_ptr".} = object
  Type* {.header:llvm_header, importcpp:"Type".}= object
  Value* {.header:llvm_header, importcpp:"Value".}= object
  LLVMContext* {.header:llvm_header, importcpp:"LLVMContext".}= object
  Module* {.header:llvm_header, importcpp:"Module".}= object
  EngineBuilder* {.header:llvm_header, importcpp:"EngineBuilder".}= object
  ExecutionEngine* {.header:llvm_header, importcpp:"ExecutionEngine".}= object
  BasicBlock* {.header:llvm_header, importcpp:"BasicBlock".}= object  
  Function* {.header:llvm_header, importcpp:"Function".}= object
  FunctionType* {.header:llvm_header, importcpp:"FunctionType".}= object
  LinkageTypes* = enum 
    ExternalLinkage = 0, #< Externally visible function
    AvailableExternallyLinkage,  #< Available for inspection, not emission.
    LinkOnceAnyLinkage,  #< Keep one copy of function when linking (inline)
    LinkOnceODRLinkage,  #< Same, but only replaced by something equivalent.
    WeakAnyLinkage,      #< Keep one copy of named function when linking (weak)
    WeakODRLinkage,      #< Same, but only replaced by something equivalent.
    AppendingLinkage,    #< Special purpose, only applies to global arrays
    InternalLinkage,     #< Rename collisions when linking (static functions).
    PrivateLinkage,      #< Like Internal, but omit from symbol table.
    ExternalWeakLinkage, #< ExternalWeak linkage description.
    CommonLinkage        #< Tentative definitions.


# type defs
proc getInt32Ty*(ctx:LLVMContext):ptr Type  {.importcpp:"Type::getInt32Ty(@)", header:llvm_header.}
proc getFloatTy*(ctx:LLVMContext):ptr Type  {.importcpp:"Type::getFloatTy(@)", header:llvm_header.} 
proc getDoubleTy*(ctx:LLVMContext):ptr Type {.importcpp:"Type::getDoubleTy(@)", header:llvm_header.}
proc getVoidTy*(ctx:LLVMContext):ptr Type   {.importcpp:"Type::getVoidTy(@)", header:llvm_header.}
proc getInt64Ty*(ctx:LLVMContext):ptr Type  {.importcpp:"Type::getInt64Ty(@)", header:llvm_header.}

{.push header:llvm_header, importcpp.}

# llvm init
proc InitializeNativeTarget*()
proc InitializeNativeTargetAsmPrinter*()
proc InitializeNativeTargetAsmParser*()
{.pop.}

proc CreateFunction*(funcType: FunctionType, linkageType: LinkageTypes, name : cstring, module: ptr Module) : ptr Function
  {.header:llvm_header, importcpp:"Function::Create(@)".}
proc newFunctionType*(retType: ptr Type, params:CppVector[ptr Type], isVarArgs:bool) : FunctionType 
  {.header:llvm_header, importcpp:"FunctionType::get(@)".}
proc newBuilder*(context : LLVMContext) : pointer 
  {.header:llvm_header, importcpp:"new IRBuilder<>(@)".}

proc newContext*() : ptr LLVMContext 
  {.header:llvm_header, importcpp:"new LLVMContext()".}

proc newEngineBuilder*(module : ptr Module) : ptr EngineBuilder =
  {.emit:"unique_ptr<Module>um(module);  result = new EngineBuilder(move(um));".}

proc newEngine*(eb:ptr EngineBuilder) : ptr ExecutionEngine
  {.header:llvm_header, importcpp:"#->create()".}

proc newBasicBlock*(context : LLVMContext, name : cstring, function : ptr Function, insertBefore : ptr BasicBlock = nil) : BasicBlock 
  {.header:llvm_header, importcpp:"BasicBlock::Create(@)".}
proc setInsertPoint*(builder:pointer, basicBlock: BasicBlock) 
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->SetInsertPoint(#)".}
proc getArg*(function:ptr Function, i:int) : ptr Value 
  {.header:llvm_header, importcpp:"#->arg_begin() + #".}
proc CreateFAdd*(builder:pointer, p0,p1:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateFAdd(#,#)".}
proc CreateFSub*(builder:pointer, p0,p1:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateFSub(#,#)".}
proc CreateFMul*(builder:pointer, p0,p1:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateFMul(#,#)".}
proc CreateFDiv*(builder:pointer, p0,p1:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateFDiv(#,#)".}
proc CreateFRem*(builder:pointer, p0,p1:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateFRem(#,#)".}
proc CreateRet*(builder:pointer, p0:ptr Value) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateRet(#)".}
proc CreateCall*(builder:pointer, function:ptr Function, args:CppVector[ptr Value]) : ptr Value
  {.header:llvm_header, importcpp:"((IRBuilder<>*)#)->CreateCall(#,#)".}

proc printIR*(module:ptr Module)
  {.header:llvm_header, importcpp:"#->print(outs(), nullptr)".}
proc getFunctionAddress(e:ptr ExecutionEngine, name : cstring) : int
# typedef void (*fptr)();
  {.header:llvm_header, importcpp:"#->getFunctionAddress(#)".}

# nim wrap
proc newModule*(name:cstring, context:LLVMContext) : ptr Module {.header:llvm_header, importcpp:"new Module(@)".}
proc deleteModule*(module:ptr Module) {.importcpp:"delete #".}
proc deleteEngine*(engine:ptr ExecutionEngine) {.importcpp:"delete #".}
proc deleteEngineBuilder*(engine:ptr EngineBuilder) {.importcpp:"delete #".}

proc llvmInit*() =
  InitializeNativeTarget()
  InitializeNativeTargetAsmPrinter()
  InitializeNativeTargetAsmParser()

## JIT object

type JIT = object
  context* : ptr LLVMContext
  module* : ptr Module
  builder* : pointer
  engineBuilder* : ptr EngineBuilder
  engine* : ptr ExecutionEngine

proc getInt32Ty*(jit:JIT):ptr Type  = getInt32Ty(jit.context)
proc getFloatTy*(jit:JIT):ptr Type  = getFloatTy(jit.context)
proc getDoubleTy*(jit:JIT):ptr Type = getDoubleTy(jit.context)
proc getVoidTy*(jit:JIT):ptr Type   = getVoidTy(jit.context)
proc getInt64Ty*(jit:JIT):ptr Type  = getInt64Ty(jit.context)

proc `=destroy`(jit:var JIT)=
  {.emit:"""
  delete jit.builder; 
  if (jit.engineBuilder) delete jit.engineBuilder;
  if (jit.engine) delete jit.engine; 
  """.}

proc newJIT*(mod_name:cstring) : JIT =
  llvmInit()
  let ctx = newContext()
  result = JIT(context:ctx, builder : newBuilder(ctx[]), module : newModule(mod_name, ctx[]) )
  result.engineBuilder = newEngineBuilder(result.module)
  result.engine = result.engineBuilder.newEngine

proc beginBlock*(jit:JIT, name:cstring, function:ptr Function)=
  jit.builder.setInsertPoint(newBasicBlock(jit.context, name, function))

proc CreateFunction*(jit:JIT, retType:ptr Type, paramsType:seq[ptr Type], name : cstring) : ptr Function =
  result = CreateFunction(newFunctionType(retType, paramsType.toCppVector, false), ExternalLinkage, name, jit.module)
  {.emit:"result->setCallingConv(CallingConv::C);".}

proc CreateFunctionBlock*(jit:JIT, retType:ptr Type, paramsType:seq[ptr Type], name : cstring) : ptr Function =
  result = CreateFunction(newFunctionType(retType, paramsType.toCppVector, false), ExternalLinkage, name, jit.module)
  jit.beginBlock(($name & "_block").cstring, result)

proc `[]`*(function:ptr Function, i:int):ptr Value = function.getArg(i)

proc fadd*(jit:JIT, p0,p1:ptr Value):ptr Value = jit.builder.CreateFAdd(p0,p1)
proc fsub*(jit:JIT, p0,p1:ptr Value):ptr Value = jit.builder.CreateFSub(p0,p1)
proc fmul*(jit:JIT, p0,p1:ptr Value):ptr Value = jit.builder.CreateFMul(p0,p1)
proc fdiv*(jit:JIT, p0,p1:ptr Value):ptr Value = jit.builder.CreateFDiv(p0,p1)
proc frem*(jit:JIT, p0,p1:ptr Value):ptr Value = jit.builder.CreateFRem(p0,p1)
proc ret*(jit:JIT, p0:ptr Value):ptr Value = jit.builder.CreateRet(p0)

proc fcall*(jit:JIT, function:ptr Function, args:seq[ptr Value]) : ptr Value =
  jit.builder.CreateCall(function, args.toCppVector)

proc initDbl*(jit:JIT, d : float =0.0) : ptr Value = {.emit:"result = ConstantFP::get(Type::getDoubleTy(*(jit->context)), d);".}

# convert proc() to a multiple arg/ret type proc casting:
# let cfunc = cast[proc(a,b,c: float):float {.cdecl.}] ( jit.getFuncAddr(funcName) )
proc getFuncAddr*(jit:JIT, name:cstring) : int64 = 
  jit.engine.getFunctionAddress(name)

proc printIR*(jit:JIT)=printIR(jit.module)


# custom function list (funcs.nim) -> libfuncs.so 
func foo*(t : float):float {.importc.}
func wave*(t, a,h,p : float):float {.importc.}

##################
when isMainModule:
  
  import strformat, math

  proc test_JIT=
    const funcName = "addMult"
    var 
      jit = newJIT("addMult.module")
      dblt = jit.getDoubleTy
      function = jit.CreateFunctionBlock(dblt, @[dblt,dblt,dblt], funcName)

    let 
      ffoo = jit.CreateFunction(dblt, @[dblt], "foo") # custom callable func
      fwave = jit.CreateFunction(dblt, @[dblt, dblt, dblt, dblt], "wave") # 
      fsin = jit.CreateFunction(dblt, @[dblt], "sin") # clib func

    let # generate expression proc addMult(a,b,c:float):float = ((a+b)*c-a)/b + 123.45
      m = jit.fmul(jit.fadd(function[0], function[1]), function[2])
      d = jit.fdiv(jit.fsub(m,function[0]),function[1])
      d1 = jit.fadd(d, jit.initDbl(123.45))
      ds = jit.fcall(fsin, @[d1])
      df = jit.fcall(ffoo, @[ds])
      dw = jit.fcall(fwave, @[df, df, df, df])
    discard jit.ret(dw)

    jit.printIR()

    #[  
        convert proc() func addr to a callable nim func with 
        ret type and arguments as defined in CreateFunction, {.cdecl.} is mandatory
    ]# 
    let func_addr = jit.getFuncAddr(funcName)
    if func_addr!=0:
      let cfunc = cast[proc(a,b,c: float):float {.cdecl.}] ( func_addr )

      proc nimaddMult(a,b,c:float):float =  
        let ds = sin(((a+b)*c-a) / b + 123.45)
        foo(wave(ds,ds,ds,ds))
      
      let 
        (b,c)=(20.0,30.0)

      echo "evaluating cfunc..."
      echo nimaddMult(1.0, b, c)

      echo "evaluating addMult"
      for a in countup(0,1000,234):
        # echo a, ",", nimaddMult(a.float,b,c)
        echo &"{cfunc(a.float,b,c)} == {nimaddMult(a.float,b,c)}, {cfunc(a.float,b,c) == nimaddMult(a.float,b,c)}"

  test_JIT()