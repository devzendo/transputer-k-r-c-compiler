/*
 ** Transputer assembler.
 **
 ** (c) Copyright 1995-2025 Oscar Toledo G.
 ** https://nanochess.org/
 **
 ** Creation date: Feb/01/2025. Ported from old code from Jun/14/1995.
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define NO       0
#define YES      1

#define LINE_SIZE  128
#define BUF_SIZE  2048

/*
 ** Assembler label
 */
struct label {
    struct label *next;        /* Next label in the table */
    struct label *sequence;    /* Linear sequence */
    int type;                     /* 0= address, 1= data value */
    int value;                    /* Data/address */
    char name[1];                     /* Label name, null-terminated */
};

/*
 ** Unresolved entry for widening
 */
struct unresolved {
    struct unresolved *next;     /* Next unresolved entry */
    int opcode;                   /* Instruction opcode (0 to 15); 16 means */
    /* db, and 17 means dw */
    int address;                 /* Address */
    char expression[1];          /* Expression */
};

/*
 ** Instruction table
 */
char *instr_table[] = {
    
    /*
     ** Basic instructions
     */
    "j", "ldlp", "pfix", "ldnl", "ldc", "ldnlp", "nfix", "ldl",
    "adc", "call", "cj", "ajw", "eqc", "stl", "stnl", "opr",
    
    /*
     ** Basic operations
     */
    "rev", "lb", "bsub", "endp", "diff", "add", "gcall", "in",
    "prod", "gt", "wsub", "out", "sub", "startp", "outbyte", "outword",
    
    /*
     ** Instructions
     */
    "seterr", "?", "resetch", "csub0", "?", "stopp", "ladd", "stlb",
    "sthf", "norm", "ldiv", "ldpi", "stlf", "xdble", "ldpri", "rem",
    "ret", "lend", "ldtimer", "?", "?", "?", "?", "?",
    "?", "testerr", "testpranal", "tin", "div", "?", "dist", "disc",
    "diss", "lmul", "not", "xor", "bcnt", "lshr", "lshl", "lsum",
    "lsub", "runp", "xword", "sb", "gajw", "savel", "saveh", "wcnt",
    "shr", "shl", "mint", "alt", "altwt", "altend", "and", "enbt",
    "enbc", "enbs", "move", "or", "csngl", "ccnt1", "talt", "ldiff",
    "sthb", "taltwt", "sum", "mul", "sttimer", "stoperr", "cword", "clrhalterr",
    "sethalterr", "testhalterr", "dup", "move2dinit",
    "move2dall", "move2dnonzero", "move2dzero", "?",
    "?", "?", "?", "unpacksn", "?", "?", "?", "?",
    "?", "?", "?", "?", "postnormsn", "roundsn", "?", "?",
    "?", "ldinf", "fmul", "cflerr", "crcword", "crcbyte", "bitcnt", "bitrevword",
    "bitrevnbits", "pop", "timerdisableh", "timerdisablel",
    "timerenableh", "timerenablel", "ldmemstartval", "?",
    "?", "wsubdb", "fpldnldbi", "fpchkerror",
    "fpstnldb", "?", "fpldnlsni", "fpadd",
    "fpstnlsn", "fpsub", "fpldnldb", "fpmul",
    "fpdiv", "?", "fpldnlsn", "fpremfirst",
    "fpremstep", "fpnan", "fpordered", "fpnotfinite",
    "fpgt", "fpeq", "fpi32tor32", "?",
    "fpi32tor64", "?", "fpb32tor64", "?",
    "fptesterror", "fprtoi32", "fpstnli32", "fpldzerosn",
    "fpldzerodb", "fpint", "?", "fpdup", "fprev", "?", "fpldnladddb", "?",
    "fpldnlmuldb", "?", "fpldnladdsn", "fpentry", "fpldnlmulsn", "?", "?", "?",
    "?", "break", "clrj0break", "setj0break", "testj0break", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    
    /*
     ** FPU microcode instructions
     */
    "?", "fpusqrtfirst", "fpusqrtstep", "fpusqrtlast",
    "fpurp", "fpurm", "fpurz", "fpur32tor64",
    "fpur64tor32", "fpuexpdec32", "fpuexpinc32", "fpuabs",
    "?", "fpunoround", "fpuchki32", "fpuchki64",
    "?", "fpudivby2", "fpumulby2", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "fpurn", "fpuseterror", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "fpuclearerror", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
    "?", "?", "?", "?", "?", "?", "?", "?",
};

