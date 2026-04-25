/*
** G10 Assembler.
**
** (c) Copyright 1995 Oscar Toledo G.
**
** 17-jun-1995.
*/

#define NULL     0
#define EOF     (-1)
#define LINE_SIZE  128
#define NO       0
#define YES      1

#define BUF_SIZE   2048

#define MEM_SIZE   77777

#define LABEL_SIZE 17  /* 1 byte: 0= address, 1= data value. */
                     /* 4 num_bytes de data/direcci�n. */
                     /* 4 bytes for the next label */
                     /* 4 bytes for the left child */
                     /* 4 bytes for the right child */
                     /* x bytes for the name (null-terminated) */
#define UNRES_SIZE 9  /* 1 byte: instruction opcode (0-15) */
                     /*         16= db, 17= dw. */
                     /* 4 bytes of target address */
                     /* 4 bytes for the next unresolved entry */
                     /* x bytes for the expression (null-terminated) */

int parse_err;
int num_files;
int input_fp, line_pos;

char pre_ins[8];
char orig_ins[8];
int accum;

int temp1_fp;
int temp2_fp;
int end_of_file;
int current_line;
int available;
int asm_pos;
char *expr_ptr;
char *first_label;
char *last_label;
int num_labels;
char *first_unres;
char *last_unres;
int num_unres;
int ptemp1, ptemp2;
char name_buf[15];
char line_buf[LINE_SIZE];
char token[LINE_SIZE];
char token2[LINE_SIZE];
char undef_label[LINE_SIZE];
char buf1[BUF_SIZE];
char buf2[BUF_SIZE];
int instr_table[528];
char t[MEM_SIZE];

#define TEMPORAL "TEMP1E.$$$"

main() {
  puts("\r\n");
  puts("G10 Assembler  16-jun-95  (c) Copyright 1995 Oscar Toledo G.\r\n");
  puts("\r\n");
  init_basic_ops();   /* The 16 basic instructions */
  init_ops();   /* The 16 basic operations */
  init_instr1();   /* First half of the instruction set */
  init_instr2();   /* Second half of the instruction set */
  init_fpu();   /* FPU microcode instructions */
  num_files = 0;
  available = 1;
  first_label = NULL;
  last_label = NULL;
  num_labels = 0;
  first_unres = NULL;
  last_unres = NULL;
  num_unres = 0;
  asm_pos = 0;
  temp1_fp = fopen(TEMPORAL, "w");
  if(temp1_fp == NULL) {
    puts("Error al crear el input_fp temporal\r\n\r\n");
    quit();
  }
  ptemp1 = 0;
  temp2_fp = NULL;
  while(1) {
    puts("Input file > ");
    read_input(name_buf, 15);
    if(*name_buf == 0) {
      flush_temp1();
      if(num_files == 0) {
        puts("\r\nAssembly cancelled.\r\n\r\n");
        quit();
      }
      current_line = 0;
      puts("Output file > ");
      read_input(name_buf, 15);
      if(*name_buf == 0) {
        puts("\r\nAssembly cancelled.\r\n\r\n");
        quit();
      }
      puts("\r\n");
      link_pass();
      puts("\r                          \r");
      print_decimal(num_labels);
      puts(" define_label definidas.\r\n");
      print_decimal((available + 1023) / 1024);
      puts(" KB used.\r\n\r\n");
      exit(1);
    }
    input_fp = fopen(name_buf, "r");
    if(input_fp == NULL) {
      puts("File not found.\r\n");
      continue;
    }
    end_of_file = NO;
    current_line = 0;
    while(!end_of_file)
      assemble();
    fclose(input_fp);
    ++num_files;
  }
}

quit() {
  if(temp1_fp != NULL) fclose(temp1_fp);
  if(temp2_fp != NULL) fclose(temp2_fp);
  exit(1);
}

alloc(num_bytes) int num_bytes; {
  int orig_pos;
  orig_pos = available;
  available = available + num_bytes;
  if(available > MEM_SIZE) {
    if(input_fp != NULL) fclose(input_fp);
    puts("\r\nOut of memory.\r\n");
    quit();
  }
  return t + orig_pos;
}

next_token() {
  char *sep;
  while(line_buf[line_pos] == ' ') ++line_pos;
  sep = token;
  while((line_buf[line_pos] != 0) & (line_buf[line_pos] != ' ')) {
    *sep++ = line_buf[line_pos++];
  }
  *sep = 0;
  while(line_buf[line_pos] == ' ') ++line_pos;
}

