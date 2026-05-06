mult(a, b)
  int a, b;
{
  return a * b;
}

outbyte(c)
  char c;
{
  if (c == 0)
    return 0;
  putchar(c);
  return c;
}

outdec(number)
  int number;
{
  if (number < 0) {
    outbyte('-');
    if (number < -9)
      outdec(-(number / 10));
    outbyte(-(number % 10) + '0');
  } else {
    if (number > 9)
      outdec(number / 10);
    outbyte((number % 10) + '0');
  }
}

main()
{
int a;
int b;
int c;
  b = 8;
  a = 5;
  c = mult(a, b);

  outdec(c);

  exit(0);
}

