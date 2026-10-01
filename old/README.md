# Contents of the 'old' directory

## Tools formerly provided by this project


### 'Ron Cain' Small-C Compiler tc2 and tasm
These were written by Óscar for his emulation and OS project, between 1993-1996.
They are based on the Small-C compiler by Ron Cain, which was published in Dr. Dobbs'
journal vol 5 no 45 - the full volume of which may be found
at https://archive.org/details/dr_dobbs_journal_vol_05_201803/page/n189/mode/2up
A copy of just the Ron Cain article PDF may be found in this repository.

Óscar's journey of building these tools and his Transputer system can be found
at https://nanochess.org/bootstrapping_c_os_transputer.html .
The repository of his original whole system can be found
at https://github.com/nanochess/transputer .

This repository contains a copy of his early compiler and assemblers, modified by Matt Gumbley (files tc2*, tasm*).
The modifications are:
* Translation of messages, identifiers, comments etc. from Spanish to English. Matt does
  not speak Spanish, but the translations are being verified against the Ron Cain article.
  See AI Declaration, below.
* Modifications to allow the tools to be first built on a 32-bit Linux system, running
  Debian Bookworm.
* Enhancements to work with the Parachute IServer.
* Bugfix: When errors are detected in the compiler, it exits with status 1.

The 'tasm' assembler and 'tc2' compiler are older, and no longer used.

### 'James Hendrix K&R C Compiler' cc1_en
Note that this directory is historical, and no longer used in Parachute.

The `cc1_en` and `cc1_es` directories in this repository contain a copy of a later (1998) version of Óscar's compiler,
documented in his article at https://nanochess.org/am29000_c_compiler_web_browser.html . In his repository, there are
two variants of this compiler, cc0 (more like James Hendrix' Small-C than Ron Cain's), and cc1, which enhances the cc0
compiler with a dynamic expression tree generator using malloc/free. It was written to build using the DJGPP compiler
on MSDOS.

In this repository, the `cc1_es` directory contains a copy of Óscar's cc1 compiler with no changes or translation.

The `cc1_en` directory contains my attempt at porting this to the platforms I'm targetting with Parachute, and
manual translation of the user-facing messages from Spanish to English. Initially, it builds on Intel Debian 32-bit
Linux, using gcc and its stdlib.

The modifications are:
* Translation of messages from Spanish to English. I am attempting to translate this 'by hand' rather than by using
  Claude, although I also use Google Translate which is now LLM-based.

My eventual goal was to cross-compile to run on the Parachute emulator and IServer, using the iserverstdio.c routines
to interface with the IServer. I'll be continuing this with 'cc1' (see above)

Óscar enhanced this code significantly to make it build on 64-bit systems directly. (see 'cc1', in the parent directory.)


# C Compiler Translation details
Here's a summary of everything that was translated across the 3,018-line tc2.c file:

## String literals (user-facing messages)

Banner/version strings, all prompts ("Output file? ", "Input file? ", "Pause after each error? (Y/N) ", etc.)

All error messages ("Missing semicolon", "Expression too complex", "Global table full", etc.)

The "Compilation aborted." / "End of compilation" runtime strings

The assembler labels emitted to output (COMIENZO→START, INICIO→ENTRY, INICIO2→ENTRY2)

## Identifiers and function names

SI→YES, hello()→banner(), see()→options()

Tree arrays: nodo_izq[]→node_left[], nodo_der[]→node_right[], esp[]→stk[]

Tree globals: ultimo_nodo→last_node, raiz_arbol→tree_root, TAM_ARBOL→TREE_SIZE

Functions: crea_nodo()→make_node(), etiqueta()→annotate(), gen_codigo()→gen_code(), enlace()→load_static_base(), outpos()→emit_global_addr(), doublereg()→scale_by_word(), raise()→to_upper(), predel()→pre_space(), prequote()→pre_quote(), preapos()→pre_apos(), precomm()→pre_comment()

Node op macros: N_IGUAL→N_EQ, N_CIGUAL→N_CEQ, N_MAYOR→N_GT, N_CSUMA→N_CADD, N_NULO→N_NULL, N_SMAYOR→N_SGT, N_SUMA→N_ADD, N_RESTA→N_SUB, N_CPAL→N_CWORD, N_GBYTE→N_SBYTE, N_GPAL→N_SWORD

Globals: posglobal→global_pos, usaexpr→use_expr

Local variables throughout: izq→left, der→right, conteo→count, pals→words, primero→first, anterior→prev, pila→stack, reqres→need_result, nodo→node, codigo→code, valor→value

## All comments
Every block and inline comment translated, including the full function-header doc comments.

## Verification
Both the original compiler and the translated compiler (with changes to build
successfully on Debian 32-bit) were run, and the original Spanish compiler
source was compiled into the two files
`tc2_es_orig-en.asm` (by the translated English compiler) and
tc2_es_orig-es.asm` (by the original Spanish compiler).
These files are committed into the repository. The diff between the two is shown
in `tc2_es_orig.asm.diff`, an explanation of which follows:
```
1,3c1,3
< ;*** Compilador de C para G-10 ***
< ;          Version 1.00
< ;   por Oscar Toledo Gutierrez.
---
> ;Transputer Small C Compiler
> ;Version 1.01
> ;By Oscar Toledo Gutierrez; translated by Matt Gumbley.

The banner emitted by the compiler into the output assembler. This has been
justified and modified by Matt.

5,6c5,6
< COMIENZO:
< j INICIO
---
> START:
> j ENTRY
13009,13010c13009,13010
< ; Fin de compilacion
< INICIO:
---
> ; End of compilation
> ENTRY:
13016c13016
< INICIO2:
---
> ENTRY2:
13028c13028
< cj INICIO2
---
> cj ENTRY2

The compiler emits the symbols `COMIENZO/START`, `INICIO/ENTRY`,
`INICIO2/ENTRY2` at the start and end of the compiled code. These symbols have
been translated.
```

Since the assembly of a complex program is essentially identical between the
original Spanish version and the translated English version, I conclude
that the AI translation has been successful, and has not adversely
affected the operation of the compiler in any way, other than translating
symbols, messages and comments.

