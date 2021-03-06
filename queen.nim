# n - Queens problem w/ui
# finds first solution & transformations

const short_cuts = """keys:
                
s : single thread 1st solution
space, m : multi thread 1st solution
+ : n++
- : n--
p : print solutions -> stdout

q/esc : quit"""

import ui/rawui, random, math, stint, times, cpuinfo, threadpool, sequtils,
        algorithm, strformat

const max_queens = 100

# board
type UInt1024* = StUint[1024] # supports upto n=140
func u1024*(n: SomeInteger): UInt1024 {.inline.} = n.stuint(1024)

type Board* = object
    n: int
    board: seq[int]
    ld, rd, cl: seq[bool]

proc newBoard*(n: int): Board =
    let n2 = n * 2
    result = Board(n: n, board: newSeq[int](n), ld: newSeq[bool](n2),
            rd: newSeq[bool](n2), cl: newSeq[bool](n2))

proc newBoard*(b: seq[int]): Board =
    let (n, n2) = (b.len, b.len * 2)
    result = Board(n: n, board: b, ld: newSeq[bool](n2), rd: newSeq[bool](n2),
            cl: newSeq[bool](n2))

proc set*(b: var Board, col, val: int) {.inline.} = # set
    b.board[col] = val

    b.ld[(val - col + b.n - 1)] = true
    b.rd[(val + col)] = true
    b.cl[val] = true

proc get*(b: Board, col: int): int {.inline.} =
    b.board[col]

proc reset*(b: var Board, col, val: int) {.inline.} =
    b.board[col] = 0

    b.ld[(val - col + b.n - 1)] = false
    b.rd[(val + col)] = false
    b.cl[val] = false

proc is_valid_position*(b: Board, col, i: int): bool {.inline.} =
    not (b.ld[(i - col + b.n - 1)] or b.rd[(i + col)] or b.cl[i])

proc is_not_valid_position*(b: Board, col, i: int): bool {.inline.} =
    not b.is_valid_position(col, i)

proc cmp*(b0, b1: Board): int =
    for i in zip(b0.board, b1.board):
        if i[0] != i[1]: return i[0]-i[1]
    0
proc `[]`*(b: Board, i: int): int = result = b.board[i]
proc `[]`*(b: var Board, i: int): int = result = b.board[i]

proc `$`*(b: Board): string =
    result = ""
    for c in b.board: result &= $c & " "

proc toInt*(b: Board): UInt1024 =
    result = 0.u1024
    var p = 1.u1024
    for index in 0..b.board.high:
        result += p * b.get(index).stuint(1024)
        p = p * b.board.len.u1024

proc toBoard*(b: var Board, ip: UInt1024) =
    var i = ip

    for index in 0..b.board.high:
        b.set(index, (i mod b.n.u1024).truncate(int))
        i = i div b.board.len.u1024


# static abort scan
var abort_queen_scan* {.global.}: bool = false

# Queen

type Queen = object
    n*: int
    board*: Board
    count_evals: UInt256
    solutions: seq[Board]
    current_sol: int
    count_solutions: int
    max_solutions: int
    running: ptr[bool]

proc newQueen*(n: int): Queen =
    result = Queen(n: n, board: newBoard(n), running: abort_queen_scan.addr)
    result.running[] = true

proc is_running*(q: Queen): bool {.inline.} = q.running[]

proc `[]`*(q: Queen, i: int): int = result = q.board.board[i]

proc is_valid*(q: Queen): bool

proc save_solution*(q: var Queen) =
    if q.is_valid: q.solutions.add(q.board)
proc save_solution*(q: var Queen, b: Board) =
    if q.is_valid: q.solutions.add(b)
proc save_solution*(q: var Queen, b: seq[int]) =
    if q.is_valid: q.solutions.add(newBoard(b))

proc clear(q: var Queen) =
    q = newQueen(q.n)

proc add_eval_n(q: var Queen) = q.count_evals += q.n.u256 #

proc is_valid*(q: Queen): bool =
    for i in 0..<q.n-1:
        for j in i+1..<q.n:
            if q[i] == q[j]: return false # horizontal -> ci=cj
            if i - q[i] == j - q[j]: return false # vertical  / ri-ci = rj-cj
            if (q[i] - q[j]).abs == (i - j).abs: return false # vertical \ |ci-cj| = |i-j|
    true