assemble() {
  int instr, has_label;
  char *end_ptr, *ap;
  read_line();
  has_label = NO;
  while(1) {
    next_token();
    if(*token == 0) break;
    if(*token == ';') break;
    end_ptr = token;
    while(*end_ptr) ++end_ptr;
    if((end_ptr != token) & (*(end_ptr-1) == ':')) {
      *(end_ptr-1) = 0;
      if(isalpha(*token) | (*token == '_')) {
        define_label();
        has_label = YES;
      }
      else error("Invalid label");
    }
    else if(match_str("db", token)) {
      def_byte();
      break;
    }
    else if(match_str("dw", token)) {
      def_word32();
      break;
    }
    else if(match_str("ds", token)) {
      def_space();
      break;
    }
    else if(match_str("equ", token)) {
      if(has_label) def_equ();
      else error("El equ debe ir con una define_label");
      break;
    }
    else {
      instr = 0;
      while(instr < 528) {
        ap = instr_table[instr++];
        if(*ap == '?') continue;
        if(match_str(ap, token)) {
          --instr;
          if(instr < 16) emit_basic_op(instr);
          else if(instr < 272) emit_simple(instr - 16);
          else if(instr < 528) emit_extended(instr - 272);
          break;
        }
      }
      if(instr == 528) {
        error("Undefined instruction");
      }
      else break;
    }
  }
  if(end_of_file) return;
}

strlen(cad) char *cad; {
  char *ori;
  ori = cad;
  while(*cad) ++cad;
  return(cad - ori);
}

strcpy(des, ori) char *des, *ori; {
  while(*des++ = *ori++) ;
}

strcat(des, ori) char *des, *ori; {
  while(*des) ++des;
  strcpy(des, ori);
}

strcmp(ori, des) char *ori, *des; {
  while(1) {
    if(*ori < *des) return -1;
    if(*ori > *des++) return 1;
    if(*ori++ == 0) return 0;
  }
}

define_label() {
  char *new_label;
  char *addr, *pos1;
  int u, count, val;
  addr = first_label;
  pos1 = NULL;
  while(addr != NULL) {
    if((val = strcmp(token, addr + 17)) == 0) {
      error("Label redefined");
      return;
    }
    if(val == -1) {
      pos1 = addr + 9;
      addr = (*(addr + 9)) | (*(addr + 10) << 8) |
            (*(addr + 11) << 16) | (*(addr + 12) << 24);
    } else if(val == 1) {
      pos1 = addr + 13;
      addr = (*(addr + 13)) | (*(addr + 14) << 8) |
            (*(addr + 15) << 16) | (*(addr + 16) << 24);
    }
  }
  u = addr = new_label = alloc(LABEL_SIZE + strlen(token) + 1);
  if(pos1 != NULL) {
    *pos1 = u;
    *(pos1+1) = u >> 8;
    *(pos1+2) = u >> 16;
    *(pos1+3) = u >> 24;
  }
  *addr++ = 0;
  *addr++ = asm_pos;
  *addr++ = asm_pos >> 8;
  *addr++ = asm_pos >> 16;
  *addr++ = asm_pos >> 24;
  count = 0;
  while(count++ < 12)
    *addr++ = 0;
  pos1 = token;
  while(*addr++ = *pos1++);
  if(last_label != NULL) {
    *(last_label + 5) = u;
    *(last_label + 6) = u >> 8;
    *(last_label + 7) = u >> 16;
    *(last_label + 8) = u >> 24;
  }
  if(first_label == NULL) first_label = new_label;
  last_label = new_label;
  ++num_labels;
}

find_label(label_name) char *label_name; {
  char *addr;
  int val;
  addr = first_label;
  while(addr != NULL) {
    if((val = strcmp(label_name, addr + 17)) == 0) return addr;
    if(val == -1) {
      addr = (*(addr + 9)) | (*(addr + 10) << 8) |
            (*(addr + 11) << 16) | (*(addr + 12) << 24);
    } else if(val == 1) {
      addr = (*(addr + 13)) | (*(addr + 14) << 8) |
            (*(addr + 15) << 16) | (*(addr + 16) << 24);
    }
  }
  return NULL;
}

emit_basic_op(op) int op; {
  int val;
  int adjust, jump_dist;
  next_token();
  parse_err = 0;
  expr_ptr = token;
  val = eval_expr();
  if(parse_err) {
    add_unresolved(op);
    write_temp1(op << 4);
    ++asm_pos;
    return;
  }
  if((op == 0) | (op == 9) | (op == 10)) {
    add_unresolved(op);
    adjust = 1;
    while(1) {
      accum = 0;
      gen_ins(op, jump_dist = (val - (asm_pos + adjust)));
      if(asm_pos + accum + jump_dist == val) break;
      ++adjust;
    }
  } else {
    accum = 0;
    gen_ins(op, val);
  }
  val = 0;
  while(val < accum) {
    write_temp1(pre_ins[val++]);
    ++asm_pos;
  }
}

add_unresolved(key) int key; {
  char *new_unres;
  char *addr, *pos1;
  int u;
  u = addr = new_unres = alloc(UNRES_SIZE + strlen(token) + 1);
  *addr++ = key;
  *addr++ = asm_pos;
  *addr++ = asm_pos >> 8;
  *addr++ = asm_pos >> 16;
  *addr++ = asm_pos >> 24;
  *addr++ = 0;
  *addr++ = 0;
  *addr++ = 0;
  *addr++ = 0;
  pos1 = token;
  while(*addr++ = *pos1++) ;
  if(last_unres != NULL) {
    *(last_unres + 5) = u;
    *(last_unres + 6) = u >> 8;
    *(last_unres + 7) = u >> 16;
    *(last_unres + 8) = u >> 24;
  }
  if(first_unres == NULL) first_unres = new_unres;
  last_unres = new_unres;
  ++num_unres;
}

