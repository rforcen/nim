// vsl.cl
// vibrational symbolic language VM
// clcc -cl-nv-cstd=CL2.0 src/vsl.cl src/vsl.ptx

enum Symbol { // list of symbols
  SNULL,
  CONST,
  LET,
  RPN,
  FUNC,
  RET,
  PARAM,
  ALGEBRAIC,
  NUMBER,
  IDENT,
  STRING,
  IDENTt_offset,
  PLUS,
  MINUS,
  MULT,
  DIV,
  OPAREN,
  CPAREN,
  OCURL,
  CCURL,
  OSQARE,
  CSQUARE,
  BACKSLASH,
  RANDOM,
  VERT_LINE,
  OLQUOTE,
  CLQUOTE,
  YINYANG,
  SEQUENCE,
  FREQ_MESH,
  FACT,
  TILDE,
  POWER,
  PERIOD,
  SEMICOLON,
  COMMA,
  COLON,
  EQ,
  GT,
  GE,
  LT,
  LE,
  NE,
  SPI,
  SPHI,
  FSIN,
  FCOS,
  FTAN,
  FEXP,
  FLOG,
  FLOG10,
  FINT,
  FSQRT,
  FASIN,
  FACOS,
  FATAN,
  FABS,
  SWAVE,
  SWAVE1,
  SWAVE2,
  TONE,
  NOTE,
  SEC,
  OSC,
  ABS,
  SAW,
  SAW1,
  LAP,
  HZ2OCT,
  MAGNETICRING,
  PUSH_CONST,
  PUSH_T,
  PUSH_ID,
  PUSH_STR,
  POP,
  NEG,
  FLOAT,
  RATE,
  NOTE_CONST,
  // notes
  N_DO,
  N_RE,
  N_MI,
  N_FA,
  N_SOL,
  N_LA,
  N_SI,
  FLAT,
  SHARP,
};

struct uParams {
  uint uparam0, uparam1;
};

struct PCode {
  char _p0;  // align pad
  char code; // CODE
  short _p1; // align pad
  union {
    float fparam0;
    struct uParams uparams;
  };
};

typedef int2 FromTo;

kernel void vsl_exec(global float *samples,     // 0: out samples output
                     global struct PCode *code, // 1: in code
                     int from_pc,               // 2: from_pc
                     int to_pc,                 // 3: to pc
                     float t_offset,            // 4: t offset
                     float t_inc,               // 5: t_inc
                     float volume,              // 6: volume

                     FromTo blk_const,       // 7: const block
                     FromTo blk_let,         // 8: let block
                     int n_chan,             // 9: n_chan
                     global FromTo *blk_code // 10: code block

) {

  int index = get_global_id(0);
  // int n_samples = get_global_size(0);

  float t = t_offset + (float)index * t_inc;
  float stack[32], values[32];
  int sp_base[32], ispbase = 0;
  int n_params[32], inparams = 0;
  int sp = 0;

#define param0 code[pc].uparams.uparam0
#define param1 code[pc].uparams.uparam1

  for (int pc = from_pc; pc < to_pc; pc++) {
    switch (code[pc].code) {
    case PUSH_CONST:
      stack[sp++] = code[pc].fparam0;
      break;
    case PUSH_T:
      stack[sp++] = t;
      break;
    case PUSH_ID:
      stack[sp++] = values[param0];
      break;
    case POP:
      values[param0] = stack[--sp];
      break;

    case PARAM:
      stack[sp] =
          stack[sp_base[ispbase - 1] - 1 - n_params[inparams - 1] + param0];
      sp++;
      break;
    case FUNC: // pc, nparams
      stack[sp] = (float)(pc + 1);
      sp++;
      n_params[inparams++] = param1;
      sp_base[ispbase++] = sp;
      pc = param0 - 1; // as it will be inc +1
      break;
    case RET:
      pc = (int)(stack[sp - 2] - 1); // as pc++
      stack[sp - (param0 + 2)] = stack[sp - 1];
      sp -= param0 + 2 - 1;
      ispbase--;
      inparams--;
      break;

    // arithmetic
    case PLUS:
      sp--;
      stack[sp - 1] += stack[sp];
      break;
    case MINUS:
      sp--;
      stack[sp - 1] -= stack[sp];
      break;
    case MULT:
      sp--;
      stack[sp - 1] *= stack[sp];
      break;
    case DIV:
      sp--;
      stack[sp - 1] /= stack[sp];
      break;
    case SWAVE1:
      stack[sp - 1] = sin(t * stack[sp - 1]);
      break;
    case FSIN:
      stack[sp - 1] = sin(stack[sp - 1]);
      break;
    case FCOS:
      stack[sp - 1] = sin(stack[sp - 1]);
      break;
    case FTAN:
      stack[sp - 1] = sin(stack[sp - 1]);
      break;
    }
  }

  // samples[index] = (float)sizeof(*code); // check PCode size
  // samples[index] = (float)code[2].code;
  // samples[index] = (float)code[1].uparams.uparam0;
  // samples[index] = (float)code[index % n_code].uparams.uparam0;
  // samples[index] = code[index % n_code].fparam0;

  samples[index] = (sp == 1) ? volume * stack[0] : -9999.99;
}