cmake_minimum_required(VERSION 3.10)
project(transputer-k-r-c-compiler C)

# ── Targets ───────────────────────────────────────────────────────────────────
# tc2     -- K&R C compiler (tc2.c):  old-style K&R source, needs special treatment
# tasm    -- Transputer assembler (tasm.c): modern C99 with full prototypes, clean build
add_executable(tc2  tc2.c)
add_executable(tasm tasm.c)

# ── Helper: apply a list of compile options to a target ───────────────────────
# Used below to keep the per-compiler blocks readable.
# cmake_language(CALL ...) requires CMake 3.18+; we use a macro instead so
# we stay compatible with the 3.10 minimum declared above.
macro(target_knr_options target)
    target_compile_options(${target} PRIVATE ${ARGN})
endmacro()

# ── Language standard ─────────────────────────────────────────────────────────
# tc2:  K&R C -- must use C90; C99+ rejects implicit int, unprototyped calls, gets().
# tasm: Modern C with full prototypes -- C99 is fine and cleaner.
# MSVC ignores C_STANDARD entirely for its C frontend, so skip it there.
if(NOT MSVC)
    set_target_properties(tc2 PROPERTIES
            C_STANDARD 90
            C_STANDARD_REQUIRED ON
            C_EXTENSIONS ON          # -std=gnu90: keeps gets() and implicit-int tolerated
    )
    set_target_properties(tasm PROPERTIES
            C_STANDARD 99
            C_STANDARD_REQUIRED ON
            C_EXTENSIONS OFF
    )
endif()

# ── Apple Clang (macOS / Xcode 16+) ──────────────────────────────────────────
# Clang 16+ promotes several K&R idioms to hard errors.
# -Wno-implicit-int does NOT exist on Apple Clang; implicit-int is folded into
# -Wno-implicit-function-declaration on this toolchain.
if(CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
    target_knr_options(tc2
            -Wno-implicit-function-declaration  # calls before declaration
            -Wno-return-type                    # fall-off-end functions
            -Wno-int-conversion                 # char*/int* pointer aliasing
            -Wno-strict-prototypes              # unprototyped parameter lists
            -Wno-old-style-definition           # K&R parameter-declaration syntax
            -Wno-deprecated-non-prototype       # same, newer Clang name
            -Wno-knr-promoted-parameter         # char/short args promoted to int
            -Wno-parentheses                    # assignment-as-condition (K&R idiom)
            -fno-strict-aliasing                # char[] walked as struct fields
    )
    # Apple SDK gates gets() behind _XOPEN_SOURCE on recent SDKs
    target_compile_definitions(tc2 PRIVATE _XOPEN_SOURCE=600)

    # ── Upstream Clang (Linux) ────────────────────────────────────────────────────
    # Same warning flags as Apple Clang. glibc exposes gets() freely in gnu90 mode
    # so no feature-test macro is needed.
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_knr_options(tc2
            -Wno-implicit-function-declaration
            -Wno-return-type
            -Wno-int-conversion
            -Wno-strict-prototypes
            -Wno-old-style-definition
            -Wno-deprecated-non-prototype
            -Wno-knr-promoted-parameter
            -Wno-parentheses
            -fno-strict-aliasing
    )

    # ── GCC (Linux / MinGW) ───────────────────────────────────────────────────────
elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_knr_options(tc2
            -Wno-implicit-int
            -Wno-implicit-function-declaration
            -Wno-return-type
            -Wno-int-conversion
            -Wno-strict-prototypes
            -Wno-old-style-definition
            -Wno-old-style-declaration
            -Wno-parentheses
            -fno-strict-aliasing
    )

    # ── Debian Bookworm 32-bit ────────────────────────────────────────────────
    # tc2 stores FILE* and char* in plain `int` variables throughout, which
    # only works when sizeof(int) == sizeof(void*) -- i.e. on ILP32.
    # On a native 32-bit Bookworm install this is already true and nothing
    # extra is needed. On a 64-bit host you can cross-compile to 32-bit by
    # passing -DBUILD_32BIT=ON; this requires the multilib packages:
    #   sudo apt install gcc-multilib
    # The resulting binary can then be run under `linux32` on the 64-bit host
    # or copied to a real 32-bit machine.
    # Note: tasm is clean modern C and builds correctly on 64-bit without -m32.
    option(BUILD_32BIT "Cross-compile tc2 to 32-bit (ILP32) on a 64-bit GCC host" OFF)
    if(BUILD_32BIT)
        if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
            target_compile_options(tc2 PRIVATE -m32)
            target_link_options(tc2 PRIVATE -m32)
        else()
            message(STATUS "BUILD_32BIT requested but host is already 32-bit; -m32 not needed.")
        endif()
    endif()

    # ── MSVC cl 19.16 (Visual Studio 2017 15.9, x86) ─────────────────────────────
    # MSVC never had a real K&R mode but 19.16 is permissive enough to compile
    # tc2 if the right warnings are suppressed and gets() is shimmed.
    # tasm uses standard C99 and needs no special treatment under MSVC.
    #
    # Warning numbers for K&R patterns in tc2:
    #   C4013  implicit function declaration (returns int)
    #   C4131  old-style (K&R) declarator used
    #   C4028  formal parameter N different from declaration
    #   C4047  'int *' differs in levels of indirection from 'char *'
    #   C4024  different types for formal and actual parameter N
    #   C4033  function must return a value (implicit void functions)
    #   C4505  unreferenced local function removed (static K&R fns)
    #   C4706  assignment within conditional expression
    #
    # gets() was fully removed from the MSVC CRT headers in VS 2015.
    # We inject a one-line macro shim so the source compiles without modification.
    # The shim uses fgets()+stdin, which is safe for the interactive use this
    # compiler makes of gets() (reading short filenames/responses from the user).
    # Note: fgets() retains the newline unlike gets(); the code only looks at the
    # first character of the response buffer (ch()), so this is harmless here.
elseif(MSVC)
    target_compile_options(tc2 PRIVATE
            /wd4013   # implicit function declaration
            /wd4131   # K&R old-style declarator
            /wd4028   # parameter differs from declaration
            /wd4047   # pointer indirection level mismatch
            /wd4024   # type mismatch for formal parameter
            /wd4033   # function must return a value
            /wd4505   # unreferenced local function removed
            /wd4706   # assignment within conditional expression
            /wd4996   # any remaining CRT deprecation warnings
    )
    # Shim gets() using fgets(); 512 matches the linesize #define in tc2.
    target_compile_definitions(tc2 PRIVATE
            "gets(b)=fgets((b),512,stdin)"
    )
endif()