isdigit(c) char c; {
  return((c >= '0') & (c <= '9'));
}

isalpha(c) char c; {
  return(((c >= 'A') & (c <= 'Z')) |
         ((c >= 'a') & (c <= 'z')));
}

eval_expr() {
  int val1;
  val1 = eval1();
  while((*expr_ptr == '+') | (*expr_ptr == '-')) {
    if(*expr_ptr == '+') {
      ++expr_ptr;
      val1 = val1 + eval1();
    } else {
      ++expr_ptr;
      val1 = val1 - eval1();
    }
  }
  return val1;
}

eval1() {
  if(*expr_ptr == '+') ++expr_ptr;
  else if(*expr_ptr == '-') {
    ++expr_ptr;
    return -eval2();
  }
  return eval2();
}

eval2() {
  int val1;
  val1 = eval3();
  while((*expr_ptr == '*') |
        (*expr_ptr == '/') |
        (*expr_ptr == '%')) {
    if(*expr_ptr == '*') {
      ++expr_ptr;
      val1 = val1 * eval3();
    } else if(*expr_ptr == '/') {
      ++expr_ptr;
      val1 = val1 / eval3();
    } else {
      ++expr_ptr;
      val1 = val1 % eval3();
    }
  }
  return val1;
}

eval3() {
  char *ap;
  int val;
  if(*expr_ptr == '(') {
    ++expr_ptr;
    val = eval_expr();
    if(*expr_ptr != ')')
      error("Missing closing parenthesis");
    else ++expr_ptr;
    return val;
  } else if(isdigit(*expr_ptr)) {
    if((*(expr_ptr + 1) == 'X') |
       (*(expr_ptr + 1) == 'x'))
      return eval_hex();
    else return eval_dec();
  }
  else if(isalpha(*expr_ptr) | (*expr_ptr == '_')) {
    ap = token2;
    while((*expr_ptr == '_') | isalpha(*expr_ptr) |
          isdigit(*expr_ptr)) {
      *ap++ = *expr_ptr++;
    }
    *ap = 0;
    if((ap = find_label(token2)) != NULL) {
      val = *(ap+1) | (*(ap+2) << 8) | (*(ap+3) << 16) | (*(ap+4) << 24);
      return val;
    }
    else {
      strcpy(undef_label, token2);
      parse_err = 1;
      return 0;
    }
  }
  else error("Syntax error");
}

isxdigit(c) int c; {
  return (((c>='0') & (c<='9')) |
          ((c>='a') & (c<='f')) |
          ((c>='A') & (c<='F')));
}

eval_hex() {
  int c;
  int val;
  val = 0;
  expr_ptr = expr_ptr + 2;
  while(isxdigit(*expr_ptr)) {
    c = toupper(*expr_ptr++) - '0';
    if(c > 9) c = c - 7;
    val = (val << 4) | c;
  }
  return val;
}

eval_dec() {
  int c;
  int val;
  val = 0;
  while(isdigit(*expr_ptr)) {
    c = *expr_ptr++ - '0';
    val = val * 10 + c;
  }
  return val;
}

gen_ins(oper, val) int oper; int val; {
  if(val < 0) gen_ins(6, ~val >> 4);
  else if(val >= 16) gen_ins(2, val >> 4);
  pre_ins[accum++] = (oper << 4) | (val & 15);
}

emit_simple(op) int op; {
  if(op > 15) {
    write_temp1(0x20 + (op >> 4));
    ++asm_pos;
  }
  write_temp1(0xf0 + (op & 15));
  ++asm_pos;
}

emit_extended(op) int op; {
  if(op > 15) {
    write_temp1(0x20 + (op >> 4));
    ++asm_pos;
  }
  write_temp1(0x40 + (op & 15));
  ++asm_pos;
  write_temp1(0x2a);
  ++asm_pos;
  write_temp1(0xfb);
  ++asm_pos;
}

def_byte() {
  int val;
  next_token();
  expr_ptr = token;
  while(1) {
    parse_err = 0;
    val = eval_expr();
    if(parse_err) add_unresolved(16);
    write_temp1(val & 255);
    ++asm_pos;
    if(*expr_ptr != ',') {
      if(*expr_ptr)
        error("Missing comma");
      return;
    }
    ++expr_ptr;
  }
}

def_word32() {
  int val;
  next_token();
  expr_ptr = token;
  while(1) {
    parse_err = 0;
    val = eval_expr();
    if(parse_err) add_unresolved(17);
    write_temp1(val & 255);
    ++asm_pos;
    write_temp1((val >> 8) & 255);
    ++asm_pos;
    write_temp1((val >> 16) & 255);
    ++asm_pos;
    write_temp1((val >> 24) & 255);
    ++asm_pos;
    if(*expr_ptr != ',') {
      if(*expr_ptr)
        error("Missing comma");
      return;
    }
    ++expr_ptr;
  }
}