/*
 ** Hash table
 */
struct label *hash_table[256];  /* Hash table for labels */
struct label *last_defined;  /* Last label defined */

char *input_file;
char *output_file;
char *temporary1_file;
char *temporary2_file;
char *library_file;

int pass_num;                          /* Assembly pass number */
int parse_err;
FILE *input_fp;
char *line_ptr;                  /* Processing pointer (in line) */

char pre_ins[8];
char orig_ins[8];
int accum;

FILE *temp1;
FILE *temp2;
int current_line;                 /* Current line being processed */
int errors_detected;            /* Total errors detected */
int available;
int asm_pos;
char *expr_ptr;
struct label *first_label;
struct unresolved *first_unres;
struct unresolved *last_unres;
int num_unres;
int ptemp1;
int ptemp2;
char name_buf[15];
char line_buf[LINE_SIZE];
char token[LINE_SIZE];
char token2[LINE_SIZE];
char undef_label[LINE_SIZE];
char buf1[BUF_SIZE];
char buf2[BUF_SIZE];

void assemble(void);
int hash_name(char *);
struct label *define_label(char *);
struct label *find_label(char *);
void free_memory(void);
char *next_token(void);
void process(void);
void check_end(void);
void error_extra_chars(void);
void emit_basic_op(int);
void add_unresolved(int);
int eval_expr(void);
int eval1(void);
int eval2(void);
int eval3(void);
int eval_hex(void);
int eval_dec(void);
void gen_ins(int, int);
void emit_simple(int);
void emit_extended(int);
void def_byte(void);
void def_word32(void);
void def_space(void);
void def_equ(void);
int match_str(char *, char *);
int read_line(void);
void link_pass(void);
void widen_pass(void);
void copy_range(int, int);
void write_temp1(int);
void flush_temp1(void);
void write_temp2(int);
void flush_temp2(void);
int read_temp1(void);
void error(char *, char *);

/*
 ** Main program
 */
int main(int argc, char *argv[])
{
    fprintf(stderr, "\n");
    fprintf(stderr, "Transputer assembler v0.1. Feb/01/2025\n");
    fprintf(stderr, "by Oscar Toledo G. https://nanochess.org/\n\n");
    if (argc != 3 && argc != 4) {
        fprintf(stderr, "Usage: tasm input.len output.cmg library.len\n\n");
        exit(1);
    }
    input_file = argv[1];
    output_file = argv[2];
    if (argc == 4)
        library_file = argv[3];
    else
        library_file = NULL;
    assemble();
    exit(0);
}

/*
 ** Perform the assembly
 */
void assemble(void)
{
    temporary1_file = "_tasm1.tmp";
    temporary2_file = "_tasm2.tmp";
    available = 1;
    first_label = NULL;
    last_defined = NULL;
    first_unres = NULL;
    last_unres = NULL;
    num_unres = 0;
    asm_pos = 0;
    input_fp = fopen(input_file, "r");
    if (input_fp == NULL) {
        fprintf(stderr, "Unable to open '%s'\n", input_file);
        return;
    }
    temp1 = fopen(temporary1_file, "wb");
    if (temp1 == NULL) {
        fprintf(stderr, "Couldn't open temporary write file\n");
        fclose(input_fp);
        return;
    }
    ptemp1 = 0;
    pass_num = 0;
    current_line = 0;
    process();
    fclose(input_fp);
    if (library_file != NULL) {
        input_fp = fopen(library_file, "r");
        if (input_fp == NULL) {
            fprintf(stderr, "Unable to open '%s'\n", library_file);
        } else {
            process();
            fclose(input_fp);
        }
    }
    flush_temp1();
    pass_num = 1;
    link_pass();
    free_memory();
    fprintf(stderr, "%d error(s) detected.\n", errors_detected);
    fprintf(stderr, "%d line(s) assembled.\n\n", current_line);
}

