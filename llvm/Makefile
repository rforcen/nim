all:
	@nim c -d:danger -d:release --noMain --app:lib --out:libfuncs.so funcs 
	@nim cpp -r -d:release -d:danger expression_llvm
	@nim cpp -r -d:release -d:danger expression

clean:
	@ rm -fr funcs.so expression expression_llvm