def_space() {
  int val;
  next_token();
  expr_ptr = token;
  parse_err = 0;
  val = eval_expr();
  if(parse_err) {
    error("Se requiere un val definido");
    return;
  }
  while(val--) {
    write_temp1(0);
    ++asm_pos;
  }
}

def_equ() {
  int val;
  next_token();
  expr_ptr = token;
  parse_err = 0;
  val = eval_expr();
  if(parse_err) {
    error("Se requiere un val definido");
    return;
  }
  if(last_label == NULL) {
    error("Internal error");
    return;
  }
  *last_label = 1;
  *(last_label+1) = val;
  *(last_label+2) = val >> 8;
  *(last_label+3) = val >> 16;
  *(last_label+4) = val >> 24;
}

match_str(op, token) char *op, *token; {
  while(*op == *token++) {
    if(*op++ == 0) return 1;
  }
  return 0;
}

error(msg) char *msg; {
  puts(msg);
  if(current_line) {
    puts(" at line ");
    print_decimal(current_line);
  }
  puts("\r\n");
}

read_line() {
  int count, ch;
  count = 0;
  while(1) {
    ch = fgetc(input_fp);
    if(ch == EOF) {
      end_of_file = YES;
      break;
    }
    if(ch == '\r') continue;
    if(ch == '\n') break;
    if(ch == '\t') ch = ' ';
    if(count != LINE_SIZE - 1)
      line_buf[count++] = ch;
  }
  line_buf[count] = 0;
  ++current_line;
  line_pos = 0;
}

int changed;

link_pass() {
  while(1) {
    temp1_fp = fopen(TEMPORAL, "r");
    ptemp1 = BUF_SIZE;
    temp2_fp = fopen(name_buf, "w");
    ptemp2 = 0;
    if(temp2_fp == NULL) {
      error("Disk access error");
      quit();
    }
    changed = NO;
    widen_pass();
    flush_temp2();
    fclose(temp1_fp);
    temp1_fp = NULL;
    if(!changed) break;
    temp1_fp = fopen(name_buf, "r");
    ptemp1 = BUF_SIZE;
    temp2_fp = fopen(TEMPORAL, "w");
    ptemp2 = 0;
    if(temp2_fp == NULL) {
      error("Disk access error");
      quit();
    }
    changed = NO;
    widen_pass();
    flush_temp2();
    fclose(temp1_fp);
    temp1_fp = NULL;
/*
    if(!changed) {
      unlink(name_buf);
      rename(TEMPORAL, name_buf);
      break;
    }
*/
  }
}

widen_pass() {
  char *list, *list2;
  int start;
  int last;
  int addr;
  int val, byte_val;
  int orig_len, op;
  int adjust, jump_dist;
  int delta;
  int a;

  last = asm_pos;
  asm_pos = 0;

  delta = 0;

  start = 0;

  list = first_unres;

  a = 0;
  while(list != NULL) {
    addr = *(list + 1) | (*(list + 2) << 8) |
          (*(list + 3) << 16) | (*(list + 4) << 24);
    copy_range(start, addr);

    op = *list;

    if(op == 16) {
      byte_val = read_temp1();
      start = addr + 1;
    } else if(op == 17) {
      byte_val = read_temp1();
      byte_val = read_temp1();
      byte_val = read_temp1();
      byte_val = read_temp1();
      start = addr + 4;
    } else {
      orig_len = 0;
      while(1) {
        orig_ins[orig_len++] = byte_val = read_temp1();
        if((byte_val & 0xf0) == 0x20) continue;
        if((byte_val & 0xf0) == 0x60) continue;
        break;
      }
      start = addr + orig_len;
    }

    *(list + 1) = asm_pos;
    *(list + 2) = asm_pos >> 8;
    *(list + 3) = asm_pos >> 16;
    *(list + 4) = asm_pos >> 24;

    parse_err = 0;
    expr_ptr = list + 9;
    val = eval_expr();
    if(parse_err) {
      strcpy(token2, "Undefined label ");
      strcat(token2, undef_label);
      error(token2);
      val = 0;
    }

    if(op == 16) {
      write_temp2(val);
      ++asm_pos;
    } else if(op == 17) {
      write_temp2(val);
      ++asm_pos;
      write_temp2(val >> 8);
      ++asm_pos;
      write_temp2(val >> 16);
      ++asm_pos;
      write_temp2(val >> 24);
      ++asm_pos;
    } else if((op == 0) | (op == 9) | (op == 10)) {
      accum = 0;
      gen_ins(op, val - (asm_pos + orig_len));
    } else {
      accum = 0;
      gen_ins(op, val);
    }
    if((op != 16) & (op != 17)) {
      val = 0;
      while(val < accum) {
        write_temp2(pre_ins[val++]);
        ++asm_pos;
      }
      if(accum != orig_len) {
        changed = YES;
        list2 = first_label;
        while(list2 != NULL) {
          if(*list2 == 0) {
            val = *(list2+1) | (*(list2+2) << 8) |
                    (*(list2+3) << 16) | (*(list2+4) << 24);
            if(val >= start + delta)
              val = val + (accum - orig_len);
            *(list2+1) = val;
            *(list2+2) = val >> 8;
            *(list2+3) = val >> 16;
            *(list2+4) = val >> 24;
          }
          list2 = *(list2+5) | (*(list2+6) << 8) |
                  (*(list2+7) << 16) | (*(list2+8) << 24);
        }
        delta = delta + (accum - orig_len);
      }
    }

    list = *(list + 5) | (*(list + 6) << 8) |
           (*(list + 7) << 16) | (*(list + 8) << 24);
    print_decimal(++a * 100 / num_unres);
    puts("%  \r");
  }

  copy_range(start, last);
}

