/*
** Small C compiler for transputer.
** Now with expression trees and optimized code generator.
**
** by Oscar Toledo Gutierrez.
**
** Original compiler by Ron Cain.
**
** English translation, modernisation by Matt Gumbley & Claude.
**
** 12-jun-1995
*/

#define BANNER  "*** C Compiler for G-10 ***"
#define AUTHOR  "   by Oscar Toledo Gutierrez."
#define VERSION "          Version 1.00"

#define NO      0
#define YES     1

/* Definitions for standalone execution */

#define NULL 0
#define eol 10

/* Define symbol table parameters */

#define symsiz  24
#define symtbsz 8400
#define numglbs 300
#define startglb symtab
#define endglb  startglb+numglbs*symsiz
#define startloc endglb+symsiz
#define endloc  symtab+symtbsz-symsiz

/* Define symbol entry format */

#define name    0
#define ident   17
#define type    18
#define storage 19
#define offset  20

/* Maximum name size */

#define namesize 17
#define namemax  16

/* Possible values for "ident" */

#define variable 1
#define array    2
#define pointer  3
#define function 4

/* Possible values for "type" */

#define cchar   1
#define cint    2

/* Possible values for "storage" */

#define statik  1
#define stkloc  2

/* Define the while-loop queue */

#define wqtabsz 100
#define wqsiz   4
#define wqmax   wq+wqtabsz-wqsiz

/* Define offsets within the while-loop queue */

#define wqsym   0
#define wqsp    1
#define wqloop  2
#define wqlab   3

/* Define string literal storage */

#define litabsz 1024
#define litmax  litabsz-1

/* Define the input line buffer */

#define linesize 512
#define linemax linesize-1
#define mpmax   linemax

/* Define macro storage */

#define macqsize 4096
#define macmax   macqsize-1

/* Define statement types */

#define stif     1
#define stwhile  2
#define streturn 3
#define stbreak  4
#define stcont   5
#define stasm    6
#define stexp    7

/* Define how to truncate a long name for the assembler */

#define asmpref 7
#define asmsuff 7

/* Reserve space for variables */

char symtab[symtbsz];   /* Symbol table */
char *glbptr, *locptr;  /* Pointers to the next free entries */

int wq[wqtabsz];        /* Loop queue */
int *wqptr;             /* Pointer to the next entry */

char litq[litabsz];     /* String literal storage */
int litidx;             /* Index to the next entry in litq */

char macq[macqsize];    /* Macro buffer */
int macidx;             /* Index into the buffer */

char line[linesize];    /* Parse buffer */
char mline[linesize];   /* Pre-preprocessed buffer */
int lidx, midx;         /* Respective indices */

/* Miscellaneous storage */
char *                  /* FILE * really, but this compiler only understands char * */
    input;              /* Input file */
char *
    output;             /* Output file */
char *
    input2;             /* #include file */
char *
    saveout;            /* Indicates redirect to console */

int nxtlab,             /* Next available label */
    litlab,             /* Label for the string buffer */
    Zsp,                /* Compiler stack pointer */
    argstk,             /* Argument stack */
    ncmp,               /* Number of open blocks */
    errcnt,             /* Number of errors detected */
    errstop,            /* Whether to stop on error */
    eof,                /* Indicates end of input file */
    ctext,              /* Whether to include source in output */
    cmode,              /* Whether currently compiling C */
    lastst,             /* Last statement executed */
    fnstart,            /* Starting line of the current function */
    lineno,             /* Line number in current file */
    infunc,             /* Whether inside a function */
    savestart,          /* Copy of "fnstart" */
    saveline,           /* Copy of "lineno" */
    saveinfn;           /* Copy of "infunc" */

char *currfn,           /* Pointer to the definition of the current function */
     *savecurr;         /* Copy of "currfn" for #include */
char quote[2];          /* Literal string for '"' */
char *cptr;             /* Working pointer */
int *iptr;              /* Working pointer */
int global_pos;          /* Position for static variables */
int use_expr;            /* Whether the expression result is used */

/*
** Compiler execution starts here.
*/
main()
{
  banner();             /* Banner */
  options();            /* Process options */
  openin();             /* First file to process */
  while (input != 0) {  /* Process all requested files */
    glbptr = startglb;  /* Clear the global table */
    locptr = startloc;  /* Clear the local table */
    wqptr = wq;         /* Clear the loop queue */
    macidx =            /* Clear the macro table */
    Zsp =               /* Stack pointer */
    errcnt =            /* No errors */
    eof =               /* EOF not yet reached */
    input2 =            /* No #include open */
    saveout =           /* Output not yet redirected */
    ncmp =              /* No open blocks */
    lastst =
    fnstart =           /* Current function started at line 0 */
    lineno =            /* No lines have been read from the file */
    infunc =            /* Not inside a function */
    nxtlab =            /* Initialize label numbers */
    quote[1] =
    0;
    quote[0] = '"';     /* Create a string with a quote */
    global_pos = 2;
    currfn = NULL;      /* No function yet */
    cmode = 1;          /* Enable preprocessing */
    openout();
    header();
    parse();
    if (ncmp)
      error("Missing closing brace");
    trailer();
    closeout();
    errorsummary();
    openin();
  }
}

/*
** Abort the compilation.
*/
abort()
{
  if (input2)
    endinclude();
  if (input)
    fclose(input);
  closeout();
  toconsole();
  pl("Compilation aborted.");
  nl();
  exit(1);
}


/*
** Process all the input text.
**
** At this level, only static declarations,
** #define, #include, and function definitions
** are legal.
*/
parse()
{
  while (eof == 0) {    /* Work until no more input */
    if (amatch("char", 4)) {
      declglb(cchar);
      ns();
    } else if (amatch("int", 3)) {
      declglb(cint);
      ns();
    } else if (match("#asm"))
      doasm();
    else if (match("#include"))
      doinclude();
    else if (match("#define"))
      addmac();
    else
      newfunc();
    blanks();           /* Track end of file */
  }
}

/*
** Flush the string literal storage
*/
dumplits()
{
  int j, k;

  if (litidx == 0)
    return;             /* Nothing to dump, return... */
  printlabel(litlab);   /* Print the label */
  col();
  nl();
  k = 0;                /* Start an index... */
  while (k < litidx) {  /* to flush the storage */
    defbyte();          /* Define byte */
    j = 5;              /* Bytes per line */
    while (j--) {
      outdec(litq[k++] & 255);
      if ((j == 0) | (k >= litidx)) {
        nl();           /* Another line */
        break;
      }
      outbyte(',');     /* Separate the bytes */
    }
  }
}

/*
** Report errors
*/
errorsummary()
{
  nl();
  outstr("There were ");
  outdec(errcnt);       /* Total number of errors */
  outstr(" errors in the compilation.");
  nl();
}

/*
** Banner.
*/
banner()
{
  nl();
  nl();
  pl(BANNER);
  nl();
  pl(AUTHOR);
  nl();
  nl();
  pl(VERSION);
  nl();
  nl();
}

options()
{
  /* Check whether the user wants to see all errors */
  pl("Pause after each error? (Y/N) ");
  gets(line);
  errstop = 0;
  if ((ch() == 'Y') | (ch() == 'y'))
    errstop = 1;

  pl("Show C source listing? (Y/N) ");
  gets(line);
  ctext = 0;
  if ((ch() == 'Y') | (ch() == 'y'))
    ctext = 1;
}

/*
** Get the output file name.
*/
openout()
{
  output = 0;           /* Default output to console */
  while (output == 0) {
    kill();
    pl("Output file? ");
    gets(line);         /* Get the name */
    if (ch() == 0)
      break;            /* None... */
    if ((output = fopen(line, "w")) == NULL) {  /* Try to create */
      output = 0;       /* Could not create */
      error("Could not create file");
    }
  }
  kill();               /* Clear the line */
}

/*
** Get the input file
*/
openin()
{
  input = 0;            /* None yet */
  while (input == 0) {
    kill();             /* Clear the input line */
    pl("Input file? ");
    gets(line);         /* Get a name */
    if (ch() == 0)
      break;
    if ((input = fopen(line, "r")) != NULL)
      newfile();
    else {
      input = 0;        /* Could not read */
      pl("Could not read file");
    }
  }
  kill();               /* Clear the line */
}

