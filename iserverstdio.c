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
#define REQ_GETS    14
#define REQ_PUTS    15
#define REQ_GETKEY  30
#define REQ_POLLKEY 31
#define REQ_EXIT    35

/* Devzendo extended IServer tag */
#define REQ_PUTCHAR 90

#define FILE_STDIN 0
#define FILE_STDOUT 1
#define FILE_STDERR 2

/* The IServer is fixed on Link 0 for now */
#define LINK0_OUTPUT 0x80000000
#define LINK0_INPUT  0x80000010

_dummy() 
{
char *_library;
    _library = "iserverstdio.c";
}

/* Internal I/O words ------------------------------------------------------- */

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
_recv_is_word()
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

/* Wait for a response byte */
_recv_is_byte()
{
    int inbyte; /* local 0 */
#asm
    ldlp 0 ; inbyte
    ldc 0x80000010 ; LINK0_INPUT
    ldc 1 ; just one byte
    in
#endasm
    return inbyte & 0xff;
}

/* Read a number of bytes into the buffer at bufptr */
_recv_buf(bufptr, buflen)
    char *bufptr; /* local 2? */
    int buflen;   /* local 3? */
{
#asm
    ; need a len, b link, c buf
    ldl 2 ; a bufptr
    ldc 0x80000010 ; LINK0_INPUT a link, b, bufptr
    ldl 3 ; a buflen b link c bufptr
    in
#endasm
}

/* Send a single byte */
_send_is_byte(by)
    int by; /* local 2 */
{
#asm
    ldlp 2 ; &by addr
    ; areg addr
    ldc 0x80000000 ; LINK0_OUTPUT ; areg link, breg addr
    ldc 1 ; single byte - areg length, breg link, creg addr
    out
#endasm
}

/* Send both bytes of a short, LSB first */
_send_is_short(sh)
    int sh;
{
    _send_is_byte(sh & 0x000000ff);
    _send_is_byte((sh & 0x0000ff00) >> 8);
}

/* Send four bytes of a word, LSB first */
_send_is_word(word)
    int word; /* local 2 */
{
#asm
    ldlp 2 ; word
    ldc 0x80000000 ; LINK0_OUTPUT
    ldc 4 ; all of the word
    out
#endasm
}

/* Utility routines --------------------------------------------------------- */

/* TODO Move this to string.c later */
strlen(cad)
    char *cad;
{
    char *ori;
    ori = cad;
    while (*cad) ++cad;
    return (cad - ori);
}

_short_at(bufptr)
    char *bufptr;
{
    return bufptr[0] + (bufptr[1] << 8);
}

/* Main stdio routines ------------------------------------------------------ */

/* Send an exit status word to the IServer, requesting it to end, reporting
 * this status to the OS. Ignore response.
 */
exit(code)
    int code;
{
    char _req_exit_buf[8];
    /* Initialise rest of message first time this is called. */
    _req_exit_buf[0] = 0x06;
    _req_exit_buf[1] = 0x00;
    _req_exit_buf[2] = REQ_EXIT;
    /* [3..6] is the int code */
    /* Always output as a little-endian word, LSB first MSB last */
    _req_exit_buf[3] = (code & 0x000000ff);
    _req_exit_buf[4] = ((code & 0x0000ff00) >> 8);
    _req_exit_buf[5] = ((code & 0x00ff0000) >> 16);
    _req_exit_buf[6] = ((code & 0xff000000) >> 24);
    _req_exit_buf[7] = 0x00;
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
    char _getchar_buf[8]; /* ldl 1; ldnlp 4 */
    /* Reuse request buffer for the size/status of the response. If successful, read the data into buf. */
    _getchar_buf[0] = 0x06; /* Frame length */
    _getchar_buf[1] = 0x00;
    _getchar_buf[2] = REQ_GETKEY;
    _getchar_buf[3] = 0x00;
    _getchar_buf[4] = 0x00;
    _getchar_buf[5] = 0x00;
    _getchar_buf[6] = 0x00;
    _getchar_buf[7] = 0x00;
    _send_is(_getchar_buf, 8);
    /* works up to here - look at _recv_buf next */
    _recv_buf(_getchar_buf, 3); /* Overwrite the frame length and status: 2 bytes frame length, 1 byte status */
    if (_getchar_buf[2] == 0x00) {
        /* Success. Ignore frame length, get one more byte (the key) */
        return _recv_is_byte();
    } else {
        /* Inmos IServer & TDS doc don't produce/define any errors in this frame type. But our IServer can fail with a
         * word of zeroes, and a byte of padding. */
        _recv_is_word();
        _recv_is_byte();
        /* Error. */
        return 0;
    }
}

/* buf should be at least 507+1 bytes long, as that's the maximum that the IServer will return (unless a LF or EOF is
 * encountered. +1 for null termination, that this function adds. If the input string is terminated by LF, this is not
 * stored. Any CR in the input is ignored and not returned by the IServer.
 */
gets(buf)
    char *buf; /* ldl 2 */
{
    int length;
    int read_length;
    char _gets_buf[10];
    /* Reuse request buffer for the size/status of the response. If successful, read the data into buf. */
    _gets_buf[0] = 0x08; /* Frame length */
    _gets_buf[1] = 0x00;
    _gets_buf[2] = REQ_GETS;
    _gets_buf[3] = 0x00; /* STDIN */
    _gets_buf[4] = 0x00;
    _gets_buf[5] = 0x00;
    _gets_buf[6] = 0x00;
    _gets_buf[7] = 0xFB; /* Max len 507 */
    _gets_buf[8] = 0x01;
    _gets_buf[9] = 0x00; /* Padding */
    _send_is(_gets_buf, 10);
    _recv_buf(_gets_buf, 3); /* Overwrite the frame length and status: 2 bytes frame length, 1 byte status */
    if (_gets_buf[2] == 0x00) {
        /* Success. Ignore frame length - there's a valid string length coming. Read its 2 bytes into _gets_buf[0,1] */
        _recv_buf(_gets_buf, 2); /* 5 bytes (odd) so far) */
        /* Now read that length into buf */
        read_length = length = _short_at(_gets_buf);
        /* if length is even, we'll have a byte of padding to read as well */
        if ((length & 0x0001) == 0x0000) {
            read_length++;
        }
        _recv_buf(buf, read_length);
        /* Null terminate */
        buf[length] = '\0';
        return buf;
    } else {
        /* Need to get the final byte of padding after frame len and tag */
        _recv_is_byte();
        /* Error. */
        return 0;
    }
}

/* Send a single character to the IServer to display on its stdout. Ignore response.
 * Note that this is an extended IServer protocol
 * frame, not present in the original Inmos IServer.
 */
putchar(ch)
    char ch;
{
    char _req_putchar_buf[8];
    _req_putchar_buf[0] = 0x06;
    _req_putchar_buf[1] = 0x00;
    _req_putchar_buf[2] = REQ_PUTCHAR;
    _req_putchar_buf[3] = ch;
    _req_putchar_buf[4] = 0x00;
    _req_putchar_buf[5] = 0x00;
    _req_putchar_buf[6] = 0x00;
    _req_putchar_buf[7] = 0x00;
    _send_is_r(_req_putchar_buf, 8);
}

/* Send a string of characters to the IServer to display on its stdout, with a line
 * break automatically added. Ignore response.
 * Note that the maximum frame length the IServer supports is 512, and the framing
 * overhead gives a maximum string length that this routine supports as 505 bytes.*
 */
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
    _recv_is_word();
}