copy_range(start, end_ptr) int start, end_ptr; {
  while(start++ < end_ptr) {
    write_temp2(read_temp1());
    ++asm_pos;
  }
}

toupper(ch) int ch; {
  if((ch >= 'a') & (ch <= 'z')) return ch - 32;
  else return ch;
}

read_input(addr, size) char *addr; int size; {
  char *cur;
  int ch;
  cur = addr;
  while(1) {
    ch = getchar();
    if(ch == 8) {
      if(cur == addr) continue;
      putchar(8);
      --cur;
      continue;
    } else if(ch == 13) {
      puts("\r\n");
      *cur = 0;
      return;
    } else {
      if(cur == addr + size - 1) continue;
      putchar(ch);
      *cur++ = ch;
    }
  }
}

write_temp1(data) int data; {
  buf1[ptemp1++] = data;
  if(ptemp1 == BUF_SIZE) {
    ptemp1 = 0;
    while(ptemp1 < BUF_SIZE) {
      if(fputc(buf1[ptemp1++], temp1_fp) == EOF) {
        error("Disk full");
        break;
      }
    }
    ptemp1 = 0;
  }
}

flush_temp1() {
  int count;
  count = 0;
  while(count < ptemp1) {
    if(fputc(buf1[count++], temp1_fp) == EOF) {
      error("Disk full");
      break;
    }
  }
  fclose(temp1_fp);
  temp1_fp = NULL;
}

write_temp2(data) int data; {
  buf2[ptemp2++] = data;
  if(ptemp2 == BUF_SIZE) {
    ptemp2 = 0;
    while(ptemp2 < BUF_SIZE) {
      if(fputc(buf2[ptemp2++], temp2_fp) == EOF) {
        error("Disk full");
        break;
      }
    }
    ptemp2 = 0;
  }
}

flush_temp2() {
  int count;
  count = 0;
  while(count < ptemp2) {
    if(fputc(buf2[count++], temp2_fp) == EOF) {
      error("Disk full");
      break;
    }
  }
  fclose(temp2_fp);
  temp2_fp = NULL;
}

read_temp1() {
  if(ptemp1 == BUF_SIZE) {
    ptemp1 = 0;
    while(ptemp1 < BUF_SIZE)
      buf1[ptemp1++] = fgetc(temp1_fp);
    ptemp1 = 0;
  }
  return buf1[ptemp1++];
}

print_decimal(num)
  int num;
{
  if (num < 0) {
    putchar('-');
    if (num < -9)
      print_decimal(-(num / 10));
    putchar(-(num % 10) + '0');
  } else {
    if (num > 9)
      print_decimal(num / 10);
    putchar((num % 10) + '0');
  }
}

init_basic_ops() {
  instr_table[0] = "j";
  instr_table[1] = "ldlp";
  instr_table[2] = "pfix";
  instr_table[3] = "ldnl";
  instr_table[4] = "ldc";
  instr_table[5] = "ldnlp";
  instr_table[6] = "nfix";
  instr_table[7] = "ldl";
  instr_table[8] = "adc";
  instr_table[9] = "call";
  instr_table[10] = "cj";
  instr_table[11] = "ajw";
  instr_table[12] = "eqc";
  instr_table[13] = "stl";
  instr_table[14] = "stnl";
  instr_table[15] = "opr";
}

init_ops() {
  instr_table[16] = "rev";
  instr_table[17] = "lb";
  instr_table[18] = "bsub";
  instr_table[19] = "endp";
  instr_table[20] = "diff";
  instr_table[21] = "add";
  instr_table[22] = "gcall";
  instr_table[23] = "in";
  instr_table[24] = "prod";
  instr_table[25] = "gt";
  instr_table[26] = "wsub";
  instr_table[27] = "out";
  instr_table[28] = "sub";
  instr_table[29] = "startp";
  instr_table[30] = "outbyte";
  instr_table[31] = "outword";
}

