
main()
{
  char *p;
  p = "Hello world from an IServer putchar example\r\n";
  while (*p) {
    putchar(*p++);
  }
  exit(0);
}