/*
** Initialize the line counter.
*/
newfile()
{
  lineno = 0;           /* No lines read yet */
  fnstart = 0;          /* No function yet */
  currfn = NULL;
  infunc = 0;
}

/*
** Open a #include file
*/
doinclude()
{
  blanks();             /* Skip whitespace */

  toconsole();
  outstr("#include ");
  outstr(line + lidx);
  nl();
  tofile();

  if (input2)
    error("Cannot nest include files");
  else if ((input2 = fopen(line + lidx, "r")) == NULL) {
    input2 = 0;
    error("Could not read file");
  } else {
    saveline = lineno;
    savecurr = currfn;
    saveinfn = infunc;
    savestart = fnstart;
    newfile();
  }
  kill();               /* Next input will come from */
                        /* the new file. */
}

/*
** Close a #include file
*/
endinclude()
{
  toconsole();
  outstr("#end include");
  nl();
  tofile();

  input2 = 0;
  lineno = saveline;
  currfn = savecurr;
  infunc = saveinfn;
  fnstart = savestart;
}

/*
** Close the output file.
*/
closeout()
{
  tofile();             /* If redirected, return to file */
  if (output)
    fclose(output);     /* If open, close it */
  output = 0;           /* Mark as closed */
}

/*
** Declare a static variable.
**
** Creates a table entry so that subsequent
** references can call it by name.
*/
declglb(typ)            /* typ is cchar or cint */
  int typ;
{
  int k, j;
  char sname[namesize];

  while (1) {
    while (1) {
      if (endst())
        return;         /* Process the line */
      k = 1;            /* Assume 1 element */
      if (match("*"))   /* Pointer? */
        j = pointer;    /* Yes */
      else
        j = variable;   /* No */
      if (symname(sname) == 0)  /* Valid name? */
        illname();              /* No... */
      if (findglb(sname))       /* Already in the table? */
        multidef(sname);
      if (match("[")) {         /* Array? */
        k = needsub();          /* Get the size */
        if (k)
          j = array;            /* !0= Array */
        else
          j = pointer;          /* 0= Pointer */
      }
      addglb(sname, j, typ, global_pos); /* Add the name */
      if ((cptr[type] == cint) |
          (cptr[ident] == pointer))
        k = k * 4;
      global_pos = global_pos + ((k + 3) / 4);
      break;
    }
    if (match(",") == 0)
      return;                   /* More? */
  }
}

/*
** Process local variable declarations.
*/
declloc() {
  int k, j, stack, typ;
  char sname[namesize];

  stack = Zsp;
  while (1) {
    if (amatch("int", 3))
      typ = cint;
    else if (amatch("char", 4))
      typ = cchar;
    else
      break;
    while (1) {
      if (endst())
        break;
      if (match("*"))
        j = pointer;
      else
        j = variable;
      if (symname(sname) == 0)
        illname();
      if (findloc(sname))
        multidef(sname);
      if (match("[")) {
        k = needsub();
        if (k) {
          j = array;
          if (typ == cint)
            k = k * 4;
        } else {
          j = pointer;
          k = 4;
        }
      } else if ((typ == cchar)
                 & (j != pointer))
        k = 1;
      else
        k = 4;
      /* Adjust the stack */
      k = (k + 3) / 4;
      stack = stack - k;
      addloc(sname, j, typ, stack);
      if (match(",") == 0)
        break;
    }
    ns();
  }
  Zsp = modstk(stack);
}

/*
** Get the size of an array.
**
** Called when a declaration is followed
** by "[".
*/
needsub()
{
  int num[1];

  if (match("]"))
    return 0;                   /* Zero size */
  if (number(num) == 0) {       /* Look for the number */
    error("Must be a number");/* Not a number */
    num[0] = 1;                 /* Force to 1 */
  }
  if (num[0] < 0) {
    error("Negative size");
    num[0] = (-num[0]);
  }
  needbrack("]");       /* Force a dimension */
  return num[0];        /* and return the size */
}

/*
** Compile a function.
**
** Called by "parse", this routine attempts to compile a function
** from the input.
*/
newfunc()
{
  char n[namesize];
  int argtop;

  if (symname(n) == 0) {
    if (eof == 0)
      error("Illegal declaration or function");
    kill();                     /* Invalidate the line */
    return;
  }
  fnstart = lineno;             /* Remember which line the function started on */
  infunc = 1;                   /* Indicate that we are inside a function */
  if (currfn = findglb(n)) {    /* Already in the symbol table? */
    if (currfn[ident] != function)
      multidef(n);              /* There is already a variable with that name */
    else if (currfn[offset] == function)
      multidef(n);              /* A function was redefined */
    else
      currfn[offset] = function;/* A previously referenced function */
  }

  /* Not in the table; define as a function */

  else
    currfn = addglb(n, function, cint, function);

  toconsole();
  outstr("Compiling ");
  outstr(currfn + name);
  outstr("()...");
  nl();
  tofile();

  /* Check for opening parenthesis */
  if (match("(") == 0)
    error("Missing opening parenthesis");
  outname(n);                   /* Print the function name */
  col();
  nl();

  locptr = startloc;            /* Clear the local variable table */
  argstk = 0;                   /* Initialize the argument count */
  while (match(")") == 0) {     /* Start counting */

    /* Any valid name increments the count */

    if (symname(n)) {
      if (findloc(n))
        multidef(n);
      else {
        addloc(n, 0, 0, argstk + 2);
        ++argstk;
      }
    } else {
      error("Illegal argument name");
      junk();
    }
    blanks();

    /* If not a closing parenthesis, must be a comma */

    if (streq(line + lidx, ")") == 0) {
      if (match(",") == 0)
        error("Comma required");
    }
    if (endst())
      break;
  }

  argtop = argstk;
  while (argstk) {

    /* Now the user declares the argument types */

    if (amatch("char", 4)) {
      getarg(cchar, argtop);
      ns();
    } else if (amatch("int", 3)) {
      getarg(cint, argtop);
      ns();
    } else {
      error("Incorrect number of arguments");
      break;
    }
  }

  Zsp = 0;              /* Initialize the stack pointer */

  litlab = getlabel();  /* Label for the literal buffer */
  litidx = 0;           /* Clear the literal buffer */

  /* Process a statement; if it is a return */
  /* then do not clean the stack */

  if (statement() != streturn) {
    modstk(0);
    zret();
  }
  dumplits();

  Zsp = 0;              /* Clean the stack again */
  locptr = startloc;    /* Remove all local variables */
  infunc = 0;           /* No longer inside a function */
}

/*
** Declare the types of the arguments.
*/
getarg(t, top)                  /* Type = cchar or cint */
  int t, top;
{                               /* top = highest point on the stack */
  char n[namesize], *argptr;
  int j;

  while (1) {
    if (match("*"))
      j = pointer;
    else
      j = variable;
    if (symname(n)) {
      if (match("[")) {         /* Ignore what is between [] */
        while (in_byte() != ']')
	        if (endst())
	          break;
	      j = pointer;
      }
      if (argptr = findloc(n)) {

	/* Set the correct type for the argument */

	argptr[ident] = j;
	argptr[type] = t;

      } else
        error("Argument name required");
    } else
      illname();

    --argstk;                   /* count backwards */
    if (endst())
      return;
    if (match(",") == 0)
      error("Comma required");
  }
}

/*
** Statement parser.
**
** Called when the syntax requires a
** statement; returns a number indicating
** the last statement processed.
*/
statement()
{
  if ((ch() == 0) & (eof))
    return;
  else if (match("{"))
    compound();
  else if (amatch("if", 2)) {
    doif();
    lastst = stif;
  } else if (amatch("while", 5)) {
    dowhile();
    lastst = stwhile;
  } else if (amatch("return", 6)) {
    doreturn();
    ns();
    lastst = streturn;
  } else if (amatch("break", 5)) {
    dobreak();
    ns();
    lastst = stbreak;
  } else if (amatch("continue", 8)) {
    docont();
    ns();
    lastst = stcont;
  } else if (match(";"))
    lastst = stexp;
  else if (match("#asm")) {
    doasm();
    lastst = stasm;
  }
  /* Assume it is an expression */
  else {
    use_expr = NO;
    expression();
    ns();
    lastst = stexp;
  }
  return lastst;
}

