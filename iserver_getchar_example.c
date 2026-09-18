/* This works */
main()
{
char buf[4];
  char p;
  p='a';
  puts("Press some keys! q to exit");
  while (p != 'q') {
    p = getchar();
    buf[0] = '[';
    buf[1] = p;
    buf[2] = ']';
    buf[3] = '\0';
    puts("You pressed:");
    puts(buf);
  }
  puts("Bye!");
  exit(0);
}

