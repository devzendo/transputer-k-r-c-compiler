
main()
{
  char line[512];
  char *p;

  /* any odd length input is fine. even length input eventually crashes it. */
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
    /*puts(line);*/
    puts("]");
  }
  puts("Bye!");
  exit(0);
}