/*
 ** Cálcula el val de dispersión para un label_name
 */
int hash_name(char *label_name)
{
    int val;
    
    val = 0;
    while (*label_name)
        val = (val << 1) + (*label_name++ & 0xff);
    return val & 0xff;
}

/*
 ** Define a new label
 */
struct label *define_label(char *label_name)
{
    struct label *new_entry;
    int c;
    
    new_entry = malloc(sizeof(struct label) + strlen(label_name) + 1);
    if (new_entry == NULL)
        return NULL;
    c = hash_name(label_name);
    new_entry->next = hash_table[c];
    hash_table[c] = new_entry;
    new_entry->sequence = NULL;
    new_entry->type = 0;
    new_entry->value = asm_pos;
    strcpy(new_entry->name, label_name);
    if (first_label == NULL)
        first_label = new_entry;
    if (last_defined != NULL)
        last_defined->sequence = new_entry;
    last_defined = new_entry;
    return new_entry;
}

/*
 ** Search for a label
 */
struct label *find_label(char *label_name)
{
    struct label *list;
    int c;
    
    c = hash_name(label_name);
    list = hash_table[c];
    while (list != NULL) {
        if (strcmp(list->name, label_name) == 0)
            return list;
        list = list->next;
    }
    return NULL;
}

/*
 ** Free allocated memory
 */
void free_memory(void)
{
    struct label *list;
    struct label *next_ptr;
    struct unresolved *list2;
    struct unresolved *next_ptr2;
    int c;
    
    for (c = 0; c < 256; c++) {
        list = hash_table[c];
        while (list != NULL) {
            next_ptr = list->next;
            free(list);
            list = next_ptr;
        }
        hash_table[c] = NULL;
    }
    first_label = NULL;
    last_defined = NULL;
    list2 = first_unres;
    while (list2 != NULL) {
        next_ptr2 = list2->next;
        free(list2);
        list2 = next_ptr2;
    }
    first_unres = NULL;
    last_unres = NULL;
}

/*
 ** Extract the next token from the input line
 */
char *next_token(void)
{
    char *ap1 = line_ptr;
    char *ap2 = token;
    int c;
    
    while (isspace(*ap1))
        ap1++;
    if (*ap1 == ';') {  /* Comments are discarded */
        *ap2 = '\0';
        return ap2;
    }
    c = 0;
    while (*ap1) {
        if (c == 0 && isspace(*ap1))
            break;
        if (*ap1 == '"') {
            if (c & 1) {
                if (ap1[1] == '"') {
                    *ap2++ = *ap1++;
                    *ap2++ = *ap1++;
                    continue;
                }
            }
            c ^= 1;
        }
        if (*ap1 =='\'') {
            if (c & 2) {
                if (ap1[1] == '\'') {
                    *ap2++ = *ap1++;
                    *ap2++ = *ap1++;
                    continue;
                }
            }
            c ^= 2;
        }
        if (c)
            *ap2++ = *ap1;
        else
            *ap2++ = tolower(*ap1);
        ap1++;
    }
    *ap2 = '\0';
    while (isspace(*ap1))
        ap1++;
    line_ptr = ap1;
    if (ap2 != token)
        return ap2 - 1;
    return ap2;
}

/*
 ** Process the input file
 */
