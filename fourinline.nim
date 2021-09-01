# 4 inline game
import sequtils, threadpool, cpuinfo

const
  N = 7
  N_COL = N
  N_ROW = N-1

  EVAL_DRAW = 2
  MAX_EVAL = int.high
  MIN_EVAL = -int.high

  LEVEL = 10

type 
  Chip = enum
    Empty
    Human
    Machine

  Board = object
    board   : seq[Chip]
    cols_sum: seq[int]

  Move = object
    col     : int
    res     : int
    chip    : Chip

  EvalMove=object
    eval:int
    move:Move

  Fourinline = object
    board       : Board
    best_move   : Move
    win_coords  : seq[seq[(int,int)]]

proc `<`(a,b:EvalMove) : bool = a.eval<b.eval

# Board

proc newBoard() : Board =
  Board(  board   : newSeq[Chip](N_COL * N_ROW),  cols_sum: newSeq[int](N_COL) )

proc clear*(b:var Board) =
  b=newBoard()

proc `[]`(b: Board, row, col : int) : Chip {.inline.}= b.board[row * N_COL + col]
proc `[]=`(b:var Board, row, col : int, chip:Chip) {.inline.}=
  b.board[(row * N_COL + col)] = chip

proc generate_moves(b:Board) : seq[int] {.inline.} =
  for i in 0..<N_COL:
      var p = i + N_COL div 2
      if p >= N_COL:  p -= N_COL 
      if b.cols_sum[p] < N_ROW:  result.add(p)  

proc is_draw*(b:Board) : bool =
  b.generate_moves().len == 0

proc move(b: var Board, col : int, who : Chip) {.inline.} =
  b[ b.cols_sum[col], col ]=who
  b.cols_sum[col].inc

proc move_check(b: var Board, col : int, who : Chip) : bool =
  result = b.cols_sum[col] < N_ROW and col < N_COL
  if result: 
      b[b.cols_sum[col], col]=who
      b.cols_sum[col].inc

proc take(b: var Board, col : int) {.inline} =
  b.cols_sum[col].dec
  b[b.cols_sum[col], col]=Empty        


proc print*(b:Board) =
  for r in 0..<N_ROW:
      for c in 0..<N_COL:
        let cc = case b[N_ROW-1-r, c]:
              of Human: 'O'
              of Machine: 'X'
              of Empty:'.'
              
        stdout.write cc,' '
      echo ""
  
  echo "-------------"
  echo "0 1 2 3 4 5 6"


# Move

proc newMove() : Move = Move( col:0, res: -1, chip:Empty )

proc set_if_better(mv: var Move, col:int, res:int, chip:Chip) {.inline.} =
  if res > mv.res:
    mv = Move(col:col, res:res, chip:chip)
        
proc set(mv: var Move, col:int, res:int, chip:Chip) {.inline.} =
  mv = Move(col:col, res:res, chip:chip)
    
proc clear(mv:var Move) =  mv = newMove()
    

# Fourinline

# fwd's
proc evaluate(fil: Fourinline, chip : Chip) : int {.inline.}
proc find_all_winning_coords() : seq[seq[(int,int)]]
proc alpha_beta(fil: var Fourinline, level : int, max_level : int, palpha : int, pbeta : int, who : Chip ) : int
proc is_winner(fil: Fourinline, chip : Chip) : bool 

proc computer_wins(fil: Fourinline) : bool =  fil.evaluate(Machine) == MAX_EVAL   
proc human_wins(fil: Fourinline) : bool =     fil.evaluate(Human) == MAX_EVAL    

proc evaluate(fil: Fourinline, chip : Chip)  : int  {.inline.}= 
  if fil.is_winner(chip):  MAX_EVAL  else: 0

proc newFourinline*() : Fourinline = 
  Fourinline(
      board       : newBoard(), 
      best_move   : newMove(),
      win_coords  : find_all_winning_coords() 
  )

proc move(fil: var Fourinline, mv : Move) =
  fil.board.move(mv.col, mv.chip)

proc play(fil: var Fourinline, level : int) : int = # single thread
  fil.best_move.clear()
  result = fil.alpha_beta(level, level, -int.high, int.high, Human)
  fil.move( fil.best_move )

proc play(fil: var Fourinline, level : int, em:var EvalMove)  = # single thread evaluate & best_move
  fil.best_move=newMove()
  let eval = fil.alpha_beta(level, level, -int.high, int.high, Human)
  em = EvalMove(eval:eval, move:fil.best_move)

proc play_mt*(fil: var Fourinline, level : int) : int = # multi-threaded version
  fil.best_move.clear()
  let 
    moves = fil.board.generate_moves()
    nth = min(moves.len, countProcessors())
  var 
    fils = fil.repeat(nth)
    evals = newSeq[EvalMove](nth)

  parallel: #  --threadAnalysis:off
    for i in 0..<nth:
      fils[i].board.move(moves[i], Human)
      spawn fils[i].play(level-1, evals[i])

  # set max & best move
  let best_eval = evals[ maxIndex(evals) ]
 
  fil.move( best_eval.move )
  fil.best_move = best_eval.move
  best_eval.eval  


