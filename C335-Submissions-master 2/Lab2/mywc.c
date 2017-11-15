/*Filename: mywc.c *
*Part of: C335 Homework/Lab Assignment "Lab 2" *
*Created by: Brandon Wynne *
*Created on: 1/23/2014 *
*Last Modified by: Brandon Wynne *
*Last Modified on: 1/23/2014 *
*/

#include <stdio.h>
#include <string.h>

int isWhiteSpace(int c);
int main()
{
  int c; /* current character */
  int wordCounter = 0; /* word */
  int lineCounter = 0; /* lines */
  int characterCounter = 0; /* characters */
 
  while ((c = getchar()) != EOF) {
    characterCounter++;
    if (isWhiteSpace(c) == 1) {
      while (isWhiteSpace(c) == 1) {
   
      if ( c == '\n') { 
	lineCounter++;
      }
      c = getchar();
      }  wordCounter++; 
    }	
  }

  printf("%d %d %d", lineCounter, wordCounter, characterCounter);
  
return 0;
}

int isWhiteSpace(int c) 
{
  if (c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f' || c == '\v') {
    return 1;
  } 
  else {
    return 0;
  } 
}




