// testwhite.c
// Brandon Wynne
// April 15 2014

#include <stdio.h>
extern int myiswhite(char c);

int main() {
  static char test_chars[] = {' ', '\t', '\r', '\n', '\f', '\v'};
  int i;
  static char *result;

  for (i = 0; i < sizeof(test_chars); i++) {
    if (myiswhite(test_chars[i]))
      result = "yes";
    else
      result = "no";
    printf("%c %s \n", test_chars[i], result);
  }
}
