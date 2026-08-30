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
#define REQ_PUTS    15
#define REQ_POLLKEY 31
#define REQ_EXIT    35

/* Devzendo extended IServer tag */
#define REQ_PUTCHAR 90

#define FILE_STDIN 0
#define FILE_STDOUT 1
#define FILE_STDERR 2

#define STDOUT_STREAMID 0x01

/* The IServer is fixed on Link 0 for now */
#define LINK0_OUTPUT 0x80000000
#define LINK0_INPUT  0x80000010

_dummy() 
{
char *_library;
    _library = "iserverstdio.c";
}

/* Send a buffer and wait for a response */
_send_is_r(bufptr, buflen)
    char *bufptr; /* local 3 */
    int buflen;   /* local 4 */
{
int inword; /* local 0 */
#asm
    ldl 3 ; bufptr
    ldc 0x80000000 ; LINK0_OUTPUT
    ldl 4 ; buflen
    out
    ; read and ignore the IServer response
    ldlp 0 ; inword
    ldc 0x80000010 ; LINK0_INPUT
    ldc 4 ; a word's worth
    in
#endasm
}

/* Send a buffer, don't wait for a response */
_send_is(bufptr, buflen)
    char *bufptr; /* local 2 */
    int buflen;   /* local 3 */
{
#asm
    ldl 2 ; bufptr
    ldc 0x80000000 ; LINK0_OUTPUT
    ldl 3 ; buflen
    out
#endasm
}

/* Wait for a response word */
_recv_is_i()
{
    int inword; /* local 0 */
#asm
    ; read and ignore the IServer response
    ldlp 0 ; inword
    ldc 0x80000010 ; LINK0_INPUT
    ldc 4 ; a word's worth
    in
#endasm
}

_send_is_byte(by)
    int by; /* local 2 */
{
#asm
    ldc 0x80000000 ; LINK0_OUTPUT
    ldl 2 ; by
    outbyte
#endasm
}

_send_is_short(sh)
    int sh;
{
    _send_is_byte(sh & 0x000000ff);
    _send_is_byte((sh & 0x0000ff00) >> 8);
}

_send_is_word(word)
    int word; /* local 2 */
{
#asm
    ldc 0x80000000 ; LINK0_OUTPUT
    ldl 2 ; word
    outword
#endasm
}


char _req_exit_buf[8];
exit(code)
    int code;
{
    /* Always output as a little-endian word, LSB first MSB last */
    _req_exit_buf[3] = (code & 0x000000ff);
    _req_exit_buf[4] = ((code & 0x0000ff00) >> 8);
    _req_exit_buf[5] = ((code & 0x00ff0000) >> 16);
    _req_exit_buf[6] = ((code & 0xff000000) >> 24);

    /* Initialise rest of message first time this is called. */
    if (_req_exit_buf[0] != 0x06) {
        _req_exit_buf[0] = 0x06;
        _req_exit_buf[1] = 0x00;
        _req_exit_buf[2] = REQ_EXIT;
        /* [3..6] is the int code */
        _req_exit_buf[7] = 0x00;
    }
    _send_is_r(_req_exit_buf, 8);
    /* Terminate the emulator. Or (re-)start, if on embedded? */
#asm
    terminate
#endasm
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
    _send_is_r(_req_putchar_buf, 8);
}

/* TODO Move this to string.c later */
strlen(cad)
    char *cad;
{
    char *ori;
    ori = cad;
    while (*cad) ++cad;
    return (cad - ori);
}

puts(buf)
    char *buf;
{
    /* locals
     * 4 - p (main's pointer to the string)
     * 1 - len
     * 0 - odd
     */
int len;
int odd;
    len = strlen(buf);
    odd = len & 1;
    /* ABCD would give 0c 00 0f 01 00 00 00 04 00 41 42 43 44 00       | .........ABCD.  */
    /* 2 bytes REMAINING frame len (this does not count the frame len itself), counting:
     * 1 byte tag, 4 bytes stream + 2 bytes str len + str + padding? */
    /* 4 bytes - len is 4, odd is 0 */
    /* Remaining frame length: */
    _send_is_short(7 + len + (!odd));
    /* Tag */
    _send_is_byte(REQ_PUTS);
    /* Stream */
    _send_is_word(FILE_STDOUT);
    /* String: length & data */
    _send_is_short(len);
    _send_is(buf, len);
    /* The frame length MUST be even. A padding zero byte is needed 7 + len is odd.
     * If the string has an even length, then adding that number of bytes to the 7 fixed
     * bytes of the frame will give an odd length, so then add a null.
     */
    if (!odd) {
        _send_is_byte(0);
    }
    _recv_is_i();
}