void process(void)
{
    int instr;
    int has_label;
    char *ap;
    char *end_ptr;
    
    while (!read_line()) {
        has_label = NO;
        while (1) {
            ap = next_token();
            if (*ap == ':') {
                *ap = '\0';
                if (isalpha(*token) || *token == '_') {
                    if (find_label(token) != NULL) {
                        error("Label redefined", token);
                    } else if (define_label(token) == NULL) {
                        error("Out of memory", NULL);
                        return;
                    }
                } else {
                    error("Invalid label", token);
                }
                ap = next_token();
            }
            if (token[0] == '\0')
                break;
            if (match_str("db", token)) {
                def_byte();
                check_end();
                break;
            } else if (match_str("dw", token)) {
                def_word32();
                check_end();
                break;
            } else if (match_str("ds", token)) {
                def_space();
                check_end();
                break;
            } else if (match_str("equ", token)) {
                def_equ();
                check_end();
                break;
            } else {
                instr = 0;
                while (instr < 528) {
                    ap = instr_table[instr++];
                    if (*ap == '?')
                        continue;
                    if (match_str(ap, token)) {
                        --instr;
                        if (instr < 16)
                            emit_basic_op(instr);
                        else if (instr < 272)
                            emit_simple(instr - 16);
                        else if (instr < 528)
                            emit_extended(instr - 272);
                        check_end();
                        break;
                    }
                }
                if (instr == 528)
                    error("Instrucción indefinida", token);
                else
                    break;
            }
        }
    }
    return;
}

/*
 ** Verify the correct end of an instruction
 */
void check_end(void)
{
    if (*line_ptr && *line_ptr != ';')
        error_extra_chars();
}

/*
 ** Report an error de caracteres extras en la línea
 */
void error_extra_chars(void)
{
    error("Extra characters", NULL);
}

/*
 ** Process a basic instruction
 */
void emit_basic_op(int op)
{
    int val;
    int adjust;
    int jump_dist;
    
    next_token();
    parse_err = 0;
    expr_ptr = token;
    val = eval_expr();
    if (*expr_ptr)
        error_extra_chars();
    if (parse_err) {
        add_unresolved(op);
        write_temp1(op << 4);
        ++asm_pos;
        return;
    }
    if (op == 0 || op == 9 || op == 10) {
        add_unresolved(op);
        adjust = 1;
        while (1) {
            accum = 0;
            gen_ins(op, jump_dist = (val - (asm_pos + adjust)));
            if (asm_pos + accum + jump_dist == val)
                break;
            ++adjust;
        }
    } else {
        accum = 0;
        gen_ins(op, val);
    }
    val = 0;
    while (val < accum) {
        write_temp1(pre_ins[val++]);
        ++asm_pos;
    }
}

/*
 ** Add an unresolved entry to the list
 */
void add_unresolved(int key)
{
    struct unresolved *new_entry;
    char *addr;
    char *pos1;
    int u;
    
    new_entry = malloc(sizeof(struct unresolved) + strlen(token) + 1);
    if (new_entry == NULL) {
        error("Out of memory", NULL);
        return;
    }
    new_entry->next = NULL;
    new_entry->opcode = key;
    new_entry->address = asm_pos;
    strcpy(new_entry->expression, token);
    if (first_unres == NULL)
        first_unres = new_entry;
    if (last_unres != NULL)
        last_unres->next = new_entry;
    last_unres = new_entry;
    ++num_unres;
}

/*
 ** Evaluate an expression
 */
int eval_expr(void)
{
    int val1;
    
    val1 = eval1();
    while (*expr_ptr == '+' || *expr_ptr == '-') {
        if (*expr_ptr == '+') {
            ++expr_ptr;
            val1 += eval1();
        } else {
            ++expr_ptr;
            val1 -= eval1();
        }
    }
    return val1;
}

/*
 ** Evaluation level 1
 */
int eval1(void)
{
    if (*expr_ptr == '+')
        ++expr_ptr;
    else if (*expr_ptr == '-') {
        ++expr_ptr;
        return -eval2();
    }
    return eval2();
}

/*
 ** Evaluation level 2
 */
int eval2(void)
{
    int val1;
    
    val1 = eval3();
    while (*expr_ptr == '*' || *expr_ptr == '/' || *expr_ptr == '%') {
        if (*expr_ptr == '*') {
            ++expr_ptr;
            val1 *= eval3();
        } else if (*expr_ptr == '/') {
            ++expr_ptr;
            val1 /= eval3();
        } else {
            ++expr_ptr;
            val1 %= eval3();
        }
    }
    return val1;
}

/*
 ** Evaluation level 3
 */
