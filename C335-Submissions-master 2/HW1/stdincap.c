/*Filename: stdincap.c *
 *Part of: C335 Homework/Lab Assignment "Homework 1" *
 *Created by: Brandon Wynne *
 *Created on: 1/27/2014 *
 *Last Modified by: Brandon Wynne *
 *Last Modified on: 1/28/2014 *
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>

void upperCaseConversion(); //function prototyping with no param
int main()
{
    upperCaseConversion(); //execute upperCaseConversion with input from "<"
    
}

void upperCaseConversion() //function that uses toupper() on character arrays with getchar()
{
    int c;
    while ((c = getchar()) != EOF) // While loop similar to Lab 2
    {
        int upperCaseCharacters  = toupper(c);
        putchar(upperCaseCharacters);
    }
}
