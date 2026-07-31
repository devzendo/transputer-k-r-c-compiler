/* -----------------------------------------------------------------------------
//
// File        : iserverstdio.c
// Description : The 'stdio' routines needed by the compiler and assembler,
//               using the IServer protocol.
// License     : see LICENSE.txt for more details
// Created     : 01/07/2026
//
// (C) 2026 Matt J. Gumbley
// matt.gumbley@devzendo.org
// http://devzendo.github.io/parachute
//
//--------------------------------------------------------------------------- */

/* IServer frame tags */
#define REQ_POLLKEY 31
#define REQ_EXIT    35
#define REQ_PUTCHAR 90
#define STDOUT_STREAMID 0x01

/* The IServer is fixed on Link 0 for now */
#define LINK0_OUTPUT 0x80000000
#define LINK0_INPUT  0x80000010

_dummy() 
{
char *_library;
    _library = "iserverstdio.c";
}

_send_iserver(bufptr, buflen)
    char *bufptr; /* local 3 */
    int buflen;   /* local 4 */
{
int inword; /* local 1 */
#asm
    ldl 3 ; bufptr
    ldc 0x80000000 ; LINK0_OUTPUT
    ldl 4 ; buflen
    out
    ; read and ignore the IServer response
    ldlp 1 ; inword
    ldc 0x80000010 ; LINK0_INPUT
    ldc 4 ; a word's worth
    in
#endasm
}

exit(code)
    int code;
{

}

fclose(file)
    char* file;
{

}

/* char */ fgetc(file)
    char *file;
{

}

fputc(c, file)
    char c;
    char* file;
{

}

/* char * */ fopen(filename, mode)
    char *filename;
    char *mode;
{

}

/* int */ getchar()
{

}

gets(buf)
    char *buf;
{

}

char _req_putchar_buf[8];
putchar(ch)
    char ch;
{
    _req_putchar_buf[3] = ch;
    /* Initialise rest of message first time this is called. */
    if (_req_putchar_buf[0] != 0x06) {
        _req_putchar_buf[0] = 0x06;
        _req_putchar_buf[1] = 0x00;
        _req_putchar_buf[2] = REQ_PUTCHAR;
        /* [3] is the char ch */
        _req_putchar_buf[4] = 0x00;
        _req_putchar_buf[5] = 0x00;
        _req_putchar_buf[6] = 0x00;
        _req_putchar_buf[7] = 0x00;
    }
    _send_iserver(_req_putchar_buf, 8);
}

puts(buf)
    char *buf;
{

}