init_instr1() {
  instr_table[32] = "seterr";
  instr_table[33] = "?";
  instr_table[34] = "resetch";
  instr_table[35] = "csub0";
  instr_table[36] = "?";
  instr_table[37] = "stopp";
  instr_table[38] = "ladd";
  instr_table[39] = "stlb";
  instr_table[40] = "sthf";
  instr_table[41] = "norm";
  instr_table[42] = "ldiv";
  instr_table[43] = "ldpi";
  instr_table[44] = "stlf";
  instr_table[45] = "xdble";
  instr_table[46] = "ldpri";
  instr_table[47] = "rem";

  instr_table[48] = "ret";
  instr_table[49] = "lend";
  instr_table[50] = "ldtimer";
  instr_table[51] =
  instr_table[52] =
  instr_table[53] =
  instr_table[54] =
  instr_table[55] =
  instr_table[56] = "?";
  instr_table[57] = "testerr";
  instr_table[58] = "testpranal";
  instr_table[59] = "tin";
  instr_table[60] = "div";
  instr_table[61] = "?";
  instr_table[62] = "dist";
  instr_table[63] = "disc";

  instr_table[64] = "diss";
  instr_table[65] = "lmul";
  instr_table[66] = "not";
  instr_table[67] = "xor";
  instr_table[68] = "bcnt";
  instr_table[69] = "lshr";
  instr_table[70] = "lshl";
  instr_table[71] = "lsum";
  instr_table[72] = "lsub";
  instr_table[73] = "runp";
  instr_table[74] = "xword";
  instr_table[75] = "sb";
  instr_table[76] = "gajw";
  instr_table[77] = "savel";
  instr_table[78] = "saveh";
  instr_table[79] = "wcnt";

  instr_table[80] = "shr";
  instr_table[81] = "shl";
  instr_table[82] = "mint";
  instr_table[83] = "alt";
  instr_table[84] = "altwt";
  instr_table[85] = "altend";
  instr_table[86] = "and";
  instr_table[87] = "enbt";
  instr_table[88] = "enbc";
  instr_table[89] = "enbs";
  instr_table[90] = "move";
  instr_table[91] = "or";
  instr_table[92] = "csngl";
  instr_table[93] = "ccnt1";
  instr_table[94] = "talt";
  instr_table[95] = "ldiff";

  instr_table[96] = "sthb";
  instr_table[97] = "taltwt";
  instr_table[98] = "sum";
  instr_table[99] = "mul";
  instr_table[100] = "sttimer";
  instr_table[101] = "stoperr";
  instr_table[102] = "cword";
  instr_table[103] = "clrhalterr";
  instr_table[104] = "sethalterr";
  instr_table[105] = "testhalterr";
  instr_table[106] = "dup";
  instr_table[107] = "move2dinit";
  instr_table[108] = "move2dall";
  instr_table[109] = "move2dnonzero";
  instr_table[110] = "move2dzero";
  instr_table[111] = "?";

  instr_table[112] =
  instr_table[113] =
  instr_table[114] = "?";
  instr_table[115] = "unpacksn";
  instr_table[116] =
  instr_table[117] =
  instr_table[118] =
  instr_table[119] =
  instr_table[120] =
  instr_table[121] =
  instr_table[122] =
  instr_table[123] = "?";
  instr_table[124] = "postnormsn";
  instr_table[125] = "roundsn";
  instr_table[126] =
  instr_table[127] = "?";

  instr_table[128] = "?";
  instr_table[129] = "ldinf";
  instr_table[130] = "fmul";
  instr_table[131] = "cflerr";
  instr_table[132] = "crcword";
  instr_table[133] = "crcbyte";
  instr_table[134] = "bitcnt";
  instr_table[135] = "bitrevword";
  instr_table[136] = "bitrevnbits";
  instr_table[137] = "pop";
  instr_table[138] = "timerdisableh";
  instr_table[139] = "timerdisablel";
  instr_table[140] = "timerenableh";
  instr_table[141] = "timerenablel";
  instr_table[142] = "ldmemstartval";
  instr_table[143] = "?";

  instr_table[144] = "?";
  instr_table[145] = "wsubdb";
  instr_table[146] = "fpldnldbi";
  instr_table[147] = "fpchkerror";
  instr_table[148] = "fpstnldb";
  instr_table[149] = "?";
  instr_table[150] = "fpldnlsni";
  instr_table[151] = "fpadd";
  instr_table[152] = "fpstnlsn";
  instr_table[153] = "fpsub";
  instr_table[154] = "fpldnldb";
  instr_table[155] = "fpmul";
  instr_table[156] = "fpdiv";
  instr_table[157] = "?";
  instr_table[158] = "fpldnlsn";
  instr_table[159] = "fpremfirst";
}