int eval3(void)
{
    struct label *lbl;
    char *ap;
    int val;
    
    if (*expr_ptr == '(') {
        ++expr_ptr;
        val = eval_expr();
        if (*expr_ptr != ')')
            error("Missing closing parenthesis", NULL);
        else
            ++expr_ptr;
        return val;
    } else if (isdigit(*expr_ptr)) {
        if (*(expr_ptr + 1) == 'X' || *(expr_ptr + 1) == 'x')
            return eval_hex();
        else
            return eval_dec();
    } else if (*expr_ptr == 39) {
        expr_ptr++;
        val = *expr_ptr++;
        if (val == 39) {
            if (*expr_ptr == 39 && expr_ptr[1] == 39)
                expr_ptr += 2;
            else
                error("Missing closing apostrophe", NULL);
        } else {
            if (*expr_ptr == 39)
                expr_ptr++;
            else
                error("Missing closing apostrophe", NULL);
        }
        return val;
    } else if (isalpha(*expr_ptr) || *expr_ptr == '_') {
        ap = token2;
        while (*expr_ptr == '_'
               || isalpha(*expr_ptr)
               || isdigit(*expr_ptr))
            *ap++ = *expr_ptr++;
        *ap = '\0';
        if ((lbl = find_label(token2)) != NULL) {
            val = lbl->value;
            return val;
        } else {
            strcpy(undef_label, token2);
            parse_err = 1;
            return 0;
        }
    } else {
        error("Syntax error", NULL);
        return 0;
    }
}

/*
 ** Process a hexadecimal number
 */
int eval_hex(void)
{
    int c;
    int val;
    
    val = 0;
    expr_ptr += 2;
    while (isxdigit(*expr_ptr)) {
        c = toupper(*expr_ptr++) - '0';
        if (c > 9)
            c -= 7;
        val = (val << 4) | c;
    }
    return val;
}

/*
 ** Process a decimal number
 */
int eval_dec(void)
{
    int c;
    int val;
    
    val = 0;
    while (isdigit(*expr_ptr)) {
        c = *expr_ptr++ - '0';
        val = val * 10 + c;
    }
    return val;
}

/*
 ** Generate the instructions needed to load a value
 */
void gen_ins(int oper, int val)
{
    if (val < 0)
        gen_ins(6, ~val >> 4);
    else if (val >= 16)
        gen_ins(2, val >> 4);
    pre_ins[accum++] = (oper << 4) | (val & 15);
}

/*
 ** Generate a simple instruction
 */
void emit_simple(int op)
{
    if (op > 15) {
        write_temp1(0x20 + (op >> 4));
        ++asm_pos;
    }
    write_temp1(0xf0 + (op & 15));
    ++asm_pos;
}

/*
 ** Generate an extended instruction
 */
