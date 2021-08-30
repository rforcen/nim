all:
	@g++ -c btreedx.cpp
	@nim cpp -d:release -d:danger --passL:btreedx.o --passC:-std=c++11 btreedx_wrapper.nim
