# sudoku
import sequtils, random, math, strutils, locks
import weave

const 
  MaxN = 8  
  Invalid_Coord=(-1,-1)
  EmptyCell=0

type
  Level = enum DontTouch, VeryEasy, Easy, Medium, Difficult, Master
  Chip = int
  Coord = (Chip, Chip)
  Coords = seq[Coord]
  Board = seq[seq[Chip]]
  Sudoku = object
    n, sz_box:int
    board,board_solv : Board
    lookup_upper_cells : seq[seq[Coords]]
    found_solutions, max_solutions : int

proc newArray2d[T](n:int):seq[seq[T]]= newSeqWith(n,newSeq[T](n))
proc newArray3d[T](n:int):seq[seq[seq[T]]]= newSeqWith(n,newSeqWith(n,newSeq[T](0)))
proc gen_lookup(s:var Sudoku)
proc `[]`(b:Board, c:Coord):int = b[c[0]][c[1]]

proc newSoduku*(sz_box:int):Sudoku=
  if sz_box > MaxN: raise newException(Exception, "max box size is 8")

  let n = sz_box^2

  result = Sudoku(n:n, sz_box:sz_box, 
    board:newArray2d[Chip](n),
    board_solv:newArray2d[Chip](n),
    lookup_upper_cells : newArray3d[Coord](n),
    max_solutions:1)

  result.gen_lookup

# aux funcs  
proc bit(v,n:int):int {.inline.}= v and (1 shl n)
proc setbit(v:var int, n:int) {.inline.}= v = v or (1 shl n)
proc bin2seq(v,n:int):seq[int]=
  for i in 0..<n:
    if bit(v,i)==0: result.add i+1
    else: result.add 0

proc copy2solv(s:var Sudoku)= # GC safe board_solv = board
  for r in 0..<s.n:
    for c in 0..<s.n: s.board_solv[r][c]=s.board[r][c]
proc copy2board(s:var Sudoku)= # GC safe board = board_solv
  for r in 0..<s.n:
    for c in 0..<s.n: s.board[r][c]=s.board_solv[r][c]

proc copyboards(dest:var Board, src:Board)=
  for r in 0..dest.high:
    for c in 0..dest[r].high:  dest[r][c]=src[r][c]

proc is_valid(s:Sudoku) : bool

proc gen_lookup(s:var Sudoku) =  # generate UPPER lookUp vector per cell including box

  for row in 0..<s.n: 
    for col in 0..<s.n: 
      
      let  curr_coord = (row, col)
      var  lkp = s.lookup_upper_cells[row][col].addr

      for r in 0..<s.n:  lkp[].add( (r, col) )   # upper rows
      for c in 0..<s.n:  lkp[].add( (row, c) )   # & cols ONLY not lower ones

      let 
        rb = s.sz_box * (row div s.sz_box)
        cb = s.sz_box * (col div s.sz_box)

      for r in 0..<s.sz_box: 
        for c in 0..<s.sz_box:
          let coord = ( r + rb, c + cb )

          if coord != curr_coord: # != current 
            lkp[].add(coord)

      lkp[] = deduplicate(lkp[], isSorted=false)

proc gen_moves(s:Sudoku, row, col : int) : int = # n = sz_box^2, max sz_box=8
  for l in s.lookup_upper_cells[row][col]:
    let v = s.board[l] # range 1..n
    if v != EmptyCell: setbit(result, v-1) # 0's are posible moves

proc gen_moves(s: Sudoku, coord : Coord) : int =          
  s.gen_moves(coord[0], coord[1])

proc print(s:Sudoku)= # board_ptr
  proc one_char(i:int):string=
    if i==0: result=" "
    elif i<10: result = $i
    else: result.add chr('A'.int+i-10)

  for i in 0..<s.n:
    if i mod s.sz_box == 0: 
      write stdout, "-".repeat(s.n*2+4)
      echo ""
    for j in 0..<s.n:
      if j mod s.sz_box == 0: write stdout, "|"
      write stdout, s.board_solv[i][j].one_char," "
    echo "|"
  write stdout, "-".repeat(s.n*2+4)
  echo ""
  
proc find_first_empty(s:Sudoku) : Coord =
  for r in 0..<s.n:  
    for c in 0..<s.n: 
      if s.board[r][c]==EmptyCell: return (r, c)
  
  Invalid_Coord

proc save_solution*(s:Sudoku) =
  if s.is_valid: s.print

proc move(s:var Sudoku, row, col, val : int) {.inline.} = s.board[row][col] = val 
proc move(s:var Sudoku, coord:Coord, val : int) = s.board[coord[0]][coord[1]] = val 

proc scan(s:var Sudoku, row, col :int) = # GC safe
  if s.found_solutions < s.max_solutions:
    if s.board[row][col] == EmptyCell:   # skip non empty cells (solve process)

      let moves = s.gen_moves(row, col)
      
      for i in 0..<s.n:

        if bit(moves, i)==0: # 0's -> move
          s.move(row, col, i+1)

          if col < s.n-1:    s.scan(row, col + 1) 
          else: 
            if row < s.n-1:  s.scan(row + 1, 0) 
            else: 
              s.found_solutions.inc
              s.copy2solv
              break

          s.move(row, col, EmptyCell)  # b(r,c)=0   
      
    else:   # next cell
      if col < s.n-1:  s.scan(row, col + 1) 
      else: 
        if row < s.n-1: s.scan(row + 1, 0) 
        else:           
          s.found_solutions.inc
          s.copy2solv
      