/*
** Check for semicolon.
**
** Called when the syntax requires one.
*/
ns()
{
  if (match(";") == 0)
    error("Missing semicolon");
}

/*
** Compound statement.
*/
compound()
{
  int local, stack;

  local = locptr;               /* Local variables */
  stack = Zsp;                  /* Current stack */
  ++ncmp;                       /* A new level */
  declloc();                    /* Process local declarations */
  while (match("}") == 0)
    statement();                /* Process statements */
  --ncmp;                       /* Close the level */
  locptr = local;               /* Clear local variables */
  if(lastst == streturn) return;
  if(lastst == stbreak) return;
  if(lastst == stcont) return;
  Zsp = modstk(stack);           /* Clean the stack */
}

/*
** "if" statement
*/
doif()
{
  int flab1, flab2;

  flab1 = getlabel();           /* Label for the false branch */
  test(flab1);                  /* Test the expression and jump if false */
  statement();                  /* True: process statements */
  if (amatch("else", 4) == 0)   /* if...else? */
                                /* Simple "if" ... print false label */
  {
    printlabel(flab1);
    col();
    nl();
    return;                     /* And return */
  }
                                /* An "if...else" statement */
  jump(flab2 = getlabel());     /* Jump around the else code */
  printlabel(flab1);
  col();
  nl();                         /* Print false label */
  statement();                  /* Process the else */
  printlabel(flab2);
  col();
  nl();                         /* Print true label */
}

/*
** "while" statement
*/
dowhile()
{
  int wq[4];                    /* Create an entry */

  wq[wqsym] = locptr;           /* Local variable level */
  wq[wqsp] = Zsp;               /* Stack level */
  wq[wqloop] = getlabel();      /* Loop label */
  wq[wqlab] = getlabel();       /* Exit label */
  addwhile(wq);                 /* Add to queue (for break) */
  printlabel(wq[wqloop]);       /* Loop label */
  col();
  nl();
  test(wq[wqlab]);              /* Check the expression */
  statement();                  /* Process a statement */
  if((lastst != streturn) &
     (lastst != stcont) &
     (lastst != stbreak))
    jump(wq[wqloop]);           /* Return to the loop */
  printlabel(wq[wqlab]);        /* Exit label */
  col();
  nl();
  delwhile();                   /* Remove from the queue */
}

/*
** "return" statement
*/
doreturn()
{
  /* Check whether there is an expression */
  if (endst() == 0) {
    use_expr = YES;
    expression();
  }
  modstk(0);                    /* Clean the stack */
  zret();                       /* Exit the function */
}

/*
** "break" statement
*/
dobreak()
{
  int *ptr;

  /* See if there is an open while */
  if ((ptr = readwhile()) == 0)
    return;                     /* No */
  modstk((ptr[wqsp]));          /* Yes, fix the stack */
  jump(ptr[wqlab]);             /* Jump to the exit label */
}

/*
** "continue" statement
*/
docont()
{
  int *ptr;

  /* See if there is an open while */
  if ((ptr = readwhile()) == 0)
    return;                     /* No */
  modstk((ptr[wqsp]));          /* Yes, fix the stack */
  jump(ptr[wqloop]);            /* Jump to the exit label */
}

/*
** "asm" pseudo-statement
**
** Enters a mode in which assembly language
** is passed through the parser untouched.
*/
doasm()
{
  cmode = 0;                    /* Mark assembler mode */
  while (1) {
    in_line();                  /* Get and print lines */
    if (match("#endasm"))
      break;                    /* until... */
    if (eof)
      break;
    outstr(line);
    nl();
  }
  kill();                       /* Clear the line */
  cmode = 1;                    /* Return to parse mode */
}

junk()
{
  if (an(in_byte()))
    while (an(ch()))
      gch();
  else
    while (an(ch()) == 0) {
      if (ch() == 0)
	break;
      gch();
    }
  blanks();
}

endst()
{
  blanks();
  return ((streq(line + lidx, ";") | (ch() == 0)));
}

illname()
{
  error("Illegal name");
  junk();
}

multidef(sname)
  char *sname;
{
  error("Redefined name");
  comment();
  outstr(sname);
  nl();
}

needbrack(str)
  char *str;
{
  if (match(str) == 0) {
    error("Missing ");
    comment();
    outstr(str);
    nl();
  }
}

needlval()
{
  error("Must be an lvalue");
}

findglb(sname)
  char *sname;
{
  char *ptr;

  ptr = startglb;
  while (ptr != glbptr) {
    if (astreq(sname, ptr, namemax))
      return ptr;
    ptr = ptr + symsiz;
  }
  return 0;
}

findloc(sname)
  char *sname;
{
  char *ptr;

  ptr = startloc;
  while (ptr != locptr) {
    if (astreq(sname, ptr, namemax))
      return ptr;
    ptr = ptr + symsiz;
  }
  return 0;
}

addglb(sname, id, typ, value)
  char *sname, id, typ;
  int value;
{
  char *ptr;

  if (cptr = findglb(sname))
    return cptr;
  if (glbptr >= endglb) {
    error("Global table full");
    return 0;
  }
  cptr = ptr = glbptr;
  while (an(*ptr++ = *sname++));/* Copy the name */
  cptr[ident] = id;
  cptr[type] = typ;
  cptr[storage] = statik;
  cptr[offset] = value;
  cptr[offset + 1] = value >> 8;
  cptr[offset + 2] = value >> 16;
  cptr[offset + 3] = value >> 24;
  glbptr = glbptr + symsiz;
  return cptr;
}

addloc(sname, id, typ, value)
  char *sname, id, typ;
  int value;
{
  char *ptr;

  if (cptr = findloc(sname))
    return cptr;
  if (locptr >= endloc) {
    error("Local table full");
    return 0;
  }
  cptr = ptr = locptr;
  while (an(*ptr++ = *sname++));/* Copy the name */
  cptr[ident] = id;
  cptr[type] = typ;
  cptr[storage] = stkloc;
  cptr[offset] = value;
  cptr[offset + 1] = value >> 8;
  cptr[offset + 2] = value >> 16;
  cptr[offset + 3] = value >> 24;
  locptr = locptr + symsiz;
  return cptr;
}


/* Test if the next input string is a valid name */
symname(sname)
  char *sname;
{
  int k;
  char c;

  blanks();
  if (alpha(ch()) == 0)
    return 0;
  k = 0;
  while (an(ch()))
    sname[k++] = gch();
  sname[k] = 0;
  return 1;
}

/* Test if the given character is a letter */
alpha(c)
  int c;
{
  c = c & 255;
  return (((c >= 'a') & (c <= 'z')) |
	  ((c >= 'A') & (c <= 'Z')) |
	  (c == '_'));
}

/* Test if the given character is a digit */
numeric(c)
  int c;
{
  c = c & 255;
  return ((c >= '0') & (c <= '9'));
}

/* Test if the given character is alphanumeric */
an(c)
  char c;
{
  return ((alpha(c)) | (numeric(c)));
}

/* Print a carriage return and a string to the console */
pl(str)
  char *str;
{
  int k;

  k = 0;
  putchar(13);
  putchar(10);
  while (*str)
    putchar(*str++);
}

addwhile(ptr)
  int ptr[];

{
  int k;

  if (wqptr == wqmax) {
    error("Too many active loops");
    return;
  }
  k = 0;
  while (k < wqsiz)
    *wqptr++ = ptr[k++];
}

delwhile()
{
  if (readwhile())
    wqptr = wqptr - wqsiz;
}

readwhile()
{
  if (wqptr == wq) {
    error("No active loops");
    return 0;
  } else
    return (wqptr - wqsiz);
}

ch()
{
  return (line[lidx] & 255);
}

nch()
{
  if (ch() == 0)
    return 0;
  else
    return (line[lidx + 1] & 255);
}

gch()
{
  if (ch() == 0)
    return 0;
  else
    return (line[lidx++] & 255);
}