init_instr2() {
  instr_table[160] = "fpremstep";
  instr_table[161] = "fpnan";
  instr_table[162] = "fpordered";
  instr_table[163] = "fpnotfinite";
  instr_table[164] = "fpgt";
  instr_table[165] = "fpeq";
  instr_table[166] = "fpi32tor32";
  instr_table[167] = "?";
  instr_table[168] = "fpi32tor64";
  instr_table[169] = "?";
  instr_table[170] = "fpb32tor64";
  instr_table[171] = "?";
  instr_table[172] = "fptesterror";
  instr_table[173] = "fprtoi32";
  instr_table[174] = "fpstnli32";
  instr_table[175] = "fpldzerosn";

  instr_table[176] = "fpldzerodb";
  instr_table[177] = "fpint";
  instr_table[178] = "?";
  instr_table[179] = "fpdup";
  instr_table[180] = "fprev";
  instr_table[181] = "?";
  instr_table[182] = "fpldnladddb";
  instr_table[183] = "?";
  instr_table[184] = "fpldnlmuldb";
  instr_table[185] = "?";
  instr_table[186] = "fpldnladdsn";
  instr_table[187] = "fpentry";
  instr_table[188] = "fpldnlmulsn";
  instr_table[189] =
  instr_table[190] =
  instr_table[191] = "?";

  instr_table[192] = "?";
  instr_table[193] = "break";
  instr_table[194] = "clrj0break";
  instr_table[195] = "setj0break";
  instr_table[196] = "testj0break";
  instr_table[197] =
  instr_table[198] =
  instr_table[199] =
  instr_table[200] =
  instr_table[201] =
  instr_table[202] =
  instr_table[203] =
  instr_table[204] =
  instr_table[205] =
  instr_table[206] =
  instr_table[207] = "?";

  instr_table[208] =
  instr_table[209] =
  instr_table[210] =
  instr_table[211] =
  instr_table[212] =
  instr_table[213] =
  instr_table[214] =
  instr_table[215] =
  instr_table[216] =
  instr_table[217] =
  instr_table[218] =
  instr_table[219] =
  instr_table[220] =
  instr_table[221] =
  instr_table[222] =
  instr_table[223] = "?";

  instr_table[224] =
  instr_table[225] =
  instr_table[226] =
  instr_table[227] =
  instr_table[228] =
  instr_table[229] =
  instr_table[230] =
  instr_table[231] =
  instr_table[232] =
  instr_table[233] =
  instr_table[234] =
  instr_table[235] =
  instr_table[236] =
  instr_table[237] =
  instr_table[238] =
  instr_table[239] = "?";

  instr_table[240] =
  instr_table[241] =
  instr_table[242] =
  instr_table[243] =
  instr_table[244] =
  instr_table[245] =
  instr_table[246] =
  instr_table[247] =
  instr_table[248] =
  instr_table[249] =
  instr_table[250] =
  instr_table[251] =
  instr_table[252] =
  instr_table[253] =
  instr_table[254] =
  instr_table[255] = "?";

  instr_table[256] =
  instr_table[257] =
  instr_table[258] =
  instr_table[259] =
  instr_table[260] =
  instr_table[261] =
  instr_table[262] =
  instr_table[263] =
  instr_table[264] =
  instr_table[265] =
  instr_table[266] =
  instr_table[267] =
  instr_table[268] =
  instr_table[269] =
  instr_table[270] =
  instr_table[271] = "?";
}