proc is_valid(s:Sudoku) : bool =
    
    var valid = true
    let seq1n = toSeq(1..s.n)
    
    for rc in 0..1:   # rows & cols
      if not valid:  break 

      for r in 0..<s.n:

        var vb = newSeq[int](s.n)

        for c in 0..<s.n:
          let b = if rc == 0:  s.board[r][c]  else:  s.board[c][r]
          if b!=0:  vb[b - 1] = b
          else: 
            echo "invalid empty cell r:", r, ", c:", c, vb
            valid = false
            # break

        if vb != seq1n: 
          echo "invalid set, missing value, row:", r, vb
          valid = false
          # break

    # if not valid: return false

    for row in countup(0, s.n-1, s.sz_box):
      # if not valid:  break 

      for col in countup(0, s.n-1, s.sz_box):
        var vb=newSeq[int](s.n)
        for r in 0..<s.sz_box:  # box
          for c in 0..<s.sz_box: 
            let b = s.board[r + row][c + col]
            if b!=0:  vb[b - 1] = b 
            else: 
              echo "2. invalid empty cell r:", row, ", c:", col, vb
              valid = false
              # break
        
        if vb != toSeq(1..s.n):
          valid = false
          echo "2. invalid set, missing value", row, ", c:", col, vb
          # break

    valid     
    
proc init_board*(s:var Sudoku) = s.board = newArray2d[Chip](s.n)

proc scan*(s:var Sudoku) = s.scan(0,0)
proc scan*(s:var Sudoku, coord:Coord) = s.scan(coord[0],coord[1])

proc swap_col(s:var Sudoku, c0, c1 : int) =
  for c in 0..<s.n: swap s.board[c][c0], s.board[c][c1]

proc swap_row(s:var Sudoku, r0, r1 : int) =
  for r in 0..<s.n: swap s.board[r0][r], s.board[r1][r]

proc gen_problem(s:var Sudoku, level : Level) = # generate a random solvable problem in board_solv

  let 
    n = s.n
    szb = s.sz_box

  # generate first
  s.max_solutions=1
  s.init_board
  s.scan(s.find_first_empty)
  
  s.copy2board
  s.found_solutions=0
  
  var
    s0 = toSeq(0..<szb)
    s1 = s0

  for b in 0..<s.n:
    let (r, c) = ( b div szb, b mod szb )
    
    for _ in 0..n*n:
      s0.shuffle
      s1.shuffle
      
      for (x0, x1) in s0.zip(s1): 
        let (rs, cs) = (r * szb, c * szb)
        s.swap_col szb-1 + cs, cs
        s.swap_row szb-1 + rs, rs
        s.swap_col x0 + cs, x1 + cs
        s.swap_row x0 + rs, x1 + rs

  # the higher the level the more empty cells 0:n/3, 1:n/2, 2:2*n/3
  for _ in 0..n*n div (2+Master.int-level.int):
    s.board[rand(n-1)][rand(n-1)] = EmptyCell 
  s.copy2solv

proc solve(s:var Sudoku) =
  let coord = s.find_first_empty

  if coord!=Invalid_Coord:
    s.found_solutions=0
    s.scan(coord)

proc solve_mt*(s:var Sudoku) =
  let coord=s.find_first_empty
  if coord!=Invalid_Coord:
    let moves = s.gen_moves(coord)
    var 
      ss = newSeqWith(s.n, s)
      l : Lock
      found : bool = false
    let 
      ssp = ss.addr
      sp = s.addr
      lp = l.addr
      foundp = found.addr

    l.initLock

    Weave.init()
  
    parallelFor i in 0..<s.n:

      captures: {foundp, lp, sp, ssp, moves, coord}

      if bit(moves, i)==0:
        ssp[i].move(coord, i)
        ssp[i].scan(coord) # GC safe

        if ssp[i].found_solutions!=0 and not foundp[]:
          lp[].withLock:
            sp[].found_solutions.inc
            copyboards(sp[].board_solv, ssp[i].board_solv)
            for s in ssp[].mitems: s.found_solutions.inc
            foundp[] = true
            break
  
    Weave.exit()
        
when isMainModule:
  import os

  proc gen_problem_solution(n:int, level:Level)=
    var sudoku = newSoduku(n)

    randomize()
    sudoku.gen_problem(level)

    echo "generated problem"
    sudoku.print

    echo "solution"
    sudoku.solve
    sudoku.copy2board
    sudoku.print

    echo if sudoku.is_valid: "ok" else: "bad solution"

  proc test_mt* =
    var sudoku = newSoduku(4)
    sudoku.solve_mt()
    sudoku.print
    sudoku.board = sudoku.board_solv
    echo if sudoku.is_valid: "ok" else: "bad solution"

  proc test_bits* =
    var a=0
    echo a.toBin(9);    a.setbit(1)
    echo a.toBin(9);    a.setbit(1)
    echo a.toBin(9);    a.setbit(0)
    echo a.toBin(9);    a.setbit(0)
    echo a.toBin(9);    a.setbit(8)
    echo a.toBin(9)
    echo bin2seq(a, 9)

  proc main* =
    let params=commandLineParams()
    case params.len:
    of 0: gen_problem_solution(3, Medium)
    of 1: gen_problem_solution(params[0].parseInt, Medium)
    of 2: gen_problem_solution(params[0].parseInt, (params[1].parseInt mod 5).Level)
    else: echo "usage: n level"

  proc test01* =
    var sdk = newSoduku(3)
    echo sdk.lookup_upper_cells[0][0]

  # test01()
  main()
  # test_mt()