cmake_minimum_required(VERSION 3.10)
project(transputer-k-r-c-compiler C)

# Only build the compiler and assembler with CMake, to get a cross-platform build.
# All examples are built using make on macOS (see Makefile).

# Patching - if not specified with WORKING_DIRECTORY, these run from the cmake-build-xxxx dir.
message(STATUS "Applying patches...")
execute_process(COMMAND git apply 0001-Set-Parachute-banner.patch
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
# Note these will fail to apply when compiling (from mvn) on subsequent runs (but this doesn't stop the generate phase);
# the mvn clean goal restores the original state of the submodule, so they can cleanly apply again.

# CC.c includes all other sources, we don't need CMake to add compilations of each, as they'll fail with
# undeclared identifiers.
add_executable(cc1 cc1/CC.c)
add_executable(tasm tasm.c)

if(NOT MSVC)
    set_target_properties(cc1 PROPERTIES
        C_STANDARD 90
        C_STANDARD_REQUIRED ON
        C_EXTENSIONS OFF
    )
    set_target_properties(tasm PROPERTIES
            C_STANDARD 90
            C_STANDARD_REQUIRED ON
            C_EXTENSIONS OFF
    )
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
    message(STATUS "Using the AppleClang settings")
    # Clang 16+ promotes several K&R idioms to hard errors.
    # -Wno-implicit-int does NOT exist on Apple Clang; implicit-int is folded into
    # -Wno-implicit-function-declaration on this toolchain.
    # Apple SDK gates gets() behind _XOPEN_SOURCE on recent SDKs

    target_compile_options(tasm PRIVATE
        -Wno-implicit-function-declaration  # calls before declaration
        -Wno-return-type                    # fall-off-end functions
        -Wno-int-conversion                 # char*/int* pointer aliasing
        -Wno-strict-prototypes              # unprototyped parameter lists
        -Wno-old-style-definition           # K&R parameter-declaration syntax
        -Wno-deprecated-non-prototype       # same, newer Clang name
        -Wno-parentheses                    # assignment-as-condition (K&R idiom)
        -fno-strict-aliasing                # char[] walked as struct fields
        -Wno-knr-promoted-parameter         # char/short args promoted to int
    )
    target_compile_definitions(tasm PRIVATE _XOPEN_SOURCE=600)

    target_compile_options(cc1 PRIVATE
            -Wno-implicit-function-declaration  # calls before declaration
            -Wno-return-type                    # fall-off-end functions
            -Wno-int-conversion                 # char*/int* pointer aliasing
            -Wno-strict-prototypes              # unprototyped parameter lists
            -Wno-old-style-definition           # K&R parameter-declaration syntax
            -Wno-deprecated-non-prototype       # same, newer Clang name
            -Wno-parentheses                    # assignment-as-condition (K&R idiom)
            -fno-strict-aliasing                # char[] walked as struct fields
            -Wno-knr-promoted-parameter         # char/short args promoted to int
            -Wno-deprecated-declarations
            -Wno-pointer-sign
            -Wno-empty-body
    )
    target_compile_definitions(cc1 PRIVATE _XOPEN_SOURCE=600)

elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    message(STATUS "Using the GNU settings")

elseif(MSVC)
    message(STATUS "Using the MSVC settings")

endif()
