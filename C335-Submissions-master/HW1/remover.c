/*Filename: remover.c *                                                        
 *Part of: C335 Homework/Lab Assignment "Homework 1" *                          
 *Created by: Brandon Wynne *                                                   
 *Created on: 1/27/2014 *                                                       
 *Last Modified by: Brandon Wynne *                                             
 *Last Modified on: 1/28/2014 *                                                 
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>

int remover(char source[], char substring[], char result[]); //Function prototype
int main(void)
{
    // Create Variables
    char source[100], substring[100];
    char result[substring-source];
    char userInputSource, userInputSubstring;
  
    // Printing Menu for User Input
    printf("--------------------------- Remover --------------------------- \n");
    
    // Prompts user
    printf("Insert characters into source: \n \n");
    // Scans user input and places it into source
    scanf("%s", &source);
    // Prints the value of source
    printf("The value of source is: %s \n \n", source);
    
    // Prompts user
    printf("Insert the characters that you want to be the substring: \n \n");
    // Scans user input and places it into substring
    scanf("%s", &substring);
    // Prints the value of substring
    printf("The value of substring is: %s \n \n", substring);
    
    
    // Supposed to check if remover is equal to 1 which means that substring is located in source.
    if (remover(source, substring, result) == 1) {
        // If it is located then it prints result which is substring-source
        printf("The result is: %s \n \n", result);
    } else {
        // Or it is not located and there is nothing to remove
        printf("The substring is not located in the source. There is nothing to remove. \n");
    }
    
   
    
  return (0);
}


int remover(char source[], char substring[], char result[])
{
    
    if (substring == source) {
        return 1;
    }
    else {
        return 0;
    }
    
}


