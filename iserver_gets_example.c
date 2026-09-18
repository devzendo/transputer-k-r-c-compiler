/* This crashes. Don't know why. */
char line[512];
main()
{
  char *p;

  line[0] = '\0';
  while (line[0] != 'q') {
    puts("Please enter some text and press return. Enter a 'q' to quit.");
    gets(line);
    puts("You entered:");
    putchar('[');
    /* Output the string, without newline at end, so can't use puts */
    p = line;
    while (*p) {
      putchar(*p++);
    }
    puts("]");
  }
  puts("Bye!");
  exit(0);
}

