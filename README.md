# transputer-k-r-c-compiler

## What is this?
A 'packaging build' of Óscar Toledo Gutiérrez's K&R C compiler and assembler, targetting native
platforms - and in later phases of the project, the Transputer / IServer. 
These are included as part of the [Parachute Project](https://devzendo.github.io/parachute).

Please note that much of this repository contains historical versions of these tools, and my attempts to integrate them
with the rest of my project - Parachute contains native builds of the 'tasm' assembler (source from here), and
the 'cc1' compiler (this project pulls this in as a submodule from its origin, and patches it for use in Parachute).

## Project Status
Actively in development, last changes in October 2026.

Started late April 2026.

## Tools provided by this project

### 'cc1' K&R C Native Compiler with English messages
Shortly after writing https://nanochess.org/bootstrapping_c_os_transputer.html, Óscar started modifying his compiler to
build properly on 64-bit systems, and also provide user messages in English.
See https://nanochess.org/transputer_c_compiler.html for more details of this. The
compiler is now hosted in his repo at https://github.com/nanochess/transputer-cc . 

The compilers ports/translations in the 'old' directory of this repo are no longer required (see `old/README.md`).

This repo now pulls in Óscar's repo as a submodule under the 'cc1' directory, applies a few patches to it for use in the
Parachute system, and builds it natively for all the platforms Parachute supports.
The patches perform the following:
* Updates the banner to show that this is a Parachute variant of the compiler.

Later patches will:
* Add command-line handling to set the input/output file and options. The original compiler is interactive.

Later enhancements will add stdio/stdlib functions to permit the compiler to run on the emulator itself, using the IServer
for I/O and command line handling - this will aid the project's bootstrappability.

### 'tasm' Assembler translated to English
Written by Óscar for his emulation and OS project, between 1993-1996. 'tasm' is a copy of his later assembler,
modified by Matt Gumbley..
The modifications are:
* Translation of messages, identifiers, comments etc. from Spanish to English. Matt does
  not speak Spanish, but the translations are being verified against the Ron Cain article.
  See AI Declaration, below.
* Modifications to allow the tools to be built on native systems.
* Enhancements to work with the Parachute IServer.
* Bugfix: When errors are detected in the compiler, it exits with status 1.


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
## Creating patches to the cc1 compiler
Make the changes locally, commit them to the cc1 submodule repo with a suitable short comment, but do not push. In
SmartGit use tools/Format Patch to create the patch file, in the root of this repo. Rename to have a numeric prefix as
necessary. Edit the patch to add in the cc1/ prefix to all directories/files. You can now Undo the Last Commit in the
cc1 submodule.

## Building
For the first phase, on native platforms, build it with GNU make:

`make clean; make`

This will build the compiler and assembler (build/cc1, build/tasm), then use this compiler to compile itself into the
Transputer assembler file build/cc1.asm.

This will then have to have the boot loader added, and assembled into a final binary by my macro assembler
(transputer-macro-assembler) as the bootstrap code won't build with these assemblers yet - or, there isn't a bootstrap
that's compatible with the syntax understood by these assemblers.

To build it on the Transputer... (later)

# Packaging
Later!

# Documentation
When there is some, it'll be in the 'docs' directory, when this exists!


# Modern Assembler Translation details

## Structs

struct etiqueta → struct label (fields: siguiente→next, secuencia→sequence, tipo→type, dato→value, nombre→name)
struct indefinido → struct unresolved (fields: siguiente→next, codigo→opcode, direccion→address, expresion→expression)

## Globals

dispersion[]→hash_table[], ultima_definida→last_defined, paso→pass_num, archivo_entrada→input_fp, ap_proceso→line_ptr, linea_actual→current_line, errores_detectados→errors_detected, disponible→available, pos_ens→asm_pos, pos_global→expr_ptr, primer_etiq→first_label, primer_indef/ultimo_indef→first_unres/last_unres, num_indef→num_unres, nom→name_buf, linea→line_buf, separa/separa2→token/token2, etiq_indef→undef_label, btemp1/btemp2→buf1/buf2, acumula→accum, err→parse_err, preins/oriins→pre_ins/orig_ins, tabla→instr_table

## Functions

All 20+ renamed: ensambla→assemble, calcula_dispersion→hash_name, define_etiqueta→define_label, busca_etiqueta→find_label, libera_memoria→free_memory, separa_componente→next_token, procesa→process, verifica_final→check_end, error_extras→error_extra_chars, ins_op→emit_basic_op, agrega_indefinido→add_unresolved, evalua_expresion→eval_expr, ins_sim→emit_simple, ins_ext→emit_extended, def_pal32→def_word32, def_espacio→def_space, def_equiv→def_equ, compara→match_str, lee_linea→read_line, enlaza→link_pass, repaso→widen_pass, copia→copy_range, etemp1/etemp2→write_temp1/write_temp2, vtemp1/vtemp2→flush_temp1/flush_temp2, ltemp1→read_temp1

## All comments

All error strings and comments translated throughout.

# Small C Assembler Translation details

Here's a summary of everything translated across the 1,473-line file:

Macros — SI→YES, TAM_LIN→LINE_SIZE, TAM_BUF→BUF_SIZE, TAM_MEM→MEM_SIZE, TAM_ETIQ→LABEL_SIZE, TAM_INDEF→UNRES_SIZE, plus all the struct layout comments on those defines.

Global variables — archivo→input_fp, temp1/temp2→temp1_fp/temp2_fp, fin_de_archivo→end_of_file, linea_actual→current_line, disponible→available, pos_ens→asm_pos, pos_global→expr_ptr, primer_etiq/ultima_etiq→first_label/last_label, primer_indef/ultimo_indef→first_unres/last_unres, num_etiq→num_labels, num_indef→num_unres, num_arch→num_files, pos_linea→line_pos, nom→name_buf, linea→line_buf, separa/separa2→token/token2, etiq_indef→undef_label, btemp1/btemp2→buf1/buf2, tabla→instr_table, algo→changed, acumula→accum, preins/oriins→pre_ins/orig_ins, err→parse_err.

Functions — inicia1–inicia5→init_basic_ops, init_ops, init_instr1, init_instr2, init_fpu; sale→quit, asigna→alloc, separa_componente→next_token, ensambla→assemble, etiqueta→define_label, busca_etiq→find_label, ins_op→emit_basic_op, ag_indef→add_unresolved, evalua_expresion→eval_expr, ins_sim→emit_simple, ins_ext→emit_extended, def_pal32→def_word32, def_espacio→def_space, def_equiv→def_equ, compara→match_str, obtiene_linea→read_line, enlaza→link_pass, paso→widen_pass, copia→copy_range, lee_linea→read_input, etemp1/etemp2→write_temp1/write_temp2, vtemp1/vtemp2→flush_temp1/flush_temp2, ltemp1→read_temp1, decimal→print_decimal.

All string literals and error messages translated throughout.

# Acknowledgements
Óscar Toledo Gutierrez for writing his Transputer project, the original code, and
his kind permission for me to undertake this translation.

Nora Sandler for her blog posts, that eventually turned into the 'Writing a C
Compiler' book - I've put that project (retro-c-compiler) on hold for a while.

Brian Kernighan & the late Dennis Ritchie, of course!

John Kennedy of Craic Design for the Opcodes iOS app - an indispensible reference of
opcodes for many retrocomputing processors, including the Transputer. For more info
see https://www.craicdesign.com/index.html and https://apps.apple.com/us/app/id6760205834 .

# AI Declaration

The very early commits to this repo contain translations of Óscar's original Spanish code
into English. These were done by Matt using Claude. Matt has done his best to verify
that these translations are correct. These are the 'old/tc2' and 'old/tasm' files, and the
'tasm' files here.

Further miscellaneous translations done using Google Translate.

All other work in this repo is of human origin.

# License, Copyright & Contact info
This code is released under Óscar's original license, which may be found in LICENSE.txt.

(C) 1993-1996 Óscar Toledo Gutiérrez
(C) 2026 Matt J. Gumbley

matt.gumbley@devzendo.org

Mastodon: @M0CUV@mastodon.radio

http://devzendo.github.io/parachute


