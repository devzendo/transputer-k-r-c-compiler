# transputer-k-r-c-compiler

## What is this?
A Small-C compiler and assembler, targetting the Transputer. It was written by
Óscar Toledo Gutiérrez for his emulation and OS project, between 1993-1996. It
is based on the Small-C compiler by Ron Cain, which was published in Dr. Dobbs'
journal vol 5 no 45 - the full volume of which may be found
at https://archive.org/details/dr_dobbs_journal_vol_05_201803/page/n189/mode/2up
A copy of just the Ron Cain article PDF may be found in this repository.

Óscar's journey of building these tools and his Transputer system can be found
at https://nanochess.org/bootstrapping_c_os_transputer.html .
The repository of his original whole system can be found
at https://github.com/nanochess/transputer .

This repository contains a copy of his compiler and assembler, modified by Matt Gumbley.
The modifications are:
* Translation of messages, identifiers, comments etc. from Spanish to English. Matt does
  not speak Spanish, but the translations are being verified against the Ron Cain article.
  See AI Declaration, below.
* Modifications to allow the tools to be first built on a 32-bit Linux system, running
  Debian Bookworm.
* Enhancements to work with the Parachute IServer.


It is part of the [Parachute Project](https://devzendo.github.io/parachute).

## Project Status
Actively in development.

Started late April 2026. 

# Overview
I'd like to bootstrap my development efforts for Transputer code, and with my existing
assembler (transputer-macro-assembler) being written in Scala, it's not going to run
on the Transputer itself any time soon. It was written with the goal of assembling
eForth, writing in a modern language with pattern matching/parser combinators. At the
time, I never considered bootstrapping. I'm considering rewriting it in C. I also need
a C compiler that I can bootstrap, and my initial effort at this (retro-c-compiler) was
also not started with the vision of bootstrapping in mind, so I started writing it in
Rust, as this was/is my current favourite/day job language. Again, I'm not going to run
that on the Transputer itself any time soon.

Then I heard of Óscar's project, and asked permission to translate it, which was kindly
granted.

The plan is to build the compiler and assembler on modern 64-bit systems - to
provide tools for building C into Transputer binaries on these modern systems.

However initially, these first versions have to run on a 32-bit system, as early experiments
with 64-bit execution lead to crashes. I know where some pointer/int length
problems lie, and will be working to address these problems, so that these tools
can run on 64-bit systems.

Then, use these versions of the compiler to compile itself, completing the
bootstrap loop - providing tools that run on the Transputer directly, compiling into
Transputer binaries, making use of the IServer for host communications.

Then, use these versions with the forthcoming Parachute OS, to build completely
on-Transputer.


## Transputer requirements
It should be able to generate code for the T425ish that is currently emulated.
* Target: T425


# Development


## Building
For the first phase, on Debian 32-bit Intel Linux, build it with GNU make:

`make clean; make`

This will build the compiler and assembler (build/tc2_linux and
build/tasm_linux), then use this compiler to compile itself into the Transputer
assembler file build/tc2.asm.

To build it on the Transputer... (later)

# Packaging
Later!

# Documentation
When there is some, it'll be in the 'docs' directory, when this exists!


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

# Assembler Translation details

## Structs

struct etiqueta → struct label (fields: siguiente→next, secuencia→sequence, tipo→type, dato→value, nombre→name)
struct indefinido → struct unresolved (fields: siguiente→next, codigo→opcode, direccion→address, expresion→expression)

## Globals

dispersion[]→hash_table[], ultima_definida→last_defined, paso→pass_num, archivo_entrada→input_fp, ap_proceso→line_ptr, linea_actual→current_line, errores_detectados→errors_detected, disponible→available, pos_ens→asm_pos, pos_global→expr_ptr, primer_etiq→first_label, primer_indef/ultimo_indef→first_unres/last_unres, num_indef→num_unres, nom→name_buf, linea→line_buf, separa/separa2→token/token2, etiq_indef→undef_label, btemp1/btemp2→buf1/buf2, acumula→accum, err→parse_err, preins/oriins→pre_ins/orig_ins, tabla→instr_table

## Functions — all 20+ renamed: ensambla→assemble, calcula_dispersion→hash_name, define_etiqueta→define_label, busca_etiqueta→find_label, libera_memoria→free_memory, separa_componente→next_token, procesa→process, verifica_final→check_end, error_extras→error_extra_chars, ins_op→emit_basic_op, agrega_indefinido→add_unresolved, evalua_expresion→eval_expr, ins_sim→emit_simple, ins_ext→emit_extended, def_pal32→def_word32, def_espacio→def_space, def_equiv→def_equ, compara→match_str, lee_linea→read_line, enlaza→link_pass, repaso→widen_pass, copia→copy_range, etemp1/etemp2→write_temp1/write_temp2, vtemp1/vtemp2→flush_temp1/flush_temp2, ltemp1→read_temp1

## All comments

All error strings and comments translated throughout.

# Acknowledgements
Óscar Toledo Gutierrez for writing his Transputer project, the original code, and
his kind permission for me to undertake this translation.

Nora Sandler for her blog posts, that eventually turned into the 'Writing a C
Compiler' book - I've put that project (retro-c-compiler) on hold for a while.

Brian Kernighan & the late Dennis Ritchie, of course!

# AI Declaration

The very early commits to this repo contain translations of Óscar's original Spanish code
into English. These were done by Matt using Claude. Matt has done his best to verify
that these translations are correct.

Further miscellaneous translations done using Google Translate.

All other work in this repo is of human origin.

# License, Copyright & Contact info
This code is released under Óscar's original license, which may be found in LICENSE.txt.

(C) 1993-1996 Óscar Toledo Gutiérrez
(C) 2026 Matt J. Gumbley

matt.gumbley@devzendo.org

Mastodon: @M0CUV@mastodon.radio

http://devzendo.github.io/parachute


