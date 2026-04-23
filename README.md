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
* Modifications to allow the tools to be first built on modern 64-bit systems, notably
  macOS Tahoe, Linux Mint 22, Windows 10.
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

The plan is to first build the compiler and assembler on modern 64-bit systems - to
provide tools for building C into Transputer binaries on these modern systems.

It may be that these first versions have to run on a 32-bit system, as early experiments
with 64-bit execution lead to crashes.

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
For the first phase, build it with CMake. (Explain exactly how, later.)

To build it on the Transputer... (later)

# Packaging
Later!

# Documentation
When there is some, it'll be in the 'docs' directory, when this exists!


# Acknowledgements
Óscar Toledo Gutierrez for writing his Transputer project, the original code, and
his kind permission for me to undertake this translation.

Nora Sandler for her blog posts, that eventually turned into the 'Writing a C
Compiler' book - I've put that project (retro-c-compiler) on hold for a while.

Brian Kernighan & the late Dennis Ritchie, of course!

# AI Declaration

The very early commits to this repo contain translations of Óscar's original Spanish code
into English. These were done by Matt using Claude. The CMakeLists.txt was also built with
Claude's assistance. Matt has done his best to verify that these translations are correct.

Further miscellaneous translations done using Google Translate.

All other work in this repo is of human origin.

# License, Copyright & Contact info
This code is released under Óscar's original license, which may be found in LICENSE.txt.

(C) 1993-1996 Óscar Toledo Gutiérrez
(C) 2026 Matt J. Gumbley

matt.gumbley@devzendo.org

Mastodon: @M0CUV@mastodon.radio

http://devzendo.github.io/parachute