proc set_board*(q: var Queen, b: Board) =
    q.board = newBoard(q.n)
    for j, c in b.board:
        if c != 0:
            q.board.set(j, c)

proc scan_first*(q: var Queen, col: int = 0) =
    if q.is_running:
        if col >= q.n:
            if q.is_valid: q.solutions.add(q.board)
            q.running[] = false
        else:
            for i in 0..<q.n:
                if q.board.is_valid_position(col, i):
                    q.board.set(col, i)

                    q.scan_first(col + 1) # recur to place rest

                    q.board.reset(col, i) # unmove
            q.add_eval_n()

proc find_first_mt_es*(q: var Queen) =
    var qs = repeat(q, countProcessors())

    var b = newBoard(q.n)
    for i in 0..<qs.high: # evently spaced starting scan point
        let ns = i.u1024 * q.n.u1024.pow(q.n.u1024) div qs.len.u1024
        b.toBoard(ns)
        qs[i].set_board(b)

    parallel:
        for i in 0..qs.high:
            spawn qs[i].scan_first(0)

    q.solutions = qs.mapIt(it.solutions).filterIt(it.len != 0)[0]
    q.count_evals = qs.foldl(a + b.count_evals, 0.u256)

proc find_first_mt*(q: var Queen) =
    var qs = repeat(q, countProcessors())

    for i in 0..qs.high:
        qs[i].board.set(0, i)
        qs[i].board.set(1, ((q.n div 2) + i + 1) %% q.n)

    parallel:
        for i in 0..qs.high:
            spawn qs[i].scan_first(2)

    q.solutions = qs.mapIt(it.solutions).filterIt(it.len != 0)[0]
    q.count_evals = qs.foldl(a + b.count_evals, 0.u256)

# transformations
proc translate_vert(q: var Queen) = # up
    for i in 0..<q.n:
        q.board.set(i, (q[i] + 1) %% q.n)
    q.save_solution()

proc translate_horz(q: var Queen) = # right
    var v = newSeq[int](q.n)

    for i in 0..<q.n-1:
        v[i + 1] = q[i]
    v[0] = q[q.n - 1]
    q.save_solution(v)

proc rotate90(q: var Queen) =
    var rot_queens = newSeq[int](q.n)

    for i in 0..<q.n:
        rot_queens[i] = 0
        for j in 0..<q.n: # find i
            if q[j] == i:
                rot_queens[i] = q.n - j - 1
                break
    q.save_solution(rot_queens)

proc mirror_horz(q: var Queen) =
    for i in 0..<q.n:
        q.board.set(i, (q.n - 1) - q[i])
    q.save_solution()

proc mirror_vert(q: var Queen) =
    for i in 0..<q.n div 2:
        let tmp = q[i]
        q.board.set(i, q[(q.n - 1 - i)])
        q.board.set(q.n - 1 - i, tmp)
    q.save_solution()

proc transformations*(q: var Queen) =
    q.solutions = @[]
    q.current_sol = 0

    var b = q.board

    for mv in 0..1:
        for mh in 0..1:
            for r90 in 0..3:
                for tv in 0..<q.n: # translations
                    for th in 0..<q.n:
                        q.translate_vert() # tV
                    q.translate_horz() # tH
                q.rotate90() # R90
            q.mirror_horz() # mH
        q.mirror_vert() # mV

    # q.sort_solutions_unique()
    q.board = b
    q.solutions = q.solutions.sorted(cmp).deduplicate()