kill()
{
  lidx = 0;
  line[lidx] = 0;
}

in_byte()
{
  while (ch() == 0) {
    if (eof)
      return 0;
    in_line();
    preprocess();
  }
  return gch();
}

in_line()
{
  int k, unit;

  while (1) {
    if (input == 0) {
      eof = 1;
      return;
    }
    if ((unit = input2) == 0)
      unit = input;
    kill();
    while ((k = fgetc(unit)) > 0) {
      if (k == 13)
	continue;
      if ((k == eol) | (lidx >= linemax))
	break;
      line[lidx++] = k;
    }
    line[lidx] = 0;     /* Append a null character */
    lineno++;           /* One more line has been read */
    if (k <= 0) {
      fclose(unit);
      if (input2)
	endinclude();
      else
	input = 0;
    }
    if (lidx) {
      if (ctext & cmode) {
	comment();
	outstr(line);
	nl();
      }
      lidx = 0;
      return;
    }
  }
}

preprocess()
{
  int k;
  char c, sname[namesize];

  if (cmode == 0)
    return;
  midx = lidx = 0;
  while (ch()) {
    if ((ch() == ' ') | (ch() == 9))
      pre_space();
    else if (ch() == '"')
      pre_quote();
    else if (ch() == 39)
      pre_apos();
    else if ((ch() == '/') & (nch() == '*'))
      pre_comment();
    else if (alpha(ch())) {
      k = 0;
      while (an(ch())) {
	if (k < namemax)
	  sname[k++] = ch();
	gch();
      }
      sname[k] = 0;
      if (k = findmac(sname))
	while (c = macq[k++])
	  keepch(c);
      else {
	k = 0;
	while (c = sname[k++])
	  keepch(c);
      }
    } else
      keepch(gch());
  }
  keepch(0);
  if (midx >= mpmax)
    error("Line too long");
  lidx = midx = 0;
  while (line[lidx++] = mline[midx++]);
  lidx = 0;
}

keepch(c)
  char c;
{
  mline[midx] = c;
  if (midx < mpmax)
    midx++;
  return c;
}

pre_space()
{
  keepch(' ');
  while ((ch() == ' ') |
	 (ch() == 9))
    gch();
}

pre_quote()
{
  keepch(ch());
  gch();
  while ((ch() != '"') | ((line[lidx - 1] == 92) & (line[lidx - 2] != 92))) {
    if (ch() == 0) {
      error("Missing closing quote");
      break;
    }
    keepch(gch());
  }
  gch();
  keepch('"');
}

pre_apos()
{
  keepch(39);
  gch();
  while ((ch() != 39) | ((line[lidx - 1] == 92) & (line[lidx - 2] != 92))) {
    if (ch() == 0) {
      error("Missing apostrophe");
      break;
    }
    keepch(gch());
  }
  gch();
  keepch(39);
}

pre_comment()
{
  lidx = lidx + 2;
  while (((ch() == '*') &
	  (nch() == '/')) == 0) {
    if (ch() == 0)
      in_line();
    else
      ++lidx;
    if (eof)
      break;
  }
  lidx = lidx + 2;
}

addmac()
{
  char sname[namesize];
  int k;

  if (symname(sname) == 0) {
    illname();
    kill();
    return;
  }
  k = 0;
  while (putmac(sname[k++]));
  while (ch() == ' ' | ch() == 9)
    gch();
  while (putmac(gch()));
  if (macidx >= macmax)
    error("Macro table full");
}

putmac(c)
  char c;
{
  macq[macidx] = c;
  if (macidx < macmax)
    macidx++;
  return c;
}

findmac(sname)
  char *sname;
{
  int k;

  k = 0;
  while (k < macidx) {
    if (astreq(sname, macq + k, namemax)) {
      while (macq[k++]);
      return k;
    }
    while (macq[k++]);
    while (macq[k++]);
  }
  return 0;
}

/* Redirect output to console */
toconsole()
{
  saveout = output;
  output = 0;
}

/* Redirect output back to file */
tofile()
{
  if (saveout)
    output = saveout;
  saveout = 0;
}

outbyte(c)
  char c;
{
  if (c == 0)
    return 0;
  if (output) {
    if ((fputc(c, output)) <= 0) {
      closeout();
      error("Write error");
      abort();
    }
  } else
    putchar(c);
  return c;
}

nl()
{
  outbyte(13);
  outbyte(10);
}

outstr(ptr)
  char *ptr;
{
  while (outbyte(*ptr++));
}

/*
** Writes text intended for the assembler
*/
outasm(ptr)
  char *ptr;
{
  while (outbyte(*ptr++));
}

error(ptr)
  char ptr[];
{
  int k;
  char junk[81];

  toconsole();
  outstr("Line ");
  outdec(lineno);
  outstr(", ");
  if (infunc == 0)
    outbyte('(');
  if (currfn == NULL)
    outstr("beginning of file");
  else
    outstr(currfn + name);
  if (infunc == 0)
    outbyte(')');
  outstr(" + ");
  outdec(lineno - fnstart);
  outstr(": ");
  outstr(ptr);
  nl();

  outstr(line);
  nl();

  k = 0;                /* Find the error position */
  while (k < lidx) {
    if (line[k++] == 9)
      outbyte(9);
    else
      outbyte(' ');
  }
  outbyte('^');
  nl();
  ++errcnt;

  if (errstop) {
    pl("Continue? (Yes, No, Skip errors) ");
    gets(junk);
    k = junk[0];
    if ((k == 'N') | (k == 'n'))
      abort();
    if ((k == 'S') | (k == 's'))
      errstop = 0;
  }
  tofile();
}

ol(ptr)
  char ptr[];
{
  ot(ptr);
  nl();
}

ot(ptr)
  char ptr[];
{
  outasm(ptr);
}

streq(str1, str2)
  char str1[], str2[];
{
  int k;

  k = 0;
  while (str2[k]) {
    if ((str1[k]) != (str2[k]))
      return 0;
    k++;
  }
  return k;
}

astreq(str1, str2, len)
  char str1[], str2[];
  int len;
{
  int k;

  k = 0;
  while (k < len) {
    if ((str1[k]) != (str2[k]))
      break;
    if (str1[k] == 0)
      break;
    if (str2[k] == 0)
      break;
    k++;
  }
  if (an(str1[k]))
    return 0;
  if (an(str2[k]))
    return 0;
  return k;
}

match(lit)
  char *lit;
{
  int k;

  blanks();
  if (k = streq(line + lidx, lit)) {
    lidx = lidx + k;
    return 1;
  }
  return 0;
}

amatch(lit, len)
  char *lit;
  int len;
{
  int k;

  blanks();
  if (k = astreq(line + lidx, lit, len)) {
    lidx = lidx + k;
    while (an(ch()))
      in_byte();
    return 1;
  }
  return 0;
}

blanks()
{
  while (1) {
    while (ch() == 0) {
      in_line();
      preprocess();
      if (eof)
	break;
    }
    if (ch() == ' ')
      gch();
    else if (ch() == 9)
      gch();
    else
      return;
  }
}

outdec(number)
  int number;
{
  if (number < 0) {
    outbyte('-');
    if (number < -9)
      outdec(-(number / 10));
    outbyte(-(number % 10) + '0');
  } else {
    if (number > 9)
      outdec(number / 10);
    outbyte((number % 10) + '0');
  }
}

/* Convert to uppercase. */
to_upper(c)
  char c;
{
  if ((c >= 'a') & (c <= 'z'))
    c = c - 'a' + 'A';
  return (c);
}

/*
** Expression evaluator.
**
** by Oscar Toledo Gutierrez.
**
** (c) Copyright 1995 Oscar Toledo G.
*/