proc alpha_beta(fil: var Fourinline, level : int, max_level : int, palpha : int, pbeta : int, who : Chip ) : int =
  var  eval : int

  result = 0

  var
    alpha = palpha
    beta = pbeta

  if level == 0: 
      result = fil.evaluate( who ) # eval. terminal node
  else: 
      let moves = fil.board.generate_moves()

      if moves.len() > 0:
        
          case who:
              of Human :  # test all computer moves
                  for mv in moves:
                      fil.board.move(mv, Machine)

                      if fil.computer_wins():
                          eval = MAX_EVAL
                          if level == max_level:
                              fil.best_move.set_if_better(mv, MAX_EVAL, Machine )
                      else:
                          eval = fil.alpha_beta(level - 1, max_level, alpha, beta, Machine)

                      if eval > alpha:
                          alpha = eval
                          if level == max_level:
                              fil.best_move.set_if_better(mv, alpha, Machine)
                          
                      fil.board.take(mv)

                      if beta <= alpha:  break  # beta prune
                  
                  result = alpha

              of Machine :  # test all human moves
                  for mv in moves:
                      fil.board.move(mv, Human)

                      if fil.human_wins():
                          eval = -MAX_EVAL
                          alpha = -MAX_EVAL
                      else:
                          eval = fil.alpha_beta(level - 1, max_level, alpha, beta, Human)

                      if eval < beta:
                          beta = eval
                          if level == max_level:
                              fil.best_move.set(mv, beta, Machine)

                      fil.board.take(mv)

                      if beta <= alpha:  break  # alpha prune

                  result = beta
              
              of Empty : discard 

      else: 
          result = EVAL_DRAW

proc is_winner(fil: Fourinline, chip : Chip) : bool =
  result = false

  for wcs in fil.win_coords: 
      var is_win = true
      for c4 in wcs:
          if fil.board[c4[0], c4[1]] != chip:
            is_win = false 
            break 
      
      if is_win:
        result=true  
        break

proc find_all_winning_coords() : seq[seq[(int,int)]] =

  for r in 0..<N_ROW:  # rows
      for c in 0..(N_COL-4):
        result.add( toSeq(0..<4).mapIt((r, c+it)) ) 
  
  for c in 0..<N_COL:  # cols
      for r in 0..(N_ROW-4):
        result.add(toSeq(0..<4).mapIt((r+it, c))) 
 
  # diag-right & left      
  for (r, cr) in [2, 1, 0].zip([0..<4, 0..<5, 0..<6]):      
      for c in cr:
          var 
            cpr : seq[(int, int)]
            cpl : seq[(int, int)]
            np=0

          for p in 0..<4: 
              if r+p >= N_ROW or c+p >= N_COL:  break 
              cpr.add((r+p, c+p))
              cpl.add((r+p, (N_COL-1)-(c+p)))
              np.inc 
                       
          if np == 4:  
              result.add(cpr)
              result.add(cpl)
  result
 
# main

