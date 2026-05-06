;*** Compilador de C para G-10 ***
;          Version 1.00
;   por Oscar Toledo Gutierrez.
;
COMIENZO:
j INICIO
;/*
;** Small C compiler for transputer.
;** Now with expresion trees and optimized code generator.
;**
;** by Oscar Toledo Gutierrez.
;**
;** Original compiler by Ron Cain.
;**
;** 12-jun-1995
;*/
; 
;#define BANNER  "*** Compilador de C para G-10 ***"
;#define AUTHOR  "   por Oscar Toledo Gutierrez."
;#define VERSION "          Version 1.00"
;#define NO      0
;#define SI      1
;/* Definiciones para ejecucion solitaria */
;#define NULL 0
;#define eol 10
;/* Define parametros de la tabla de nombres */
;#define symsiz  24
;#define symtbsz 8400
;#define numglbs 300
;#define startglb symtab
;#define endglb  startglb+numglbs*symsiz
;#define startloc endglb+symsiz
;#define endloc  symtab+symtbsz-symsiz
;/* Define formato de los nombres */
;#define name    0
;#define ident   17
;#define type    18
;#define storage 19
;#define offset  20
;/* Tama¤o m ximo de los nombres */
;#define namesize 17
;#define namemax  16
;/* Valores posibles para "ident" */
;#define variable 1
;#define array    2
;#define pointer  3
;#define function 4
;/* Valores posibles para "type" */
;#define cchar   1
;#define cint    2
;/* Valores posibles para "storage" */
;#define statik  1
;#define stkloc  2
;/* Define la cola de "while" */
;#define wqtabsz 100
;#define wqsiz   4
;#define wqmax   wq+wqtabsz-wqsiz
;/* Define los desplazamientos en la cola de while's */
;#define wqsym   0
;#define wqsp    1
;#define wqloop  2
;#define wqlab   3
;/* Define el almacenamiento de cadenas */
;#define litabsz 1024
;#define litmax  litabsz-1
;/* Define la linea de entrada */
;#define linesize 512
;#define linemax linesize-1
;#define mpmax   linemax
;/* Define el almacenamiento de macros */
;#define macqsize 4096
;#define macmax  macqsize-1
;/* Define los tipos de sentencias */
;#define stif     1
;#define stwhile  2
;#define streturn 3
;#define stbreak  4
;#define stcont   5
;#define stasm    6
;#define stexp    7
;/* Define como cortar un nombre muy largo para el ensamblador */
;#define asmpref 7
;#define asmsuff 7
;/* Reserva espacio para las variables */
;char symtab[symtbsz];   /* Tabla de nombres */
;char *glbptr, *locptr;  /* Apuntadores a las sigs. entradas libres */
;int wq[wqtabsz];        /* Cola de bucles */
;int *wqptr;             /* Apuntador a la sig. entrada */
;char litq[litabsz];     /* Almacenamiento de cadenas */
;int litptr;             /* Apuntador a la sig. entrada */
;char macq[macqsize];    /* Buffer de macros */
;int macptr;             /* Indice en el buffer */
;char line[linesize];    /* Buffer de analisis */
;char mline[linesize];   /* Buffer sin preprocesar */
;int lptr, mptr;         /* Apuntadores respectivos */
;/* Almacenamiento miscelaneo */
;int nxtlab,             /* Siguiente etiqueta disponible */
;    litlab,             /* Etiqueta para el buffer de cadenas */
;    Zsp,                /* Apuntador de pila del compilador */
;    argstk,             /* Pila de argumentos */
;    ncmp,               /* No. de bloques abiertos */
;    errcnt,             /* No. de errores detectados */
;    errstop,            /* Indica si se detiene en caso de error */
;    eof,                /* Indica el final del archivo de entrada */
;    input,              /* Archivo de entrada */
;    output,             /* Archivo de salida */
;    input2,             /* Archivo #include */
;    ctext,              /* Indica si incluye el prog. en la salida */
;    cmode,              /* Indica si esta compilando C */
;    lastst,             /* Ultima sentencia ejecutada */
;    saveout,            /* Indica desvio a la consola */
;    fnstart,            /* Linea de comienzo de la funcion actual */
;    lineno,             /* Linea en el archivo actual */
;    infunc,             /* Indica si esta dentro de una funcion */
;    savestart,          /* Copia de "fnstart" */
;    saveline,           /* Copia de "lineno" */
;    saveinfn;           /* Copia de "infunc" */
;char *currfn,           /* Apuntador a la definicion de la funci¢n actual */
;     *savecurr;         /* Copia de "currfn" para #include */
;char quote[2];          /* Cadena literal para '"' */
;char *cptr;             /* Apuntador de trabajo */
;int *iptr;              /* Apuntador de trabajo */
;int posglobal;          /* Posicion para variables estaticas */
;int usaexpr;            /* Indica si se usa el resultado de la expr. */
;/*
;** El compilador comienza su ejecucion aqui.
;*/
;main()
qmain:
;{
;  hello();              /* Presentacion */
ldl 1
call qhello
;  see();                /* Determina las opciones */
ldl 1
call qsee
;  openin();             /* Primer archivo a procesar */
ldl 1
call qopenin
;  while (input != 0) {  /* Procesa todos los archivos que se pidan */
c2:
ldl 1
ldnl 3753
eqc 0
eqc 0
cj c3
;    glbptr = startglb;  /* Limpia la tabla global */
ldl 1
ldnlp 2
ldl 1
stnl 2102
;    locptr = startloc;  /* Limpia la tabla local */
ldl 1
ldnlp 2
adc 7224
ldl 1
stnl 2103
;    wqptr = wq;         /* Limpia la cola de bucles */
ldl 1
ldnlp 2104
ldl 1
stnl 2204
;    macptr =            /* Limpia la tabla de macros */
;    Zsp =               /* Apuntador de pila */
;    errcnt =            /* No hay errores */
;    eof =               /* No se ha alcanzado el fin del archivo */
;    input2 =            /* No hay #include */
;    saveout =           /* No se ha desviado la salida */
;    ncmp =              /* No hay bloques abiertos */
;    lastst =
;    fnstart =           /* La funcion actual empez¢ en la linea 0 */
;    lineno =            /* No se han leido lineas del archivo */
;    infunc =            /* No esta dentro de una funci¢n */
;    nxtlab =            /* Inicia n£meros de etiquetas */
;    quote[1] =
;    0;
ldc 0
dup
ldl 1
ldnlp 3768
adc 1
sb
dup
ldl 1
stnl 3745
dup
ldl 1
stnl 3762
dup
ldl 1
stnl 3761
dup
ldl 1
stnl 3760
dup
ldl 1
stnl 3758
dup
ldl 1
stnl 3749
dup
ldl 1
stnl 3759
dup
ldl 1
stnl 3755
dup
ldl 1
stnl 3752
dup
ldl 1
stnl 3750
dup
ldl 1
stnl 3747
ldl 1
stnl 3486
;    quote[0] = '"';     /* Crea una cadena con una comilla */
ldc 34
ldl 1
ldnlp 3768
sb
;    posglobal = 2;
ldc 2
ldl 1
stnl 3771
;    currfn = NULL;      /* Ninguna funci¢n a£n */
ldc 0
ldl 1
stnl 3766
;    cmode = 1;          /* Activa el preprocesamiento */
ldc 1
ldl 1
stnl 3757
;    openout();
ldl 1
call qopenout
;    header();
ldl 1
call qheader
;    parse();
ldl 1
call qparse
;    if (ncmp)
ldl 1
ldnl 3749
cj c4
;      error("Falta llave de cierre");
ldc c1-c5+0
ldpi
c5:
ldl 1
call qerror
;    trailer();
c4:
ldl 1
call qtrailer
;    closeout();
ldl 1
call qcloseout
;    errorsummary();
ldl 1
call qerrorsummary
;    openin();
ldl 1
call qopenin
;  }
j c2
c3:
;}
ret
c1:
db 70,97,108,116,97
db 32,108,108,97,118
db 101,32,100,101,32
db 99,105,101,114,114
db 101,0
;/*
;** Cancela la compilaci¢n.
;*/
;abort()
qabort:
;{
;  if (input2)
ldl 1
ldnl 3755
cj c7
;    endinclude();
ldl 1
call qendinclude
;  if (input)
c7:
ldl 1
ldnl 3753
cj c8
;    fclose(input);
ldl 1
ldnl 3753
ldl 1
call qfclose
;  closeout();
c8:
ldl 1
call qcloseout
;  toconsole();
ldl 1
call qtoconsole
;  pl("Compilaci¢n cancelada.");
ldc c6-c9+0
ldpi
c9:
ldl 1
call qpl
;  nl();
ldl 1
call qnl
;  exit(0);
ldc 0
ldl 1
call qexit
;}
ret
c6:
db 67,111,109,112,105
db 108,97,99,105,162
db 110,32,99,97,110
db 99,101,108,97,100
db 97,46,0
;/*
;** Procesa todo el texto de entrada.
;**
;** En este nivel, solo declaraciones estaticas,
;** #define, #include, y definiciones de funcion
;** son legales.
;*/
;parse()
qparse:
;{
;  while (eof == 0) {    /* Trabaja hasta que no haya mas entrada */
c11:
ldl 1
ldnl 3752
eqc 0
cj c12
;    if (amatch("char", 4)) {
ldc 4
ldc c10-c14+0
ldpi
c14:
ldl 1
call qamatch
cj c13
;      declglb(cchar);
ldc 1
ldl 1
call qdeclglb
;      ns();
ldl 1
call qns
;    } else if (amatch("int", 3)) {
j c15
c13:
ldc 3
ldc c10-c17+5
ldpi
c17:
ldl 1
call qamatch
cj c16
;      declglb(cint);
ldc 2
ldl 1
call qdeclglb
;      ns();
ldl 1
call qns
;    } else if (match("#asm"))
j c18
c16:
ldc c10-c20+9
ldpi
c20:
ldl 1
call qmatch
cj c19
;      doasm();
ldl 1
call qdoasm
;    else if (match("#include"))
j c21
c19:
ldc c10-c23+14
ldpi
c23:
ldl 1
call qmatch
cj c22
;      doinclude();
ldl 1
call qdoinclude
;    else if (match("#define"))
j c24
c22:
ldc c10-c26+23
ldpi
c26:
ldl 1
call qmatch
cj c25
;      addmac();
ldl 1
call qaddmac
;    else
j c27
c25:
;      newfunc();
ldl 1
call qnewfunc
c27:
c24:
c21:
c18:
c15:
;    blanks();           /* Rastrea fin de archivo */
ldl 1
call qblanks
;  }
j c11
c12:
;}
ret
c10:
db 99,104,97,114,0
db 105,110,116,0,35
db 97,115,109,0,35
db 105,110,99,108,117
db 100,101,0,35,100
db 101,102,105,110,101
db 0
;/*
;** Vacia el almacenamiento de cadenas
;*/
;dumplits()
qdumplits:
;{
;  int j, k;
;  if (litptr == 0)
ajw -2
ldl 3
ldnl 2461
eqc 0
cj c29
;    return;             /* No hay nada, volver... */
ajw 2
ret
;  printlabel(litlab);   /* Imprime la etiqueta */
c29:
ldl 3
ldnl 3746
ldl 3
call qprintlabel
;  col();
ldl 3
call qcol
;  nl();
ldl 3
call qnl
;  k = 0;                /* Inicia un indice... */
ldc 0
stl 0
;  while (k < litptr) {  /* para vaciar el almacenamiento */
c30:
ldl 3
ldnl 2461
ldl 0
gt
cj c31
;    defbyte();          /* Define byte */
ldl 3
call qdefbyte
;    j = 5;              /* Bytes por linea */
ldc 5
stl 1
;    while (j--) {
c32:
ldl 1
dup
adc -1
stl 1
cj c33
;      outdec(litq[k++] & 255);
ldl 0
dup
adc 1
stl 0
ldl 3
ldnlp 2205
bsub
lb
ldc 255
and
ldl 3
call qoutdec
;      if ((j == 0) | (k >= litptr)) {
ldl 3
ldnl 2461
ldl 0
gt
eqc 0
ldl 1
eqc 0
or
cj c34
;        nl();           /* Otra linea */
ldl 3
call qnl
;        break;
j c33
;      }
;      outbyte(',');     /* Separa los bytes */
c34:
ldc 44
ldl 3
call qoutbyte
;    }
j c32
c33:
;  }
j c30
c31:
;}
ajw 2
ret
;/*
;** Reporta los errores
;*/
;errorsummary()
qerrorsummary:
;{
;  nl();
ldl 1
call qnl
;  outstr("Hubo ");
ldc c35-c36+0
ldpi
c36:
ldl 1
call qoutstr
;  outdec(errcnt);       /* No. total de errores */
ldl 1
ldnl 3750
ldl 1
call qoutdec
;  outstr(" errores en la compilaci¢n.");
ldc c35-c37+6
ldpi
c37:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;}
ret
c35:
db 72,117,98,111,32
db 0,32,101,114,114
db 111,114,101,115,32
db 101,110,32,108,97
db 32,99,111,109,112
db 105,108,97,99,105
db 162,110,46,0
;/*
;** Presentacion.
;*/
;hello()
qhello:
;{
;  nl();
ldl 1
call qnl
;  nl();
ldl 1
call qnl
;  pl(BANNER);
ldc c38-c39+0
ldpi
c39:
ldl 1
call qpl
;  nl();
ldl 1
call qnl
;  pl(AUTHOR);
ldc c38-c40+34
ldpi
c40:
ldl 1
call qpl
;  nl();
ldl 1
call qnl
;  nl();
ldl 1
call qnl
;  pl(VERSION);
ldc c38-c41+65
ldpi
c41:
ldl 1
call qpl
;  nl();
ldl 1
call qnl
;  nl();
ldl 1
call qnl
;}
ret
c38:
db 42,42,42,32,67
db 111,109,112,105,108
db 97,100,111,114,32
db 100,101,32,67,32
db 112,97,114,97,32
db 71,45,49,48,32
db 42,42,42,0,32
db 32,32,112,111,114
db 32,79,115,99,97
db 114,32,84,111,108
db 101,100,111,32,71
db 117,116,105,101,114
db 114,101,122,46,0
db 32,32,32,32,32
db 32,32,32,32,32
db 86,101,114,115,105
db 111,110,32,49,46
db 48,48,0
;see()
qsee:
;{
;  /* Checa si el usuario quiere ver todos los errores */
;  pl("Desea una pausa despues de un error (S/N) ? ");
ldc c42-c43+0
ldpi
c43:
ldl 1
call qpl
;  gets(line);
ldl 1
ldnlp 3487
ldl 1
call qgets
;  errstop = 0;
ldc 0
ldl 1
stnl 3751
;  if ((ch() == 'S') | (ch() == 's'))
ldl 1
call qch
eqc 115
ajw -1
stl 0
ldl 2
call qch
eqc 83
ldl 0
ajw 1
or
cj c44
;    errstop = 1;
ldc 1
ldl 1
stnl 3751
;  pl("Desea que aparezca el listado C (S/N) ? ");
c44:
ldc c42-c45+45
ldpi
c45:
ldl 1
call qpl
;  gets(line);
ldl 1
ldnlp 3487
ldl 1
call qgets
;  ctext = 0;
ldc 0
ldl 1
stnl 3756
;  if ((ch() == 'S') | (ch() == 's'))
ldl 1
call qch
eqc 115
ajw -1
stl 0
ldl 2
call qch
eqc 83
ldl 0
ajw 1
or
cj c46
;    ctext = 1;
ldc 1
ldl 1
stnl 3756
;}
c46:
ret
c42:
db 68,101,115,101,97
db 32,117,110,97,32
db 112,97,117,115,97
db 32,100,101,115,112
db 117,101,115,32,100
db 101,32,117,110,32
db 101,114,114,111,114
db 32,40,83,47,78
db 41,32,63,32,0
db 68,101,115,101,97
db 32,113,117,101,32
db 97,112,97,114,101
db 122,99,97,32,101
db 108,32,108,105,115
db 116,97,100,111,32
db 67,32,40,83,47
db 78,41,32,63,32
db 0
;/*
;** Obtiene el nombre del archivo de salida.
;*/
;openout()
qopenout:
;{
;  output = 0;           /* Por defecto la salida a la consola */
ldc 0
ldl 1
stnl 3754
;  while (output == 0) {
c48:
ldl 1
ldnl 3754
eqc 0
cj c49
;    kill();
ldl 1
call qkill
;    pl("Archivo de salida ? ");
ldc c47-c50+0
ldpi
c50:
ldl 1
call qpl
;    gets(line);         /* Obtiene el nombre */
ldl 1
ldnlp 3487
ldl 1
call qgets
;    if (ch() == 0)
ldl 1
call qch
eqc 0
cj c51
;      break;            /* Ninguno... */
j c49
;    if ((output = fopen(line, "w")) == NULL) {  /* Intenta crear */
c51:
ldc c47-c53+21
ldpi
c53:
ldl 1
ldnlp 3487
ldl 1
call qfopen
dup
ldl 1
stnl 3754
eqc 0
cj c52
;      output = 0;       /* No pudo crearse */
ldc 0
ldl 1
stnl 3754
;      error("No se pudo crear el archivo");
ldc c47-c54+23
ldpi
c54:
ldl 1
call qerror
;    }
;  }
c52:
j c48
c49:
;  kill();               /* Limpia la linea */
ldl 1
call qkill
;}
ret
c47:
db 65,114,99,104,105
db 118,111,32,100,101
db 32,115,97,108,105
db 100,97,32,63,32
db 0,119,0,78,111
db 32,115,101,32,112
db 117,100,111,32,99
db 114,101,97,114,32
db 101,108,32,97,114
db 99,104,105,118,111
db 0
;/*
;** Obtiene el archivo de entrada
;*/
;openin()
qopenin:
;{
;  input = 0;            /* Ninguno aun */
ldc 0
ldl 1
stnl 3753
;  while (input == 0) {
c56:
ldl 1
ldnl 3753
eqc 0
cj c57
;    kill();             /* Limpia la linea de entrada */
ldl 1
call qkill
;    pl("Archivo de entrada ? ");
ldc c55-c58+0
ldpi
c58:
ldl 1
call qpl
;    gets(line);         /* Obtiene un nombre */
ldl 1
ldnlp 3487
ldl 1
call qgets
;    if (ch() == 0)
ldl 1
call qch
eqc 0
cj c59
;      break;
j c57
;    if ((input = fopen(line, "r")) != NULL)
c59:
ldc c55-c61+22
ldpi
c61:
ldl 1
ldnlp 3487
ldl 1
call qfopen
dup
ldl 1
stnl 3753
eqc 0
eqc 0
cj c60
;      newfile();
ldl 1
call qnewfile
;    else {
j c62
c60:
;      input = 0;        /* No se pudo leer */
ldc 0
ldl 1
stnl 3753
;      pl("No se pudo leer el archivo");
ldc c55-c63+24
ldpi
c63:
ldl 1
call qpl
;    }
c62:
;  }
j c56
c57:
;  kill();               /* Limpia la linea */
ldl 1
call qkill
;}
ret
c55:
db 65,114,99,104,105
db 118,111,32,100,101
db 32,101,110,116,114
db 97,100,97,32,63
db 32,0,114,0,78
db 111,32,115,101,32
db 112,117,100,111,32
db 108,101,101,114,32
db 101,108,32,97,114
db 99,104,105,118,111
db 0
;/*
;** Inicia el contador de lineas.
;*/
;newfile()
qnewfile:
;{
;  lineno = 0;           /* Ninguna linea leida */
ldc 0
ldl 1
stnl 3761
;  fnstart = 0;          /* Ninguna funcion aun */
ldc 0
ldl 1
stnl 3760
;  currfn = NULL;
ldc 0
ldl 1
stnl 3766
;  infunc = 0;
ldc 0
ldl 1
stnl 3762
;}
ret
;/*
;** Abre un archivo #include
;*/
;doinclude()
qdoinclude:
;{
;  blanks();             /* Salta los espacios */
ldl 1
call qblanks
;  toconsole();
ldl 1
call qtoconsole
;  outstr("#include ");
ldc c65-c66+0
ldpi
c66:
ldl 1
call qoutstr
;  outstr(line + lptr);
ldl 1
ldnlp 3487
ldl 1
ldnl 3743
bsub
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  tofile();
ldl 1
call qtofile
;  if (input2)
ldl 1
ldnl 3755
cj c67
;    error("No se pueden anidar archivos");
ldc c65-c68+10
ldpi
c68:
ldl 1
call qerror
;  else if ((input2 = fopen(line + lptr, "r")) == NULL) {
j c69
c67:
ldl 1
ldnlp 3487
ldl 1
ldnl 3743
bsub
ldc c65-c71+39
ldpi
c71:
rev
ldl 1
call qfopen
dup
ldl 1
stnl 3755
eqc 0
cj c70
;    input2 = 0;
ldc 0
ldl 1
stnl 3755
;    error("No se pudo leer el archivo");
ldc c65-c72+41
ldpi
c72:
ldl 1
call qerror
;  } else {
j c73
c70:
;    saveline = lineno;
ldl 1
ldnl 3761
ldl 1
stnl 3764
;    savecurr = currfn;
ldl 1
ldnl 3766
ldl 1
stnl 3767
;    saveinfn = infunc;
ldl 1
ldnl 3762
ldl 1
stnl 3765
;    savestart = fnstart;
ldl 1
ldnl 3760
ldl 1
stnl 3763
;    newfile();
ldl 1
call qnewfile
;  }
c73:
c69:
;  kill();               /* La siguiente entrada sera del */
ldl 1
call qkill
;                        /* nuevo archivo. */
;}
ret
c65:
db 35,105,110,99,108
db 117,100,101,32,0
db 78,111,32,115,101
db 32,112,117,101,100
db 101,110,32,97,110
db 105,100,97,114,32
db 97,114,99,104,105
db 118,111,115,0,114
db 0,78,111,32,115
db 101,32,112,117,100
db 111,32,108,101,101
db 114,32,101,108,32
db 97,114,99,104,105
db 118,111,0
;/*
;** Cierra un archivo #include
;*/
;endinclude()
qendinclude:
;{
;  toconsole();
ldl 1
call qtoconsole
;  outstr("#fin include");
ldc c74-c75+0
ldpi
c75:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  tofile();
ldl 1
call qtofile
;  input2 = 0;
ldc 0
ldl 1
stnl 3755
;  lineno = saveline;
ldl 1
ldnl 3764
ldl 1
stnl 3761
;  currfn = savecurr;
ldl 1
ldnl 3767
ldl 1
stnl 3766
;  infunc = saveinfn;
ldl 1
ldnl 3765
ldl 1
stnl 3762
;  fnstart = savestart;
ldl 1
ldnl 3763
ldl 1
stnl 3760
;}
ret
c74:
db 35,102,105,110,32
db 105,110,99,108,117
db 100,101,0
;/*
;** Cierra el archivo de salida.
;*/
;closeout()
qcloseout:
;{
;  tofile();             /* Si esta desviado, volver al archivo */
ldl 1
call qtofile
;  if (output)
ldl 1
ldnl 3754
cj c77
;    fclose(output);     /* Si esta abierto, cerrarlo */
ldl 1
ldnl 3754
ldl 1
call qfclose
;  output = 0;           /* Marcar como cerrado */
c77:
ldc 0
ldl 1
stnl 3754
;}
ret
;/*
;** Declara una variable est tica.
;**
;** Crea una entrada en la tabla, para que las
;** referencias subsiguientes la llamen por nombre.
;*/
;declglb(typ)            /* typ es cchar o cint */
qdeclglb:
;  int typ;
;{
;  int k, j;
;  char sname[namesize];
;  while (1) {
ajw -7
c79:
ldc 1
cj c80
;    while (1) {
c81:
ldc 1
cj c82
;      if (endst())
ldl 8
call qendst
cj c83
;        return;         /* Procesa la linea */
ajw 7
ret
;      k = 1;            /* Asume 1 elemento */
c83:
ldc 1
stl 6
;      if (match("*"))   /* ¨ Apuntador ? */
ldc c78-c85+0
ldpi
c85:
ldl 8
call qmatch
cj c84
;        j = pointer;    /* Si */
ldc 3
stl 5
;      else
j c86
c84:
;        j = variable;   /* No */
ldc 1
stl 5
c86:
;      if (symname(sname) == 0)  /* ¨ Nombre correcto ? */
ldlp 0
ldl 8
call qsymname
eqc 0
cj c87
;        illname();              /* No... */
ldl 8
call qillname
;      if (findglb(sname))       /* ¨ Ya estaba en la tabla ? */
c87:
ldlp 0
ldl 8
call qfindglb
cj c88
;        multidef(sname);
ldlp 0
ldl 8
call qmultidef
;      if (match("[")) {         /* ¨ Matriz ? */
c88:
ldc c78-c90+2
ldpi
c90:
ldl 8
call qmatch
cj c89
;        k = needsub();          /* Obtiene el tama¤o */
ldl 8
call qneedsub
stl 6
;        if (k)
ldl 6
cj c91
;          j = array;            /* !0= Matriz */
ldc 2
stl 5
;        else
j c92
c91:
;          j = pointer;          /* 0= Apuntador */
ldc 3
stl 5
c92:
;      }
;      addglb(sname, j, typ, posglobal); /* Agrega el nombre */
c89:
ajw -2
ldl 11
stl 0
ldl 10
ldnl 3771
stl 1
ldl 7
ldlp 2
ldl 10
call qaddglb
ajw 2
;      if ((cptr[type] == cint) |
;          (cptr[ident] == pointer))
ldl 8
ldnl 3769
adc 18
lb
eqc 2
ldl 8
ldnl 3769
adc 17
lb
eqc 3
or
cj c93
;        k = k * 4;
ldl 6
ldc 4
prod
stl 6
;      posglobal = posglobal + ((k + 3) / 4);
c93:
ldl 6
adc 3
ldc 4
div
ldl 8
ldnl 3771
bsub
ldl 8
stnl 3771
;      break;
j c82
;    }
c82:
;    if (match(",") == 0)
ldc c78-c95+4
ldpi
c95:
ldl 8
call qmatch
eqc 0
cj c94
;      return;                   /* ¨ M s ? */
ajw 7
ret
;  }
c94:
j c79
c80:
;}
ajw 7
ret
c78:
db 42,0,91,0,44
db 0
;/*
;** Procesa declaraciones de variables locales.
;*/
;declloc()
qdeclloc:
;{
;  int k, j, pila, typ;
;  char sname[namesize];
;  pila = Zsp;
ajw -9
ldl 10
ldnl 3747
stl 6
;  while (1) {
c97:
ldc 1
cj c98
;    if (amatch("int", 3))
ldc 3
ldc c96-c100+0
ldpi
c100:
ldl 10
call qamatch
cj c99
;      typ = cint;
ldc 2
stl 5
;    else if (amatch("char", 4))
j c101
c99:
ldc 4
ldc c96-c103+4
ldpi
c103:
ldl 10
call qamatch
cj c102
;      typ = cchar;
ldc 1
stl 5
;    else
j c104
c102:
;      break;
j c98
c104:
c101:
;    while (1) {
c105:
ldc 1
cj c106
;      if (endst())
ldl 10
call qendst
cj c107
;	break;
j c106
;      if (match("*"))
c107:
ldc c96-c109+9
ldpi
c109:
ldl 10
call qmatch
cj c108
;	j = pointer;
ldc 3
stl 7
;      else
j c110
c108:
;	j = variable;
ldc 1
stl 7
c110:
;      if (symname(sname) == 0)
ldlp 0
ldl 10
call qsymname
eqc 0
cj c111
;	illname();
ldl 10
call qillname
;      if (findloc(sname))
c111:
ldlp 0
ldl 10
call qfindloc
cj c112
;	multidef(sname);
ldlp 0
ldl 10
call qmultidef
;      if (match("[")) {
c112:
ldc c96-c114+11
ldpi
c114:
ldl 10
call qmatch
cj c113
;	k = needsub();
ldl 10
call qneedsub
stl 8
;	if (k) {
ldl 8
cj c115
;	  j = array;
ldc 2
stl 7
;	  if (typ == cint)
ldl 5
eqc 2
cj c116
;	    k = k * 4;
ldl 8
ldc 4
prod
stl 8
;	} else {
c116:
j c117
c115:
;	  j = pointer;
ldc 3
stl 7
;	  k = 4;
ldc 4
stl 8
;	}
c117:
;      } else if ((typ == cchar)
j c118
c113:
;		 & (j != pointer))
ldl 5
eqc 1
ldl 7
eqc 3
eqc 0
and
cj c119
;	k = 1;
ldc 1
stl 8
;      else
j c120
c119:
;	k = 4;
ldc 4
stl 8
c120:
c118:
;      /* Modifica la pila */
;      k = (k + 3) / 4;
ldl 8
adc 3
ldc 4
div
stl 8
;      pila = pila - k;
ldl 6
ldl 8
diff
stl 6
;      addloc(sname, j, typ, pila);
ajw -2
ldl 7
stl 0
ldl 8
stl 1
ldl 9
ldlp 2
ldl 12
call qaddloc
ajw 2
;      if (match(",") == 0)
ldc c96-c122+13
ldpi
c122:
ldl 10
call qmatch
eqc 0
cj c121
;        break;
j c106
;    }
c121:
j c105
c106:
;    ns();
ldl 10
call qns
;  }
j c97
c98:
;  Zsp = modstk(pila);
ldl 6
ldl 10
call qmodstk
ldl 10
stnl 3747
;}
ajw 9
ret
c96:
db 105,110,116,0,99
db 104,97,114,0,42
db 0,91,0,44,0
;/*
;** Obtiene el tama¤o de una matriz.
;**
;** Invocada cuando una declaraci¢n es seguida
;** por "[".
;*/
;needsub()
qneedsub:
;{
;  int num[1];
;  if (match("]"))
ajw -1
ldc c123-c125+0
ldpi
c125:
ldl 2
call qmatch
cj c124
;    return 0;                   /* Tama¤o nulo */
ldc 0
ajw 1
ret
;  if (number(num) == 0) {       /* Busca el n£mero */
c124:
ldlp 0
ldl 2
call qnumber
eqc 0
cj c126
;    error("Debe ser un n£mero");/* No es un n£mero */
ldc c123-c127+2
ldpi
c127:
ldl 2
call qerror
;    num[0] = 1;                 /* Forza a 1 */
ldc 1
stl 0
;  }
;  if (num[0] < 0) {
c126:
ldc 0
ldl 0
gt
cj c128
;    error("Tama¤o negativo");
ldc c123-c129+21
ldpi
c129:
ldl 2
call qerror
;    num[0] = (-num[0]);
ldl 0
not
adc 1
stl 0
;  }
;  needbrack("]");       /* Forza una dimensi¢n */
c128:
ldc c123-c130+37
ldpi
c130:
ldl 2
call qneedbrack
;  return num[0];        /* y retorna el tama¤o */
ldl 0
ajw 1
ret
;}
c123:
db 93,0,68,101,98
db 101,32,115,101,114
db 32,117,110,32,110
db 163,109,101,114,111
db 0,84,97,109,97
db 164,111,32,110,101
db 103,97,116,105,118
db 111,0,93,0
;/*
;** Compila una funci¢n.
;**
;** Invocada por "parse", esta rutina intenta compilar una funcion
;** a partir de la entrada.
;*/
;newfunc()
qnewfunc:
;{
;  char n[namesize];
;  int argtop;
;  if (symname(n) == 0) {
ajw -6
ldlp 1
ldl 7
call qsymname
eqc 0
cj c132
;    if (eof == 0)
ldl 7
ldnl 3752
eqc 0
cj c133
;      error("Declaracion o funcion ilegal");
ldc c131-c134+0
ldpi
c134:
ldl 7
call qerror
;    kill();                     /* Inv lida la linea */
c133:
ldl 7
call qkill
;    return;
ajw 6
ret
;  }
;  fnstart = lineno;             /* Recuerda en que linea comenzo la funci¢n */
c132:
ldl 7
ldnl 3761
ldl 7
stnl 3760
;  infunc = 1;                   /* Indica que esta dentro de una funci¢n */
ldc 1
ldl 7
stnl 3762
;  if (currfn = findglb(n)) {    /* ¨ Ya estaba en la tabla de nombres ? */
ldlp 1
ldl 7
call qfindglb
dup
ldl 7
stnl 3766
cj c135
;    if (currfn[ident] != function)
ldl 7
ldnl 3766
adc 17
lb
eqc 4
eqc 0
cj c136
;      multidef(n);              /* Ya hay una variable con ese nombre */
ldlp 1
ldl 7
call qmultidef
;    else if (currfn[offset] == function)
j c137
c136:
ldl 7
ldnl 3766
adc 20
lb
eqc 4
cj c138
;      multidef(n);              /* Se redefinio una funci¢n */
ldlp 1
ldl 7
call qmultidef
;    else
j c139
c138:
;      currfn[offset] = function;/* Una funci¢n referenciada antes */
ldc 4
ldl 7
ldnl 3766
adc 20
sb
c139:
c137:
;  }
;  /* No estaba en la tabla, definir c¢mo una funci¢n */
;  else
j c140
c135:
;    currfn = addglb(n, function, cint, function);
ajw -2
ldc 2
stl 0
ldc 4
stl 1
ldc 4
ldlp 3
ldl 9
call qaddglb
ajw 2
ldl 7
stnl 3766
c140:
;  toconsole();
ldl 7
call qtoconsole
;  outstr("Compilando ");
ldc c131-c141+29
ldpi
c141:
ldl 7
call qoutstr
;  outstr(currfn + name);
ldl 7
ldnl 3766
ldl 7
call qoutstr
;  outstr("()...");
ldc c131-c142+41
ldpi
c142:
ldl 7
call qoutstr
;  nl();
ldl 7
call qnl
;  tofile();
ldl 7
call qtofile
;  /* Checa que haya parentesis de apertura */
;  if (match("(") == 0)
ldc c131-c144+47
ldpi
c144:
ldl 7
call qmatch
eqc 0
cj c143
;    error("Falta un parentesis de apertura");
ldc c131-c145+49
ldpi
c145:
ldl 7
call qerror
;  outname(n);                   /* Imprime el nombre de la funci¢n */
c143:
ldlp 1
ldl 7
call qoutname
;  col();
ldl 7
call qcol
;  nl();
ldl 7
call qnl
;  locptr = startloc;            /* Limpia la tabla de variables locales */
ldl 7
ldnlp 2
adc 7224
ldl 7
stnl 2103
;  argstk = 0;                   /* Inicia la cuenta de argumentos */
ldc 0
ldl 7
stnl 3748
;  while (match(")") == 0) {     /* Empieza a contar */
c146:
ldc c131-c148+81
ldpi
c148:
ldl 7
call qmatch
eqc 0
cj c147
;    /* Cualquier nombre legal incrementa la cuenta */
;    if (symname(n)) {
ldlp 1
ldl 7
call qsymname
cj c149
;      if (findloc(n))
ldlp 1
ldl 7
call qfindloc
cj c150
;	multidef(n);
ldlp 1
ldl 7
call qmultidef
;      else {
j c151
c150:
;	addloc(n, 0, 0, argstk + 2);
ajw -2
ldc 0
stl 0
ldl 9
ldnl 3748
adc 2
stl 1
ldc 0
ldlp 3
ldl 9
call qaddloc
ajw 2
;	++argstk;
ldl 7
ldnlp 3748
dup
ldnl 0
adc 1
rev
stnl 0
;      }
c151:
;    } else {
j c152
c149:
;      error("Nombre ilegal para el argumento");
ldc c131-c153+83
ldpi
c153:
ldl 7
call qerror
;      junk();
ldl 7
call qjunk
;    }
c152:
;    blanks();
ldl 7
call qblanks
;    /* Si no es parentesis de cierre, debe ser coma */
;    if (streq(line + lptr, ")") == 0) {
ldl 7
ldnlp 3487
ldl 7
ldnl 3743
bsub
ldc c131-c155+115
ldpi
c155:
rev
ldl 7
call qstreq
eqc 0
cj c154
;      if (match(",") == 0)
ldc c131-c157+117
ldpi
c157:
ldl 7
call qmatch
eqc 0
cj c156
;	error("Se requiere una coma");
ldc c131-c158+119
ldpi
c158:
ldl 7
call qerror
;    }
c156:
;    if (endst())
c154:
ldl 7
call qendst
cj c159
;      break;
j c147
;  }
c159:
j c146
c147:
;  argtop = argstk;
ldl 7
ldnl 3748
stl 0
;  while (argstk) {
c160:
ldl 7
ldnl 3748
cj c161
;    /* Ahora el usuario declara los tipos de los argumentos */
;    if (amatch("char", 4)) {
ldc 4
ldc c131-c163+140
ldpi
c163:
ldl 7
call qamatch
cj c162
;      getarg(cchar, argtop);
ldl 0
ldc 1
ldl 7
call qgetarg
;      ns();
ldl 7
call qns
;    } else if (amatch("int", 3)) {
j c164
c162:
ldc 3
ldc c131-c166+145
ldpi
c166:
ldl 7
call qamatch
cj c165
;      getarg(cint, argtop);
ldl 0
ldc 2
ldl 7
call qgetarg
;      ns();
ldl 7
call qns
;    } else {
j c167
c165:
;      error("Numero incorrecto de argumentos");
ldc c131-c168+149
ldpi
c168:
ldl 7
call qerror
;      break;
j c161
;    }
c167:
c164:
;  }
j c160
c161:
;  Zsp = 0;              /* Inicializa el apuntador de la pila */
ldc 0
ldl 7
stnl 3747
;  litlab = getlabel();  /* Etiqueta para el buffer literal */
ldl 7
call qgetlabel
ldl 7
stnl 3746
;  litptr = 0;           /* Limpia el buffer literal */
ldc 0
ldl 7
stnl 2461
;  /* Procesa una sentencia, si es un retorno */
;  /* entonces no limpia la pila */
;  if(statement() != streturn) {
ldl 7
call qstatement
eqc 3
eqc 0
cj c169
;    modstk(0);
ldc 0
ldl 7
call qmodstk
;    zret();
ldl 7
call qzret
;  }
;  dumplits();
c169:
ldl 7
call qdumplits
;  Zsp = 0;              /* Limpia la pila de nuevo */
ldc 0
ldl 7
stnl 3747
;  locptr = startloc;    /* Elimina todas las variables locales */
ldl 7
ldnlp 2
adc 7224
ldl 7
stnl 2103
;  infunc = 0;           /* Ahora no esta dentro de una funci¢n */
ldc 0
ldl 7
stnl 3762
;}
ajw 6
ret
c131:
db 68,101,99,108,97
db 114,97,99,105,111
db 110,32,111,32,102
db 117,110,99,105,111
db 110,32,105,108,101
db 103,97,108,0,67
db 111,109,112,105,108
db 97,110,100,111,32
db 0,40,41,46,46
db 46,0,40,0,70
db 97,108,116,97,32
db 117,110,32,112,97
db 114,101,110,116,101
db 115,105,115,32,100
db 101,32,97,112,101
db 114,116,117,114,97
db 0,41,0,78,111
db 109,98,114,101,32
db 105,108,101,103,97
db 108,32,112,97,114
db 97,32,101,108,32
db 97,114,103,117,109
db 101,110,116,111,0
db 41,0,44,0,83
db 101,32,114,101,113
db 117,105,101,114,101
db 32,117,110,97,32
db 99,111,109,97,0
db 99,104,97,114,0
db 105,110,116,0,78
db 117,109,101,114,111
db 32,105,110,99,111
db 114,114,101,99,116
db 111,32,100,101,32
db 97,114,103,117,109
db 101,110,116,111,115
db 0
;/*
;** Declara los tipos de los argumentos.
;*/
;getarg(t, top)                  /* Tipo = cchar o cint */
qgetarg:
;  int t, top;
;{                               /* tope = punto m s alto de la pila */
;  char n[namesize], *argptr;
;  int j;
;  while (1) {
ajw -7
c171:
ldc 1
cj c172
;    if (match("*"))
ldc c170-c174+0
ldpi
c174:
ldl 8
call qmatch
cj c173
;      j = pointer;
ldc 3
stl 0
;    else
j c175
c173:
;      j = variable;
ldc 1
stl 0
c175:
;    if (symname(n)) {
ldlp 2
ldl 8
call qsymname
cj c176
;      if (match("[")) {         /* Ignora lo que esta entre [] */
ldc c170-c178+2
ldpi
c178:
ldl 8
call qmatch
cj c177
;	while (inbyte() != ']')
c179:
ldl 8
call qinbyte
eqc 93
eqc 0
cj c180
;	  if (endst())
ldl 8
call qendst
cj c181
;	    break;
j c180
;	j = pointer;
c181:
j c179
c180:
ldc 3
stl 0
;      }
;      if (argptr = findloc(n)) {
c177:
ldlp 2
ldl 8
call qfindloc
dup
stl 1
cj c182
;	/* Pone el tipo correcto al argumento */
;	argptr[ident] = j;
ldl 0
ldl 1
adc 17
sb
;	argptr[type] = t;
ldl 9
ldl 1
adc 18
sb
;      } else
j c183
c182:
;	error("Se requiere el nombre de un argumento");
ldc c170-c184+4
ldpi
c184:
ldl 8
call qerror
c183:
;    } else
j c185
c176:
;      illname();
ldl 8
call qillname
c185:
;    --argstk;                   /* cuenta hacia atras */
ldl 8
ldnlp 3748
dup
ldnl 0
adc -1
rev
stnl 0
;    if (endst())
ldl 8
call qendst
cj c186
;      return;
ajw 7
ret
;    if (match(",") == 0)
c186:
ldc c170-c188+42
ldpi
c188:
ldl 8
call qmatch
eqc 0
cj c187
;      error("Se requiere una coma");
ldc c170-c189+44
ldpi
c189:
ldl 8
call qerror
;  }
c187:
j c171
c172:
;}
ajw 7
ret
c170:
db 42,0,91,0,83
db 101,32,114,101,113
db 117,105,101,114,101
db 32,101,108,32,110
db 111,109,98,114,101
db 32,100,101,32,117
db 110,32,97,114,103
db 117,109,101,110,116
db 111,0,44,0,83
db 101,32,114,101,113
db 117,105,101,114,101
db 32,117,110,97,32
db 99,111,109,97,0
;/*
;** Analizador de sentencias.
;**
;** Llamado cuando la sintaxis requiere una
;** sentencia, retorna un n£mero que indica
;** la £ltima sentencia procesada.
;*/
;statement()
qstatement:
;{
;  if ((ch() == 0) & (eof))
ldl 1
call qch
eqc 0
ldl 1
ldnl 3752
and
cj c191
;    return;
ret
;  else if (match("{"))
j c192
c191:
ldc c190-c194+0
ldpi
c194:
ldl 1
call qmatch
cj c193
;    compound();
ldl 1
call qcompound
;  else if (amatch("if", 2)) {
j c195
c193:
ldc 2
ldc c190-c197+2
ldpi
c197:
ldl 1
call qamatch
cj c196
;    doif();
ldl 1
call qdoif
;    lastst = stif;
ldc 1
ldl 1
stnl 3758
;  } else if (amatch("while", 5)) {
j c198
c196:
ldc 5
ldc c190-c200+5
ldpi
c200:
ldl 1
call qamatch
cj c199
;    dowhile();
ldl 1
call qdowhile
;    lastst = stwhile;
ldc 2
ldl 1
stnl 3758
;  } else if (amatch("return", 6)) {
j c201
c199:
ldc 6
ldc c190-c203+11
ldpi
c203:
ldl 1
call qamatch
cj c202
;    doreturn();
ldl 1
call qdoreturn
;    ns();
ldl 1
call qns
;    lastst = streturn;
ldc 3
ldl 1
stnl 3758
;  } else if (amatch("break", 5)) {
j c204
c202:
ldc 5
ldc c190-c206+18
ldpi
c206:
ldl 1
call qamatch
cj c205
;    dobreak();
ldl 1
call qdobreak
;    ns();
ldl 1
call qns
;    lastst = stbreak;
ldc 4
ldl 1
stnl 3758
;  } else if (amatch("continue", 8)) {
j c207
c205:
ldc 8
ldc c190-c209+24
ldpi
c209:
ldl 1
call qamatch
cj c208
;    docont();
ldl 1
call qdocont
;    ns();
ldl 1
call qns
;    lastst = stcont;
ldc 5
ldl 1
stnl 3758
;  } else if (match(";"))
j c210
c208:
ldc c190-c212+33
ldpi
c212:
ldl 1
call qmatch
cj c211
;    lastst = stexp;
ldc 7
ldl 1
stnl 3758
;  else if (match("#asm")) {
j c213
c211:
ldc c190-c215+35
ldpi
c215:
ldl 1
call qmatch
cj c214
;    doasm();
ldl 1
call qdoasm
;    lastst = stasm;
ldc 6
ldl 1
stnl 3758
;  }
;  /* Asumir que es una expresi¢n */
;  else {
j c216
c214:
;    usaexpr = NO;
ldc 0
ldl 1
stnl 3772
;    expression();
ldl 1
call qexpression
;    ns();
ldl 1
call qns
;    lastst = stexp;
ldc 7
ldl 1
stnl 3758
;  }
c216:
c213:
c210:
c207:
c204:
c201:
c198:
c195:
c192:
;  return lastst;
ldl 1
ldnl 3758
ret
;}
c190:
db 123,0,105,102,0
db 119,104,105,108,101
db 0,114,101,116,117
db 114,110,0,98,114
db 101,97,107,0,99
db 111,110,116,105,110
db 117,101,0,59,0
db 35,97,115,109,0
;/*
;** Checa punto y coma.
;**
;** Llamado cuando la sintaxis lo requiere.
;*/
;ns()
qns:
;{
;  if (match(";") == 0)
ldc c217-c219+0
ldpi
c219:
ldl 1
call qmatch
eqc 0
cj c218
;    error("Falta punto y coma");
ldc c217-c220+2
ldpi
c220:
ldl 1
call qerror
;}
c218:
ret
c217:
db 59,0,70,97,108
db 116,97,32,112,117
db 110,116,111,32,121
db 32,99,111,109,97
db 0
;/*
;** Bloque de sentencias.
;*/
;compound()
qcompound:
;{
;  int local, pila;
;  local = locptr;               /* Variables locales */
ajw -2
ldl 3
ldnl 2103
stl 1
;  pila = Zsp;                   /* Pila actual */
ldl 3
ldnl 3747
stl 0
;  ++ncmp;                       /* Un nuevo nivel */
ldl 3
ldnlp 3749
dup
ldnl 0
adc 1
rev
stnl 0
;  declloc();                    /* Procesa declaraciones locales */
ldl 3
call qdeclloc
;  while (match("}") == 0)
c222:
ldc c221-c224+0
ldpi
c224:
ldl 3
call qmatch
eqc 0
cj c223
;    statement();                /* Procesa sentencias */
ldl 3
call qstatement
j c222
c223:
;  --ncmp;                       /* Cierra el nivel */
ldl 3
ldnlp 3749
dup
ldnl 0
adc -1
rev
stnl 0
;  locptr = local;               /* Limpia las variables locales */
ldl 1
ldl 3
stnl 2103
;  if(lastst == streturn) return;
ldl 3
ldnl 3758
eqc 3
cj c225
ajw 2
ret
;  if(lastst == stbreak) return;
c225:
ldl 3
ldnl 3758
eqc 4
cj c226
ajw 2
ret
;  if(lastst == stcont) return;
c226:
ldl 3
ldnl 3758
eqc 5
cj c227
ajw 2
ret
;  Zsp = modstk(pila);           /* Limpia la pila */
c227:
ldl 0
ldl 3
call qmodstk
ldl 3
stnl 3747
;}
ajw 2
ret
c221:
db 125,0
;/*
;** Sentencia "if"
;*/
;doif()
qdoif:
;{
;  int flab1, flab2;
;  flab1 = getlabel();           /* Etiqueta para el salto falso */
ajw -2
ldl 3
call qgetlabel
stl 1
;  test(flab1);                  /* Prueba la expresi¢n y salta si es falsa */
ldl 1
ldl 3
call qtest
;  statement();                  /* Verdadera, procesa sentencias */
ldl 3
call qstatement
;  if (amatch("else", 4) == 0)   /* ¨ if...else ? */
ldc 4
ldc c228-c230+0
ldpi
c230:
ldl 3
call qamatch
eqc 0
cj c229
;                                /* "if" simple ... imprimir etiqueta de falso */
;  {
;    printlabel(flab1);
ldl 1
ldl 3
call qprintlabel
;    col();
ldl 3
call qcol
;    nl();
ldl 3
call qnl
;    return;                     /* Y vuelve */
ajw 2
ret
;  }
;                                /* Una sentencia "if...else" */
;  jump(flab2 = getlabel());     /* Salta alrededor del codigo de else */
c229:
ldl 3
call qgetlabel
dup
stl 0
ldl 3
call qjump
;  printlabel(flab1);
ldl 1
ldl 3
call qprintlabel
;  col();
ldl 3
call qcol
;  nl();                         /* Imprime etiqueta falsa */
ldl 3
call qnl
;  statement();                  /* Procesa el else */
ldl 3
call qstatement
;  printlabel(flab2);
ldl 0
ldl 3
call qprintlabel
;  col();
ldl 3
call qcol
;  nl();                         /* Imprime etiqueta verdadera */
ldl 3
call qnl
;}
ajw 2
ret
c228:
db 101,108,115,101,0
;/*
;** Sentencia "while"
;*/
;dowhile()
qdowhile:
;{
;  int wq[4];                    /* Crea una entrada */
;  wq[wqsym] = locptr;           /* Nivel de variables locales */
ajw -4
ldl 5
ldnl 2103
stl 0
;  wq[wqsp] = Zsp;               /* Nivel de la pila */
ldl 5
ldnl 3747
stl 1
;  wq[wqloop] = getlabel();      /* Etiqueta del bucle */
ldl 5
call qgetlabel
stl 2
;  wq[wqlab] = getlabel();       /* Etiqueta de salida */
ldl 5
call qgetlabel
stl 3
;  addwhile(wq);                 /* Agrega a la cola (para el break) */
ldlp 0
ldl 5
call qaddwhile
;  printlabel(wq[wqloop]);       /* Etiqueta del bucle */
ldl 2
ldl 5
call qprintlabel
;  col();
ldl 5
call qcol
;  nl();
ldl 5
call qnl
;  test(wq[wqlab]);              /* Checa la expresi¢n */
ldl 3
ldl 5
call qtest
;  statement();                  /* Procesa una sentencia */
ldl 5
call qstatement
;  if((lastst != streturn) &
;     (lastst != stcont) &
;     (lastst != stbreak))
ldl 5
ldnl 3758
eqc 3
eqc 0
ldl 5
ldnl 3758
eqc 5
eqc 0
and
ldl 5
ldnl 3758
eqc 4
eqc 0
and
cj c232
;    jump(wq[wqloop]);           /* Vuelve al bucle */
ldl 2
ldl 5
call qjump
;  printlabel(wq[wqlab]);        /* Etiqueta de salida */
c232:
ldl 3
ldl 5
call qprintlabel
;  col();
ldl 5
call qcol
;  nl();
ldl 5
call qnl
;  delwhile();                   /* Borra de la cola */
ldl 5
call qdelwhile
;}
ajw 4
ret
;/*
;** Sentencia "return"
;*/
;doreturn()
qdoreturn:
;{
;  /* Checa si hay una expresi¢n */
;  if (endst() == 0) {
ldl 1
call qendst
eqc 0
cj c234
;    usaexpr = SI;
ldc 1
ldl 1
stnl 3772
;    expression();
ldl 1
call qexpression
;  }
;  modstk(0);                    /* Limpia la pila */
c234:
ldc 0
ldl 1
call qmodstk
;  zret();                       /* Sale de la funci¢n */
ldl 1
call qzret
;}
ret
;/*
;** Sentencia "break"
;*/
;dobreak()
qdobreak:
;{
;  int *ptr;
;  /* Ve si hay un while abierto */
;  if ((ptr = readwhile()) == 0)
ajw -1
ldl 2
call qreadwhile
dup
stl 0
eqc 0
cj c236
;    return;                     /* No */
ajw 1
ret
;  modstk((ptr[wqsp]));          /* Si, arregla la pila */
c236:
ldl 0
ldnl 1
ldl 2
call qmodstk
;  jump(ptr[wqlab]);             /* Salta a la etiqueta de salida */
ldl 0
ldnl 3
ldl 2
call qjump
;}
ajw 1
ret
;/*
;** Sentencia "continue"
;*/
;docont()
qdocont:
;{
;  int *ptr;
;  /* Ve si hay un while abierto */
;  if ((ptr = readwhile()) == 0)
ajw -1
ldl 2
call qreadwhile
dup
stl 0
eqc 0
cj c238
;    return;                     /* No */
ajw 1
ret
;  modstk((ptr[wqsp]));          /* Si, arregla la pila */
c238:
ldl 0
ldnl 1
ldl 2
call qmodstk
;  jump(ptr[wqloop]);            /* Salta a la etiqueta de salida */
ldl 0
ldnl 2
ldl 2
call qjump
;}
ajw 1
ret
;/*
;** Seudo-sentencia "asm"
;**
;** Entra en un modo en el que el lenguaje ensamblador
;** es pasado intacto a traves del analizador.
;*/
;doasm()
qdoasm:
;{
;  cmode = 0;                    /* Marca modo ensamblador */
ldc 0
ldl 1
stnl 3757
;  while (1) {
c240:
ldc 1
cj c241
;    in_line();                   /* Obtiene y imprime lineas */
ldl 1
call qin_line
;    if (match("#endasm"))
ldc c239-c243+0
ldpi
c243:
ldl 1
call qmatch
cj c242
;      break;                    /* hasta que... */
j c241
;    if (eof)
c242:
ldl 1
ldnl 3752
cj c244
;      break;
j c241
;    outstr(line);
c244:
ldl 1
ldnlp 3487
ldl 1
call qoutstr
;    nl();
ldl 1
call qnl
;  }
j c240
c241:
;  kill();                       /* Limpia la linea */
ldl 1
call qkill
;  cmode = 1;                    /* Vuelve al modo de an lisis */
ldc 1
ldl 1
stnl 3757
;}
ret
c239:
db 35,101,110,100,97
db 115,109,0
;junk()
qjunk:
;{
;  if (an(inbyte()))
ldl 1
call qinbyte
ldl 1
call qan
cj c246
;    while (an(ch()))
c247:
ldl 1
call qch
ldl 1
call qan
cj c248
;      gch();
ldl 1
call qgch
j c247
c248:
;  else
j c249
c246:
;    while (an(ch()) == 0) {
c250:
ldl 1
call qch
ldl 1
call qan
eqc 0
cj c251
;      if (ch() == 0)
ldl 1
call qch
eqc 0
cj c252
;	break;
j c251
;      gch();
c252:
ldl 1
call qgch
;    }
j c250
c251:
c249:
;  blanks();
ldl 1
call qblanks
;}
ret
;endst()
qendst:
;{
;  blanks();
ldl 1
call qblanks
;  return ((streq(line + lptr, ";") | (ch() == 0)));
ldl 1
call qch
eqc 0
ajw -1
stl 0
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c253-c254+0
ldpi
c254:
rev
ldl 2
call qstreq
ldl 0
ajw 1
or
ret
;}
c253:
db 59,0
;illname()
qillname:
;{
;  error("Nombre ilegal");
ldc c255-c256+0
ldpi
c256:
ldl 1
call qerror
;  junk();
ldl 1
call qjunk
;}
ret
c255:
db 78,111,109,98,114
db 101,32,105,108,101
db 103,97,108,0
;multidef(sname)
qmultidef:
;  char *sname;
;{
;  error("Nombre redefinido");
ldc c257-c258+0
ldpi
c258:
ldl 1
call qerror
;  comment();
ldl 1
call qcomment
;  outstr(sname);
ldl 2
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;}
ret
c257:
db 78,111,109,98,114
db 101,32,114,101,100
db 101,102,105,110,105
db 100,111,0
;needbrack(str)
qneedbrack:
;  char *str;
;{
;  if (match(str) == 0) {
ldl 2
ldl 1
call qmatch
eqc 0
cj c260
;    error("Falta un ");
ldc c259-c261+0
ldpi
c261:
ldl 1
call qerror
;    comment();
ldl 1
call qcomment
;    outstr(str);
ldl 2
ldl 1
call qoutstr
;    nl();
ldl 1
call qnl
;  }
;}
c260:
ret
c259:
db 70,97,108,116,97
db 32,117,110,32,0
;needlval()
qneedlval:
;{
;  error("Debe ser un valor-l");
ldc c262-c263+0
ldpi
c263:
ldl 1
call qerror
;}
ret
c262:
db 68,101,98,101,32
db 115,101,114,32,117
db 110,32,118,97,108
db 111,114,45,108,0
;findglb(sname)
qfindglb:
;  char *sname;
;{
;  char *ptr;
;  ptr = startglb;
ajw -1
ldl 2
ldnlp 2
stl 0
;  while (ptr != glbptr) {
c265:
ldl 0
ldl 2
ldnl 2102
diff
eqc 0
eqc 0
cj c266
;    if (astreq(sname, ptr, namemax))
ajw -1
ldc 16
stl 0
ldl 1
ldl 4
ldl 3
call qastreq
ajw 1
cj c267
;      return ptr;
ldl 0
ajw 1
ret
;    ptr = ptr + symsiz;
c267:
ldl 0
adc 24
stl 0
;  }
j c265
c266:
;  return 0;
ldc 0
ajw 1
ret
;}
;findloc(sname)
qfindloc:
;  char *sname;
;{
;  char *ptr;
;  ptr = startloc;
ajw -1
ldl 2
ldnlp 2
adc 7224
stl 0
;  while (ptr != locptr) {
c269:
ldl 0
ldl 2
ldnl 2103
diff
eqc 0
eqc 0
cj c270
;    if (astreq(sname, ptr, namemax))
ajw -1
ldc 16
stl 0
ldl 1
ldl 4
ldl 3
call qastreq
ajw 1
cj c271
;      return ptr;
ldl 0
ajw 1
ret
;    ptr = ptr + symsiz;
c271:
ldl 0
adc 24
stl 0
;  }
j c269
c270:
;  return 0;
ldc 0
ajw 1
ret
;}
;addglb(sname, id, typ, value)
qaddglb:
;  char *sname, id, typ;
;  int value;
;{
;  char *ptr;
;  if (cptr = findglb(sname))
ajw -1
ldl 3
ldl 2
call qfindglb
dup
ldl 2
stnl 3769
cj c273
;    return cptr;
ldl 2
ldnl 3769
ajw 1
ret
;  if (glbptr >= endglb) {
c273:
ldl 2
ldnlp 2
adc 7200
ldl 2
ldnl 2102
rev
mint
xor
rev
mint
xor
gt
eqc 0
cj c274
;    error("Tabla global llena");
ldc c272-c275+0
ldpi
c275:
ldl 2
call qerror
;    return 0;
ldc 0
ajw 1
ret
;  }
;  cptr = ptr = glbptr;
c274:
ldl 2
ldnl 2102
dup
stl 0
ldl 2
stnl 3769
;  while (an(*ptr++ = *sname++));/* Copia el nombre */
c276:
ldl 0
dup
adc 1
stl 0
ajw -1
stl 0
ldl 4
dup
adc 1
stl 4
lb
dup
ldl 0
ajw 1
sb
ldl 2
call qan
cj c277
j c276
c277:
;  cptr[ident] = id;
ldlp 4
lb
ldl 2
ldnl 3769
adc 17
sb
;  cptr[type] = typ;
ldlp 5
lb
ldl 2
ldnl 3769
adc 18
sb
;  cptr[storage] = statik;
ldc 1
ldl 2
ldnl 3769
adc 19
sb
;  cptr[offset] = value;
ldl 6
ldl 2
ldnl 3769
adc 20
sb
;  cptr[offset + 1] = value >> 8;
ldl 6
ldc 8
shr
ldl 2
ldnl 3769
adc 21
sb
;  cptr[offset + 2] = value >> 16;
ldl 6
ldc 16
shr
ldl 2
ldnl 3769
adc 22
sb
;  cptr[offset + 3] = value >> 24;
ldl 6
ldc 24
shr
ldl 2
ldnl 3769
adc 23
sb
;  glbptr = glbptr + symsiz;
ldl 2
ldnl 2102
adc 24
ldl 2
stnl 2102
;  return cptr;
ldl 2
ldnl 3769
ajw 1
ret
;}
c272:
db 84,97,98,108,97
db 32,103,108,111,98
db 97,108,32,108,108
db 101,110,97,0
;addloc(sname, id, typ, value)
qaddloc:
;  char *sname, id, typ;
;  int value;
;{
;  char *ptr;
;  if (cptr = findloc(sname))
ajw -1
ldl 3
ldl 2
call qfindloc
dup
ldl 2
stnl 3769
cj c279
;    return cptr;
ldl 2
ldnl 3769
ajw 1
ret
;  if (locptr >= endloc) {
c279:
ldl 2
ldnlp 2
adc 8376
ldl 2
ldnl 2103
rev
mint
xor
rev
mint
xor
gt
eqc 0
cj c280
;    error("Tabla local llena");
ldc c278-c281+0
ldpi
c281:
ldl 2
call qerror
;    return 0;
ldc 0
ajw 1
ret
;  }
;  cptr = ptr = locptr;
c280:
ldl 2
ldnl 2103
dup
stl 0
ldl 2
stnl 3769
;  while (an(*ptr++ = *sname++));/* Copia el nombre */
c282:
ldl 0
dup
adc 1
stl 0
ajw -1
stl 0
ldl 4
dup
adc 1
stl 4
lb
dup
ldl 0
ajw 1
sb
ldl 2
call qan
cj c283
j c282
c283:
;  cptr[ident] = id;
ldlp 4
lb
ldl 2
ldnl 3769
adc 17
sb
;  cptr[type] = typ;
ldlp 5
lb
ldl 2
ldnl 3769
adc 18
sb
;  cptr[storage] = stkloc;
ldc 2
ldl 2
ldnl 3769
adc 19
sb
;  cptr[offset] = value;
ldl 6
ldl 2
ldnl 3769
adc 20
sb
;  cptr[offset + 1] = value >> 8;
ldl 6
ldc 8
shr
ldl 2
ldnl 3769
adc 21
sb
;  cptr[offset + 2] = value >> 16;
ldl 6
ldc 16
shr
ldl 2
ldnl 3769
adc 22
sb
;  cptr[offset + 3] = value >> 24;
ldl 6
ldc 24
shr
ldl 2
ldnl 3769
adc 23
sb
;  locptr = locptr + symsiz;
ldl 2
ldnl 2103
adc 24
ldl 2
stnl 2103
;  return cptr;
ldl 2
ldnl 3769
ajw 1
ret
;}
c278:
db 84,97,98,108,97
db 32,108,111,99,97
db 108,32,108,108,101
db 110,97,0
;/* Prueba si la proxima cadena de entrada es un nombre legal */
;symname(sname)
qsymname:
;  char *sname;
;{
;  int k;
;  char c;
;  blanks();
ajw -2
ldl 3
call qblanks
;  if (alpha(ch()) == 0)
ldl 3
call qch
ldl 3
call qalpha
eqc 0
cj c285
;    return 0;
ldc 0
ajw 2
ret
;  k = 0;
c285:
ldc 0
stl 1
;  while (an(ch()))
c286:
ldl 3
call qch
ldl 3
call qan
cj c287
;    sname[k++] = gch();
ldl 3
call qgch
ldl 1
dup
adc 1
stl 1
ldl 4
bsub
sb
j c286
c287:
;  sname[k] = 0;
ldc 0
ldl 1
ldl 4
bsub
sb
;  return 1;
ldc 1
ajw 2
ret
;}
;/* Prueba si el caracter dado es una letra */
;alpha(c)
qalpha:
;  int c;
;{
;  c = c & 255;
ldl 2
ldc 255
and
stl 2
;  return (((c >= 'a') & (c <= 'z')) |
;	  ((c >= 'A') & (c <= 'Z')) |
;	  (c == '_'));
ldc 65
ldl 2
gt
eqc 0
ldl 2
ldc 90
gt
eqc 0
and
ajw -1
stl 0
ldc 97
ldl 3
gt
eqc 0
ldl 3
ldc 122
gt
eqc 0
and
ldl 0
ajw 1
or
ldl 2
eqc 95
or
ret
;}
;/* Prueba si el caracter dado es un n£mero */
;numeric(c)
qnumeric:
;  int c;
;{
;  c = c & 255;
ldl 2
ldc 255
and
stl 2
;  return ((c >= '0') & (c <= '9'));
ldc 48
ldl 2
gt
eqc 0
ldl 2
ldc 57
gt
eqc 0
and
ret
;}
;/* Prueba si el caracter dado es alfanum‚rico */
;an(c)
qan:
;  char c;
;{
;  return ((alpha(c)) | (numeric(c)));
ldlp 2
lb
ldl 1
call qnumeric
ajw -1
stl 0
ldlp 3
lb
ldl 2
call qalpha
ldl 0
ajw 1
or
ret
;}
;/* Imprime un retorno de carro y una cadena a la consola */
;pl(str)
qpl:
;  char *str;
;{
;  int k;
;  k = 0;
ajw -1
ldc 0
stl 0
;  putchar(13);
ldc 13
ldl 2
call qputchar
;  putchar(10);
ldc 10
ldl 2
call qputchar
;  while (*str)
c292:
ldl 3
lb
cj c293
;    putchar(*str++);
ldl 3
dup
adc 1
stl 3
lb
ldl 2
call qputchar
j c292
c293:
;}
ajw 1
ret
;addwhile(ptr)
qaddwhile:
;  int ptr[];
;{
;  int k;
;  if (wqptr == wqmax) {
ajw -1
ldl 2
ldnl 2204
ldl 2
ldnlp 2104
adc 96
diff
eqc 0
cj c295
;    error("Demasiados bucles activos");
ldc c294-c296+0
ldpi
c296:
ldl 2
call qerror
;    return;
ajw 1
ret
;  }
;  k = 0;
c295:
ldc 0
stl 0
;  while (k < wqsiz)
c297:
ldc 4
ldl 0
gt
cj c298
;    *wqptr++ = ptr[k++];
ldl 2
ldnlp 2204
dup
ldnl 0
dup
adc 4
pop
pop
stnl 0
ldl 0
dup
adc 1
stl 0
ldl 3
wsub
ldnl 0
rev
stnl 0
j c297
c298:
;}
ajw 1
ret
c294:
db 68,101,109,97,115
db 105,97,100,111,115
db 32,98,117,99,108
db 101,115,32,97,99
db 116,105,118,111,115
db 0
;delwhile()
qdelwhile:
;{
;  if (readwhile())
ldl 1
call qreadwhile
cj c300
;    wqptr = wqptr - wqsiz;
ldl 1
ldnl 2204
adc -16
ldl 1
stnl 2204
;}
c300:
ret
;readwhile()
qreadwhile:
;{
;  if (wqptr == wq) {
ldl 1
ldnl 2204
ldl 1
ldnlp 2104
diff
eqc 0
cj c302
;    error("No hay bucles activos");
ldc c301-c303+0
ldpi
c303:
ldl 1
call qerror
;    return 0;
ldc 0
ret
;  } else
j c304
c302:
;    return (wqptr - wqsiz);
ldl 1
ldnl 2204
adc -16
ret
c304:
;}
ret
c301:
db 78,111,32,104,97
db 121,32,98,117,99
db 108,101,115,32,97
db 99,116,105,118,111
db 115,0
;ch()
qch:
;{
;  return (line[lptr] & 255);
ldl 1
ldnl 3743
ldl 1
ldnlp 3487
bsub
lb
ldc 255
and
ret
;}
;nch()
qnch:
;{
;  if (ch() == 0)
ldl 1
call qch
eqc 0
cj c307
;    return 0;
ldc 0
ret
;  else
j c308
c307:
;    return (line[lptr + 1] & 255);
ldl 1
ldnl 3743
adc 1
ldl 1
ldnlp 3487
bsub
lb
ldc 255
and
ret
c308:
;}
ret
;gch()
qgch:
;{
;  if (ch() == 0)
ldl 1
call qch
eqc 0
cj c310
;    return 0;
ldc 0
ret
;  else
j c311
c310:
;    return (line[lptr++] & 255);
ldl 1
ldnlp 3743
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 1
ldnlp 3487
bsub
lb
ldc 255
and
ret
c311:
;}
ret
;kill()
qkill:
;{
;  lptr = 0;
ldc 0
ldl 1
stnl 3743
;  line[lptr] = 0;
ldc 0
ldl 1
ldnl 3743
ldl 1
ldnlp 3487
bsub
sb
;}
ret
;inbyte()
qinbyte:
;{
;  while (ch() == 0) {
c314:
ldl 1
call qch
eqc 0
cj c315
;    if (eof)
ldl 1
ldnl 3752
cj c316
;      return 0;
ldc 0
ret
;    in_line();
c316:
ldl 1
call qin_line
;    preprocess();
ldl 1
call qpreprocess
;  }
j c314
c315:
;  return gch();
ldl 1
call qgch
ret
;}
;in_line()
qin_line:
;{
;  int k, unit;
;  while (1) {
ajw -2
c318:
ldc 1
cj c319
;    if (input == 0) {
ldl 3
ldnl 3753
eqc 0
cj c320
;      eof = 1;
ldc 1
ldl 3
stnl 3752
;      return;
ajw 2
ret
;    }
;    if ((unit = input2) == 0)
c320:
ldl 3
ldnl 3755
dup
stl 0
eqc 0
cj c321
;      unit = input;
ldl 3
ldnl 3753
stl 0
;    kill();
c321:
ldl 3
call qkill
;    while ((k = fgetc(unit)) > 0) {
c322:
ldl 0
ldl 3
call qfgetc
dup
stl 1
ldc 0
gt
cj c323
;      if (k == 13)
ldl 1
eqc 13
cj c324
;	continue;
j c322
;      if ((k == eol) | (lptr >= linemax))
c324:
ldc 511
ldl 3
ldnl 3743
gt
eqc 0
ldl 1
eqc 10
or
cj c325
;	break;
j c323
;      line[lptr++] = k;
c325:
ldl 3
ldnlp 3743
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 3
ldnlp 3487
bsub
ldl 1
rev
sb
;    }
j c322
c323:
;    line[lptr] = 0;     /* Agrega un caracter nulo */
ldc 0
ldl 3
ldnl 3743
ldl 3
ldnlp 3487
bsub
sb
;    lineno++;           /* Se ha leido una l¡nea m s */
ldl 3
ldnlp 3761
dup
ldnl 0
adc 1
rev
stnl 0
;    if (k <= 0) {
ldl 1
ldc 0
gt
eqc 0
cj c326
;      fclose(unit);
ldl 0
ldl 3
call qfclose
;      if (input2)
ldl 3
ldnl 3755
cj c327
;	endinclude();
ldl 3
call qendinclude
;      else
j c328
c327:
;	input = 0;
ldc 0
ldl 3
stnl 3753
c328:
;    }
;    if (lptr) {
c326:
ldl 3
ldnl 3743
cj c329
;      if (ctext & cmode) {
ldl 3
ldnl 3756
ldl 3
ldnl 3757
and
cj c330
;	comment();
ldl 3
call qcomment
;	outstr(line);
ldl 3
ldnlp 3487
ldl 3
call qoutstr
;	nl();
ldl 3
call qnl
;      }
;      lptr = 0;
c330:
ldc 0
ldl 3
stnl 3743
;      return;
ajw 2
ret
;    }
;  }
c329:
j c318
c319:
;}
ajw 2
ret
;preprocess()
qpreprocess:
;{
;  int k;
;  char c, sname[namesize];
;  if (cmode == 0)
ajw -7
ldl 8
ldnl 3757
eqc 0
cj c332
;    return;
ajw 7
ret
;  mptr = lptr = 0;
c332:
ldc 0
dup
ldl 8
stnl 3743
ldl 8
stnl 3744
;  while (ch()) {
c333:
ldl 8
call qch
cj c334
;    if ((ch() == ' ') | (ch() == 9))
ldl 8
call qch
eqc 9
ajw -1
stl 0
ldl 9
call qch
eqc 32
ldl 0
ajw 1
or
cj c335
;      predel();
ldl 8
call qpredel
;    else if (ch() == '"')
j c336
c335:
ldl 8
call qch
eqc 34
cj c337
;      prequote();
ldl 8
call qprequote
;    else if (ch() == 39)
j c338
c337:
ldl 8
call qch
eqc 39
cj c339
;      preapos();
ldl 8
call qpreapos
;    else if ((ch() == '/') & (nch() == '*'))
j c340
c339:
ldl 8
call qnch
eqc 42
ajw -1
stl 0
ldl 9
call qch
eqc 47
ldl 0
ajw 1
and
cj c341
;      precomm();
ldl 8
call qprecomm
;    else if (alpha(ch())) {
j c342
c341:
ldl 8
call qch
ldl 8
call qalpha
cj c343
;      k = 0;
ldc 0
stl 6
;      while (an(ch())) {
c344:
ldl 8
call qch
ldl 8
call qan
cj c345
;	if (k < namemax)
ldc 16
ldl 6
gt
cj c346
;	  sname[k++] = ch();
ldl 8
call qch
ldl 6
dup
adc 1
stl 6
ldlp 0
bsub
sb
;	gch();
c346:
ldl 8
call qgch
;      }
j c344
c345:
;      sname[k] = 0;
ldc 0
ldl 6
ldlp 0
bsub
sb
;      if (k = findmac(sname))
ldlp 0
ldl 8
call qfindmac
dup
stl 6
cj c347
;	while (c = macq[k++])
c348:
ldl 6
dup
adc 1
stl 6
ldl 8
ldnlp 2462
bsub
lb
dup
ldlp 5
sb
cj c349
;	  keepch(c);
ldlp 5
lb
ldl 8
call qkeepch
j c348
c349:
;      else {
j c350
c347:
;	k = 0;
ldc 0
stl 6
;	while (c = sname[k++])
c351:
ldl 6
dup
adc 1
stl 6
ldlp 0
bsub
lb
dup
ldlp 5
sb
cj c352
;	  keepch(c);
ldlp 5
lb
ldl 8
call qkeepch
j c351
c352:
;      }
c350:
;    } else
j c353
c343:
;      keepch(gch());
ldl 8
call qgch
ldl 8
call qkeepch
c353:
c342:
c340:
c338:
c336:
;  }
j c333
c334:
;  keepch(0);
ldc 0
ldl 8
call qkeepch
;  if (mptr >= mpmax)
ldc 511
ldl 8
ldnl 3744
gt
eqc 0
cj c354
;    error("Linea muy larga");
ldc c331-c355+0
ldpi
c355:
ldl 8
call qerror
;  lptr = mptr = 0;
c354:
ldc 0
dup
ldl 8
stnl 3744
ldl 8
stnl 3743
;  while (line[lptr++] = mline[mptr++]);
c356:
ldl 8
ldnlp 3743
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 8
ldnlp 3487
bsub
ajw -1
stl 0
ldl 9
ldnlp 3744
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 9
ldnlp 3615
bsub
lb
dup
ldl 0
ajw 1
sb
cj c357
j c356
c357:
;  lptr = 0;
ldc 0
ldl 8
stnl 3743
;}
ajw 7
ret
c331:
db 76,105,110,101,97
db 32,109,117,121,32
db 108,97,114,103,97
db 0
;keepch(c)
qkeepch:
;  char c;
;{
;  mline[mptr] = c;
ldlp 2
lb
ldl 1
ldnl 3744
ldl 1
ldnlp 3615
bsub
sb
;  if (mptr < mpmax)
ldc 511
ldl 1
ldnl 3744
gt
cj c359
;    mptr++;
ldl 1
ldnlp 3744
dup
ldnl 0
adc 1
rev
stnl 0
;  return c;
c359:
ldlp 2
lb
ret
;}
;predel()
qpredel:
;{
;  keepch(' ');
ldc 32
ldl 1
call qkeepch
;  while ((ch() == ' ') |
c361:
;	 (ch() == 9))
ldl 1
call qch
eqc 9
ajw -1
stl 0
ldl 2
call qch
eqc 32
ldl 0
ajw 1
or
cj c362
;    gch();
ldl 1
call qgch
j c361
c362:
;}
ret
;prequote()
qprequote:
;{
;  keepch(ch());
ldl 1
call qch
ldl 1
call qkeepch
;  gch();
ldl 1
call qgch
;  while ((ch() != '"') | ((line[lptr - 1] == 92) & (line[lptr - 2] != 92))) {
c364:
ldl 1
ldnl 3743
adc -1
ldl 1
ldnlp 3487
bsub
lb
eqc 92
ldl 1
ldnl 3743
adc -2
ldl 1
ldnlp 3487
bsub
lb
eqc 92
eqc 0
and
ajw -1
stl 0
ldl 2
call qch
eqc 34
eqc 0
ldl 0
ajw 1
or
cj c365
;    if (ch() == 0) {
ldl 1
call qch
eqc 0
cj c366
;      error("Faltan comillas");
ldc c363-c367+0
ldpi
c367:
ldl 1
call qerror
;      break;
j c365
;    }
;    keepch(gch());
c366:
ldl 1
call qgch
ldl 1
call qkeepch
;  }
j c364
c365:
;  gch();
ldl 1
call qgch
;  keepch('"');
ldc 34
ldl 1
call qkeepch
;}
ret
c363:
db 70,97,108,116,97
db 110,32,99,111,109
db 105,108,108,97,115
db 0
;preapos()
qpreapos:
;{
;  keepch(39);
ldc 39
ldl 1
call qkeepch
;  gch();
ldl 1
call qgch
;  while ((ch() != 39) | ((line[lptr - 1] == 92) & (line[lptr - 2] != 92))) {
c369:
ldl 1
ldnl 3743
adc -1
ldl 1
ldnlp 3487
bsub
lb
eqc 92
ldl 1
ldnl 3743
adc -2
ldl 1
ldnlp 3487
bsub
lb
eqc 92
eqc 0
and
ajw -1
stl 0
ldl 2
call qch
eqc 39
eqc 0
ldl 0
ajw 1
or
cj c370
;    if (ch() == 0) {
ldl 1
call qch
eqc 0
cj c371
;      error("Falta un apostrofe");
ldc c368-c372+0
ldpi
c372:
ldl 1
call qerror
;      break;
j c370
;    }
;    keepch(gch());
c371:
ldl 1
call qgch
ldl 1
call qkeepch
;  }
j c369
c370:
;  gch();
ldl 1
call qgch
;  keepch(39);
ldc 39
ldl 1
call qkeepch
;}
ret
c368:
db 70,97,108,116,97
db 32,117,110,32,97
db 112,111,115,116,114
db 111,102,101,0
;precomm()
qprecomm:
;{
;  lptr = lptr + 2;
ldl 1
ldnl 3743
adc 2
ldl 1
stnl 3743
;  while (((ch() == '*') &
c374:
;	  (nch() == '/')) == 0) {
ldl 1
call qnch
eqc 47
ajw -1
stl 0
ldl 2
call qch
eqc 42
ldl 0
ajw 1
and
eqc 0
cj c375
;    if (ch() == 0)
ldl 1
call qch
eqc 0
cj c376
;      in_line();
ldl 1
call qin_line
;    else
j c377
c376:
;      ++lptr;
ldl 1
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
c377:
;    if (eof)
ldl 1
ldnl 3752
cj c378
;      break;
j c375
;  }
c378:
j c374
c375:
;  lptr = lptr + 2;
ldl 1
ldnl 3743
adc 2
ldl 1
stnl 3743
;}
ret
;addmac()
qaddmac:
;{
;  char sname[namesize];
;  int k;
;  if (symname(sname) == 0) {
ajw -6
ldlp 1
ldl 7
call qsymname
eqc 0
cj c380
;    illname();
ldl 7
call qillname
;    kill();
ldl 7
call qkill
;    return;
ajw 6
ret
;  }
;  k = 0;
c380:
ldc 0
stl 0
;  while (putmac(sname[k++]));
c381:
ldl 0
dup
adc 1
stl 0
ldlp 1
bsub
lb
ldl 7
call qputmac
cj c382
j c381
c382:
;  while (ch() == ' ' | ch() == 9)
c383:
ldl 7
call qch
eqc 9
ajw -1
stl 0
ldl 8
call qch
eqc 32
ldl 0
ajw 1
or
cj c384
;    gch();
ldl 7
call qgch
j c383
c384:
;  while (putmac(gch()));
c385:
ldl 7
call qgch
ldl 7
call qputmac
cj c386
j c385
c386:
;  if (macptr >= macmax)
ldc 4095
ldl 7
ldnl 3486
gt
eqc 0
cj c387
;    error("Tabla de macros llena");
ldc c379-c388+0
ldpi
c388:
ldl 7
call qerror
;}
c387:
ajw 6
ret
c379:
db 84,97,98,108,97
db 32,100,101,32,109
db 97,99,114,111,115
db 32,108,108,101,110
db 97,0
;putmac(c)
qputmac:
;  char c;
;{
;  macq[macptr] = c;
ldlp 2
lb
ldl 1
ldnl 3486
ldl 1
ldnlp 2462
bsub
sb
;  if (macptr < macmax)
ldc 4095
ldl 1
ldnl 3486
gt
cj c390
;    macptr++;
ldl 1
ldnlp 3486
dup
ldnl 0
adc 1
rev
stnl 0
;  return c;
c390:
ldlp 2
lb
ret
;}
;findmac(sname)
qfindmac:
;  char *sname;
;{
;  int k;
;  k = 0;
ajw -1
ldc 0
stl 0
;  while (k < macptr) {
c392:
ldl 2
ldnl 3486
ldl 0
gt
cj c393
;    if (astreq(sname, macq + k, namemax)) {
ajw -1
ldc 16
stl 0
ldl 3
ldnlp 2462
ldl 1
bsub
ldl 4
ldl 3
call qastreq
ajw 1
cj c394
;      while (macq[k++]);
c395:
ldl 0
dup
adc 1
stl 0
ldl 2
ldnlp 2462
bsub
lb
cj c396
j c395
c396:
;      return k;
ldl 0
ajw 1
ret
;    }
;    while (macq[k++]);
c394:
c397:
ldl 0
dup
adc 1
stl 0
ldl 2
ldnlp 2462
bsub
lb
cj c398
j c397
c398:
;    while (macq[k++]);
c399:
ldl 0
dup
adc 1
stl 0
ldl 2
ldnlp 2462
bsub
lb
cj c400
j c399
c400:
;  }
j c392
c393:
;  return 0;
ldc 0
ajw 1
ret
;}
;/* Desvia la salida a la consola */
;toconsole()
qtoconsole:
;{
;  saveout = output;
ldl 1
ldnl 3754
ldl 1
stnl 3759
;  output = 0;
ldc 0
ldl 1
stnl 3754
;}
ret
;/* Regresa la salida al archivo */
;tofile()
qtofile:
;{
;  if (saveout)
ldl 1
ldnl 3759
cj c403
;    output = saveout;
ldl 1
ldnl 3759
ldl 1
stnl 3754
;  saveout = 0;
c403:
ldc 0
ldl 1
stnl 3759
;}
ret
;outbyte(c)
qoutbyte:
;  char c;
;{
;  if (c == 0)
ldlp 2
lb
eqc 0
cj c405
;    return 0;
ldc 0
ret
;  if (output) {
c405:
ldl 1
ldnl 3754
cj c406
;    if ((fputc(c, output)) <= 0) {
ldl 1
ldnl 3754
ldlp 2
lb
ldl 1
call qfputc
ldc 0
gt
eqc 0
cj c407
;      closeout();
ldl 1
call qcloseout
;      error("Error al escribir");
ldc c404-c408+0
ldpi
c408:
ldl 1
call qerror
;      abort();
ldl 1
call qabort
;    }
;  } else
c407:
j c409
c406:
;    putchar(c);
ldlp 2
lb
ldl 1
call qputchar
c409:
;  return c;
ldlp 2
lb
ret
;}
c404:
db 69,114,114,111,114
db 32,97,108,32,101
db 115,99,114,105,98
db 105,114,0
;nl()
qnl:
;{
;  outbyte(13);
ldc 13
ldl 1
call qoutbyte
;  outbyte(10);
ldc 10
ldl 1
call qoutbyte
;}
ret
;outstr(ptr)
qoutstr:
;  char *ptr;
;{
;  while (outbyte(*ptr++));
c412:
ldl 2
dup
adc 1
stl 2
lb
ldl 1
call qoutbyte
cj c413
j c412
c413:
;}
ret
;/*
;** Escribe texto destinado al ensamblador
;*/
;outasm(ptr)
qoutasm:
;  char *ptr;
;{
;  while (outbyte(*ptr++));
c415:
ldl 2
dup
adc 1
stl 2
lb
ldl 1
call qoutbyte
cj c416
j c415
c416:
;}
ret
;error(ptr)
qerror:
;  char ptr[];
;{
;  int k;
;  char junk[81];
;  toconsole();
ajw -22
ldl 23
call qtoconsole
;  outstr("L¡nea ");
ldc c417-c418+0
ldpi
c418:
ldl 23
call qoutstr
;  outdec(lineno);
ldl 23
ldnl 3761
ldl 23
call qoutdec
;  outstr(", ");
ldc c417-c419+7
ldpi
c419:
ldl 23
call qoutstr
;  if (infunc == 0)
ldl 23
ldnl 3762
eqc 0
cj c420
;    outbyte('(');
ldc 40
ldl 23
call qoutbyte
;  if (currfn == NULL)
c420:
ldl 23
ldnl 3766
eqc 0
cj c421
;    outstr("comienzo del archivo");
ldc c417-c422+10
ldpi
c422:
ldl 23
call qoutstr
;  else
j c423
c421:
;    outstr(currfn + name);
ldl 23
ldnl 3766
ldl 23
call qoutstr
c423:
;  if (infunc == 0)
ldl 23
ldnl 3762
eqc 0
cj c424
;    outbyte(')');
ldc 41
ldl 23
call qoutbyte
;  outstr(" + ");
c424:
ldc c417-c425+31
ldpi
c425:
ldl 23
call qoutstr
;  outdec(lineno - fnstart);
ldl 23
ldnl 3761
ldl 23
ldnl 3760
diff
ldl 23
call qoutdec
;  outstr(": ");
ldc c417-c426+35
ldpi
c426:
ldl 23
call qoutstr
;  outstr(ptr);
ldl 24
ldl 23
call qoutstr
;  nl();
ldl 23
call qnl
;  outstr(line);
ldl 23
ldnlp 3487
ldl 23
call qoutstr
;  nl();
ldl 23
call qnl
;  k = 0;                /* Busca la posici¢n del error */
ldc 0
stl 21
;  while (k < lptr) {
c427:
ldl 23
ldnl 3743
ldl 21
gt
cj c428
;    if (line[k++] == 9)
ldl 21
dup
adc 1
stl 21
ldl 23
ldnlp 3487
bsub
lb
eqc 9
cj c429
;      outbyte(9);
ldc 9
ldl 23
call qoutbyte
;    else
j c430
c429:
;      outbyte(' ');
ldc 32
ldl 23
call qoutbyte
c430:
;  }
j c427
c428:
;  outbyte('^');
ldc 94
ldl 23
call qoutbyte
;  nl();
ldl 23
call qnl
;  ++errcnt;
ldl 23
ldnlp 3750
dup
ldnl 0
adc 1
rev
stnl 0
;  if (errstop) {
ldl 23
ldnl 3751
cj c431
;    pl("Continuar (Si, No, Pasar de largo) ? ");
ldc c417-c432+38
ldpi
c432:
ldl 23
call qpl
;    gets(junk);
ldlp 0
ldl 23
call qgets
;    k = junk[0];
ldlp 0
lb
stl 21
;    if ((k == 'N') | (k == 'n'))
ldl 21
eqc 78
ldl 21
eqc 110
or
cj c433
;      abort();
ldl 23
call qabort
;    if ((k == 'P') | (k == 'p'))
c433:
ldl 21
eqc 80
ldl 21
eqc 112
or
cj c434
;      errstop = 0;
ldc 0
ldl 23
stnl 3751
;  }
c434:
;  tofile();
c431:
ldl 23
call qtofile
;}
ajw 22
ret
c417:
db 76,161,110,101,97
db 32,0,44,32,0
db 99,111,109,105,101
db 110,122,111,32,100
db 101,108,32,97,114
db 99,104,105,118,111
db 0,32,43,32,0
db 58,32,0,67,111
db 110,116,105,110,117
db 97,114,32,40,83
db 105,44,32,78,111
db 44,32,80,97,115
db 97,114,32,100,101
db 32,108,97,114,103
db 111,41,32,63,32
db 0
;ol(ptr)
qol:
;  char ptr[];
;{
;  ot(ptr);
ldl 2
ldl 1
call qot
;  nl();
ldl 1
call qnl
;}
ret
;ot(ptr)
qot:
;  char ptr[];
;{
;  outasm(ptr);
ldl 2
ldl 1
call qoutasm
;}
ret
;streq(str1, str2)
qstreq:
;  char str1[], str2[];
;{
;  int k;
;  k = 0;
ajw -1
ldc 0
stl 0
;  while (str2[k]) {
c438:
ldl 0
ldl 4
bsub
lb
cj c439
;    if ((str1[k]) != (str2[k]))
ldl 0
ldl 3
bsub
lb
ldl 0
ldl 4
bsub
lb
diff
eqc 0
eqc 0
cj c440
;      return 0;
ldc 0
ajw 1
ret
;    k++;
c440:
ldl 0
adc 1
stl 0
;  }
j c438
c439:
;  return k;
ldl 0
ajw 1
ret
;}
;astreq(str1, str2, len)
qastreq:
;  char str1[], str2[];
;  int len;
;{
;  int k;
;  k = 0;
ajw -1
ldc 0
stl 0
;  while (k < len) {
c442:
ldl 5
ldl 0
gt
cj c443
;    if ((str1[k]) != (str2[k]))
ldl 0
ldl 3
bsub
lb
ldl 0
ldl 4
bsub
lb
diff
eqc 0
eqc 0
cj c444
;      break;
j c443
;    if (str1[k] == 0)
c444:
ldl 0
ldl 3
bsub
lb
eqc 0
cj c445
;      break;
j c443
;    if (str2[k] == 0)
c445:
ldl 0
ldl 4
bsub
lb
eqc 0
cj c446
;      break;
j c443
;    k++;
c446:
ldl 0
adc 1
stl 0
;  }
j c442
c443:
;  if (an(str1[k]))
ldl 0
ldl 3
bsub
lb
ldl 2
call qan
cj c447
;    return 0;
ldc 0
ajw 1
ret
;  if (an(str2[k]))
c447:
ldl 0
ldl 4
bsub
lb
ldl 2
call qan
cj c448
;    return 0;
ldc 0
ajw 1
ret
;  return k;
c448:
ldl 0
ajw 1
ret
;}
;match(lit)
qmatch:
;  char *lit;
;{
;  int k;
;  blanks();
ajw -1
ldl 2
call qblanks
;  if (k = streq(line + lptr, lit)) {
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldl 3
rev
ldl 2
call qstreq
dup
stl 0
cj c450
;    lptr = lptr + k;
ldl 2
ldnl 3743
ldl 0
bsub
ldl 2
stnl 3743
;    return 1;
ldc 1
ajw 1
ret
;  }
;  return 0;
c450:
ldc 0
ajw 1
ret
;}
;amatch(lit, len)
qamatch:
;  char *lit;
;  int len;
;{
;  int k;
;  blanks();
ajw -1
ldl 2
call qblanks
;  if (k = astreq(line + lptr, lit, len)) {
ajw -1
ldl 5
stl 0
ldl 3
ldnlp 3487
ldl 3
ldnl 3743
bsub
ldl 4
rev
ldl 3
call qastreq
ajw 1
dup
stl 0
cj c452
;    lptr = lptr + k;
ldl 2
ldnl 3743
ldl 0
bsub
ldl 2
stnl 3743
;    while (an(ch()))
c453:
ldl 2
call qch
ldl 2
call qan
cj c454
;      inbyte();
ldl 2
call qinbyte
j c453
c454:
;    return 1;
ldc 1
ajw 1
ret
;  }
;  return 0;
c452:
ldc 0
ajw 1
ret
;}
;blanks()
qblanks:
;{
;  while (1) {
c456:
ldc 1
cj c457
;    while (ch() == 0) {
c458:
ldl 1
call qch
eqc 0
cj c459
;      in_line();
ldl 1
call qin_line
;      preprocess();
ldl 1
call qpreprocess
;      if (eof)
ldl 1
ldnl 3752
cj c460
;	break;
j c459
;    }
c460:
j c458
c459:
;    if (ch() == ' ')
ldl 1
call qch
eqc 32
cj c461
;      gch();
ldl 1
call qgch
;    else if (ch() == 9)
j c462
c461:
ldl 1
call qch
eqc 9
cj c463
;      gch();
ldl 1
call qgch
;    else
j c464
c463:
;      return;
ret
c464:
c462:
;  }
j c456
c457:
;}
ret
;outdec(number)
qoutdec:
;  int number;
;{
;  if (number < 0) {
ldc 0
ldl 2
gt
cj c466
;    outbyte('-');
ldc 45
ldl 1
call qoutbyte
;    if (number < -9)
ldc -9
ldl 2
gt
cj c467
;      outdec(-(number / 10));
ldl 2
ldc 10
div
not
adc 1
ldl 1
call qoutdec
;    outbyte(-(number % 10) + '0');
c467:
ldl 2
ldc 10
rem
not
adc 1
adc 48
ldl 1
call qoutbyte
;  } else {
j c468
c466:
;    if (number > 9)
ldl 2
ldc 9
gt
cj c469
;      outdec(number / 10);
ldl 2
ldc 10
div
ldl 1
call qoutdec
;    outbyte((number % 10) + '0');
c469:
ldl 2
ldc 10
rem
adc 48
ldl 1
call qoutbyte
;  }
c468:
;}
ret
;/* Retorna el tama¤o de una cadena. */
;strlen(s)
qstrlen:
;  char *s;
;{
;  char *t;
;  t = s;
ajw -1
ldl 3
stl 0
;  while (*s)
c471:
ldl 3
lb
cj c472
;    s++;
ldl 3
adc 1
stl 3
j c471
c472:
;  return (s - t);
ldl 3
ldl 0
diff
ajw 1
ret
;}
;/* Conversi¢n a m yusculas. */
;raise(c)
qraise:
;  char c;
;{
;  if ((c >= 'a') & (c <= 'z'))
ldc 97
ldlp 2
lb
gt
eqc 0
ldlp 2
lb
ldc 122
gt
eqc 0
and
cj c474
;    c = c - 'a' + 'A';
ldlp 2
lb
adc -32
ldlp 2
sb
;  return (c);
c474:
ldlp 2
lb
ret
;}
;/*
;** Evaluador de Expresiones.
;**
;** por Oscar Toledo Gutierrez.
;**
;** (c) Copyright 1995 Oscar Toledo G.
;*/
;#define N_OR      1
;#define N_XOR     2
;#define N_AND     3
;#define N_IGUAL   4
;#define N_CIGUAL  5
;#define N_MAYOR   6
;#define N_CSUMA   7
;#define N_NULO    8
;#define N_STNL    9
;#define N_SMAYOR  10
;#define N_FUNC    11
;#define N_FUNCI   12
;#define N_PAR     13
;#define N_CD      14
;#define N_CI      15
;#define N_SUMA    16
;#define N_RESTA   17
;#define N_MUL     18
;#define N_DIV     19
;#define N_MOD     20
;#define N_NEG     21
;#define N_COM     22
;#define N_INC     23
;#define N_STL     24
;#define N_PINC    25
;#define N_LDNL    26
;#define N_NOT     27
;#define N_IXP     28
;#define N_APFUNC  29
;#define N_CONST   30
;#define N_LIT     31
;#define N_CBYTE   32
;#define N_CPAL    33
;#define N_LDLP    34
;#define N_LDL     35
;#define N_LDNLP   36
;#define N_GBYTE   37
;#define N_GPAL    38
;#define TAM_ARBOL 128
;int nodo_izq[TAM_ARBOL];
;int nodo_der[TAM_ARBOL];
;int oper[TAM_ARBOL];
;int esp[TAM_ARBOL];
;int regs[TAM_ARBOL];
;int ultimo_nodo;
;int raiz_arbol;
;expression()
qexpression:
;{
;  int lval[2];
;  ultimo_nodo = 0;
ajw -2
ldc 0
ldl 3
stnl 4413
;  if (heir1(lval))
ldlp 0
ldl 3
call qheir1
cj c476
;    rvalue(lval);
ldlp 0
ldl 3
call qrvalue
;  etiqueta(ultimo_nodo);
c476:
ldl 3
ldnl 4413
ldl 3
call qetiqueta
;  raiz_arbol = ultimo_nodo;
ldl 3
ldnl 4413
ldl 3
stnl 4414
;  gen_codigo(ultimo_nodo);
ldl 3
ldnl 4413
ldl 3
call qgen_codigo
;}
ajw 2
ret
;heir1(lval)
qheir1:
;  int lval[];
;{
;  int k, lval2[2];
;  int der;
;  char *ap;
;  k = heir2(lval);
ajw -5
ldl 7
ldl 6
call qheir2
stl 4
;  blanks();
ldl 6
call qblanks
;  if (ch() != '=')
ldl 6
call qch
eqc 61
eqc 0
cj c478
;    return k;
ldl 4
ajw 5
ret
;  ++lptr;
c478:
ldl 6
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;  der = ultimo_nodo;
ldl 6
ldnl 4413
stl 1
;  if (k == 0)
ldl 4
eqc 0
cj c479
;    needlval();
ldl 6
call qneedlval
;  if (heir1(lval2))
c479:
ldlp 2
ldl 6
call qheir1
cj c480
;    rvalue(lval2);
ldlp 2
ldl 6
call qrvalue
;  if (lval[1] == cint)
c480:
ldl 7
ldnl 1
eqc 2
cj c481
;    crea_nodo(N_GPAL, ultimo_nodo, der, 0);
ajw -2
ldl 3
stl 0
ldc 0
stl 1
ldl 8
ldnl 4413
ldc 38
ldl 8
call qcrea_nodo
ajw 2
;  else
j c482
c481:
;    crea_nodo(N_GBYTE, ultimo_nodo, der, 0);
ajw -2
ldl 3
stl 0
ldc 0
stl 1
ldl 8
ldnl 4413
ldc 37
ldl 8
call qcrea_nodo
ajw 2
c482:
;  return 0;
ldc 0
ajw 5
ret
;}
;heir2(lval)
qheir2:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir3(lval);
ajw -4
ldl 6
ldl 5
call qheir3
stl 3
;  blanks();
ldl 5
call qblanks
;  if (ch() != '|')
ldl 5
call qch
eqc 124
eqc 0
cj c484
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c484:
ldl 3
cj c485
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (match("|")) {
c485:
c486:
ldc c483-c488+0
ldpi
c488:
ldl 5
call qmatch
cj c487
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (heir3(lval2))
ldlp 1
ldl 5
call qheir3
cj c489
;      rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;    crea_nodo(N_OR, izq, ultimo_nodo, 0);
c489:
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 1
ldl 7
call qcrea_nodo
ajw 2
;  }
j c486
c487:
;  return 0;
ldc 0
ajw 4
ret
;}
c483:
db 124,0
;heir3(lval)
qheir3:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir4(lval);
ajw -4
ldl 6
ldl 5
call qheir4
stl 3
;  blanks();
ldl 5
call qblanks
;  if (ch() != '^')
ldl 5
call qch
eqc 94
eqc 0
cj c491
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c491:
ldl 3
cj c492
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (match("^")) {
c492:
c493:
ldc c490-c495+0
ldpi
c495:
ldl 5
call qmatch
cj c494
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (heir4(lval2))
ldlp 1
ldl 5
call qheir4
cj c496
;      rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;    crea_nodo(N_XOR, izq, ultimo_nodo, 0);
c496:
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 2
ldl 7
call qcrea_nodo
ajw 2
;  }
j c493
c494:
;  return 0;
ldc 0
ajw 4
ret
;}
c490:
db 94,0
;heir4(lval)
qheir4:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir5(lval);
ajw -4
ldl 6
ldl 5
call qheir5
stl 3
;  blanks();
ldl 5
call qblanks
;  if (ch() != '&')
ldl 5
call qch
eqc 38
eqc 0
cj c498
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c498:
ldl 3
cj c499
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (match("&")) {
c499:
c500:
ldc c497-c502+0
ldpi
c502:
ldl 5
call qmatch
cj c501
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (heir5(lval2))
ldlp 1
ldl 5
call qheir5
cj c503
;      rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;    crea_nodo(N_AND, izq, ultimo_nodo, 0);
c503:
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 3
ldl 7
call qcrea_nodo
ajw 2
;  }
j c500
c501:
;  return 0;
ldc 0
ajw 4
ret
;}
c497:
db 38,0
;heir5(lval) int lval[]; {
qheir5:
;  int k, lval2[2];
;  int izq;
;  k = heir6(lval);
ajw -4
ldl 6
ldl 5
call qheir6
stl 3
;  blanks();
ldl 5
call qblanks
;  if ((streq(line + lptr, "==") == 0) &
;      (streq(line + lptr, "!=") == 0))
ldl 5
ldnlp 3487
ldl 5
ldnl 3743
bsub
ldc c504-c506+3
ldpi
c506:
rev
ldl 5
call qstreq
eqc 0
ajw -1
stl 0
ldl 6
ldnlp 3487
ldl 6
ldnl 3743
bsub
ldc c504-c507+0
ldpi
c507:
rev
ldl 6
call qstreq
eqc 0
ldl 0
ajw 1
and
cj c505
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c505:
ldl 3
cj c508
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (1) {
c508:
c509:
ldc 1
cj c510
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (match("==")) {
ldc c504-c512+6
ldpi
c512:
ldl 5
call qmatch
cj c511
;      if (heir6(lval2))
ldlp 1
ldl 5
call qheir6
cj c513
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if(oper[ultimo_nodo] == N_CONST) {
c513:
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c514
;        if(oper[izq] == N_CONST)
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c515
;          crea_nodo(N_CONST, 0, 0, esp[izq] == esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
diff
eqc 0
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;        else
j c516
c515:
;          crea_nodo(N_CIGUAL, izq, 0, esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 2
ldc 5
ldl 7
call qcrea_nodo
ajw 2
c516:
;      }
;      else if(oper[izq] == N_CONST)
j c517
c514:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c518
;        crea_nodo(N_CIGUAL, ultimo_nodo, 0, esp[izq]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 7
ldnl 4413
ldc 5
ldl 7
call qcrea_nodo
ajw 2
;      else crea_nodo(N_IGUAL, izq, ultimo_nodo, 0);
j c519
c518:
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 4
ldl 7
call qcrea_nodo
ajw 2
c519:
c517:
;    } else if (match("!=")) {
j c520
c511:
ldc c504-c522+9
ldpi
c522:
ldl 5
call qmatch
cj c521
;      if (heir6(lval2))
ldlp 1
ldl 5
call qheir6
cj c523
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if(oper[ultimo_nodo] == N_CONST) {
c523:
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c524
;        if(oper[izq] == N_CONST)
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c525
;          crea_nodo(N_CONST, 0, 0, esp[izq] != esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
diff
eqc 0
eqc 0
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;        else {
j c526
c525:
;          crea_nodo(N_CIGUAL, izq, 0, esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 2
ldc 5
ldl 7
call qcrea_nodo
ajw 2
;          crea_nodo(N_NOT, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 7
ldnl 4413
ldc 27
ldl 7
call qcrea_nodo
ajw 2
;        }
c526:
;      }
;      else if(oper[izq] == N_CONST) {
j c527
c524:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c528
;        crea_nodo(N_CIGUAL, ultimo_nodo, 0, esp[izq]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 7
ldnl 4413
ldc 5
ldl 7
call qcrea_nodo
ajw 2
;        crea_nodo(N_NOT, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 7
ldnl 4413
ldc 27
ldl 7
call qcrea_nodo
ajw 2
;      } else {
j c529
c528:
;        crea_nodo(N_IGUAL, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 4
ldl 7
call qcrea_nodo
ajw 2
;        crea_nodo(N_NOT, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 7
ldnl 4413
ldc 27
ldl 7
call qcrea_nodo
ajw 2
;      }
c529:
c527:
;    } else
j c530
c521:
;      return 0;
ldc 0
ajw 4
ret
c530:
c520:
;  }
j c509
c510:
;}
ajw 4
ret
c504:
db 61,61,0,33,61
db 0,61,61,0,33
db 61,0
;heir6(lval)
qheir6:
;  int lval[];
;{
;  int k;
;  k = heir7(lval);
ajw -1
ldl 3
ldl 2
call qheir7
stl 0
;  blanks();
ldl 2
call qblanks
;  if ((streq(line + lptr, "<") == 0) &
;      (streq(line + lptr, ">") == 0) &
;      (streq(line + lptr, "<=") == 0) &
;      (streq(line + lptr, ">=") == 0))
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c531-c533+7
ldpi
c533:
rev
ldl 2
call qstreq
eqc 0
ajw -1
stl 0
ldl 3
ldnlp 3487
ldl 3
ldnl 3743
bsub
ldc c531-c534+4
ldpi
c534:
rev
ldl 3
call qstreq
eqc 0
ajw -1
stl 0
ldl 4
ldnlp 3487
ldl 4
ldnl 3743
bsub
ldc c531-c535+2
ldpi
c535:
rev
ldl 4
call qstreq
eqc 0
ajw -1
stl 0
ldl 5
ldnlp 3487
ldl 5
ldnl 3743
bsub
ldc c531-c536+0
ldpi
c536:
rev
ldl 5
call qstreq
eqc 0
ldl 0
ajw 1
and
ldl 0
ajw 1
and
ldl 0
ajw 1
and
cj c532
;  return k;
ldl 0
ajw 1
ret
;  if (streq(line + lptr, ">>"))
c532:
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c531-c538+10
ldpi
c538:
rev
ldl 2
call qstreq
cj c537
;    return k;
ldl 0
ajw 1
ret
;  if (streq(line + lptr, "<<"))
c537:
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c531-c540+13
ldpi
c540:
rev
ldl 2
call qstreq
cj c539
;    return k;
ldl 0
ajw 1
ret
;  if (k)
c539:
ldl 0
cj c541
;    rvalue(lval);
ldl 3
ldl 2
call qrvalue
;  while (1) {
c541:
c542:
ldc 1
cj c543
;    if (match("<="))
ldc c531-c545+16
ldpi
c545:
ldl 2
call qmatch
cj c544
;      heir6wrk(1, lval);
ldl 3
ldc 1
ldl 2
call qheir6wrk
;    else if (match(">="))
j c546
c544:
ldc c531-c548+19
ldpi
c548:
ldl 2
call qmatch
cj c547
;      heir6wrk(2, lval);
ldl 3
ldc 2
ldl 2
call qheir6wrk
;    else if (streq(line + lptr, "<") &
j c549
c547:
;            (streq(line + lptr, "<<") == 0)) {
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c531-c551+24
ldpi
c551:
rev
ldl 2
call qstreq
eqc 0
ajw -1
stl 0
ldl 3
ldnlp 3487
ldl 3
ldnl 3743
bsub
ldc c531-c552+22
ldpi
c552:
rev
ldl 3
call qstreq
ldl 0
ajw 1
and
cj c550
;      inbyte();
ldl 2
call qinbyte
;      heir6wrk(3, lval);
ldl 3
ldc 3
ldl 2
call qheir6wrk
;    } else if (streq(line + lptr, ">") &
j c553
c550:
;              (streq(line + lptr, ">>") == 0)) {
ldl 2
ldnlp 3487
ldl 2
ldnl 3743
bsub
ldc c531-c555+29
ldpi
c555:
rev
ldl 2
call qstreq
eqc 0
ajw -1
stl 0
ldl 3
ldnlp 3487
ldl 3
ldnl 3743
bsub
ldc c531-c556+27
ldpi
c556:
rev
ldl 3
call qstreq
ldl 0
ajw 1
and
cj c554
;      inbyte();
ldl 2
call qinbyte
;      heir6wrk(4, lval);
ldl 3
ldc 4
ldl 2
call qheir6wrk
;    } else
j c557
c554:
;      return 0;
ldc 0
ajw 1
ret
c557:
c553:
c549:
c546:
;  }
j c542
c543:
;}
ajw 1
ret
c531:
db 60,0,62,0,60
db 61,0,62,61,0
db 62,62,0,60,60
db 0,60,61,0,62
db 61,0,60,0,60
db 60,0,62,0,62
db 62,0
;heir6wrk(k, lval)
qheir6wrk:
;  int k, lval[];
;{
;  int lval2[2];
;  int izq;
;  izq = ultimo_nodo;
ajw -3
ldl 4
ldnl 4413
stl 0
;  if (heir7(lval2))
ldlp 1
ldl 4
call qheir7
cj c559
;    rvalue(lval2);
ldlp 1
ldl 4
call qrvalue
;  if (cptr = lval[0])
c559:
ldl 6
ldnl 0
dup
ldl 4
stnl 3769
cj c560
;    if (cptr[ident] == pointer) {
ldl 4
ldnl 3769
adc 17
lb
eqc 3
cj c561
;      heir6op(izq, k);
ldl 5
ldl 0
ldl 4
call qheir6op
;      return;
ajw 3
ret
;    }
;  if (cptr = lval2[0])
c561:
c560:
ldl 1
dup
ldl 4
stnl 3769
cj c562
;    if (cptr[ident] == pointer) {
ldl 4
ldnl 3769
adc 17
lb
eqc 3
cj c563
;      heir6op(izq, k);
ldl 5
ldl 0
ldl 4
call qheir6op
;      return;
ajw 3
ret
;    }
;  if(k == 4) {
c563:
c562:
ldl 5
eqc 4
cj c564
;    if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
ldl 0
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 4
ldnl 4413
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c565
;      crea_nodo(N_CONST, 0, 0, esp[izq] > esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 6
ldnlp 4157
wsub
ldnl 0
ldl 6
ldnl 4413
ldl 6
ldnlp 4157
wsub
ldnl 0
gt
stl 1
ldc 0
ldc 30
ldl 6
call qcrea_nodo
ajw 2
;    else
j c566
c565:
;      crea_nodo(N_MAYOR, izq, ultimo_nodo, 0);
ajw -2
ldl 6
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 6
ldl 6
call qcrea_nodo
ajw 2
c566:
;  }
;  else if(k == 3) {
j c567
c564:
ldl 5
eqc 3
cj c568
;    if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
ldl 0
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 4
ldnl 4413
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c569
;      crea_nodo(N_CONST, 0, 0, esp[izq] < esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 6
ldnl 4413
ldl 6
ldnlp 4157
wsub
ldnl 0
ldl 2
ldl 6
ldnlp 4157
wsub
ldnl 0
gt
stl 1
ldc 0
ldc 30
ldl 6
call qcrea_nodo
ajw 2
;    else
j c570
c569:
;      crea_nodo(N_MAYOR, ultimo_nodo, izq, 0);
ajw -2
ldl 2
stl 0
ldc 0
stl 1
ldl 6
ldnl 4413
ldc 6
ldl 6
call qcrea_nodo
ajw 2
c570:
;  }
;  else if(k == 1) {
j c571
c568:
ldl 5
eqc 1
cj c572
;    if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
ldl 0
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 4
ldnl 4413
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c573
;      crea_nodo(N_CONST, 0, 0, esp[izq] <= esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 6
ldnlp 4157
wsub
ldnl 0
ldl 6
ldnl 4413
ldl 6
ldnlp 4157
wsub
ldnl 0
gt
eqc 0
stl 1
ldc 0
ldc 30
ldl 6
call qcrea_nodo
ajw 2
;    else {
j c574
c573:
;      crea_nodo(N_MAYOR, izq, ultimo_nodo, 0);
ajw -2
ldl 6
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 6
ldl 6
call qcrea_nodo
ajw 2
;      crea_nodo(N_NOT, ultimo_nodo, 0);
ajw -1
ldc 0
stl 0
ldl 5
ldnl 4413
ldc 27
ldl 5
call qcrea_nodo
ajw 1
;    }
c574:
;  } else {
j c575
c572:
;    if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
ldl 0
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 4
ldnl 4413
ldl 4
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c576
;      crea_nodo(N_CONST, 0, 0, esp[izq] >= esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 6
ldnl 4413
ldl 6
ldnlp 4157
wsub
ldnl 0
ldl 2
ldl 6
ldnlp 4157
wsub
ldnl 0
gt
eqc 0
stl 1
ldc 0
ldc 30
ldl 6
call qcrea_nodo
ajw 2
;    else {
j c577
c576:
;      crea_nodo(N_MAYOR, ultimo_nodo, izq, 0);
ajw -2
ldl 2
stl 0
ldc 0
stl 1
ldl 6
ldnl 4413
ldc 6
ldl 6
call qcrea_nodo
ajw 2
;      crea_nodo(N_NOT, ultimo_nodo, 0);
ajw -1
ldc 0
stl 0
ldl 5
ldnl 4413
ldc 27
ldl 5
call qcrea_nodo
ajw 1
;    }
c577:
;  }
c575:
c571:
c567:
;}
ajw 3
ret
;heir6op(izq, k)
qheir6op:
;  int izq, k;
;{
;  if(k == 4) crea_nodo(N_SMAYOR, izq, ultimo_nodo, 0);
ldl 3
eqc 4
cj c579
ajw -2
ldl 3
ldnl 4413
stl 0
ldc 0
stl 1
ldl 4
ldc 10
ldl 3
call qcrea_nodo
ajw 2
;  else if(k == 3) crea_nodo(N_SMAYOR, ultimo_nodo, izq, 0);
j c580
c579:
ldl 3
eqc 3
cj c581
ajw -2
ldl 4
stl 0
ldc 0
stl 1
ldl 3
ldnl 4413
ldc 10
ldl 3
call qcrea_nodo
ajw 2
;  else if(k == 1) {
j c582
c581:
ldl 3
eqc 1
cj c583
;    crea_nodo(N_SMAYOR, izq, ultimo_nodo, 0);
ajw -2
ldl 3
ldnl 4413
stl 0
ldc 0
stl 1
ldl 4
ldc 10
ldl 3
call qcrea_nodo
ajw 2
;    crea_nodo(N_NOT, ultimo_nodo, 0);
ajw -1
ldc 0
stl 0
ldl 2
ldnl 4413
ldc 27
ldl 2
call qcrea_nodo
ajw 1
;  } else {
j c584
c583:
;    crea_nodo(N_SMAYOR, ultimo_nodo, izq, 0);
ajw -2
ldl 4
stl 0
ldc 0
stl 1
ldl 3
ldnl 4413
ldc 10
ldl 3
call qcrea_nodo
ajw 2
;    crea_nodo(N_NOT, ultimo_nodo, 0);
ajw -1
ldc 0
stl 0
ldl 2
ldnl 4413
ldc 27
ldl 2
call qcrea_nodo
ajw 1
;  }
c584:
c582:
c580:
;}
ret
;heir7(lval)
qheir7:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir8(lval);
ajw -4
ldl 6
ldl 5
call qheir8
stl 3
;  blanks();
ldl 5
call qblanks
;  if ((streq(line + lptr, ">>") == 0) &
;      (streq(line + lptr, "<<") == 0))
ldl 5
ldnlp 3487
ldl 5
ldnl 3743
bsub
ldc c585-c587+3
ldpi
c587:
rev
ldl 5
call qstreq
eqc 0
ajw -1
stl 0
ldl 6
ldnlp 3487
ldl 6
ldnl 3743
bsub
ldc c585-c588+0
ldpi
c588:
rev
ldl 6
call qstreq
eqc 0
ldl 0
ajw 1
and
cj c586
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c586:
ldl 3
cj c589
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (1) {
c589:
c590:
ldc 1
cj c591
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (match(">>")) {
ldc c585-c593+6
ldpi
c593:
ldl 5
call qmatch
cj c592
;      if (heir8(lval2))
ldlp 1
ldl 5
call qheir8
cj c594
;	rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c594:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c595
;        crea_nodo(N_CONST, 0, 0, esp[izq] >> esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
shr
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else
j c596
c595:
;        crea_nodo(N_CD, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 14
ldl 7
call qcrea_nodo
ajw 2
c596:
;    } else if (match("<<")) {
j c597
c592:
ldc c585-c599+9
ldpi
c599:
ldl 5
call qmatch
cj c598
;      if (heir8(lval2))
ldlp 1
ldl 5
call qheir8
cj c600
;	rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c600:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c601
;        crea_nodo(N_CONST, 0, 0, esp[izq] << esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
shl
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else
j c602
c601:
;        crea_nodo(N_CI, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 15
ldl 7
call qcrea_nodo
ajw 2
c602:
;    } else
j c603
c598:
;      return 0;
ldc 0
ajw 4
ret
c603:
c597:
;  }
j c590
c591:
;}
ajw 4
ret
c585:
db 62,62,0,60,60
db 0,62,62,0,60
db 60,0
;heir8(lval)
qheir8:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir9(lval);
ajw -4
ldl 6
ldl 5
call qheir9
stl 3
;  blanks();
ldl 5
call qblanks
;  if ((ch() != '+') & (ch() != '-'))
ldl 5
call qch
eqc 45
eqc 0
ajw -1
stl 0
ldl 6
call qch
eqc 43
eqc 0
ldl 0
ajw 1
and
cj c605
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c605:
ldl 3
cj c606
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (1) {
c606:
c607:
ldc 1
cj c608
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (match("+")) {
ldc c604-c610+0
ldpi
c610:
ldl 5
call qmatch
cj c609
;      if (heir9(lval2))
ldlp 1
ldl 5
call qheir9
cj c611
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if (cptr = lval[0])
c611:
ldl 6
ldnl 0
dup
ldl 5
stnl 3769
cj c612
;        if ((cptr[ident] == pointer) &
;            (cptr[type] == cint))
ldl 5
ldnl 3769
adc 17
lb
eqc 3
ldl 5
ldnl 3769
adc 18
lb
eqc 2
and
cj c613
;          doublereg();
ldl 5
call qdoublereg
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c613:
c612:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c614
;        crea_nodo(N_CONST, 0, 0, esp[izq] + esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
bsub
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else if(oper[ultimo_nodo] == N_CONST)
j c615
c614:
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c616
;        crea_nodo(N_CSUMA, izq, 0, esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 2
ldc 7
ldl 7
call qcrea_nodo
ajw 2
;      else if(oper[izq] == N_CONST)
j c617
c616:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c618
;        crea_nodo(N_CSUMA, ultimo_nodo, 0, esp[izq]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 7
ldnl 4413
ldc 7
ldl 7
call qcrea_nodo
ajw 2
;      else
j c619
c618:
;        crea_nodo(N_SUMA, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 16
ldl 7
call qcrea_nodo
ajw 2
c619:
c617:
c615:
;    } else if (match("-")) {
j c620
c609:
ldc c604-c622+2
ldpi
c622:
ldl 5
call qmatch
cj c621
;      if (heir9(lval2))
ldlp 1
ldl 5
call qheir9
cj c623
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if (cptr = lval[0])
c623:
ldl 6
ldnl 0
dup
ldl 5
stnl 3769
cj c624
;        if ((cptr[ident] == pointer) &
;            (cptr[type] == cint))
ldl 5
ldnl 3769
adc 17
lb
eqc 3
ldl 5
ldnl 3769
adc 18
lb
eqc 2
and
cj c625
;          doublereg();
ldl 5
call qdoublereg
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c625:
c624:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c626
;        crea_nodo(N_CONST, 0, 0, esp[izq] - esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
diff
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else if(oper[ultimo_nodo] == N_CONST)
j c627
c626:
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c628
;        crea_nodo(N_CSUMA, izq, 0, -esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
not
adc 1
stl 1
ldl 2
ldc 7
ldl 7
call qcrea_nodo
ajw 2
;      else
j c629
c628:
;        crea_nodo(N_RESTA, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 17
ldl 7
call qcrea_nodo
ajw 2
c629:
c627:
;    } else
j c630
c621:
;      return 0;
ldc 0
ajw 4
ret
c630:
c620:
;  }
j c607
c608:
;}
ajw 4
ret
c604:
db 43,0,45,0
;heir9(lval)
qheir9:
;  int lval[];
;{
;  int k, lval2[2];
;  int izq;
;  k = heir10(lval);
ajw -4
ldl 6
ldl 5
call qheir10
stl 3
;  blanks();
ldl 5
call qblanks
;  if ((ch() != '*') & (ch() != '/') &
;      (ch() != '%'))
ldl 5
call qch
eqc 37
eqc 0
ajw -1
stl 0
ldl 6
call qch
eqc 47
eqc 0
ajw -1
stl 0
ldl 7
call qch
eqc 42
eqc 0
ldl 0
ajw 1
and
ldl 0
ajw 1
and
cj c632
;    return k;
ldl 3
ajw 4
ret
;  if (k)
c632:
ldl 3
cj c633
;    rvalue(lval);
ldl 6
ldl 5
call qrvalue
;  while (1) {
c633:
c634:
ldc 1
cj c635
;    izq = ultimo_nodo;
ldl 5
ldnl 4413
stl 0
;    if (match("*")) {
ldc c631-c637+0
ldpi
c637:
ldl 5
call qmatch
cj c636
;      if (heir10(lval2))
ldlp 1
ldl 5
call qheir10
cj c638
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c638:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c639
;        crea_nodo(N_CONST, 0, 0, esp[izq] * esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
prod
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else
j c640
c639:
;        crea_nodo(N_MUL, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 18
ldl 7
call qcrea_nodo
ajw 2
c640:
;    } else if (match("/")) {
j c641
c636:
ldc c631-c643+2
ldpi
c643:
ldl 5
call qmatch
cj c642
;      if (heir10(lval2))
ldlp 1
ldl 5
call qheir10
cj c644
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c644:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c645
;        crea_nodo(N_CONST, 0, 0, esp[izq] / esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
div
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else
j c646
c645:
;        crea_nodo(N_DIV, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 19
ldl 7
call qcrea_nodo
ajw 2
c646:
;    } else if (match("%")) {
j c647
c642:
ldc c631-c649+4
ldpi
c649:
ldl 5
call qmatch
cj c648
;      if (heir10(lval2))
ldlp 1
ldl 5
call qheir10
cj c650
;        rvalue(lval2);
ldlp 1
ldl 5
call qrvalue
;      if((oper[izq] == N_CONST) & (oper[ultimo_nodo] == N_CONST))
c650:
ldl 0
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
ldl 5
ldnl 4413
ldl 5
ldnlp 4029
wsub
ldnl 0
eqc 30
and
cj c651
;        crea_nodo(N_CONST, 0, 0, esp[izq] % esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 2
ldl 7
ldnlp 4157
wsub
ldnl 0
ldl 7
ldnl 4413
ldl 7
ldnlp 4157
wsub
ldnl 0
rem
stl 1
ldc 0
ldc 30
ldl 7
call qcrea_nodo
ajw 2
;      else
j c652
c651:
;        crea_nodo(N_MOD, izq, ultimo_nodo, 0);
ajw -2
ldl 7
ldnl 4413
stl 0
ldc 0
stl 1
ldl 2
ldc 20
ldl 7
call qcrea_nodo
ajw 2
c652:
;    } else
j c653
c648:
;      return 0;
ldc 0
ajw 4
ret
c653:
c647:
c641:
;  }
j c634
c635:
;}
ajw 4
ret
c631:
db 42,0,47,0,37
db 0
;heir10(lval)
qheir10:
;  int lval[];
;{
;  int k;
;  if (match("++")) {
ajw -1
ldc c654-c656+0
ldpi
c656:
ldl 2
call qmatch
cj c655
;    if (heir10(lval) == 0)
ldl 3
ldl 2
call qheir10
eqc 0
cj c657
;      needlval();
ldl 2
call qneedlval
;    heir10inc(lval);
c657:
ldl 3
ldl 2
call qheir10inc
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("--")) {
j c658
c655:
ldc c654-c660+3
ldpi
c660:
ldl 2
call qmatch
cj c659
;    if (heir10(lval) == 0)
ldl 3
ldl 2
call qheir10
eqc 0
cj c661
;      needlval();
ldl 2
call qneedlval
;    heir10dec(lval);
c661:
ldl 3
ldl 2
call qheir10dec
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("-")) {
j c662
c659:
ldc c654-c664+6
ldpi
c664:
ldl 2
call qmatch
cj c663
;    if(heir10(lval))
ldl 3
ldl 2
call qheir10
cj c665
;      rvalue(lval);
ldl 3
ldl 2
call qrvalue
;    if(oper[ultimo_nodo] == N_CONST)
c665:
ldl 2
ldnl 4413
ldl 2
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c666
;      esp[ultimo_nodo] = -esp[ultimo_nodo];
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
ldnl 0
not
adc 1
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
stnl 0
;    else
j c667
c666:
;      crea_nodo(N_NEG, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 4
ldnl 4413
ldc 21
ldl 4
call qcrea_nodo
ajw 2
c667:
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("~")) {
j c668
c663:
ldc c654-c670+8
ldpi
c670:
ldl 2
call qmatch
cj c669
;    if(heir10(lval))
ldl 3
ldl 2
call qheir10
cj c671
;      rvalue(lval);
ldl 3
ldl 2
call qrvalue
;    if(oper[ultimo_nodo] == N_CONST)
c671:
ldl 2
ldnl 4413
ldl 2
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c672
;      esp[ultimo_nodo] = ~esp[ultimo_nodo];
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
ldnl 0
not
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
stnl 0
;    else
j c673
c672:
;      crea_nodo(N_COM, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 4
ldnl 4413
ldc 22
ldl 4
call qcrea_nodo
ajw 2
c673:
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("!")) {
j c674
c669:
ldc c654-c676+10
ldpi
c676:
ldl 2
call qmatch
cj c675
;    if(heir10(lval))
ldl 3
ldl 2
call qheir10
cj c677
;      rvalue(lval);
ldl 3
ldl 2
call qrvalue
;    if(oper[ultimo_nodo] == N_CONST)
c677:
ldl 2
ldnl 4413
ldl 2
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c678
;      esp[ultimo_nodo] = !esp[ultimo_nodo];
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
ldnl 0
eqc 0
ldl 2
ldnl 4413
ldl 2
ldnlp 4157
wsub
stnl 0
;    else
j c679
c678:
;      crea_nodo(N_NOT, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 4
ldnl 4413
ldc 27
ldl 4
call qcrea_nodo
ajw 2
c679:
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("*")) {
j c680
c675:
ldc c654-c682+12
ldpi
c682:
ldl 2
call qmatch
cj c681
;    heir10as(lval);
ldl 3
ldl 2
call qheir10as
;    return 1;
ldc 1
ajw 1
ret
;  } else if (match("&")) {
j c683
c681:
ldc c654-c685+14
ldpi
c685:
ldl 2
call qmatch
cj c684
;    if(heir10(lval) == 0) {
ldl 3
ldl 2
call qheir10
eqc 0
cj c686
;      error("Direcci¢n ilegal");
ldc c654-c687+16
ldpi
c687:
ldl 2
call qerror
;      return 0;
ldc 0
ajw 1
ret
;    }
;    if (lval[1])
c686:
ldl 3
ldnl 1
cj c688
;      return 0;
ldc 0
ajw 1
ret
;    heir10at(lval);
c688:
ldl 3
ldl 2
call qheir10at
;    return 0;
ldc 0
ajw 1
ret
;  }
;  k = heir11(lval);
c684:
c683:
c680:
c674:
c668:
c662:
c658:
ldl 3
ldl 2
call qheir11
stl 0
;  if (match("++")) {
ldc c654-c690+33
ldpi
c690:
ldl 2
call qmatch
cj c689
;    if (k == 0)
ldl 0
eqc 0
cj c691
;      needlval();
ldl 2
call qneedlval
;    heir10id(lval);
c691:
ldl 3
ldl 2
call qheir10id
;    return 0;
ldc 0
ajw 1
ret
;  } else if (match("--")) {
j c692
c689:
ldc c654-c694+36
ldpi
c694:
ldl 2
call qmatch
cj c693
;    if (k == 0)
ldl 0
eqc 0
cj c695
;      needlval();
ldl 2
call qneedlval
;    heir10di(lval);
c695:
ldl 3
ldl 2
call qheir10di
;    return 0;
ldc 0
ajw 1
ret
;  } else
j c696
c693:
;    return k;
ldl 0
ajw 1
ret
c696:
c692:
;}
ajw 1
ret
c654:
db 43,43,0,45,45
db 0,45,0,126,0
db 33,0,42,0,38
db 0,68,105,114,101
db 99,99,105,162,110
db 32,105,108,101,103
db 97,108,0,43,43
db 0,45,45,0
;heir10inc(lval)
qheir10inc:
;  int lval[];
;{
;  char *ptr;
;  ptr = lval[0];
ajw -1
ldl 3
ldnl 0
stl 0
;  if ((ptr[ident] == pointer) &
;      (ptr[type] == cint))
ldl 0
adc 17
lb
eqc 3
ldl 0
adc 18
lb
eqc 2
and
cj c698
;    crea_nodo(N_INC, ultimo_nodo, 0, 4);
ajw -2
ldc 0
stl 0
ldc 4
stl 1
ldl 4
ldnl 4413
ldc 23
ldl 4
call qcrea_nodo
ajw 2
;  else
j c699
c698:
;    crea_nodo(N_INC, ultimo_nodo, 0, 1);
ajw -2
ldc 0
stl 0
ldc 1
stl 1
ldl 4
ldnl 4413
ldc 23
ldl 4
call qcrea_nodo
ajw 2
c699:
;}
ajw 1
ret
;heir10dec(lval)
qheir10dec:
;  int lval[];
;{
;  char *ptr;
;  ptr = lval[0];
ajw -1
ldl 3
ldnl 0
stl 0
;  if ((ptr[ident] == pointer) &
;      (ptr[type] == cint))
ldl 0
adc 17
lb
eqc 3
ldl 0
adc 18
lb
eqc 2
and
cj c701
;    crea_nodo(N_INC, ultimo_nodo, 0, -4);
ajw -2
ldc 0
stl 0
ldc -4
stl 1
ldl 4
ldnl 4413
ldc 23
ldl 4
call qcrea_nodo
ajw 2
;  else
j c702
c701:
;    crea_nodo(N_INC, ultimo_nodo, 0, -1);
ajw -2
ldc 0
stl 0
ldc -1
stl 1
ldl 4
ldnl 4413
ldc 23
ldl 4
call qcrea_nodo
ajw 2
c702:
;}
ajw 1
ret
;heir10as(lval)
qheir10as:
;  int lval[];
;{
;  int k;
;  char *ptr;
;  k = heir10(lval);
ajw -2
ldl 4
ldl 3
call qheir10
stl 1
;  if (k)
ldl 1
cj c704
;    rvalue(lval);
ldl 4
ldl 3
call qrvalue
;  lval[1] = cint;
c704:
ldc 2
ldl 4
stnl 1
;  if (ptr = lval[0])
ldl 4
ldnl 0
dup
stl 0
cj c705
;    lval[1] = ptr[type];
ldl 0
adc 18
lb
ldl 4
stnl 1
;  lval[0] = 0;
c705:
ldc 0
ldl 4
stnl 0
;}
ajw 2
ret
;heir10at(lval)
qheir10at:
;  int lval[];
;{
;  char *ptr;
;  lval[1] = ptr[type];
ajw -1
ldl 0
adc 18
lb
ldl 3
stnl 1
;}
ajw 1
ret
;heir10id(lval)
qheir10id:
;  int lval[];
;{
;  char *ptr;
;  ptr = lval[0];
ajw -1
ldl 3
ldnl 0
stl 0
;  if ((ptr[ident] == pointer) &
;      (ptr[type] == cint))
ldl 0
adc 17
lb
eqc 3
ldl 0
adc 18
lb
eqc 2
and
cj c708
;    crea_nodo(N_PINC, ultimo_nodo, 0, 4);
ajw -2
ldc 0
stl 0
ldc 4
stl 1
ldl 4
ldnl 4413
ldc 25
ldl 4
call qcrea_nodo
ajw 2
;  else
j c709
c708:
;    crea_nodo(N_PINC, ultimo_nodo, 0, 1);
ajw -2
ldc 0
stl 0
ldc 1
stl 1
ldl 4
ldnl 4413
ldc 25
ldl 4
call qcrea_nodo
ajw 2
c709:
;}
ajw 1
ret
;heir10di(lval)
qheir10di:
;  int lval[];
;{
;  char *ptr;
;  ptr = lval[0];
ajw -1
ldl 3
ldnl 0
stl 0
;  if ((ptr[ident] == pointer) &
;      (ptr[type] == cint))
ldl 0
adc 17
lb
eqc 3
ldl 0
adc 18
lb
eqc 2
and
cj c711
;    crea_nodo(N_PINC, ultimo_nodo, 0, -4);
ajw -2
ldc 0
stl 0
ldc -4
stl 1
ldl 4
ldnl 4413
ldc 25
ldl 4
call qcrea_nodo
ajw 2
;  else
j c712
c711:
;    crea_nodo(N_PINC, ultimo_nodo, 0, -1);
ajw -2
ldc 0
stl 0
ldc -1
stl 1
ldl 4
ldnl 4413
ldc 25
ldl 4
call qcrea_nodo
ajw 2
c712:
;}
ajw 1
ret
;heir11(lval)
qheir11:
;  int lval[];
;{
;  int k, etiq, izq;
;  char *ptr;
;  int lval2[2];
;  k = primary(lval);
ajw -6
ldl 8
ldl 7
call qprimary
stl 5
;  ptr = lval[0];
ldl 8
ldnl 0
stl 2
;  blanks();
ldl 7
call qblanks
;  if ((ch() == '[') | (ch() == '('))
ldl 7
call qch
eqc 40
ajw -1
stl 0
ldl 8
call qch
eqc 91
ldl 0
ajw 1
or
cj c714
;    while (1) {
c715:
ldc 1
cj c716
;      if (match("[")) {
ldc c713-c718+0
ldpi
c718:
ldl 7
call qmatch
cj c717
;        if (ptr == 0) {
ldl 2
eqc 0
cj c719
;          error("No se puede usar subscripto");
ldc c713-c720+2
ldpi
c720:
ldl 7
call qerror
;          junk();
ldl 7
call qjunk
;          needbrack("]");
ldc c713-c721+30
ldpi
c721:
ldl 7
call qneedbrack
;          return 0;
ldc 0
ajw 6
ret
;        } else if (ptr[ident] == pointer)
j c722
c719:
ldl 2
adc 17
lb
eqc 3
cj c723
;          rvalue(lval);
ldl 8
ldl 7
call qrvalue
;        else if (ptr[ident] != array) {
j c724
c723:
ldl 2
adc 17
lb
eqc 2
eqc 0
cj c725
;          error("No se puede usar subscripto");
ldc c713-c726+32
ldpi
c726:
ldl 7
call qerror
;          k = 0;
ldc 0
stl 5
;        }
;        izq = ultimo_nodo;
c725:
c724:
c722:
ldl 7
ldnl 4413
stl 3
;        if (heir1(lval2))
ldlp 0
ldl 7
call qheir1
cj c727
;          rvalue(lval2);
ldlp 0
ldl 7
call qrvalue
;        needbrack("]");
c727:
ldc c713-c728+60
ldpi
c728:
ldl 7
call qneedbrack
;        if (ptr[type] == cint) {
ldl 2
adc 18
lb
eqc 2
cj c729
;          if (oper[ultimo_nodo] == N_CONST)
ldl 7
ldnl 4413
ldl 7
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c730
;            crea_nodo(N_LDNLP, izq, 0, esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 9
ldnl 4413
ldl 9
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 5
ldc 36
ldl 9
call qcrea_nodo
ajw 2
;          else
j c731
c730:
;            crea_nodo(N_IXP, ultimo_nodo, izq, 0);
ajw -2
ldl 5
stl 0
ldc 0
stl 1
ldl 9
ldnl 4413
ldc 28
ldl 9
call qcrea_nodo
ajw 2
c731:
;        } else {
j c732
c729:
;          if (oper[ultimo_nodo] == N_CONST)
ldl 7
ldnl 4413
ldl 7
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c733
;            crea_nodo(N_CSUMA, izq, 0, esp[ultimo_nodo]);
ajw -2
ldc 0
stl 0
ldl 9
ldnl 4413
ldl 9
ldnlp 4157
wsub
ldnl 0
stl 1
ldl 5
ldc 7
ldl 9
call qcrea_nodo
ajw 2
;          else
j c734
c733:
;            crea_nodo(N_SUMA, ultimo_nodo, izq, 0);
ajw -2
ldl 5
stl 0
ldc 0
stl 1
ldl 9
ldnl 4413
ldc 16
ldl 9
call qcrea_nodo
ajw 2
c734:
;        }
c732:
;        lval[1] = ptr[type];
ldl 2
adc 18
lb
ldl 8
stnl 1
;        k = 1;
ldc 1
stl 5
;      } else if (match("(")) {
j c735
c717:
ldc c713-c737+62
ldpi
c737:
ldl 7
call qmatch
cj c736
;        if (ptr == 0)
ldl 2
eqc 0
cj c738
;          callfunction(0);
ldc 0
ldl 7
call qcallfunction
;        else if (ptr[ident] != function) {
j c739
c738:
ldl 2
adc 17
lb
eqc 4
eqc 0
cj c740
;          rvalue(lval);
ldl 8
ldl 7
call qrvalue
;          callfunction(0);
ldc 0
ldl 7
call qcallfunction
;        } else
j c741
c740:
;          callfunction(ptr);
ldl 2
ldl 7
call qcallfunction
c741:
c739:
;        k = lval[0] = 0;
ldc 0
dup
ldl 8
stnl 0
stl 5
;      } else
j c742
c736:
;        return k;
ldl 5
ajw 6
ret
c742:
c735:
;    }
j c715
c716:
;  if (ptr == 0)
c714:
ldl 2
eqc 0
cj c743
;    return k;
ldl 5
ajw 6
ret
;  if (ptr[ident] == function) {
c743:
ldl 2
adc 17
lb
eqc 4
cj c744
;    crea_nodo(N_APFUNC, 0, 0, ptr);
ajw -2
ldc 0
stl 0
ldl 4
stl 1
ldc 0
ldc 29
ldl 9
call qcrea_nodo
ajw 2
;    return 0;
ldc 0
ajw 6
ret
;  }
;  return k;
c744:
ldl 5
ajw 6
ret
;}
c713:
db 91,0,78,111,32
db 115,101,32,112,117
db 101,100,101,32,117
db 115,97,114,32,115
db 117,98,115,99,114
db 105,112,116,111,0
db 93,0,78,111,32
db 115,101,32,112,117
db 101,100,101,32,117
db 115,97,114,32,115
db 117,98,115,99,114
db 105,112,116,111,0
db 93,0,40,0
;primary(lval)
qprimary:
;  int lval[];
;{
;  char *ptr, sname[namesize];
;  int num[1];
;  int k;
;  if (match("(")) {
ajw -8
ldc c745-c747+0
ldpi
c747:
ldl 9
call qmatch
cj c746
;    k = heir1(lval);
ldl 10
ldl 9
call qheir1
stl 0
;    needbrack(")");
ldc c745-c748+2
ldpi
c748:
ldl 9
call qneedbrack
;    return k;
ldl 0
ajw 8
ret
;  }
;  if (symname(sname)) {
c746:
ldlp 2
ldl 9
call qsymname
cj c749
;    if (ptr = findloc(sname)) {
ldlp 2
ldl 9
call qfindloc
dup
stl 7
cj c750
;      getloc(ptr);
ldl 7
ldl 9
call qgetloc
;      lval[0] = ptr;
ldl 7
ldl 10
stnl 0
;      lval[1] = ptr[type];
ldl 7
adc 18
lb
ldl 10
stnl 1
;      if (ptr[ident] == pointer)
ldl 7
adc 17
lb
eqc 3
cj c751
;        lval[1] = cint;
ldc 2
ldl 10
stnl 1
;      if (ptr[ident] == array)
c751:
ldl 7
adc 17
lb
eqc 2
cj c752
;        return 0;
ldc 0
ajw 8
ret
;      return 1;
c752:
ldc 1
ajw 8
ret
;    }
;    if (ptr = findglb(sname)) {
c750:
ldlp 2
ldl 9
call qfindglb
dup
stl 7
cj c753
;      if (ptr[ident] != function) {
ldl 7
adc 17
lb
eqc 4
eqc 0
cj c754
;        outpos(0, ptr);
ldl 7
ldc 0
ldl 9
call qoutpos
;        lval[0] = ptr;
ldl 7
ldl 10
stnl 0
;        lval[1] = ptr[type];
ldl 7
adc 18
lb
ldl 10
stnl 1
;        if (ptr[ident] == pointer)
ldl 7
adc 17
lb
eqc 3
cj c755
;          lval[1] = cint;
ldc 2
ldl 10
stnl 1
;        if (ptr[ident] == array)
c755:
ldl 7
adc 17
lb
eqc 2
cj c756
;          return 0;
ldc 0
ajw 8
ret
;        return 1;
c756:
ldc 1
ajw 8
ret
;      }
;    } else
c754:
j c757
c753:
;      ptr = addglb(sname, function, cint, 0);
ajw -2
ldc 2
stl 0
ldc 0
stl 1
ldc 4
ldlp 4
ldl 11
call qaddglb
ajw 2
stl 7
c757:
;    lval[0] = ptr;
ldl 7
ldl 10
stnl 0
;    lval[1] = 0;
ldc 0
ldl 10
stnl 1
;    return 0;
ldc 0
ajw 8
ret
;  }
;  if (constant(num))
c749:
ldlp 1
ldl 9
call qconstant
cj c758
;    return (lval[0] = lval[1] = 0);
ldc 0
dup
ldl 10
stnl 1
dup
ldl 10
stnl 0
ajw 8
ret
;  else {
j c759
c758:
;    error("Expresion invalida");
ldc c745-c760+4
ldpi
c760:
ldl 9
call qerror
;    crea_nodo(N_CONST, 0, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldc 0
ldc 30
ldl 11
call qcrea_nodo
ajw 2
;    junk();
ldl 9
call qjunk
;    return 0;
ldc 0
ajw 8
ret
;  }
c759:
;}
ajw 8
ret
c745:
db 40,0,41,0,69
db 120,112,114,101,115
db 105,111,110,32,105
db 110,118,97,108,105
db 100,97,0
;/*
;** Compila una llamada a una funcion
;**
;** Invocada por "heir11", esta funcion llama a la funcion
;** nombra o a una funcion indirecta.
;*/
;callfunction(ptr)
qcallfunction:
;  char *ptr;
;{
;  int lval[2];
;  int anterior, primero;
;  int izq;
;  anterior = primero = 0;
ajw -5
ldc 0
dup
stl 1
stl 2
;  blanks();             /* Ya ha sido tomado el parentesis inicial */
ldl 6
call qblanks
;  if (ptr == 0)
ldl 7
eqc 0
cj c762
;    izq = ultimo_nodo;  /* Llamada indirecta */
ldl 6
ldnl 4413
stl 0
;  while (streq(line + lptr, ")") == 0) {
c762:
c763:
ldl 6
ldnlp 3487
ldl 6
ldnl 3743
bsub
ldc c761-c765+0
ldpi
c765:
rev
ldl 6
call qstreq
eqc 0
cj c764
;    if (endst())
ldl 6
call qendst
cj c766
;      break;
j c764
;    if (heir1(lval))
c766:
ldlp 3
ldl 6
call qheir1
cj c767
;      rvalue(lval);     /* Obtiene un argumento */
ldlp 3
ldl 6
call qrvalue
;    crea_nodo(N_PAR, ultimo_nodo, 0, 0);
c767:
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 8
ldnl 4413
ldc 13
ldl 8
call qcrea_nodo
ajw 2
;    if (primero == 0)
ldl 1
eqc 0
cj c768
;      primero = ultimo_nodo;
ldl 6
ldnl 4413
stl 1
;    if (anterior != 0)
c768:
ldl 2
eqc 0
eqc 0
cj c769
;      esp[anterior] = ultimo_nodo;
ldl 6
ldnl 4413
ldl 2
ldl 6
ldnlp 4157
wsub
stnl 0
;    anterior = ultimo_nodo;
c769:
ldl 6
ldnl 4413
stl 2
;    if (match(",") == 0)
ldc c761-c771+2
ldpi
c771:
ldl 6
call qmatch
eqc 0
cj c770
;      break;
j c764
;    blanks();
c770:
ldl 6
call qblanks
;  }
j c763
c764:
;  needbrack(")");
ldc c761-c772+4
ldpi
c772:
ldl 6
call qneedbrack
;  if (ptr == 0)
ldl 7
eqc 0
cj c773
;    crea_nodo(N_FUNCI, primero, 0, izq);
ajw -2
ldc 0
stl 0
ldl 2
stl 1
ldl 3
ldc 12
ldl 8
call qcrea_nodo
ajw 2
;  else
j c774
c773:
;    crea_nodo(N_FUNC, primero, 0, ptr);
ajw -2
ldc 0
stl 0
ldl 9
stl 1
ldl 3
ldc 11
ldl 8
call qcrea_nodo
ajw 2
c774:
;}
ajw 5
ret
c761:
db 41,0,44,0,41
db 0
;rvalue(lval)
qrvalue:
;  int lval[];
;{
;  if (lval[1] == cchar)
ldl 2
ldnl 1
eqc 1
cj c776
;    crea_nodo(N_CBYTE, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 3
ldnl 4413
ldc 32
ldl 3
call qcrea_nodo
ajw 2
;  else
j c777
c776:
;    crea_nodo(N_CPAL, ultimo_nodo, 0, 0);
ajw -2
ldc 0
stl 0
ldc 0
stl 1
ldl 3
ldnl 4413
ldc 33
ldl 3
call qcrea_nodo
ajw 2
c777:
;}
ret
;/* Carga la direcci¢n de una variable local */
;getloc(sym)
qgetloc:
;  char *sym;
;{
;  crea_nodo(N_LDLP, 0, 0, ((sym[offset] & 255) +
;			   ((sym[offset + 1] & 255) << 8) +
;			   ((sym[offset + 2] & 255) << 16) +
;			   ((sym[offset + 3] & 255) << 24)));
ajw -2
ldc 0
stl 0
ldl 4
adc 20
lb
ldc 255
and
ldl 4
adc 21
lb
ldc 255
and
ldc 8
shl
bsub
ldl 4
adc 22
lb
ldc 255
and
ldc 16
shl
bsub
ldl 4
adc 23
lb
ldc 255
and
ldc 24
shl
bsub
stl 1
ldc 0
ldc 34
ldl 3
call qcrea_nodo
ajw 2
;}
ret
;/* Carga la dir. de las variables estaticas */
;enlace()
qenlace:
;{
;  crea_nodo(N_LDL, 0, 0, 1);
ajw -2
ldc 0
stl 0
ldc 1
stl 1
ldc 0
ldc 35
ldl 3
call qcrea_nodo
ajw 2
;}
ret
;/* Operaciones con memoria global */
;outpos(tipo, var)
qoutpos:
;  int tipo;
;  char *var;
;{
;  int j;
;  j = (var[offset] & 255) +
ajw -1
;    ((var[offset + 1] & 255) << 8) +
;    ((var[offset + 2] & 255) << 16) +
;    ((var[offset + 3] & 255) << 24);
ldl 4
adc 20
lb
ldc 255
and
ldl 4
adc 21
lb
ldc 255
and
ldc 8
shl
bsub
ldl 4
adc 22
lb
ldc 255
and
ldc 16
shl
bsub
ldl 4
adc 23
lb
ldc 255
and
ldc 24
shl
bsub
stl 0
;  enlace();
ldl 2
call qenlace
;  crea_nodo(N_LDNLP, ultimo_nodo, 0, j);
ajw -2
ldc 0
stl 0
ldl 2
stl 1
ldl 4
ldnl 4413
ldc 36
ldl 4
call qcrea_nodo
ajw 2
;}
ajw 1
ret
;/* Multiplica por palabra el registro primario */
;doublereg()
qdoublereg:
;{
;  if(oper[ultimo_nodo] == N_CONST)
ldl 1
ldnl 4413
ldl 1
ldnlp 4029
wsub
ldnl 0
eqc 30
cj c782
;    esp[ultimo_nodo] = esp[ultimo_nodo] * 4;
ldl 1
ldnl 4413
ldl 1
ldnlp 4157
wsub
ldnl 0
ldc 4
prod
ldl 1
ldnl 4413
ldl 1
ldnlp 4157
wsub
stnl 0
;  else {
j c783
c782:
;    crea_nodo(N_CONST, 0, 0, 4);
ajw -2
ldc 0
stl 0
ldc 4
stl 1
ldc 0
ldc 30
ldl 3
call qcrea_nodo
ajw 2
;    crea_nodo(N_MUL, ultimo_nodo - 1, ultimo_nodo, 0);
ajw -2
ldl 3
ldnl 4413
stl 0
ldc 0
stl 1
ldl 3
ldnl 4413
adc -1
ldc 18
ldl 3
call qcrea_nodo
ajw 2
;  }
c783:
;}
ret
;test(label)
qtest:
;  int label;
;{
;  needbrack("(");
ldc c784-c785+0
ldpi
c785:
ldl 1
call qneedbrack
;  usaexpr = SI;
ldc 1
ldl 1
stnl 3772
;  expression();
ldl 1
call qexpression
;  needbrack(")");
ldc c784-c786+2
ldpi
c786:
ldl 1
call qneedbrack
;  testjump(label);
ldl 2
ldl 1
call qtestjump
;}
ret
c784:
db 40,0,41,0
;constant(val)
qconstant:
;  int val[];
;{
;  if (number(val))
ldl 2
ldl 1
call qnumber
cj c788
;    crea_nodo(N_CONST, 0, 0, val[0]);
ajw -2
ldc 0
stl 0
ldl 4
ldnl 0
stl 1
ldc 0
ldc 30
ldl 3
call qcrea_nodo
ajw 2
;  else if (pstr(val))
j c789
c788:
ldl 2
ldl 1
call qpstr
cj c790
;    crea_nodo(N_CONST, 0, 0, val[0]);
ajw -2
ldc 0
stl 0
ldl 4
ldnl 0
stl 1
ldc 0
ldc 30
ldl 3
call qcrea_nodo
ajw 2
;  else if (qstr(val))
j c791
c790:
ldl 2
ldl 1
call qqstr
cj c792
;    crea_nodo(N_LIT, 0, 0, val[0]);
ajw -2
ldc 0
stl 0
ldl 4
ldnl 0
stl 1
ldc 0
ldc 31
ldl 3
call qcrea_nodo
ajw 2
;  else
j c793
c792:
;    return 0;
ldc 0
ret
c793:
c791:
c789:
;  return 1;
ldc 1
ret
;}
;isxdigit(c) char c; {
qisxdigit:
;  return (((c >= '0') & (c <= '9')) |
;          ((c >= 'A') & (c <= 'F')) |
;          ((c >= 'a') & (c <= 'f')));
ldc 97
ldlp 2
lb
gt
eqc 0
ldlp 2
lb
ldc 102
gt
eqc 0
and
ajw -1
stl 0
ldc 65
ldlp 3
lb
gt
eqc 0
ldlp 3
lb
ldc 70
gt
eqc 0
and
ajw -1
stl 0
ldc 48
ldlp 4
lb
gt
eqc 0
ldlp 4
lb
ldc 57
gt
eqc 0
and
ldl 0
ajw 1
or
ldl 0
ajw 1
or
ret
;}
;number(val)
qnumber:
;  int val[];
;{
;  int k, minus, base;
;  char c;
;  k = minus = 1;
ajw -4
ldc 1
dup
stl 2
stl 3
;  while (k) {
c796:
ldl 3
cj c797
;    k = 0;
ldc 0
stl 3
;    if (match("+"))
ldc c795-c799+0
ldpi
c799:
ldl 5
call qmatch
cj c798
;      k = 1;
ldc 1
stl 3
;    if (match("-")) {
c798:
ldc c795-c801+2
ldpi
c801:
ldl 5
call qmatch
cj c800
;      minus = -minus;
ldl 2
not
adc 1
stl 2
;      k = 1;
ldc 1
stl 3
;    }
;  }
c800:
j c796
c797:
;  if (numeric(ch()) == 0)
ldl 5
call qch
ldl 5
call qnumeric
eqc 0
cj c802
;    return 0;
ldc 0
ajw 4
ret
;  if(ch() == '0') {
c802:
ldl 5
call qch
eqc 48
cj c803
;    while(ch() == '0') gch();
c804:
ldl 5
call qch
eqc 48
cj c805
ldl 5
call qgch
j c804
c805:
;    if(raise(ch()) == 'X') {
ldl 5
call qch
ldl 5
call qraise
eqc 88
cj c806
;      gch();
ldl 5
call qgch
;      while(isxdigit(ch())) {
c807:
ldl 5
call qch
ldl 5
call qisxdigit
cj c808
;        c = raise(gch()) - '0';
ldl 5
call qgch
ldl 5
call qraise
adc -48
ldlp 0
sb
;        if(c > 9) c = c - 7;
ldlp 0
lb
ldc 9
gt
cj c809
ldlp 0
lb
adc -7
ldlp 0
sb
;        k = (k << 4) | c;
c809:
ldl 3
ldc 4
shl
ldlp 0
lb
or
stl 3
;      }
j c807
c808:
;    } else {
j c810
c806:
;      while ((ch() >= '0') & (ch() <= '7'))
c811:
ldl 5
call qch
ldc 55
gt
eqc 0
ajw -1
stl 0
ldl 6
call qch
ldc 48
rev
gt
eqc 0
ldl 0
ajw 1
and
cj c812
;        k = k * 8 + (gch() - '0');
ldl 5
call qgch
adc -48
ldl 3
ldc 8
prod
bsub
stl 3
j c811
c812:
;    }
c810:
;  } else {
j c813
c803:
;    while (numeric(ch()))
c814:
ldl 5
call qch
ldl 5
call qnumeric
cj c815
;      k = k * 10 + (gch() - '0');
ldl 5
call qgch
adc -48
ldl 3
ldc 10
prod
bsub
stl 3
j c814
c815:
;  }
c813:
;  if (minus < 0)
ldc 0
ldl 2
gt
cj c816
;    k = -k;
ldl 3
not
adc 1
stl 3
;  val[0] = k;
c816:
ldl 3
ldl 6
stnl 0
;  return 1;
ldc 1
ajw 4
ret
;}
c795:
db 43,0,45,0
;pstr(val)
qpstr:
;  int val[];
;{
;  int k;
;  k = 0;
ajw -1
ldc 0
stl 0
;  if (match("'") == 0)
ldc c817-c819+0
ldpi
c819:
ldl 2
call qmatch
eqc 0
cj c818
;    return 0;
ldc 0
ajw 1
ret
;  while (ch() != 39)
c818:
c820:
ldl 2
call qch
eqc 39
eqc 0
cj c821
;    k = (k & 255) * 256 + (litchar() & 255);
ldl 2
call qlitchar
ldc 255
and
ldl 0
ldc 255
and
ldc 256
prod
bsub
stl 0
j c820
c821:
;  ++lptr;
ldl 2
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;  val[0] = k;
ldl 0
ldl 3
stnl 0
;  return 1;
ldc 1
ajw 1
ret
;}
c817:
db 39,0
;qstr(val)
qqstr:
;  int val[];
;{
;  char c;
;  if (match(quote) == 0)
ajw -1
ldl 2
ldnlp 3768
ldl 2
call qmatch
eqc 0
cj c823
;    return 0;
ldc 0
ajw 1
ret
;  val[0] = litptr;
c823:
ldl 2
ldnl 2461
ldl 3
stnl 0
;  while (ch() != '"') {
c824:
ldl 2
call qch
eqc 34
eqc 0
cj c825
;    if (ch() == 0)
ldl 2
call qch
eqc 0
cj c826
;      break;
j c825
;    if (litptr >= litmax) {
c826:
ldc 1023
ldl 2
ldnl 2461
gt
eqc 0
cj c827
;      error("Espacio de almacenamiento de cadenas agotado");
ldc c822-c828+0
ldpi
c828:
ldl 2
call qerror
;    while (match(quote) == 0)
c829:
ldl 2
ldnlp 3768
ldl 2
call qmatch
eqc 0
cj c830
;      if (gch() == 0)
ldl 2
call qgch
eqc 0
cj c831
;        break;
j c830
;      return 1;
c831:
j c829
c830:
ldc 1
ajw 1
ret
;    }
;    litq[litptr++] = litchar();
c827:
ldl 2
ldnlp 2461
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 2
ldnlp 2205
bsub
ajw -1
stl 0
ldl 3
call qlitchar
dup
ldl 0
ajw 1
sb
;  }
j c824
c825:
;  gch();
ldl 2
call qgch
;  litq[litptr++] = 0;
ldl 2
ldnlp 2461
dup
ldnl 0
dup
adc 1
pop
pop
stnl 0
ldl 2
ldnlp 2205
bsub
ldc 0
rev
sb
;  return 1;
ldc 1
ajw 1
ret
;}
c822:
db 69,115,112,97,99
db 105,111,32,100,101
db 32,97,108,109,97
db 99,101,110,97,109
db 105,101,110,116,111
db 32,100,101,32,99
db 97,100,101,110,97
db 115,32,97,103,111
db 116,97,100,111,0
;litchar()
qlitchar:
;{
;  int i, oct;
;  if ((ch() != 92) | (nch() == 0))
ajw -2
ldl 3
call qnch
eqc 0
ajw -1
stl 0
ldl 4
call qch
eqc 92
eqc 0
ldl 0
ajw 1
or
cj c833
;    return gch();
ldl 3
call qgch
ajw 2
ret
;  gch();
c833:
ldl 3
call qgch
;  if (ch() == 'n') {
ldl 3
call qch
eqc 110
cj c834
;    ++lptr;
ldl 3
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;    return 10;
ldc 10
ajw 2
ret
;  }
;  if (ch() == 't') {
c834:
ldl 3
call qch
eqc 116
cj c835
;    ++lptr;
ldl 3
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;    return 9;
ldc 9
ajw 2
ret
;  }
;  if (ch() == 'b') {
c835:
ldl 3
call qch
eqc 98
cj c836
;    ++lptr;
ldl 3
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;    return 8;
ldc 8
ajw 2
ret
;  }
;  if (ch() == 'f') {
c836:
ldl 3
call qch
eqc 102
cj c837
;    ++lptr;
ldl 3
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;    return 12;
ldc 12
ajw 2
ret
;  }
;  if (ch() == 'r') {
c837:
ldl 3
call qch
eqc 114
cj c838
;    ++lptr;
ldl 3
ldnlp 3743
dup
ldnl 0
adc 1
rev
stnl 0
;    return 13;
ldc 13
ajw 2
ret
;  }
;  i = 3;
c838:
ldc 3
stl 1
;  oct = 0;
ldc 0
stl 0
;  while ((i-- > 0) & (ch() >= '0') & (ch() <= '7'))
c839:
ldl 3
call qch
ldc 55
gt
eqc 0
ajw -1
stl 0
ldl 4
call qch
ldc 48
rev
gt
eqc 0
ldl 2
dup
adc -1
stl 2
ldc 0
gt
and
ldl 0
ajw 1
and
cj c840
;    oct = (oct << 3) + gch() - '0';
ldl 3
call qgch
ldl 0
ldc 3
shl
bsub
adc -48
stl 0
j c839
c840:
;  if (i == 2)
ldl 1
eqc 2
cj c841
;    return gch();
ldl 3
call qgch
ajw 2
ret
;  else
j c842
c841:
;    return oct;
ldl 0
ajw 2
ret
c842:
;}
ajw 2
ret
;crea_nodo(op, izq, der, val)
qcrea_nodo:
;  int op, izq, der, val;
;{
;  if(op == N_CSUMA) {
ldl 2
eqc 7
cj c844
;    if(oper[izq] == N_CSUMA) {
ldl 3
ldl 1
ldnlp 4029
wsub
ldnl 0
eqc 7
cj c845
;      val = val + esp[izq];
ldl 3
ldl 1
ldnlp 4157
wsub
ldnl 0
ldl 5
bsub
stl 5
;      izq = nodo_izq[izq];
ldl 3
ldl 1
ldnlp 3773
wsub
ldnl 0
stl 3
;    }
;  }
c845:
;  else if(op == N_LDNLP) {
j c846
c844:
ldl 2
eqc 36
cj c847
;    if(oper[izq] == N_LDNLP) {
ldl 3
ldl 1
ldnlp 4029
wsub
ldnl 0
eqc 36
cj c848
;      val = val + esp[izq];
ldl 3
ldl 1
ldnlp 4157
wsub
ldnl 0
ldl 5
bsub
stl 5
;      izq = nodo_izq[izq];
ldl 3
ldl 1
ldnlp 3773
wsub
ldnl 0
stl 3
;    }
;    else if(oper[izq] == N_LDLP) {
j c849
c848:
ldl 3
ldl 1
ldnlp 4029
wsub
ldnl 0
eqc 34
cj c850
;      val = val + esp[izq];
ldl 3
ldl 1
ldnlp 4157
wsub
ldnl 0
ldl 5
bsub
stl 5
;      izq = 0;
ldc 0
stl 3
;      op = N_LDLP;
ldc 34
stl 2
;    }
;  }
c850:
c849:
;  ++ultimo_nodo;
c847:
c846:
ldl 1
ldnlp 4413
dup
ldnl 0
adc 1
rev
stnl 0
;  if(ultimo_nodo == TAM_ARBOL) {
ldl 1
ldnl 4413
eqc 128
cj c851
;    error("Expresion muy compleja");
ldc c843-c852+0
ldpi
c852:
ldl 1
call qerror
;    abort();
ldl 1
call qabort
;  }
;  nodo_izq[ultimo_nodo] = izq;
c851:
ldl 3
ldl 1
ldnl 4413
ldl 1
ldnlp 3773
wsub
stnl 0
;  nodo_der[ultimo_nodo] = der;
ldl 4
ldl 1
ldnl 4413
ldl 1
ldnlp 3901
wsub
stnl 0
;  oper[ultimo_nodo] = op;
ldl 2
ldl 1
ldnl 4413
ldl 1
ldnlp 4029
wsub
stnl 0
;  esp[ultimo_nodo] = val;
ldl 5
ldl 1
ldnl 4413
ldl 1
ldnlp 4157
wsub
stnl 0
;  regs[ultimo_nodo] = 0;
ldc 0
ldl 1
ldnl 4413
ldl 1
ldnlp 4285
wsub
stnl 0
;}
ret
c843:
db 69,120,112,114,101
db 115,105,111,110,32
db 109,117,121,32,99
db 111,109,112,108,101
db 106,97,0
;etiqueta(nodo)
qetiqueta:
;  int nodo;
;{
;  int min, max;
;  if (nodo_izq[nodo])
ajw -2
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
cj c854
;    etiqueta(nodo_izq[nodo]);
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
ldl 3
call qetiqueta
;  if (nodo_der[nodo])
c854:
ldl 4
ldl 3
ldnlp 3901
wsub
ldnl 0
cj c855
;    etiqueta(nodo_der[nodo]);
ldl 4
ldl 3
ldnlp 3901
wsub
ldnl 0
ldl 3
call qetiqueta
;  if ((oper[nodo] == N_FUNCI) | (oper[nodo] == N_PAR))
c855:
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 12
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 13
or
cj c856
;    if (esp[nodo])
ldl 4
ldl 3
ldnlp 4157
wsub
ldnl 0
cj c857
;      etiqueta(esp[nodo]);
ldl 4
ldl 3
ldnlp 4157
wsub
ldnl 0
ldl 3
call qetiqueta
;  if ((oper[nodo] == N_FUNCI) | (oper[nodo] == N_FUNC) |
c857:
c856:
;      (oper[nodo] == N_GBYTE) | (oper[nodo] == N_GPAL))
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 12
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 11
or
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 37
or
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 38
or
cj c858
;    regs[nodo] = 3;
ldc 3
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;  else if ((oper[nodo] == N_INC) | (oper[nodo] == N_PINC)) {
j c859
c858:
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 23
ldl 4
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 25
or
cj c860
;    regs[nodo] = 3;
ldc 3
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;    if (regs[nodo_izq[nodo]] == 1)
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
ldl 3
ldnlp 4285
wsub
ldnl 0
eqc 1
cj c861
;      if (oper[nodo_izq[nodo]] == N_LDLP)
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
ldl 3
ldnlp 4029
wsub
ldnl 0
eqc 34
cj c862
;	regs[nodo] = 2;
ldc 2
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;  } else if (nodo_izq[nodo] == 0)
c862:
c861:
j c863
c860:
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
eqc 0
cj c864
;    regs[nodo] = 1;
ldc 1
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;  else if (nodo_der[nodo] == 0)
j c865
c864:
ldl 4
ldl 3
ldnlp 3901
wsub
ldnl 0
eqc 0
cj c866
;    regs[nodo] = regs[nodo_izq[nodo]];
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
ldl 3
ldnlp 4285
wsub
ldnl 0
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;  else {
j c867
c866:
;    min = regs[nodo_izq[nodo]];
ldl 4
ldl 3
ldnlp 3773
wsub
ldnl 0
ldl 3
ldnlp 4285
wsub
ldnl 0
stl 1
;    max = regs[nodo_der[nodo]];
ldl 4
ldl 3
ldnlp 3901
wsub
ldnl 0
ldl 3
ldnlp 4285
wsub
ldnl 0
stl 0
;    if (min > max)
ldl 1
ldl 0
gt
cj c868
;      max = min;
ldl 1
stl 0
;    else if (min == max)
j c869
c868:
ldl 1
ldl 0
diff
eqc 0
cj c870
;      max = max + 1;
ldl 0
adc 1
stl 0
;    regs[nodo] = max;
c870:
c869:
ldl 0
ldl 4
ldl 3
ldnlp 4285
wsub
stnl 0
;  }
c867:
c865:
c863:
c859:
;}
ajw 2
ret
;gen_oper(oper, rev)
qgen_oper:
;  int oper, rev;
;{
;  if (oper == N_OR)
ldl 2
eqc 1
cj c872
;    ol("or");
ldc c871-c873+0
ldpi
c873:
ldl 1
call qol
;  else if (oper == N_XOR)
j c874
c872:
ldl 2
eqc 2
cj c875
;    ol("xor");
ldc c871-c876+3
ldpi
c876:
ldl 1
call qol
;  else if (oper == N_AND)
j c877
c875:
ldl 2
eqc 3
cj c878
;    ol("and");
ldc c871-c879+7
ldpi
c879:
ldl 1
call qol
;  else if (oper == N_IGUAL) {
j c880
c878:
ldl 2
eqc 4
cj c881
;    ol("diff");
ldc c871-c882+11
ldpi
c882:
ldl 1
call qol
;    ol("eqc 0");
ldc c871-c883+16
ldpi
c883:
ldl 1
call qol
;  } else if (oper == N_SUMA)
j c884
c881:
ldl 2
eqc 16
cj c885
;    ol("bsub");
ldc c871-c886+22
ldpi
c886:
ldl 1
call qol
;  else if (oper == N_MUL)
j c887
c885:
ldl 2
eqc 18
cj c888
;    ol("prod");
ldc c871-c889+27
ldpi
c889:
ldl 1
call qol
;  else if (oper == N_NEG) {
j c890
c888:
ldl 2
eqc 21
cj c891
;    ol("not");
ldc c871-c892+32
ldpi
c892:
ldl 1
call qol
;    ol("adc 1");
ldc c871-c893+36
ldpi
c893:
ldl 1
call qol
;  } else if (oper == N_COM)
j c894
c891:
ldl 2
eqc 22
cj c895
;    ol("not");
ldc c871-c896+42
ldpi
c896:
ldl 1
call qol
;  else if (oper == N_NOT)
j c897
c895:
ldl 2
eqc 27
cj c898
;    ol("eqc 0");
ldc c871-c899+46
ldpi
c899:
ldl 1
call qol
;  else if (oper == N_CBYTE)
j c900
c898:
ldl 2
eqc 32
cj c901
;    ol("lb");
ldc c871-c902+52
ldpi
c902:
ldl 1
call qol
;  else if (oper == N_CPAL)
j c903
c901:
ldl 2
eqc 33
cj c904
;    ol("ldnl 0");
ldc c871-c905+55
ldpi
c905:
ldl 1
call qol
;  else if (oper == N_SMAYOR) {
j c906
c904:
ldl 2
eqc 10
cj c907
;    if (rev == 0)
ldl 3
eqc 0
cj c908
;      ol("rev");
ldc c871-c909+62
ldpi
c909:
ldl 1
call qol
;    ol("mint");
c908:
ldc c871-c910+66
ldpi
c910:
ldl 1
call qol
;    ol("xor");
ldc c871-c911+71
ldpi
c911:
ldl 1
call qol
;    ol("rev");
ldc c871-c912+75
ldpi
c912:
ldl 1
call qol
;    ol("mint");
ldc c871-c913+79
ldpi
c913:
ldl 1
call qol
;    ol("xor");
ldc c871-c914+84
ldpi
c914:
ldl 1
call qol
;    ol("gt");
ldc c871-c915+88
ldpi
c915:
ldl 1
call qol
;  } else {
j c916
c907:
;    if (rev)
ldl 3
cj c917
;      ol("rev");
ldc c871-c918+91
ldpi
c918:
ldl 1
call qol
;    if (oper == N_MAYOR)
c917:
ldl 2
eqc 6
cj c919
;      ol("gt");
ldc c871-c920+95
ldpi
c920:
ldl 1
call qol
;    else if (oper == N_CD)
j c921
c919:
ldl 2
eqc 14
cj c922
;      ol("shr");
ldc c871-c923+98
ldpi
c923:
ldl 1
call qol
;    else if (oper == N_CI)
j c924
c922:
ldl 2
eqc 15
cj c925
;      ol("shl");
ldc c871-c926+102
ldpi
c926:
ldl 1
call qol
;    else if (oper == N_RESTA)
j c927
c925:
ldl 2
eqc 17
cj c928
;      ol("diff");
ldc c871-c929+106
ldpi
c929:
ldl 1
call qol
;    else if (oper == N_DIV)
j c930
c928:
ldl 2
eqc 19
cj c931
;      ol("div");
ldc c871-c932+111
ldpi
c932:
ldl 1
call qol
;    else if (oper == N_MOD)
j c933
c931:
ldl 2
eqc 20
cj c934
;      ol("rem");
ldc c871-c935+115
ldpi
c935:
ldl 1
call qol
;    else if (oper == N_IXP)
j c936
c934:
ldl 2
eqc 28
cj c937
;      ol("wsub");
ldc c871-c938+119
ldpi
c938:
ldl 1
call qol
;  }
c937:
c936:
c933:
c930:
c927:
c924:
c921:
c916:
c906:
c903:
c900:
c897:
c894:
c890:
c887:
c884:
c880:
c877:
c874:
;}
ret
c871:
db 111,114,0,120,111
db 114,0,97,110,100
db 0,100,105,102,102
db 0,101,113,99,32
db 48,0,98,115,117
db 98,0,112,114,111
db 100,0,110,111,116
db 0,97,100,99,32
db 49,0,110,111,116
db 0,101,113,99,32
db 48,0,108,98,0
db 108,100,110,108,32
db 48,0,114,101,118
db 0,109,105,110,116
db 0,120,111,114,0
db 114,101,118,0,109
db 105,110,116,0,120
db 111,114,0,103,116
db 0,114,101,118,0
db 103,116,0,115,104
db 114,0,115,104,108
db 0,100,105,102,102
db 0,100,105,118,0
db 114,101,109,0,119
db 115,117,98,0
;gen_codigo(nodo)
qgen_codigo:
;  int nodo;
;{
;  int temp, conteo, pals, par, rev, op, req, reqres;
;  int regb, regc;
;  if((nodo != raiz_arbol) | (usaexpr == SI)) reqres = SI;
ajw -10
ldl 12
ldl 11
ldnl 4414
diff
eqc 0
eqc 0
ldl 11
ldnl 3772
eqc 1
or
cj c940
ldc 1
stl 2
;  else reqres = NO;
j c941
c940:
ldc 0
stl 2
c941:
;  op = oper[nodo];
ldl 12
ldl 11
ldnlp 4029
wsub
ldnl 0
stl 4
;  if ((op == N_FUNC) | (op == N_FUNCI)) {
ldl 4
eqc 11
ldl 4
eqc 12
or
cj c942
;    pals = conteo = 0;
ldc 0
dup
stl 8
stl 7
;    regb = regc = 0;
ldc 0
dup
stl 0
stl 1
;    temp = nodo_izq[nodo];
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
stl 9
;    while (temp) {
c943:
ldl 9
cj c944
;      if(regb == 0) regb = nodo_izq[temp];
ldl 1
eqc 0
cj c945
ldl 9
ldl 11
ldnlp 3773
wsub
ldnl 0
stl 1
;      else if(regc == 0) regc = nodo_izq[temp];
j c946
c945:
ldl 0
eqc 0
cj c947
ldl 9
ldl 11
ldnlp 3773
wsub
ldnl 0
stl 0
;      else {
j c948
c947:
;        ++pals;
ldl 7
adc 1
stl 7
;        ++conteo;
ldl 8
adc 1
stl 8
;      }
c948:
c946:
;      temp = esp[temp];
ldl 9
ldl 11
ldnlp 4157
wsub
ldnl 0
stl 9
;    }
j c943
c944:
;    Zsp = modstk(Zsp - pals);
ldl 11
ldnl 3747
ldl 7
diff
ldl 11
call qmodstk
ldl 11
stnl 3747
;    if(conteo) {
ldl 8
cj c949
;      temp = esp[esp[nodo_izq[nodo]]];
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
ldnlp 4157
wsub
ldnl 0
stl 9
;      par = 0;
ldc 0
stl 6
;      while (conteo--) {
c950:
ldl 8
dup
adc -1
stl 8
cj c951
;        gen_codigo(nodo_izq[temp]);
ldl 9
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;        ins("stl ", par++);
ldl 6
dup
adc 1
stl 6
ldc c939-c952+0
ldpi
c952:
ldl 11
call qins
;        temp = esp[temp];
ldl 9
ldl 11
ldnlp 4157
wsub
ldnl 0
stl 9
;      }
j c950
c951:
;    }
;    if (oper[nodo] == N_FUNC) {
c949:
ldl 12
ldl 11
ldnlp 4029
wsub
ldnl 0
eqc 11
cj c953
;      if(regc == 0) {
ldl 0
eqc 0
cj c954
;        if(regb) gen_codigo(regb);
ldl 1
cj c955
ldl 1
ldl 11
call qgen_codigo
;        }
c955:
;      else {
j c956
c954:
;        if ((regs[regc] >= regs[regb]) &
;            (regs[regb] < 3)) {
ldl 1
ldl 11
ldnlp 4285
wsub
ldnl 0
ldl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
gt
eqc 0
ldl 1
ldl 11
ldnlp 4285
wsub
ldnl 0
ldc 3
rev
gt
and
cj c957
;          gen_codigo(regc);
ldl 0
ldl 11
call qgen_codigo
;          gen_codigo(regb);
ldl 1
ldl 11
call qgen_codigo
;        } else if ((regs[regb] > regs[regc]) &
j c958
c957:
;                   (regs[regc] < 3)) {
ldl 1
ldl 11
ldnlp 4285
wsub
ldnl 0
ldl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
gt
ldl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldc 3
rev
gt
and
cj c959
;          gen_codigo(regb);
ldl 1
ldl 11
call qgen_codigo
;          gen_codigo(regc);
ldl 0
ldl 11
call qgen_codigo
;          ol("rev");
ldc c939-c960+5
ldpi
c960:
ldl 11
call qol
;        } else {
j c961
c959:
;          gen_codigo(regb);
ldl 1
ldl 11
call qgen_codigo
;          zpush();
ldl 11
call qzpush
;          gen_codigo(regc);
ldl 0
ldl 11
call qgen_codigo
;          zpop();
ldl 11
call qzpop
;        }
c961:
c958:
;      }
c956:
;      ins("ldl ", 1 - Zsp);
ldc 1
ldl 11
ldnl 3747
diff
ldc c939-c962+9
ldpi
c962:
ldl 11
call qins
;      zcall(esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
call qzcall
;    } else {
j c963
c953:
;      Zsp = modstk(Zsp - 4);
ldl 11
ldnl 3747
adc -4
ldl 11
call qmodstk
ldl 11
stnl 3747
;      if(regb) {
ldl 1
cj c964
;        gen_codigo(regb);
ldl 1
ldl 11
call qgen_codigo
;        ol("stl 2");
ldc c939-c965+14
ldpi
c965:
ldl 11
call qol
;        }
;      if(regc) {
c964:
ldl 0
cj c966
;        gen_codigo(regc);
ldl 0
ldl 11
call qgen_codigo
;        ol("stl 3");
ldc c939-c967+20
ldpi
c967:
ldl 11
call qol
;        }
;      gen_codigo(esp[nodo]);
c966:
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
call qgen_codigo
;      ins("ldl ", 1 - Zsp);
ldc 1
ldl 11
ldnl 3747
diff
ldc c939-c968+26
ldpi
c968:
ldl 11
call qins
;      ol("ldc 3");
ldc c939-c969+31
ldpi
c969:
ldl 11
call qol
;      ol("ldpi");
ldc c939-c970+37
ldpi
c970:
ldl 11
call qol
;      ol("stl 0");
ldc c939-c971+42
ldpi
c971:
ldl 11
call qol
;      ol("stl 1");
ldc c939-c972+48
ldpi
c972:
ldl 11
call qol
;      ol("gcall");
ldc c939-c973+54
ldpi
c973:
ldl 11
call qol
;      Zsp = Zsp + 4;
ldl 11
ldnl 3747
adc 4
ldl 11
stnl 3747
;    }
c963:
;    Zsp = modstk(Zsp + pals);
ldl 11
ldnl 3747
ldl 7
bsub
ldl 11
call qmodstk
ldl 11
stnl 3747
;    return;
ajw 10
ret
;  }
;  if ((op == N_GBYTE) | (op == N_GPAL)) {
c942:
ldl 4
eqc 37
ldl 4
eqc 38
or
cj c974
;    if(reqres) req = 2;
ldl 2
cj c975
ldc 2
stl 3
;    else req = 3;
j c976
c975:
ldc 3
stl 3
c976:
;    if (regs[nodo_der[nodo]] < req) {
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldl 3
rev
gt
cj c977
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      if(reqres) ol("dup");
ldl 2
cj c978
ldc c939-c979+60
ldpi
c979:
ldl 11
call qol
;      if ((op == N_GPAL) & (oper[nodo_der[nodo]] == N_LDLP))
c978:
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
ldnl 0
eqc 34
ldl 4
eqc 38
and
cj c980
;	oper[nodo_der[nodo]] = N_STL;
ldc 24
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      else if ((op == N_GPAL) & (oper[nodo_der[nodo]] == N_LDNLP))
j c981
c980:
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
ldnl 0
eqc 36
ldl 4
eqc 38
and
cj c982
;	oper[nodo_der[nodo]] = N_STNL;
ldc 9
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      else {
j c983
c982:
;	gen_codigo(nodo_der[nodo]);
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;	if(op == N_GPAL)
ldl 4
eqc 38
cj c984
;          ol("stnl 0");
ldc c939-c985+64
ldpi
c985:
ldl 11
call qol
;        else
j c986
c984:
;          ol("sb");
ldc c939-c987+71
ldpi
c987:
ldl 11
call qol
c986:
;        return;
ajw 10
ret
;      }
c983:
c981:
;      gen_codigo(nodo_der[nodo]);
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;      return;
ajw 10
ret
;    }
;    gen_codigo(nodo_der[nodo]);
c977:
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;    if(reqres) req = SI;
ldl 2
cj c988
ldc 1
stl 3
;    else if (regs[nodo_izq[nodo]] < 3) req = NO;
j c989
c988:
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldc 3
rev
gt
cj c990
ldc 0
stl 3
;    else req = SI;
j c991
c990:
ldc 1
stl 3
c991:
c989:
;    if(req) {
ldl 3
cj c992
;      zpush();
ldl 11
call qzpush
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      ol("dup");
ldc c939-c993+74
ldpi
c993:
ldl 11
call qol
;      zpop();
ldl 11
call qzpop
;    } else {
j c994
c992:
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      ol("rev");
ldc c939-c995+78
ldpi
c995:
ldl 11
call qol
;    }
c994:
;    if (op == N_GPAL)
ldl 4
eqc 38
cj c996
;      ol("stnl 0");
ldc c939-c997+82
ldpi
c997:
ldl 11
call qol
;    else
j c998
c996:
;      ol("sb");
ldc c939-c999+89
ldpi
c999:
ldl 11
call qol
c998:
;    return;
ajw 10
ret
;  }
;  if (op == N_APFUNC) {
c974:
ldl 4
eqc 29
cj c1000
;    ot("ldc ");
ldc c939-c1001+92
ldpi
c1001:
ldl 11
call qot
;    outname(esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
call qoutname
;    outasm("-");
ldc c939-c1002+97
ldpi
c1002:
ldl 11
call qoutasm
;    printlabel(temp = getlabel());
ldl 11
call qgetlabel
dup
stl 9
ldl 11
call qprintlabel
;    nl();
ldl 11
call qnl
;    ol("ldpi");
ldc c939-c1003+99
ldpi
c1003:
ldl 11
call qol
;    printlabel(temp);
ldl 9
ldl 11
call qprintlabel
;    col();
ldl 11
call qcol
;    nl();
ldl 11
call qnl
;    return;
ajw 10
ret
;  }
;  if (op == N_CONST) {
c1000:
ldl 4
eqc 30
cj c1004
;    ins("ldc ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1005+104
ldpi
c1005:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if (op == N_LIT) {
c1004:
ldl 4
eqc 31
cj c1006
;    ot("ldc ");
ldc c939-c1007+109
ldpi
c1007:
ldl 11
call qot
;    printlabel(litlab);
ldl 11
ldnl 3746
ldl 11
call qprintlabel
;    outasm("-");
ldc c939-c1008+114
ldpi
c1008:
ldl 11
call qoutasm
;    printlabel(temp = getlabel());
ldl 11
call qgetlabel
dup
stl 9
ldl 11
call qprintlabel
;    outasm("+");
ldc c939-c1009+116
ldpi
c1009:
ldl 11
call qoutasm
;    outdec(esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
call qoutdec
;    nl();
ldl 11
call qnl
;    ol("ldpi");
ldc c939-c1010+118
ldpi
c1010:
ldl 11
call qol
;    printlabel(temp);
ldl 9
ldl 11
call qprintlabel
;    col();
ldl 11
call qcol
;    nl();
ldl 11
call qnl
;    return;
ajw 10
ret
;  }
;  if (op == N_LDLP) {
c1006:
ldl 4
eqc 34
cj c1011
;    ins("ldlp ", esp[nodo] - Zsp);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
ldnl 3747
diff
ldc c939-c1012+123
ldpi
c1012:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if (op == N_LDL) {
c1011:
ldl 4
eqc 35
cj c1013
;    ins("ldl ", esp[nodo] - Zsp);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
ldnl 3747
diff
ldc c939-c1014+129
ldpi
c1014:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if (op == N_STL) {
c1013:
ldl 4
eqc 24
cj c1015
;    ins("stl ", esp[nodo] - Zsp);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldl 11
ldnl 3747
diff
ldc c939-c1016+134
ldpi
c1016:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if ((op == N_INC) | (op == N_PINC)) {
c1015:
ldl 4
eqc 23
ldl 4
eqc 25
or
cj c1017
;    if (regs[nodo] == 2) {
ldl 12
ldl 11
ldnlp 4285
wsub
ldnl 0
eqc 2
cj c1018
;      oper[nodo_izq[nodo]] = N_LDL;
ldc 35
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;    } else {
j c1019
c1018:
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      ol("dup");
ldc c939-c1020+139
ldpi
c1020:
ldl 11
call qol
;      ol("ldnl 0");
ldc c939-c1021+143
ldpi
c1021:
ldl 11
call qol
;    }
c1019:
;    if (op == N_PINC)
ldl 4
eqc 25
cj c1022
;      if(reqres)
ldl 2
cj c1023
;        ol("dup");
ldc c939-c1024+150
ldpi
c1024:
ldl 11
call qol
;    ins("adc ", esp[nodo]);
c1023:
c1022:
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1025+154
ldpi
c1025:
ldl 11
call qins
;    if (op == N_INC)
ldl 4
eqc 23
cj c1026
;      if(reqres)
ldl 2
cj c1027
;        ol("dup");
ldc c939-c1028+159
ldpi
c1028:
ldl 11
call qol
;    if (regs[nodo] == 2) {
c1027:
c1026:
ldl 12
ldl 11
ldnlp 4285
wsub
ldnl 0
eqc 2
cj c1029
;      oper[nodo_izq[nodo]] = N_STL;
ldc 24
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;    } else if (reqres) {
j c1030
c1029:
ldl 2
cj c1031
;      ol("pop");
ldc c939-c1032+163
ldpi
c1032:
ldl 11
call qol
;      ol("pop");
ldc c939-c1033+167
ldpi
c1033:
ldl 11
call qol
;      ol("stnl 0");
ldc c939-c1034+171
ldpi
c1034:
ldl 11
call qol
;    } else {
j c1035
c1031:
;      ol("rev");
ldc c939-c1036+178
ldpi
c1036:
ldl 11
call qol
;      ol("stnl 0");
ldc c939-c1037+182
ldpi
c1037:
ldl 11
call qol
;    }
c1035:
c1030:
;    return;
ajw 10
ret
;  }
;  if (op == N_CPAL) {
c1017:
ldl 4
eqc 33
cj c1038
;    if (oper[nodo_izq[nodo]] == N_LDLP) {
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
ldnl 0
eqc 34
cj c1039
;      oper[nodo_izq[nodo]] = N_LDL;
ldc 35
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      op = N_NULO;
ldc 8
stl 4
;    } else if (oper[nodo_izq[nodo]] == N_LDNLP) {
j c1040
c1039:
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
ldnl 0
eqc 36
cj c1041
;      oper[nodo_izq[nodo]] = N_LDNL;
ldc 26
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4029
wsub
stnl 0
;      op = N_NULO;
ldc 8
stl 4
;    }
;  }
c1041:
c1040:
;  rev = 0;
c1038:
ldc 0
stl 5
;  if (nodo_der[nodo]) {
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
cj c1042
;    if ((regs[nodo_izq[nodo]] >= regs[nodo_der[nodo]]) &
;	(regs[nodo_der[nodo]] < 3)) {
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
gt
eqc 0
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldc 3
rev
gt
and
cj c1043
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      gen_codigo(nodo_der[nodo]);
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;    } else if ((regs[nodo_der[nodo]] > regs[nodo_izq[nodo]]) &
j c1044
c1043:
;	       (regs[nodo_izq[nodo]] < 3)) {
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
gt
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
ldnlp 4285
wsub
ldnl 0
ldc 3
rev
gt
and
cj c1045
;      gen_codigo(nodo_der[nodo]);
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      rev = 1;
ldc 1
stl 5
;    } else {
j c1046
c1045:
;      gen_codigo(nodo_der[nodo]);
ldl 12
ldl 11
ldnlp 3901
wsub
ldnl 0
ldl 11
call qgen_codigo
;      zpush();
ldl 11
call qzpush
;      gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
;      zpop();
ldl 11
call qzpop
;    }
c1046:
c1044:
;  } else
j c1047
c1042:
;    gen_codigo(nodo_izq[nodo]);
ldl 12
ldl 11
ldnlp 3773
wsub
ldnl 0
ldl 11
call qgen_codigo
c1047:
;  if (op == N_CIGUAL) {
ldl 4
eqc 5
cj c1048
;    ins("eqc ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1049+189
ldpi
c1049:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if (op == N_CSUMA) {
c1048:
ldl 4
eqc 7
cj c1050
;    if(esp[nodo]) ins("adc ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
cj c1051
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1052+194
ldpi
c1052:
ldl 11
call qins
;    return;
c1051:
ajw 10
ret
;  }
;  if (op == N_LDNLP) {
c1050:
ldl 4
eqc 36
cj c1053
;    if(esp[nodo]) ins("ldnlp ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
cj c1054
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1055+199
ldpi
c1055:
ldl 11
call qins
;    return;
c1054:
ajw 10
ret
;  }
;  if (op == N_LDNL) {
c1053:
ldl 4
eqc 26
cj c1056
;    ins("ldnl ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1057+206
ldpi
c1057:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  if (op == N_STNL) {
c1056:
ldl 4
eqc 9
cj c1058
;    ins("stnl ", esp[nodo]);
ldl 12
ldl 11
ldnlp 4157
wsub
ldnl 0
ldc c939-c1059+212
ldpi
c1059:
ldl 11
call qins
;    return;
ajw 10
ret
;  }
;  gen_oper(op, rev);
c1058:
ldl 5
ldl 4
ldl 11
call qgen_oper
;}
ajw 10
ret
c939:
db 115,116,108,32,0
db 114,101,118,0,108
db 100,108,32,0,115
db 116,108,32,50,0
db 115,116,108,32,51
db 0,108,100,108,32
db 0,108,100,99,32
db 51,0,108,100,112
db 105,0,115,116,108
db 32,48,0,115,116
db 108,32,49,0,103
db 99,97,108,108,0
db 100,117,112,0,115
db 116,110,108,32,48
db 0,115,98,0,100
db 117,112,0,114,101
db 118,0,115,116,110
db 108,32,48,0,115
db 98,0,108,100,99
db 32,0,45,0,108
db 100,112,105,0,108
db 100,99,32,0,108
db 100,99,32,0,45
db 0,43,0,108,100
db 112,105,0,108,100
db 108,112,32,0,108
db 100,108,32,0,115
db 116,108,32,0,100
db 117,112,0,108,100
db 110,108,32,48,0
db 100,117,112,0,97
db 100,99,32,0,100
db 117,112,0,112,111
db 112,0,112,111,112
db 0,115,116,110,108
db 32,48,0,114,101
db 118,0,115,116,110
db 108,32,48,0,101
db 113,99,32,0,97
db 100,99,32,0,108
db 100,110,108,112,32
db 0,108,100,110,108
db 32,0,115,116,110
db 108,32,0
;ins(codigo, valor) char *codigo; int valor; {
qins:
;  outasm(codigo);
ldl 2
ldl 1
call qoutasm
;  outdec(valor);
ldl 3
ldl 1
call qoutdec
;  nl();
ldl 1
call qnl
;}
ret
;/* Comienza una linea de comentarios para el ensamblador */
;comment()
qcomment:
;{
;  outbyte(';');
ldc 59
ldl 1
call qoutbyte
;}
ret
;/* Pone el prologo para el codigo generado. */
;header()
qheader:
;{
;  comment();
ldl 1
call qcomment
;  outstr(BANNER);
ldc c1062-c1063+0
ldpi
c1063:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  comment();
ldl 1
call qcomment
;  outstr(VERSION);
ldc c1062-c1064+34
ldpi
c1064:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  comment();
ldl 1
call qcomment
;  outstr(AUTHOR);
ldc c1062-c1065+57
ldpi
c1065:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  comment();
ldl 1
call qcomment
;  nl();
ldl 1
call qnl
;  ol("COMIENZO:");
ldc c1062-c1066+88
ldpi
c1066:
ldl 1
call qol
;  ol("j INICIO");
ldc c1062-c1067+98
ldpi
c1067:
ldl 1
call qol
;}
ret
c1062:
db 42,42,42,32,67
db 111,109,112,105,108
db 97,100,111,114,32
db 100,101,32,67,32
db 112,97,114,97,32
db 71,45,49,48,32
db 42,42,42,0,32
db 32,32,32,32,32
db 32,32,32,32,86
db 101,114,115,105,111
db 110,32,49,46,48
db 48,0,32,32,32
db 112,111,114,32,79
db 115,99,97,114,32
db 84,111,108,101,100
db 111,32,71,117,116
db 105,101,114,114,101
db 122,46,0,67,79
db 77,73,69,78,90
db 79,58,0,106,32
db 73,78,73,67,73
db 79,0
;/* Pone el epilogo para el codigo generado. */
;trailer()
qtrailer:
;{
;  nl();
ldl 1
call qnl
;  comment();
ldl 1
call qcomment
;  outstr(" Fin de compilacion");
ldc c1068-c1069+0
ldpi
c1069:
ldl 1
call qoutstr
;  nl();
ldl 1
call qnl
;  outasm("INICIO");
ldc c1068-c1070+20
ldpi
c1070:
ldl 1
call qoutasm
;  col();
ldl 1
call qcol
;  nl();
ldl 1
call qnl
;  ins("ajw ", -posglobal);
ldl 1
ldnl 3771
not
adc 1
ldc c1068-c1071+27
ldpi
c1071:
ldl 1
call qins
;  if (posglobal > 2) {
ldl 1
ldnl 3771
ldc 2
gt
cj c1072
;    ol("ldlp 2");
ldc c1068-c1073+32
ldpi
c1073:
ldl 1
call qol
;    ol("stl 0");
ldc c1068-c1074+39
ldpi
c1074:
ldl 1
call qol
;    ins("ldc ", posglobal - 2);
ldl 1
ldnl 3771
adc -2
ldc c1068-c1075+45
ldpi
c1075:
ldl 1
call qins
;    ol("stl 1");
ldc c1068-c1076+50
ldpi
c1076:
ldl 1
call qol
;    outasm("INICIO2");
ldc c1068-c1077+56
ldpi
c1077:
ldl 1
call qoutasm
;    col();
ldl 1
call qcol
;    nl();
ldl 1
call qnl
;    ol("ldc 0");
ldc c1068-c1078+64
ldpi
c1078:
ldl 1
call qol
;    ol("ldl 0");
ldc c1068-c1079+70
ldpi
c1079:
ldl 1
call qol
;    ol("stnl 0");
ldc c1068-c1080+76
ldpi
c1080:
ldl 1
call qol
;    ol("ldl 0");
ldc c1068-c1081+83
ldpi
c1081:
ldl 1
call qol
;    ol("adc 4");
ldc c1068-c1082+89
ldpi
c1082:
ldl 1
call qol
;    ol("stl 0");
ldc c1068-c1083+95
ldpi
c1083:
ldl 1
call qol
;    ol("ldl 1");
ldc c1068-c1084+101
ldpi
c1084:
ldl 1
call qol
;    ol("adc -1");
ldc c1068-c1085+107
ldpi
c1085:
ldl 1
call qol
;    ol("stl 1");
ldc c1068-c1086+114
ldpi
c1086:
ldl 1
call qol
;    ol("ldl 1");
ldc c1068-c1087+120
ldpi
c1087:
ldl 1
call qol
;    ol("eqc 0");
ldc c1068-c1088+126
ldpi
c1088:
ldl 1
call qol
;    ol("cj INICIO2");
ldc c1068-c1089+132
ldpi
c1089:
ldl 1
call qol
;  }
;  ol("ldlp 0");
c1072:
ldc c1068-c1090+143
ldpi
c1090:
ldl 1
call qol
;  ol("call qmain");
ldc c1068-c1091+150
ldpi
c1091:
ldl 1
call qol
;  ins("ajw ", posglobal);
ldl 1
ldnl 3771
ldc c1068-c1092+161
ldpi
c1092:
ldl 1
call qins
;  ol("ret");
ldc c1068-c1093+166
ldpi
c1093:
ldl 1
call qol
;}
ret
c1068:
db 32,70,105,110,32
db 100,101,32,99,111
db 109,112,105,108,97
db 99,105,111,110,0
db 73,78,73,67,73
db 79,0,97,106,119
db 32,0,108,100,108
db 112,32,50,0,115
db 116,108,32,48,0
db 108,100,99,32,0
db 115,116,108,32,49
db 0,73,78,73,67
db 73,79,50,0,108
db 100,99,32,48,0
db 108,100,108,32,48
db 0,115,116,110,108
db 32,48,0,108,100
db 108,32,48,0,97
db 100,99,32,52,0
db 115,116,108,32,48
db 0,108,100,108,32
db 49,0,97,100,99
db 32,45,49,0,115
db 116,108,32,49,0
db 108,100,108,32,49
db 0,101,113,99,32
db 48,0,99,106,32
db 73,78,73,67,73
db 79,50,0,108,100
db 108,112,32,48,0
db 99,97,108,108,32
db 113,109,97,105,110
db 0,97,106,119,32
db 0,114,101,116,0
;/*
;** Imprime un nombre que no entre en conflicto con las
;** palabras reservadas del ensamblador.
;*/
;outname(sname)
qoutname:
;  char *sname;
;{
;  outasm("q");
ldc c1094-c1095+0
ldpi
c1095:
ldl 1
call qoutasm
;  outasm(sname);
ldl 2
ldl 1
call qoutasm
;}
ret
c1094:
db 113,0
;/* Pone el registro A en la pila */
;zpush()
qzpush:
;{
;  ol("ajw -1");
ldc c1096-c1097+0
ldpi
c1097:
ldl 1
call qol
;  ol("stl 0");
ldc c1096-c1098+7
ldpi
c1098:
ldl 1
call qol
;  --Zsp;
ldl 1
ldnlp 3747
dup
ldnl 0
adc -1
rev
stnl 0
;}
ret
c1096:
db 97,106,119,32,45
db 49,0,115,116,108
db 32,48,0
;/* Pone el tope de la pila en el reg. A */
;zpop()
qzpop:
;{
;  ol("ldl 0");
ldc c1099-c1100+0
ldpi
c1100:
ldl 1
call qol
;  ol("ajw 1");
ldc c1099-c1101+6
ldpi
c1101:
ldl 1
call qol
;  ++Zsp;
ldl 1
ldnlp 3747
dup
ldnl 0
adc 1
rev
stnl 0
;}
ret
c1099:
db 108,100,108,32,48
db 0,97,106,119,32
db 49,0
;/* Llama a la funci¢n especificada */
;zcall(sname)
qzcall:
;  char *sname;
;{
;  ot("call ");
ldc c1102-c1103+0
ldpi
c1103:
ldl 1
call qot
;  outname(sname);
ldl 2
ldl 1
call qoutname
;  nl();
ldl 1
call qnl
;}
ret
c1102:
db 99,97,108,108,32
db 0
;/* Retorna de una funci¢n */
;zret()
qzret:
;{
;  ol("ret");
ldc c1104-c1105+0
ldpi
c1105:
ldl 1
call qol
;}
ret
c1104:
db 114,101,116,0
;/* Salta a la etiqueta interna especificada */
;jump(label)
qjump:
;  int label;
;{
;  ins("j c", label);
ldl 2
ldc c1106-c1107+0
ldpi
c1107:
ldl 1
call qins
;}
ret
c1106:
db 106,32,99,0
;/* Prueba el registro primario y salta si es falso */
;testjump(label)
qtestjump:
;  int label;
;{
;  ins("cj c", label);
ldl 2
ldc c1108-c1109+0
ldpi
c1109:
ldl 1
call qins
;}
ret
c1108:
db 99,106,32,99,0
;/* Retorna la siguiente etiqueta interna disponible */
;getlabel()
qgetlabel:
;{
;  return (++nxtlab);
ldl 1
ldnlp 3745
dup
ldnl 0
adc 1
dup
pop
pop
stnl 0
ret
;}
;/* Imprime el n£mero especificado c¢mo una etiqueta */
;printlabel(label)
qprintlabel:
;  int label;
;{
;  outasm("c");
ldc c1111-c1112+0
ldpi
c1112:
ldl 1
call qoutasm
;  outdec(label);
ldl 2
ldl 1
call qoutdec
;}
ret
c1111:
db 99,0
;col()
qcol:
;{
;  outbyte(58);
ldc 58
ldl 1
call qoutbyte
;}
ret
;/* Seudo-operacion para definir un byte */
;defbyte()
qdefbyte:
;{
;  ot("db ");
ldc c1114-c1115+0
ldpi
c1115:
ldl 1
call qot
;}
ret
c1114:
db 100,98,32,0
;/* Modifica la posici¢n de la pila */
;modstk(newsp)
qmodstk:
;  int newsp;
;{
;  int k;
;  if (k = newsp - Zsp)
ajw -1
ldl 3
ldl 2
ldnl 3747
diff
dup
stl 0
cj c1117
;    ins("ajw ", k);
ldl 0
ldc c1116-c1118+0
ldpi
c1118:
ldl 2
call qins
;  return newsp;
c1117:
ldl 3
ajw 1
ret
;}
c1116:
db 97,106,119,32,0
;/* Fin del Compilador de Mini-C */

; Fin de compilacion
INICIO:
ajw -4415
ldlp 2
stl 0
ldc 4413
stl 1
INICIO2:
ldc 0
ldl 0
stnl 0
ldl 0
adc 4
stl 0
ldl 1
adc -1
stl 1
ldl 1
eqc 0
cj INICIO2
ldlp 0
call qmain
ajw 4415
ret