#define N_OR      1
#define N_XOR     2
#define N_AND     3
#define N_EQ   4
#define N_CEQ  5
#define N_GT   6
#define N_CADD   7
#define N_NULL    8
#define N_STNL    9
#define N_SGT  10
#define N_FUNC    11
#define N_FUNCI   12
#define N_PAR     13
#define N_CD      14
#define N_CI      15
#define N_ADD    16
#define N_SUB   17
#define N_MUL     18
#define N_DIV     19
#define N_MOD     20
#define N_NEG     21
#define N_COM     22
#define N_INC     23
#define N_STL     24
#define N_PINC    25
#define N_LDNL    26
#define N_NOT     27
#define N_IXP     28
#define N_APFUNC  29
#define N_CONST   30
#define N_LIT     31
#define N_CBYTE   32
#define N_CWORD    33
#define N_LDLP    34
#define N_LDL     35
#define N_LDNLP   36
#define N_SBYTE   37
#define N_SWORD    38

#define TREE_SIZE 128

int node_left[TREE_SIZE];
int node_right[TREE_SIZE];
int oper[TREE_SIZE];
int stk[TREE_SIZE];
int regs[TREE_SIZE];
int last_node;
int tree_root;

expression()
{
  int lval[2];

  last_node = 0;
  if (heir1(lval))
    rvalue(lval);
  annotate(last_node);
  tree_root = last_node;
  gen_code(last_node);
}

heir1(lval)
  int lval[];
{
  int k, lval2[2];
  int right;
  char *ap;

  k = heir2(lval);
  blanks();
  if (ch() != '=')
    return k;
  ++lidx;
  right = last_node;
  if (k == 0)
    needlval();
  if (heir1(lval2))
    rvalue(lval2);
  if (lval[1] == cint)
    make_node(N_SWORD, last_node, right, 0);
  else
    make_node(N_SBYTE, last_node, right, 0);
  return 0;
}

heir2(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir3(lval);
  blanks();
  if (ch() != '|')
    return k;
  if (k)
    rvalue(lval);
  while (match("|")) {
    left = last_node;
    if (heir3(lval2))
      rvalue(lval2);
    make_node(N_OR, left, last_node, 0);
  }
  return 0;
}

heir3(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir4(lval);
  blanks();
  if (ch() != '^')
    return k;
  if (k)
    rvalue(lval);
  while (match("^")) {
    left = last_node;
    if (heir4(lval2))
      rvalue(lval2);
    make_node(N_XOR, left, last_node, 0);
  }
  return 0;
}

heir4(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir5(lval);
  blanks();
  if (ch() != '&')
    return k;
  if (k)
    rvalue(lval);
  while (match("&")) {
    left = last_node;
    if (heir5(lval2))
      rvalue(lval2);
    make_node(N_AND, left, last_node, 0);
  }
  return 0;
}

heir5(lval) int lval[]; {
  int k, lval2[2];
  int left;

  k = heir6(lval);
  blanks();
  if ((streq(line + lidx, "==") == 0) &
      (streq(line + lidx, "!=") == 0))
    return k;
  if (k)
    rvalue(lval);
  while (1) {
    left = last_node;
    if (match("==")) {
      if (heir6(lval2))
        rvalue(lval2);
      if(oper[last_node] == N_CONST) {
        if(oper[left] == N_CONST)
          make_node(N_CONST, 0, 0, stk[left] == stk[last_node]);
        else
          make_node(N_CEQ, left, 0, stk[last_node]);
      }
      else if(oper[left] == N_CONST)
        make_node(N_CEQ, last_node, 0, stk[left]);
      else make_node(N_EQ, left, last_node, 0);
    } else if (match("!=")) {
      if (heir6(lval2))
        rvalue(lval2);
      if(oper[last_node] == N_CONST) {
        if(oper[left] == N_CONST)
          make_node(N_CONST, 0, 0, stk[left] != stk[last_node]);
        else {
          make_node(N_CEQ, left, 0, stk[last_node]);
          make_node(N_NOT, last_node, 0, 0);
        }
      }
      else if(oper[left] == N_CONST) {
        make_node(N_CEQ, last_node, 0, stk[left]);
        make_node(N_NOT, last_node, 0, 0);
      } else {
        make_node(N_EQ, left, last_node, 0);
        make_node(N_NOT, last_node, 0, 0);
      }
    } else
      return 0;
  }
}

heir6(lval)
  int lval[];
{
  int k;

  k = heir7(lval);
  blanks();
  if ((streq(line + lidx, "<") == 0) &
      (streq(line + lidx, ">") == 0) &
      (streq(line + lidx, "<=") == 0) &
      (streq(line + lidx, ">=") == 0))
  return k;
  if (streq(line + lidx, ">>"))
    return k;
  if (streq(line + lidx, "<<"))
    return k;
  if (k)
    rvalue(lval);
  while (1) {
    if (match("<="))
      heir6wrk(1, lval);
    else if (match(">="))
      heir6wrk(2, lval);
    else if (streq(line + lidx, "<") &
            (streq(line + lidx, "<<") == 0)) {
      in_byte();
      heir6wrk(3, lval);
    } else if (streq(line + lidx, ">") &
              (streq(line + lidx, ">>") == 0)) {
      in_byte();
      heir6wrk(4, lval);
    } else
      return 0;
  }
}

heir6wrk(k, lval)
  int k, lval[];
{
  int lval2[2];
  int left;

  left = last_node;
  if (heir7(lval2))
    rvalue(lval2);
  if (cptr = lval[0])
    if (cptr[ident] == pointer) {
      heir6op(left, k);
      return;
    }
  if (cptr = lval2[0])
    if (cptr[ident] == pointer) {
      heir6op(left, k);
      return;
    }
  if(k == 4) {
    if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
      make_node(N_CONST, 0, 0, stk[left] > stk[last_node]);
    else
      make_node(N_GT, left, last_node, 0);
  }
  else if(k == 3) {
    if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
      make_node(N_CONST, 0, 0, stk[left] < stk[last_node]);
    else
      make_node(N_GT, last_node, left, 0);
  }
  else if(k == 1) {
    if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
      make_node(N_CONST, 0, 0, stk[left] <= stk[last_node]);
    else {
      make_node(N_GT, left, last_node, 0);
      make_node(N_NOT, last_node, 0);
    }
  } else {
    if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
      make_node(N_CONST, 0, 0, stk[left] >= stk[last_node]);
    else {
      make_node(N_GT, last_node, left, 0);
      make_node(N_NOT, last_node, 0);
    }
  }
}

heir6op(left, k)
  int left, k;
{
  if(k == 4) make_node(N_SGT, left, last_node, 0);
  else if(k == 3) make_node(N_SGT, last_node, left, 0);
  else if(k == 1) {
    make_node(N_SGT, left, last_node, 0);
    make_node(N_NOT, last_node, 0);
  } else {
    make_node(N_SGT, last_node, left, 0);
    make_node(N_NOT, last_node, 0);
  }
}

heir7(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir8(lval);
  blanks();
  if ((streq(line + lidx, ">>") == 0) &
      (streq(line + lidx, "<<") == 0))
    return k;
  if (k)
    rvalue(lval);
  while (1) {
    left = last_node;
    if (match(">>")) {
      if (heir8(lval2))
	rvalue(lval2);
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] >> stk[last_node]);
      else
        make_node(N_CD, left, last_node, 0);
    } else if (match("<<")) {
      if (heir8(lval2))
	rvalue(lval2);
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] << stk[last_node]);
      else
        make_node(N_CI, left, last_node, 0);
    } else
      return 0;
  }
}

heir8(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir9(lval);
  blanks();
  if ((ch() != '+') & (ch() != '-'))
    return k;
  if (k)
    rvalue(lval);
  while (1) {
    left = last_node;
    if (match("+")) {
      if (heir9(lval2))
        rvalue(lval2);
      if (cptr = lval[0])
        if ((cptr[ident] == pointer) &
            (cptr[type] == cint))
          scale_by_word();
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] + stk[last_node]);
      else if(oper[last_node] == N_CONST)
        make_node(N_CADD, left, 0, stk[last_node]);
      else if(oper[left] == N_CONST)
        make_node(N_CADD, last_node, 0, stk[left]);
      else
        make_node(N_ADD, left, last_node, 0);
    } else if (match("-")) {
      if (heir9(lval2))
        rvalue(lval2);
      if (cptr = lval[0])
        if ((cptr[ident] == pointer) &
            (cptr[type] == cint))
          scale_by_word();
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] - stk[last_node]);
      else if(oper[last_node] == N_CONST)
        make_node(N_CADD, left, 0, -stk[last_node]);
      else
        make_node(N_SUB, left, last_node, 0);
    } else
      return 0;
  }
}

