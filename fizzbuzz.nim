#[
Write a program that prints the numbers from 1 to 100. 
But for multiples of three print "Fizz" instead of the number and for the multiples of five print "Buzz". 
For numbers which are multiples of both three and five print "FizzBuzz".
]#

import sequtils


func fizz_buzz(i:int):string=
  if i mod 15==0: "FizzBuzz" 
  elif i mod 3==0: "Fizz" 
  elif i mod 5==0: "Buzz" 
  else: $i

proc test=
  write stdout, toSeq(1..100).mapIt( fizz_buzz(it) & "," )

  echo ""

  for i in 1..100: write stdout, fizz_buzz(i), ","

  echo ""

  for i in 1..100:
    var s=""
    if i mod 3 == 0: s &= "Fizz"
    if i mod 5 == 0: s &= "Buzz"
    if s=="": s &= $i
    write stdout, s, ","

  echo ""

test()