init_fpu() {
  instr_table[272] = "?";
  instr_table[273] = "fpusqrtfirst";
  instr_table[274] = "fpusqrtstep";
  instr_table[275] = "fpusqrtlast";
  instr_table[276] = "fpurp";
  instr_table[277] = "fpurm";
  instr_table[278] = "fpurz";
  instr_table[279] = "fpur32tor64";
  instr_table[280] = "fpur64tor32";
  instr_table[281] = "fpuexpdec32";
  instr_table[282] = "fpuexpinc32";
  instr_table[283] = "fpuabs";
  instr_table[284] = "?";
  instr_table[285] = "fpunoround";
  instr_table[286] = "fpuchki32";
  instr_table[287] = "fpuchki64";

  instr_table[288] = "?";
  instr_table[289] = "fpudivby2";
  instr_table[290] = "fpumulby2";
  instr_table[291] =
  instr_table[292] =
  instr_table[293] =
  instr_table[294] =
  instr_table[295] =
  instr_table[296] =
  instr_table[297] =
  instr_table[298] =
  instr_table[299] =
  instr_table[300] =
  instr_table[301] =
  instr_table[302] =
  instr_table[303] = "?";

  instr_table[304] =
  instr_table[305] = "?";
  instr_table[306] = "fpurn";
  instr_table[307] = "fpuseterror";
  instr_table[308] =
  instr_table[309] =
  instr_table[310] =
  instr_table[311] =
  instr_table[312] =
  instr_table[313] =
  instr_table[314] =
  instr_table[315] =
  instr_table[316] =
  instr_table[317] =
  instr_table[318] =
  instr_table[319] = "?";

  instr_table[320] =
  instr_table[321] =
  instr_table[322] =
  instr_table[323] =
  instr_table[324] =
  instr_table[325] =
  instr_table[326] =
  instr_table[327] =
  instr_table[328] =
  instr_table[329] =
  instr_table[330] =
  instr_table[331] =
  instr_table[332] =
  instr_table[333] =
  instr_table[334] =
  instr_table[335] = "?";

  instr_table[336] =
  instr_table[337] =
  instr_table[338] =
  instr_table[339] =
  instr_table[340] =
  instr_table[341] =
  instr_table[342] =
  instr_table[343] =
  instr_table[344] =
  instr_table[345] =
  instr_table[346] =
  instr_table[347] =
  instr_table[348] =
  instr_table[349] =
  instr_table[350] =
  instr_table[351] = "?";

  instr_table[352] =
  instr_table[353] =
  instr_table[354] =
  instr_table[355] =
  instr_table[356] =
  instr_table[357] =
  instr_table[358] =
  instr_table[359] =
  instr_table[360] =
  instr_table[361] =
  instr_table[362] =
  instr_table[363] =
  instr_table[364] =
  instr_table[365] =
  instr_table[366] =
  instr_table[367] = "?";

  instr_table[368] =
  instr_table[369] =
  instr_table[370] =
  instr_table[371] =
  instr_table[372] =
  instr_table[373] =
  instr_table[374] =
  instr_table[375] =
  instr_table[376] =
  instr_table[377] =
  instr_table[378] =
  instr_table[379] =
  instr_table[380] =
  instr_table[381] =
  instr_table[382] =
  instr_table[383] = "?";

  instr_table[384] =
  instr_table[385] =
  instr_table[386] =
  instr_table[387] =
  instr_table[388] =
  instr_table[389] =
  instr_table[390] =
  instr_table[391] =
  instr_table[392] =
  instr_table[393] =
  instr_table[394] =
  instr_table[395] =
  instr_table[396] =
  instr_table[397] =
  instr_table[398] =
  instr_table[399] = "?";

  instr_table[400] =
  instr_table[401] =
  instr_table[402] =
  instr_table[403] =
  instr_table[404] =
  instr_table[405] =
  instr_table[406] =
  instr_table[407] =
  instr_table[408] =
  instr_table[409] =
  instr_table[410] =
  instr_table[411] =
  instr_table[412] =
  instr_table[413] =
  instr_table[414] =
  instr_table[415] = "?";

  instr_table[416] =
  instr_table[417] =
  instr_table[418] =
  instr_table[419] =
  instr_table[420] =
  instr_table[421] =
  instr_table[422] =
  instr_table[423] =
  instr_table[424] =
  instr_table[425] =
  instr_table[426] =
  instr_table[427] = "?";
  instr_table[428] = "fpuclearerror";
  instr_table[429] =
  instr_table[430] =
  instr_table[431] = "?";

  instr_table[432] =
  instr_table[433] =
  instr_table[434] =
  instr_table[435] =
  instr_table[436] =
  instr_table[437] =
  instr_table[438] =
  instr_table[439] =
  instr_table[440] =
  instr_table[441] =
  instr_table[442] =
  instr_table[443] =
  instr_table[444] =
  instr_table[445] =
  instr_table[446] =
  instr_table[447] = "?";

  instr_table[448] =
  instr_table[449] =
  instr_table[450] =
  instr_table[451] =
  instr_table[452] =
  instr_table[453] =
  instr_table[454] =
  instr_table[455] =
  instr_table[456] =
  instr_table[457] =
  instr_table[458] =
  instr_table[459] =
  instr_table[460] =
  instr_table[461] =
  instr_table[462] =
  instr_table[463] = "?";

  instr_table[464] =
  instr_table[465] =
  instr_table[466] =
  instr_table[467] =
  instr_table[468] =
  instr_table[469] =
  instr_table[470] =
  instr_table[471] =
  instr_table[472] =
  instr_table[473] =
  instr_table[474] =
  instr_table[475] =
  instr_table[476] =
  instr_table[477] =
  instr_table[478] =
  instr_table[479] = "?";

  instr_table[480] =
  instr_table[481] =
  instr_table[482] =
  instr_table[483] =
  instr_table[484] =
  instr_table[485] =
  instr_table[486] =
  instr_table[487] =
  instr_table[488] =
  instr_table[489] =
  instr_table[490] =
  instr_table[491] =
  instr_table[492] =
  instr_table[493] =
  instr_table[494] =
  instr_table[495] = "?";

  instr_table[496] =
  instr_table[497] =
  instr_table[498] =
  instr_table[499] =
  instr_table[500] =
  instr_table[501] =
  instr_table[502] =
  instr_table[503] =
  instr_table[504] =
  instr_table[505] =
  instr_table[506] =
  instr_table[507] =
  instr_table[508] =
  instr_table[509] =
  instr_table[510] =
  instr_table[511] = "?";

  instr_table[512] =
  instr_table[513] =
  instr_table[514] =
  instr_table[515] =
  instr_table[516] =
  instr_table[517] =
  instr_table[518] =
  instr_table[519] =
  instr_table[520] =
  instr_table[521] =
  instr_table[522] =
  instr_table[523] =
  instr_table[524] =
  instr_table[525] =
  instr_table[526] =
  instr_table[527] =
  instr_table[528] = "?";
}