heir9(lval)
  int lval[];
{
  int k, lval2[2];
  int left;

  k = heir10(lval);
  blanks();
  if ((ch() != '*') & (ch() != '/') &
      (ch() != '%'))
    return k;
  if (k)
    rvalue(lval);
  while (1) {
    left = last_node;
    if (match("*")) {
      if (heir10(lval2))
        rvalue(lval2);
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] * stk[last_node]);
      else
        make_node(N_MUL, left, last_node, 0);
    } else if (match("/")) {
      if (heir10(lval2))
        rvalue(lval2);
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] / stk[last_node]);
      else
        make_node(N_DIV, left, last_node, 0);
    } else if (match("%")) {
      if (heir10(lval2))
        rvalue(lval2);
      if((oper[left] == N_CONST) & (oper[last_node] == N_CONST))
        make_node(N_CONST, 0, 0, stk[left] % stk[last_node]);
      else
        make_node(N_MOD, left, last_node, 0);
    } else
      return 0;
  }
}

heir10(lval)
  int lval[];
{
  int k;

  if (match("++")) {
    if (heir10(lval) == 0)
      needlval();
    heir10inc(lval);
    return 0;
  } else if (match("--")) {
    if (heir10(lval) == 0)
      needlval();
    heir10dec(lval);
    return 0;
  } else if (match("-")) {
    if(heir10(lval))
      rvalue(lval);
    if(oper[last_node] == N_CONST)
      stk[last_node] = -stk[last_node];
    else
      make_node(N_NEG, last_node, 0, 0);
    return 0;
  } else if (match("~")) {
    if(heir10(lval))
      rvalue(lval);
    if(oper[last_node] == N_CONST)
      stk[last_node] = ~stk[last_node];
    else
      make_node(N_COM, last_node, 0, 0);
    return 0;
  } else if (match("!")) {
    if(heir10(lval))
      rvalue(lval);
    if(oper[last_node] == N_CONST)
      stk[last_node] = !stk[last_node];
    else
      make_node(N_NOT, last_node, 0, 0);
    return 0;
  } else if (match("*")) {
    heir10as(lval);
    return 1;
  } else if (match("&")) {
    if(heir10(lval) == 0) {
      error("Illegal address");
      return 0;
    }
    if (lval[1])
      return 0;
    heir10at(lval);
    return 0;
  }
  k = heir11(lval);
  if (match("++")) {
    if (k == 0)
      needlval();
    heir10id(lval);
    return 0;
  } else if (match("--")) {
    if (k == 0)
      needlval();
    heir10di(lval);
    return 0;
  } else
    return k;
}

heir10inc(lval)
  int lval[];
{
  char *ptr;

  ptr = lval[0];
  if ((ptr[ident] == pointer) &
      (ptr[type] == cint))
    make_node(N_INC, last_node, 0, 4);
  else
    make_node(N_INC, last_node, 0, 1);
}

heir10dec(lval)
  int lval[];
{
  char *ptr;

  ptr = lval[0];
  if ((ptr[ident] == pointer) &
      (ptr[type] == cint))
    make_node(N_INC, last_node, 0, -4);
  else
    make_node(N_INC, last_node, 0, -1);
}

heir10as(lval)
  int lval[];
{
  int k;
  char *ptr;

  k = heir10(lval);
  if (k)
    rvalue(lval);
  lval[1] = cint;
  if (ptr = lval[0])
    lval[1] = ptr[type];
  lval[0] = 0;
}

heir10at(lval)
  int lval[];
{
  char *ptr;

  lval[1] = ptr[type];
}

heir10id(lval)
  int lval[];
{
  char *ptr;

  ptr = lval[0];
  if ((ptr[ident] == pointer) &
      (ptr[type] == cint))
    make_node(N_PINC, last_node, 0, 4);
  else
    make_node(N_PINC, last_node, 0, 1);
}

heir10di(lval)
  int lval[];
{
  char *ptr;

  ptr = lval[0];
  if ((ptr[ident] == pointer) &
      (ptr[type] == cint))
    make_node(N_PINC, last_node, 0, -4);
  else
    make_node(N_PINC, last_node, 0, -1);
}

heir11(lval)
  int lval[];
{
  int k, etiq, left;
  char *ptr;
  int lval2[2];

  k = primary(lval);
  ptr = lval[0];
  blanks();
  if ((ch() == '[') | (ch() == '('))
    while (1) {
      if (match("[")) {
        if (ptr == 0) {
          error("Cannot use subscript");
          junk();
          needbrack("]");
          return 0;
        } else if (ptr[ident] == pointer)
          rvalue(lval);
        else if (ptr[ident] != array) {
          error("Cannot use subscript");
          k = 0;
        }
        left = last_node;
        if (heir1(lval2))
          rvalue(lval2);
        needbrack("]");
        if (ptr[type] == cint) {
          if (oper[last_node] == N_CONST)
            make_node(N_LDNLP, left, 0, stk[last_node]);
          else
            make_node(N_IXP, last_node, left, 0);
        } else {
          if (oper[last_node] == N_CONST)
            make_node(N_CADD, left, 0, stk[last_node]);
          else
            make_node(N_ADD, last_node, left, 0);
        }
        lval[1] = ptr[type];
        k = 1;
      } else if (match("(")) {
        if (ptr == 0)
          callfunction(0);
        else if (ptr[ident] != function) {
          rvalue(lval);
          callfunction(0);
        } else
          callfunction(ptr);
        k = lval[0] = 0;
      } else
        return k;
    }
  if (ptr == 0)
    return k;
  if (ptr[ident] == function) {
    make_node(N_APFUNC, 0, 0, ptr);
    return 0;
  }
  return k;
}

primary(lval)
  int lval[];
{
  char *ptr, sname[namesize];
  int num[1];
  int k;

  if (match("(")) {
    k = heir1(lval);
    needbrack(")");
    return k;
  }
  if (symname(sname)) {
    if (ptr = findloc(sname)) {
      getloc(ptr);
      lval[0] = ptr;
      lval[1] = ptr[type];
      if (ptr[ident] == pointer)
        lval[1] = cint;
      if (ptr[ident] == array)
        return 0;
      return 1;
    }
    if (ptr = findglb(sname)) {
      if (ptr[ident] != function) {
        emit_global_addr(0, ptr);
        lval[0] = ptr;
        lval[1] = ptr[type];
        if (ptr[ident] == pointer)
          lval[1] = cint;
        if (ptr[ident] == array)
          return 0;
        return 1;
      }
    } else
      ptr = addglb(sname, function, cint, 0);
    lval[0] = ptr;
    lval[1] = 0;
    return 0;
  }
  if (constant(num))
    return (lval[0] = lval[1] = 0);
  else {
    error("Invalid expression");
    make_node(N_CONST, 0, 0, 0);
    junk();
    return 0;
  }
}

/*
** Compile a function call
**
** Called by "heir11", this function calls the named function
** or an indirect function.
*/
callfunction(ptr)
  char *ptr;
{
  int lval[2];
  int prev, first;
  int left;

  prev = first = 0;
  blanks();             /* The opening parenthesis has already been consumed */
  if (ptr == 0)
    left = last_node;  /* Indirect call */
  while (streq(line + lidx, ")") == 0) {
    if (endst())
      break;
    if (heir1(lval))
      rvalue(lval);     /* Get an argument */
    make_node(N_PAR, last_node, 0, 0);
    if (first == 0)
      first = last_node;
    if (prev != 0)
      stk[prev] = last_node;
    prev = last_node;
    if (match(",") == 0)
      break;
    blanks();
  }
  needbrack(")");
  if (ptr == 0)
    make_node(N_FUNCI, first, 0, left);
  else
    make_node(N_FUNC, first, 0, ptr);
}

rvalue(lval)
  int lval[];
{
  if (lval[1] == cchar)
    make_node(N_CBYTE, last_node, 0, 0);
  else
    make_node(N_CWORD, last_node, 0, 0);
}

