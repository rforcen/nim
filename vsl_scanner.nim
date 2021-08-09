#
# vsl scanner
#

import tables, strutils, strformat, unicode
       
const phi* = 1.61803398874989

# types
type pcode* = int64 # same as float (float64)
type wchar* = Rune
type wstring* = seq[wchar] # unicode support

template u*(ch: char): wchar = wchar(ch)
template us*(s: string): wstring = s.toRunes

# Do While
template Do*(body: untyped): void =
  while true:
    body
template While*(cond: typed): void =
  if not cond: break

# scanner / run time symbols
type Symbols* =
  enum
    SNULL
    CONST
    LET
    RPN
    FUNC
    RET
    PARAM
    ALGEBRAIC
    NUMBER
    IDENT
    STRING
    IDENT_t
    PLUS
    MINUS
    MULT
    DIV
    OPAREN
    CPAREN
    OCURL
    CCURL
    OSQARE
    CSQUARE
    BACKSLASH
    RANDOM
    VERT_LINE
    OLQUOTE
    CLQUOTE
    FACT
    TILDE
    POWER
    PERIOD
    SEMICOLON
    COMMA
    COLON
    EQ
    GT
    GE
    LT
    LE
    NE
    SPI
    SPHI
    FSIN
    FCOS
    FTAN
    FEXP
    FLOG
    FLOG10
    FINT
    FSQRT
    FASIN
    FACOS
    FATAN
    FABS
    SWAVE
    SWAVE1
    SWAVE2
    TONE
    NOTE
    SEC
    OSC
    ABS
    SAW
    SAW1
    LAP
    HZ2OCT
    MAGNETICRING
    PUSH_CONST
    PUSH_T
    PUSH_ID
    PUSH_STR
    POP
    NEG
    FLOAT

    NOTE_CONST
    # notes
    N_DO
    N_RE
    N_MI
    N_FA
    N_SOL
    N_LA
    N_SI
    FLAT
    SHARP

# Scanner

type Scanner* = object
  source: wstring
  reserved: TableRef[wstring, Symbols]
  ident: wstring
  nval: float
  sym*: Symbols
  ch: Rune
  ixs: int
  line_no: int
  ch_pos: int

# tokens / symbols

const CHARS = {"+": PLUS, "*": MULT, "·": MULT,
    "/": DIV, "(": OPAREN, ")": CPAREN,
    "{": OCURL, "}": CCURL, "[": OSQARE,
    "]": CSQUARE, "\\": BACKSLASH, "?": RANDOM,
    "!": FACT, "^": POWER, ".": PERIOD,
    ",": COMMA, ":": COLON, ";": SEMICOLON,
    "=": EQ, "~": TILDE, "π": SPI,
    "Ø": SPHI, "|": VERT_LINE, "‹": OLQUOTE,
    "›": CLQUOTE, "♪": NOTE, "⬳": SAW,
    "∿": FSIN, "τ": IDENT_t,
    "➡": RET, "♭": FLAT, "♯": SHARP}.toTable
const WORDS = {"sin": FSIN, "cos": FCOS,
    "tan": FTAN, "exp": FEXP, "log": FLOG, "log10": FLOG10,
    "int": FINT, "sqrt": FSQRT, "asin": FASIN, "acos": FACOS,
    "atan": FATAN, "abs": FABS, "pi": SPI, "phi": SPHI,
    "wave": SWAVE, "wave1": SWAVE1, "wave2": SWAVE2, "tone": TONE,
    "note": NOTE, "sec": SEC, "osc": OSC,
    "saw1": SAW1, "lap": LAP, "hz2oct": HZ2OCT,

    "t": IDENT_t, "const": CONST,
    "rpn": RPN, "algebraic": ALGEBRAIC,
    "let": LET, "float": FLOAT,
    "func": FUNC}.toTable
const TWO_CH = {us">=": GE, us"<=": LE, us"<>": NE, us"->": RET}.toTable
const INITIAL = {us"-": MINUS, us">": GT, us"<": LT}.toTable
const NOTES = {"do": N_DO, "re": N_RE, "mi": N_MI, "fa": N_FA, "so": N_SOL,
        "la": N_LA, "si": N_SI}.toTable

# extend

proc extend_symbols(): TableRef[wstring, Symbols] =
  var
    res_words = newTable[wstring, Symbols]()

  for ct in [CHARS, WORDS, NOTES]:
    for k, v in ct.pairs: res_words[k.toRunes] = v
  res_words