when isMainModule:

  import times, strformat, ui/rawui, math

  var
    mainwin: ptr Window
    draw_board: ptr Area
    fil = newFourinline()
    end_game=false

  proc shouldQuit(data: pointer): cint {.cdecl.} =
      controlDestroy(mainwin)
      return 1

  proc onClosing(w: ptr Window; data: pointer): cint {.cdecl.} =
      controlDestroy(mainwin)
      rawui.quit()
      return 0

  proc handlerDraw*(a: ptr AreaHandler; area: ptr Area; p: ptr AreaDrawParams) {.cdecl.} =
      proc setSolidBrush(brush: ptr DrawBrush; color: uint32; alpha: cdouble) {.cdecl.} =
          var component: uint8
          brush.`type` = DrawBrushTypeSolid
          component = (uint8)((color shr 16) and 0x000000FF)
          brush.r = (cdouble(component)) / 255.0
          component = (uint8)((color shr 8) and 0x000000FF)
          brush.g = (cdouble(component)) / 255.0
          component = (uint8)(color and 0x000000FF)
          brush.b = (cdouble(component)) / 255.0
          brush.a = alpha
      const
          colorWhite = 0xFFFFFF
          colorBlack = 0x000000
          colorRed = 0xff0000
          colorBlue = 0x0000ff

      var
          path: ptr DrawPath
          brush: DrawBrush
          w, h: cdouble
          dx, dy: cdouble
          sp = DrawStrokeParams(cap: DrawLineCapFlat, join: DrawLineJoinMiter,
                  thickness: 1, miterLimit: DrawDefaultMiterLimit)

      proc cls = # fill the area with white
          setSolidBrush(addr(brush), (if end_game: colorBlack else: colorWhite).uint32, 1)
          path = drawNewPath(DrawFillModeWinding)
          drawPathAddRectangle(path, 0, 0, p.areaWidth, p.areaHeight)
          drawPathEnd(path)
          drawFill(p.context, path, addr(brush))
          drawFreePath(path)

      proc grid =
          setSolidBrush(addr(brush), colorBlack, 1.0)
          path = drawNewPath(DrawFillModeWinding)

          for i in 0..<N_COL:
              let px = i.cdouble * dx
              drawPathNewFigure(path, px, 0)
              drawPathLineTo(path, px, h)

          for i in 0..<N_ROW:
              let py = i.cdouble * dy
              drawPathNewFigure(path, 0, py)
              drawPathLineTo(path, w, py)

          drawPathEnd(path)
          drawStroke(p.context, path, addr(brush), addr(sp))
          drawFreePath(path)

      proc draw_board =
          for (chip, color) in [Human, Machine].zip([colorRed, colorBlue]):
            path = drawNewPath(DrawFillModeWinding)
            setSolidBrush(brush.addr, color.uint32, 1)

            for r in 0..<N_ROW:
              for c in 0..<N_COL:
                if fil.board[N_ROW-1-r,c]==chip:
                  drawPathNewFigureWithArc(path,
                      c.cdouble*dx + dx/2, r.cdouble * dy + dy/2,
                      0.8*dx.min(dy)/2, 0, 2*PI, 0)

            drawPathEnd(path)
            drawFill(p.context, path, addr(brush))
            drawFreePath(path)

      (w, h) = (p.areaWidth, p.areaHeight) # dimensions
      (dx, dy) = (w / N_COL.cdouble, h / N_ROW.cdouble)

      cls()
      grid()
      draw_board()

  proc handlerKeyEvent*(ah: ptr AreaHandler; a: ptr Area;  e: ptr AreaKeyEvent): cint {.cdecl.} =
      if e.up == 1:
          case e.extKey:
          of ExtKeyEscape:
              discard mainwin.onClosing(nil)
          
          else:
              case e.key:
              of 'q': discard mainwin.onClosing(nil)
              of 'c': 
                fil = newFourinline()
                mainwin.windowSetTitle "4 inline"
                discard fil.play LEVEL
                end_game=false

              of '1'..'7': 
                if not end_game and fil.board.move_check(e.key.int-'1'.int, Human):
                  if fil.human_wins(): 
                    mainwin.windowSetTitle "you won!"
                    end_game=true
                  else:
                    let t0 = now()
                    let res = fil.play LEVEL 
                    if fil.computer_wins(): 
                      mainwin.windowSetTitle "i win!"
                      end_game=true
                    elif fil.board.is_draw(): 
                      mainwin.windowSetTitle "draw"
                      end_game=true
                    else:
                      let lap=(now()-t0).inMilliseconds
                      mainwin.windowSetTitle fmt "moved {fil.best_move.col+1}, result:{res}, lap:{lap}"
                
              else: discard

      areaQueueRedrawAll(draw_board)

      return 1

  proc handlerMouseEvent*(a: ptr AreaHandler; area: ptr Area;
          e: ptr AreaMouseEvent) {.cdecl.} = discard

  proc handlerMouseCrossed*(ah: ptr AreaHandler; a: ptr Area; left: cint) {.
          cdecl.} = discard
  proc handlerDragBroken*(ah: ptr AreaHandler; a: ptr Area) {.cdecl.} = discard
    
  proc ui_play()=
    var
        o: InitOptions
        handler = AreaHandler(draw: handlerDraw, mouseEvent: handlerMouseEvent,
                keyEvent: handlerKeyEvent, mouseCrossed: handlerMouseCrossed,
                dragBroken: handlerDragBroken)
        hbox: ptr Box

    if rawui.init(addr(o)) == nil:

        mainwin = newWindow("4 inline", 900, 800, 1)

        discard fil.play LEVEL

        windowOnClosing(mainwin, onClosing, nil)
        onShouldQuit(shouldQuit, nil)

        windowSetMargined(mainwin, 1)

        # create boxes
        hbox = newHorizontalBox()
        boxSetPadded(hbox, 1)
        windowSetChild(mainwin, hbox)

        draw_board = newArea(addr(handler))
        boxAppend(hbox, draw_board, 1)


        controlShow(mainwin)
        rawui.main()
        rawui.uninit()

  proc cli_play*()=
    
    var 
      line : string
      n_moves = 0

    block outer: 
      while true:
        let t = now()
        let res = fil.play LEVEL
        # discard fil.play_mt(LEVEL)

        n_moves.inc
        let resp = case res:
            of MAX_EVAL : "(i'll win)"
            of MIN_EVAL : "you can win"
            else        :  $res
        

        echo fmt "my move: {fil.best_move.col}, result:{resp}, lap:{(now()-t).inMilliseconds()}ms"

        fil.board.print()
        
        if fil.computer_wins(): 
            echo fmt "i win in {n_moves} moves! at level {LEVEL}"
            break outer
        

        if fil.board.is_draw():
            echo fmt "draw in {n_moves} moves"
            break outer
        

        while true:
            stdout.write "your move? "; stdout.flushFile()

            discard stdin.readline(line)

            if line[0]=='q':  break outer 

            let col = (line[0].int - '0'.int)
            if fil.board.move_check( col, Human ):
                if fil.human_wins(): 
                    fil.board.print()
                    echo fmt "won in {n_moves}! at level {LEVEL}"
                    break outer
                break 


  ui_play()