/* Load the address of a local variable */
getloc(sym)
  char *sym;
{
  make_node(N_LDLP, 0, 0, ((sym[offset] & 255) +
			   ((sym[offset + 1] & 255) << 8) +
			   ((sym[offset + 2] & 255) << 16) +
			   ((sym[offset + 3] & 255) << 24)));
}

/* Load the address of static variables */
load_static_base()
{
  make_node(N_LDL, 0, 0, 1);
}

/* Global memory operations */
emit_global_addr(tipo, var)
  int tipo;
  char *var;
{
  int j;

  j = (var[offset] & 255) +
    ((var[offset + 1] & 255) << 8) +
    ((var[offset + 2] & 255) << 16) +
    ((var[offset + 3] & 255) << 24);
  load_static_base();
  make_node(N_LDNLP, last_node, 0, j);
}

/* Multiply the primary register by word size */
scale_by_word()
{
  if(oper[last_node] == N_CONST)
    stk[last_node] = stk[last_node] * 4;
  else {
    make_node(N_CONST, 0, 0, 4);
    make_node(N_MUL, last_node - 1, last_node, 0);
  }
}

test(label)
  int label;
{
  needbrack("(");
  use_expr = YES;
  expression();
  needbrack(")");
  testjump(label);
}

constant(val)
  int val[];
{
  if (number(val))
    make_node(N_CONST, 0, 0, val[0]);
  else if (pstr(val))
    make_node(N_CONST, 0, 0, val[0]);
  else if (qstr(val))
    make_node(N_LIT, 0, 0, val[0]);
  else
    return 0;
  return 1;
}

isxdigit(c) char c; {
  return (((c >= '0') & (c <= '9')) |
          ((c >= 'A') & (c <= 'F')) |
          ((c >= 'a') & (c <= 'f')));
}

number(val)
  int val[];
{
  int k, minus, base;
  char c;

  k = minus = 1;
  while (k) {
    k = 0;
    if (match("+"))
      k = 1;
    if (match("-")) {
      minus = -minus;
      k = 1;
    }
  }
  if (numeric(ch()) == 0)
    return 0;
  if(ch() == '0') {
    while(ch() == '0') gch();
    if(to_upper(ch()) == 'X') {
      gch();
      while(isxdigit(ch())) {
        c = to_upper(gch()) - '0';
        if(c > 9) c = c - 7;
        k = (k << 4) | c;
      }
    } else {
      while ((ch() >= '0') & (ch() <= '7'))
        k = k * 8 + (gch() - '0');
    }
  } else {
    while (numeric(ch()))
      k = k * 10 + (gch() - '0');
  }
  if (minus < 0)
    k = -k;
  val[0] = k;
  return 1;
}

pstr(val)
  int val[];
{
  int k;

  k = 0;
  if (match("'") == 0)
    return 0;
  while (ch() != 39)
    k = (k & 255) * 256 + (litchar() & 255);
  ++lidx;
  val[0] = k;
  return 1;
}

qstr(val)
  int val[];
{
  char c;

  if (match(quote) == 0)
    return 0;
  val[0] = litidx;
  while (ch() != '"') {
    if (ch() == 0)
      break;
    if (litidx >= litmax) {
      error("String literal storage exhausted");
    while (match(quote) == 0)
      if (gch() == 0)
        break;
      return 1;
    }
    litq[litidx++] = litchar();
  }
  gch();
  litq[litidx++] = 0;
  return 1;
}

litchar()
{
  int i, oct;

  if ((ch() != 92) | (nch() == 0))
    return gch();
  gch();
  if (ch() == 'n') {
    ++lidx;
    return 10;
  }
  if (ch() == 't') {
    ++lidx;
    return 9;
  }
  if (ch() == 'b') {
    ++lidx;
    return 8;
  }
  if (ch() == 'f') {
    ++lidx;
    return 12;
  }
  if (ch() == 'r') {
    ++lidx;
    return 13;
  }
  i = 3;
  oct = 0;
  while ((i-- > 0) & (ch() >= '0') & (ch() <= '7'))
    oct = (oct << 3) + gch() - '0';
  if (i == 2)
    return gch();
  else
    return oct;
}

make_node(op, left, right, val)
  int op, left, right, val;
{
  if(op == N_CADD) {
    if(oper[left] == N_CADD) {
      val = val + stk[left];
      left = node_left[left];
    }
  }
  else if(op == N_LDNLP) {
    if(oper[left] == N_LDNLP) {
      val = val + stk[left];
      left = node_left[left];
    }
    else if(oper[left] == N_LDLP) {
      val = val + stk[left];
      left = 0;
      op = N_LDLP;
    }
  }
  ++last_node;
  if(last_node == TREE_SIZE) {
    error("Expression too complex");
    abort();
  }
  node_left[last_node] = left;
  node_right[last_node] = right;
  oper[last_node] = op;
  stk[last_node] = val;
  regs[last_node] = 0;
}

annotate(node)
  int node;
{
  int min, max;

  if (node_left[node])
    annotate(node_left[node]);
  if (node_right[node])
    annotate(node_right[node]);
  if ((oper[node] == N_FUNCI) | (oper[node] == N_PAR))
    if (stk[node])
      annotate(stk[node]);
  if ((oper[node] == N_FUNCI) | (oper[node] == N_FUNC) |
      (oper[node] == N_SBYTE) | (oper[node] == N_SWORD))
    regs[node] = 3;
  else if ((oper[node] == N_INC) | (oper[node] == N_PINC)) {
    regs[node] = 3;
    if (regs[node_left[node]] == 1)
      if (oper[node_left[node]] == N_LDLP)
	regs[node] = 2;
  } else if (node_left[node] == 0)
    regs[node] = 1;
  else if (node_right[node] == 0)
    regs[node] = regs[node_left[node]];
  else {
    min = regs[node_left[node]];
    max = regs[node_right[node]];
    if (min > max)
      max = min;
    else if (min == max)
      max = max + 1;
    regs[node] = max;
  }
}

gen_oper(oper, rev)
  int oper, rev;
{
  if (oper == N_OR)
    ol("or");
  else if (oper == N_XOR)
    ol("xor");
  else if (oper == N_AND)
    ol("and");
  else if (oper == N_EQ) {
    ol("diff");
    ol("eqc 0");
  } else if (oper == N_ADD)
    ol("bsub");
  else if (oper == N_MUL)
    ol("prod");
  else if (oper == N_NEG) {
    ol("not");
    ol("adc 1");
  } else if (oper == N_COM)
    ol("not");
  else if (oper == N_NOT)
    ol("eqc 0");
  else if (oper == N_CBYTE)
    ol("lb");
  else if (oper == N_CWORD)
    ol("ldnl 0");
  else if (oper == N_SGT) {
    if (rev == 0)
      ol("rev");
    ol("mint");
    ol("xor");
    ol("rev");
    ol("mint");
    ol("xor");
    ol("gt");
  } else {
    if (rev)
      ol("rev");
    if (oper == N_GT)
      ol("gt");
    else if (oper == N_CD)
      ol("shr");
    else if (oper == N_CI)
      ol("shl");
    else if (oper == N_SUB)
      ol("diff");
    else if (oper == N_DIV)
      ol("div");
    else if (oper == N_MOD)
      ol("rem");
    else if (oper == N_IXP)
      ol("wsub");
  }
}