proc newScanner*(source: string): Scanner =
  Scanner(source: source.toRunes, reserved: extend_symbols(), ch: u ' ', nval: 0.0, ident: us"",
           ixs: 0, line_no: 0, ch_pos: 0)

proc get_id*(s: Scanner): wstring = s.ident
proc get_num*(s: Scanner): float = s.nval

proc getch(s: var Scanner): Rune =
  if s.ixs < s.source.len:
    s.ch = s.source[s.ixs]
    inc s.ixs
    inc s.ch_pos
    if (s.ch == u '\n') or (s.ch == u '\r'):
      inc s.line_no
      s.ch_pos = 0
  else:
    s.ch = u '\0'

  s.ch

proc ungetch(s: var Scanner) =
  if s.ixs > 0:
    dec s.ixs
    s.ch = s.source[s.ixs-1]

proc skip_blanks(s: var Scanner) =
  while (s.ch != u '\0') and (s.ch <=% u ' '):
    discard s.getch()

proc skip_to_eol(s: var Scanner) =
  while (s.ch != u '\0') and ((s.ch != u '\n') or (s.ch == u '\r')):
    discard s.getch() # skip line comment

proc skip_multiline_comment(s: var Scanner) =
  while s.ch != u '/':
    discard s.getch()
    while (s.ch != u '\0') and (s.ch != u '*'): discard s.getch()
    discard s.getch()

  discard s.getch() # skip last '/'

proc skip_blank_comments(s: var Scanner) = # skip blanks & comments # /**/
  Do:
    s.skip_blanks()

    if s.ch == u '/': # skip comment
      if s.getch() == u '/': s.skip_to_eol()
      else:
        if s.ch == u '*': # /**/
          s.skip_multiline_comment()
        else:
          s.ungetch()
          break

    else: break
  s.skip_blanks()

proc index_sym*(s: var Scanner) = # sym = reserved[ident]
  s.sym = s.reserved[s.ident]

proc is_reserved_word(s: Scanner, w: wstring): bool =
  s.reserved.contains(w)

proc isIdent(r: Rune): bool =
  ((r>=%u 'a') and (r<=%u 'z')) or
  ((r>=%u 'A') and (r<=%u 'Z')) or
  r == u '_'

proc isDigit(r: Rune): bool =
  (r>=%u '0') and (r<=%u '9')

proc add_next(s: var Scanner) = # add ch & getch
  s.ident.add(s.ch)
  discard s.getch()

proc getsym*(s: var Scanner): Symbols =
  s.sym = SNULL
  s.ident = us""
  s.nval = 0.0

  s.skip_blank_comments()

  # scan symbol
  if s.ch.isIdent(): # ident
    while s.ch.isIdent() or s.ch.isDigit() or s.ch == u '_':
      s.add_next()

    if s.ident == us"t": s.sym = IDENT_t
    else: # func ?
            # echo s.ident
      if s.is_reserved_word(s.ident):
        s.index_sym()
      else: # ident
        s.sym = IDENT

  elif s.ch.isDigit() or s.ch == u '.': # number
    if s.ch == u '.': s.ident.add(u '0')
    while s.ch.isDigit() or (s.ch == u '.'):
      s.add_next()
    if (s.ch == u 'e') or (s.ch == u 'E'):
      s.add_next()
      if (s.ch == u '-') or (s.ch == u '+'): s.add_next()
      while s.ch.isDigit(): s.add_next()

    s.sym = NUMBER
    try:
      s.nval = parseFloat($s.ident) # atof
    except ValueError:
      s.nval = 0.0
      s.sym = SNULL

  else:
    s.ident.add(s.ch)

    if s.is_reserved_word(s.ident): s.index_sym() # 1 ch sym
    else:
      var w_ant = s.ident
      s.ident.add(s.getch())

      if TWO_CH.contains(s.ident): s.sym = TWO_CH[s.ident] # 2 ch sym
      elif INITIAL.contains(w_ant):
        s.sym = INITIAL[w_ant]
        s.ungetch()
      else:
        s.sym = SNULL

    discard s.getch()

  s.sym

proc get_error*(s: Scanner): string =
  fmt("syntax error in line:{s.line_no+1}, pos:{s.ch_pos} char:{s.ch}, symbol:{s.sym}")