void emit_extended(int op)
{
    if (op > 15) {
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

/*
 ** Definición de bytes
 */
void def_byte(void)
{
    int val;
    
    next_token();
    expr_ptr = token;
    while (1) {
        parse_err = 0;
        if (*expr_ptr == '"') {
            expr_ptr++;
            while (*expr_ptr && (*expr_ptr != '"' || expr_ptr[1] == '"')) {
                write_temp1(*expr_ptr);
                ++asm_pos;
                if (expr_ptr[0] == '"' && expr_ptr[1] == '"')
                    expr_ptr++;
                expr_ptr++;
            }
            if (*expr_ptr != '"') {
                error("Missing closing quote", NULL);
            } else {
                ++expr_ptr;
            }
        } else if (*expr_ptr == '\'') {
            expr_ptr++;
            while (*expr_ptr && (*expr_ptr != '\'' || expr_ptr[1] == '\'')) {
                write_temp1(*expr_ptr);
                ++asm_pos;
                if (expr_ptr[0] == '\'' && expr_ptr[1] == '\'')
                    expr_ptr++;
                expr_ptr++;
            }
            if (*expr_ptr != '\'') {
                error("Missing closing apostrophe", NULL);
            } else {
                ++expr_ptr;
            }
        } else {
            val = eval_expr();
            if (parse_err)
                add_unresolved(16);
            write_temp1(val & 255);
            ++asm_pos;
        }
        if (*expr_ptr != ',') {
            if (*expr_ptr)
                error("Missing comma", NULL);
            return;
        }
        ++expr_ptr;
    }
}

/*
 ** Definición de palabras de 32 bits
 */
void def_word32(void)
{
    int val;
    
    next_token();
    expr_ptr = token;
    while (1) {
        parse_err = 0;
        val = eval_expr();
        if (parse_err)
            add_unresolved(17);
        write_temp1(val & 255);
        ++asm_pos;
        write_temp1((val >> 8) & 255);
        ++asm_pos;
        write_temp1((val >> 16) & 255);
        ++asm_pos;
        write_temp1((val >> 24) & 255);
        ++asm_pos;
        if (*expr_ptr != ',') {
            if (*expr_ptr)
                error("Missing comma", NULL);
            return;
        }
        ++expr_ptr;
    }
}

/*
 ** Free-space definition
 */
void def_space(void)
{
    int val;
    
    next_token();
    expr_ptr = token;
    parse_err = 0;
    val = eval_expr();
    if (*expr_ptr)
        error_extra_chars();
    if (parse_err) {
        error("A defined value is required", NULL);
        return;
    }
    while (val--) {
        write_temp1(0);
        ++asm_pos;
    }
}

/*
 ** Label equivalence definition
 */
void def_equ(void)
{
    int val;
    
    next_token();
    expr_ptr = token;
    parse_err = 0;
    val = eval_expr();
    if (*expr_ptr)
        error_extra_chars();
    if (parse_err) {
        error("A defined value is required", NULL);
        return;
    }
    if (last_defined == NULL) {
        error("equ without label", NULL);
        return;
    }
    last_defined->type = 1;
    last_defined->value = val;
}

/*
 ** Comparación con instrucción
 */
int match_str(char *op, char *token)
{
    while (*op == *token++)
        if (*op++ == 0)
            return 1;
    return 0;
}

/*
 ** Read a line from the input file
 */
int read_line(void)
{
    char *ap;
    int c;
    
    ap = line_buf;
    while (1) {
        c = fgetc(input_fp);
        if (c == EOF) {
            if (ap != line_buf)
                break;
            return 1;  /* End of file */
        }
        *ap = c;
        if (*ap == '\r')
            continue;
        if (*ap == '\n')
            break;
        if (ap - line_buf < sizeof(line_buf) - 1)
            ap++;
    }
    *ap = '\0';
    current_line++;
    line_ptr = line_buf;
    /*    fprintf(stderr, "[%s]\n", line_buf);*/
    return 0;
}

int changed;

/*
 ** Widen instructions in the final file
 */
void link_pass(void)
{
    int c;
    char *p;
    
    while (1) {
        temp1 = fopen(temporary1_file, "rb");
        ptemp1 = BUF_SIZE;
        temp2 = fopen(temporary2_file, "wb");
        ptemp2 = 0;
        changed = NO;
        widen_pass();
        flush_temp2();
        fclose(temp1);
        temp1 = NULL;
        remove(temporary1_file);
        p = temporary1_file;
        temporary1_file = temporary2_file;
        temporary2_file = p;
        if (!changed) {
            temp1 = fopen(temporary1_file, "rb");
            temp2 = fopen(output_file, "wb");
            while (1) {
                c = fread(buf1, 1, BUF_SIZE, temp1);
                if (c == 0)
                    break;
                fwrite(buf1, 1, c, temp2);
            }
            fclose(temp2);
            fclose(temp1);
            remove(temporary1_file);
            break;
        }
    }
}

/*
 ** Perform one widening pass
 */
void widen_pass(void)
{
    struct unresolved *list;
    struct label *list2;
    int start;
    int last;
    int addr;
    int val;
    int byte_val;
    int orig_len;
    int op;
    int adjust;
    int jump_dist;
    int delta;
    int a;
    int c;
    
    last = asm_pos;
    asm_pos = 0;
    delta = 0;
    start = 0;
    list = first_unres;
    a = 0;
    while (list != NULL) {
        addr = list->address;
        copy_range(start, addr);
        op = list->opcode;
        if (op == 16) {
            byte_val = read_temp1();
            start = addr + 1;
        } else if (op == 17) {
            byte_val = read_temp1();
            byte_val = read_temp1();
            byte_val = read_temp1();
            byte_val = read_temp1();
            start = addr + 4;
        } else {
            orig_len = 0;
            while (1) {
                orig_ins[orig_len++] = byte_val = read_temp1();
                if ((byte_val & 0xf0) == 0x20)
                    continue;
                if ((byte_val & 0xf0) == 0x60)
                    continue;
                break;
            }
            start = addr + orig_len;
        }
        list->address = asm_pos;
        parse_err = 0;
        expr_ptr = list->expression;
        val = eval_expr();
        if (parse_err) {
            error("Undefined label", undef_label);
            val = 0;
        }
        if (op == 16) {
            write_temp2(val);
            ++asm_pos;
        } else if (op == 17) {
            write_temp2(val);
            ++asm_pos;
            write_temp2(val >> 8);
            ++asm_pos;
            write_temp2(val >> 16);
            ++asm_pos;
            write_temp2(val >> 24);
            ++asm_pos;
        } else if (op == 0 || op == 9 || op == 10) {
            accum = 0;
            gen_ins(op, val - (asm_pos + orig_len));
        } else {
            accum = 0;
            gen_ins(op, val);
        }
        if (op != 16 && op != 17) {
            val = 0;
            while (val < accum) {
                write_temp2(pre_ins[val++]);
                ++asm_pos;
            }
            if (accum != orig_len) {
                changed = YES;
                list2 = first_label;
                while (list2 != NULL) {
                    if (list2->type == 0) {
                        val = list2->value;
                        if (val >= start + delta)
                            val += accum - orig_len;
                        list2->value = val;
                    }
                    list2 = list2->sequence;
                }
                delta += accum - orig_len;
            }
        }
        list = list->next;
#if 0
        putchar('\r');
        decimal(++a * 100 / num_unres);
        putchar('%');
#endif
    }
    copy_range(start, last);
}

/*
 ** Copy data from temp file 1 to temp file 2
 */
void copy_range(int start, int end_ptr)
{
    while (start++ < end_ptr) {
        write_temp2(read_temp1());
        ++asm_pos;
    }
}

/*
 ** Write data to temp file 1
 */
void write_temp1(int data)
{
    buf1[ptemp1++] = data;
    if (ptemp1 == BUF_SIZE) {
        if (fwrite(buf1, 1, ptemp1, temp1) != ptemp1)
            error("Disk full", NULL);
        ptemp1 = 0;
    }
}

/*
 ** Flush final data to temp file 1
 */
void flush_temp1(void)
{
    if (ptemp1 > 0)
        if (fwrite(buf1, 1, ptemp1, temp1) != ptemp1)
            error("Disk full", NULL);
    fclose(temp1);
    temp1 = NULL;
}

/*
 ** Write data to temp file 2
 */
void write_temp2(int data)
{
    buf2[ptemp2++] = data;
    if (ptemp2 == BUF_SIZE) {
        if (fwrite(buf2, 1, ptemp2, temp2) != ptemp2)
            error("Disk full", NULL);
        ptemp2 = 0;
    }
}

/*
 ** Flush data to temp file 2
 */
void flush_temp2(void)
{
    if (ptemp2 > 0)
        if (fwrite(buf2, 1, ptemp2, temp2) != ptemp2)
            error("Disk full", NULL);
    fclose(temp2);
    temp2 = NULL;
}

/*
 ** Read data from temp file 1
 */
int read_temp1(void)
{
    if (ptemp1 == BUF_SIZE) {
        fread(buf1, 1, BUF_SIZE, temp1);
        ptemp1 = 0;
    }
    return buf1[ptemp1++];
}

/*
 ** Report an error
 */
void error(char *msg, char *data)
{
    if (data != NULL)
        fprintf(stderr, "%s '%s' at line %d\n", msg, data, current_line);
    else
        fprintf(stderr, "%s at line %d\n", msg, current_line);
}