gen_code(node)
  int node;
{
  int temp, count, words, param, rev, op, req, need_result;
  int regb, regc;

  if((node != tree_root) | (use_expr == YES)) need_result = YES;
  else need_result = NO;
  op = oper[node];
  if ((op == N_FUNC) | (op == N_FUNCI)) {
    words = count = 0;
    regb = regc = 0;
    temp = node_left[node];
    while (temp) {
      if(regb == 0) regb = node_left[temp];
      else if(regc == 0) regc = node_left[temp];
      else {
        ++words;
        ++count;
      }
      temp = stk[temp];
    }
    Zsp = modstk(Zsp - words);
    if(count) {
      temp = stk[stk[node_left[node]]];
      param = 0;
      while (count--) {
        gen_code(node_left[temp]);
        ins("stl ", param++);
        temp = stk[temp];
      }
    }
    if (oper[node] == N_FUNC) {
      if(regc == 0) {
        if(regb) gen_code(regb);
        }
      else {
        if ((regs[regc] >= regs[regb]) &
            (regs[regb] < 3)) {
          gen_code(regc);
          gen_code(regb);
        } else if ((regs[regb] > regs[regc]) &
                   (regs[regc] < 3)) {
          gen_code(regb);
          gen_code(regc);
          ol("rev");
        } else {
          gen_code(regb);
          zpush();
          gen_code(regc);
          zpop();
        }
      }
      ins("ldl ", 1 - Zsp);
      zcall(stk[node]);
    } else {
      Zsp = modstk(Zsp - 4);
      if(regb) {
        gen_code(regb);
        ol("stl 2");
        }
      if(regc) {
        gen_code(regc);
        ol("stl 3");
        }
      gen_code(stk[node]);
      ins("ldl ", 1 - Zsp);
      ol("ldc 3");
      ol("ldpi");
      ol("stl 0");
      ol("stl 1");
      ol("gcall");
      Zsp = Zsp + 4;
    }
    Zsp = modstk(Zsp + words);
    return;
  }
  if ((op == N_SBYTE) | (op == N_SWORD)) {
    if(need_result) req = 2;
    else req = 3;
    if (regs[node_right[node]] < req) {
      gen_code(node_left[node]);
      if(need_result) ol("dup");
      if ((op == N_SWORD) & (oper[node_right[node]] == N_LDLP))
	oper[node_right[node]] = N_STL;
      else if ((op == N_SWORD) & (oper[node_right[node]] == N_LDNLP))
	oper[node_right[node]] = N_STNL;
      else {
	gen_code(node_right[node]);
	if(op == N_SWORD)
          ol("stnl 0");
        else
          ol("sb");
        return;
      }
      gen_code(node_right[node]);
      return;
    }
    gen_code(node_right[node]);
    if(need_result) req = YES;
    else if (regs[node_left[node]] < 3) req = NO;
    else req = YES;
    if(req) {
      zpush();
      gen_code(node_left[node]);
      ol("dup");
      zpop();
    } else {
      gen_code(node_left[node]);
      ol("rev");
    }
    if (op == N_SWORD)
      ol("stnl 0");
    else
      ol("sb");
    return;
  }
  if (op == N_APFUNC) {
    ot("ldc ");
    outname(stk[node]);
    outasm("-");
    printlabel(temp = getlabel());
    nl();
    ol("ldpi");
    printlabel(temp);
    col();
    nl();
    return;
  }
  if (op == N_CONST) {
    ins("ldc ", stk[node]);
    return;
  }
  if (op == N_LIT) {
    ot("ldc ");
    printlabel(litlab);
    outasm("-");
    printlabel(temp = getlabel());
    outasm("+");
    outdec(stk[node]);
    nl();
    ol("ldpi");
    printlabel(temp);
    col();
    nl();
    return;
  }
  if (op == N_LDLP) {
    ins("ldlp ", stk[node] - Zsp);
    return;
  }
  if (op == N_LDL) {
    ins("ldl ", stk[node] - Zsp);
    return;
  }
  if (op == N_STL) {
    ins("stl ", stk[node] - Zsp);
    return;
  }
  if ((op == N_INC) | (op == N_PINC)) {
    if (regs[node] == 2) {
      oper[node_left[node]] = N_LDL;
      gen_code(node_left[node]);
    } else {
      gen_code(node_left[node]);
      ol("dup");
      ol("ldnl 0");
    }
    if (op == N_PINC)
      if(need_result)
        ol("dup");
    ins("adc ", stk[node]);
    if (op == N_INC)
      if(need_result)
        ol("dup");
    if (regs[node] == 2) {
      oper[node_left[node]] = N_STL;
      gen_code(node_left[node]);
    } else if (need_result) {
      ol("pop");
      ol("pop");
      ol("stnl 0");
    } else {
      ol("rev");
      ol("stnl 0");
    }
    return;
  }
  if (op == N_CWORD) {
    if (oper[node_left[node]] == N_LDLP) {
      oper[node_left[node]] = N_LDL;
      op = N_NULL;
    } else if (oper[node_left[node]] == N_LDNLP) {
      oper[node_left[node]] = N_LDNL;
      op = N_NULL;
    }
  }
  rev = 0;
  if (node_right[node]) {
    if ((regs[node_left[node]] >= regs[node_right[node]]) &
	(regs[node_right[node]] < 3)) {
      gen_code(node_left[node]);
      gen_code(node_right[node]);
    } else if ((regs[node_right[node]] > regs[node_left[node]]) &
	       (regs[node_left[node]] < 3)) {
      gen_code(node_right[node]);
      gen_code(node_left[node]);
      rev = 1;
    } else {
      gen_code(node_right[node]);
      zpush();
      gen_code(node_left[node]);
      zpop();
    }
  } else
    gen_code(node_left[node]);
  if (op == N_CEQ) {
    ins("eqc ", stk[node]);
    return;
  }
  if (op == N_CADD) {
    if(stk[node]) ins("adc ", stk[node]);
    return;
  }
  if (op == N_LDNLP) {
    if(stk[node]) ins("ldnlp ", stk[node]);
    return;
  }
  if (op == N_LDNL) {
    ins("ldnl ", stk[node]);
    return;
  }
  if (op == N_STNL) {
    ins("stnl ", stk[node]);
    return;
  }
  gen_oper(op, rev);
}

ins(code, value) char *code; int value; {
  outasm(code);
  outdec(value);
  nl();
}

/* Begin a comment line for the assembler */
comment()
{
  outbyte(';');
}

/* Emit the prologue for the generated code. */
header()
{
  comment();
  outstr(BANNER);
  nl();
  comment();
  outstr(VERSION);
  nl();
  comment();
  outstr(AUTHOR);
  nl();
  comment();
  nl();
  ol("START:");
  ol("j ENTRY");
}

/* Emit the epilogue for the generated code. */
trailer()
{
  nl();
  comment();
  outstr(" End of compilation");
  nl();
  outasm("ENTRY");
  col();
  nl();
  ins("ajw ", -global_pos);
  if (global_pos > 2) {
    ol("ldlp 2");
    ol("stl 0");
    ins("ldc ", global_pos - 2);
    ol("stl 1");
    outasm("ENTRY2");
    col();
    nl();
    ol("ldc 0");
    ol("ldl 0");
    ol("stnl 0");
    ol("ldl 0");
    ol("adc 4");
    ol("stl 0");
    ol("ldl 1");
    ol("adc -1");
    ol("stl 1");
    ol("ldl 1");
    ol("eqc 0");
    ol("cj ENTRY2");
  }
  ol("ldlp 0");
  ol("call qmain");
  ins("ajw ", global_pos);
  ol("ret");
}

/*
** Print a name that does not conflict with
** reserved words of the assembler.
*/
outname(sname)
  char *sname;
{
  outasm("q");
  outasm(sname);
}

/* Push register A onto the stack */
zpush()
{
  ol("ajw -1");
  ol("stl 0");
  --Zsp;
}

/* Pop the top of stack into register A */
zpop()
{
  ol("ldl 0");
  ol("ajw 1");
  ++Zsp;
}

/* "Calls the specified function */
zcall(sname)
  char *sname;
{
  ot("call ");
  outname(sname);
  nl();
}

/* Returns from a function */
zret()
{
  ol("ret");
}

/* Jump to the specified internal label */
jump(label)
  int label;
{
  ins("j c", label);
}

/* Test the primary register and jump if false */
testjump(label)
  int label;
{
  ins("cj c", label);
}

/* Return the next available internal label */
getlabel()
{
  return (++nxtlab);
}

/* Print the specified number as a label */
printlabel(label)
  int label;
{
  outasm("c");
  outdec(label);
}

col()
{
  outbyte(58);
}

/* Pseudo-operation to define a byte */
defbyte()
{
  ot("db ");
}

/* Modify the stack position */
modstk(newsp)
  int newsp;
{
  int k;

  if (k = newsp - Zsp)
    ins("ajw ", k);
  return newsp;
}

/* End of the Mini-C Compiler */