var
    n = 20
    qs*: Queen

    mainwin: ptr Window
    draw_board: ptr Area


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
        colorWhite = 0x00FFFFFF
        colorBlack = 0x00000000
        colorRed = 0x00ff0000

    var
        path: ptr DrawPath
        brush: DrawBrush
        w, h: cdouble
        dx, dy: cdouble
        sp = DrawStrokeParams(cap: DrawLineCapFlat, join: DrawLineJoinMiter,
                thickness: 1, miterLimit: DrawDefaultMiterLimit)

    proc cls = # fill the area with white
        setSolidBrush(addr(brush), colorWhite, 1)
        path = drawNewPath(DrawFillModeWinding)
        drawPathAddRectangle(path, 0, 0, p.areaWidth, p.areaHeight)
        drawPathEnd(path)
        drawFill(p.context, path, addr(brush))
        drawFreePath(path)

    proc grid(n: int) =
        setSolidBrush(addr(brush), colorBlack, 1.0)
        path = drawNewPath(DrawFillModeWinding)

        for i in 0..<n:
            let (px, py) = (i.cdouble * dx, i.cdouble * dy)
            drawPathNewFigure(path, px, 0)
            drawPathLineTo(path, px, h)
            drawPathNewFigure(path, 0, py)
            drawPathLineTo(path, w, py)

        drawPathEnd(path)
        drawStroke(p.context, path, addr(brush), addr(sp))
        drawFreePath(path)

    proc draw_board =
        setSolidBrush(addr(brush), colorRed, 1)
        path = drawNewPath(DrawFillModeWinding)

        for i in 0..<n:
            drawPathNewFigureWithArc(path,
                i.cdouble*dx + dx/2, (qs.n - 1 - qs[i]).cdouble * dy + dy/2,
                0.8*dx.min(dy)/2, 0, 2*PI, 0)

        drawPathEnd(path)
        drawFill(p.context, path, addr(brush))
        drawFreePath(path)

    (w, h) = (p.areaWidth, p.areaHeight) # dimensions
    (dx, dy) = (w / n.cdouble, h / n.cdouble)

    cls()
    grid(n)
    draw_board()

proc handlerKeyEvent*(ah: ptr AreaHandler; a: ptr Area;
        e: ptr AreaKeyEvent): cint {.cdecl.} =
    # echo e.key.int, ",", e.up
    var lap: int64 = 0

    if e.up == 1:
        case e.extKey:
        of ExtKeyEscape:
            discard mainwin.onClosing(nil)
        of ExtKeyF1:
            mainwin.msgBox("help", short_cuts)

        of ExtKeyUp:
            inc qs.current_sol
            if qs.current_sol >= qs.solutions.len:
                qs.current_sol = 0
            qs.board = qs.solutions[qs.current_sol]
        of ExtKeyDown:
            dec qs.current_sol
            if qs.current_sol < 0:
                qs.current_sol = qs.solutions.high
            qs.board = qs.solutions[qs.current_sol]

        of ExtKeyNAdd:
            if n < max_queens:
                inc n
                qs = newQueen(n)
        of ExtKeyNSubtract:
            if n > 4:
                dec n
                qs = newQueen(n)

        else:
            case e.key:
            of 's': # single thread scan
                let t0 = now()

                qs.clear
                qs.scan_first
                lap = (now()-t0).inMilliseconds
                # echo "lap st ", qs.n, ":", lap, " #evals:", qs.count_evals

                qs.board = qs.solutions[0]
                qs.transformations

            of ' ', 'm': # multi thread scan
                let t0 = now()

                qs.clear
                qs.find_first_mt
                lap = (now()-t0).inMilliseconds
                qs.board = qs.solutions[0]

                qs.transformations

                # echo "lap mt ", qs.n, ":", lap, " #evals:", qs.count_evals

            of 'p':
                for s in qs.solutions:
                    echo $s.board

            of 'q': discard mainwin.onClosing(nil)
            else: discard

    areaQueueRedrawAll(draw_board)
    mainwin.windowSetTitle(fmt("nQueens {qs.n} | solutions: {qs.solutions.len} | evals:{qs.count_evals} | lap {lap}ms"))

    return 1

proc handlerMouseEvent*(a: ptr AreaHandler; area: ptr Area;
        e: ptr AreaMouseEvent) {.cdecl.} = discard

proc handlerMouseCrossed*(ah: ptr AreaHandler; a: ptr Area; left: cint) {.
        cdecl.} = discard
proc handlerDragBroken*(ah: ptr AreaHandler; a: ptr Area) {.cdecl.} = discard

proc main =
    var
        o: InitOptions
        handler = AreaHandler(draw: handlerDraw, mouseEvent: handlerMouseEvent,
                keyEvent: handlerKeyEvent, mouseCrossed: handlerMouseCrossed,
                dragBroken: handlerDragBroken)
        hbox: ptr Box

    randomize()
    qs = newQueen(n)

    if rawui.init(addr(o)) == nil:

        mainwin = newWindow("nBoard", 800, 800, 1)

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

proc test_board_num*() =
    var b = newBoard(max_queens)
    for i in 0..b.board.high: b.set(i, i)
    echo b
    let bi = b.toInt()
    echo bi

    var b1 = b
    b1.toBoard(bi)
    echo b1
    echo b1.toInt()
    echo b == b1


main()

