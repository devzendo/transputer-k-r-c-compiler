;Transputer Small C Compiler
;Version 1.01
;By Oscar Toledo Gutierrez; translated by Matt Gumbley.
;
START:
j ENTRY
;mult(a, b)
qmult:
;  int a, b;
;{
;  return a * b;
ldl 2
ldl 3
prod
ret
;}
;outbyte(c)
qoutbyte:
;  char c;
;{
;  if (c == 0)
ldlp 2
lb
eqc 0
cj c3
;    return 0;
ldc 0
ret
;  putchar(c);
c3:
ldlp 2
lb
ldl 1
call qputchar
;  return c;
ldlp 2
lb
ret
;}
;outdec(number)
qoutdec:
;  int number;
;{
;  if (number < 0) {
ldc 0
ldl 2
gt
cj c5
;    outbyte('-');
ldc 45
ldl 1
call qoutbyte
;    if (number < -9)
ldc -9
ldl 2
gt
cj c6
;      outdec(-(number / 10));
ldl 2
ldc 10
div
not
adc 1
ldl 1
call qoutdec
;    outbyte(-(number % 10) + '0');
c6:
ldl 2
ldc 10
rem
not
adc 1
adc 48
ldl 1
call qoutbyte
;  } else {
j c7
c5:
;    if (number > 9)
ldl 2
ldc 9
gt
cj c8
;      outdec(number / 10);
ldl 2
ldc 10
div
ldl 1
call qoutdec
;    outbyte((number % 10) + '0');
c8:
ldl 2
ldc 10
rem
adc 48
ldl 1
call qoutbyte
;  }
c7:
;}
ret
;main()
qmain:
;{
;int a;
;int b;
;int c;
;  b = 8;
ajw -3
ldc 8
stl 1
;  a = 5;
ldc 5
stl 2
;  c = mult(a, b);
ldl 1
ldl 2
ldl 4
call qmult
stl 0
;  outdec(c);
ldl 0
ldl 4
call qoutdec
;  exit(0);
ldc 0
ldl 4
call qexit
;}
ajw 3
ret

; End of compilation
ENTRY:
ajw -2
ldlp 0
call qmain
ajw 2
ret
