/*
 * @file     xsh_hello.c
 *
 *
 */
/* Embedded Xinu, Copyright (C) 2008. All rights reserved. */

// Created by      : Brandon Wynne
// Partner         : Paul Conway
// Created on      : Jan 19, 2014 4:14
// Last modified by: Brandon Wynne
// Last modified on: Jan 19, 2014

#include <stddef.h>
#include <stdio.h>
#include <string.h>

/**
 * @inggroup shell
 * Shell command (hello).
 * @param nargs number of arguments in args array
 * @param args  array of arguments
 * @return OK for success, SYSERR for syntax error
 */

shellcmd xsh_hello(int nargs, char *args[]) {
  
  /* Output help, if '--help' argument was supplied */

  if (nargs == 2 && strcmp(args[1], "--help") == 0) {
    printf("Usage: ./xsh_hello <-string> \n\n", args[1]);
    printf("Description:\n");
    printf("\tDisplays a friendly greeting, hello, followed by a string.\n");
    printf("Options:\n");
    printf("\t--help\tdisplay this help and exit\n");
    return OK;
  }

  /* Check for the correct number of arguments */

  if (nargs > 2) {
    fprintf(stderr, "%s: too many arguments\n", args[0]);
    fprintf(stderr, "try '%s --help' for more information\n", args[0]);
    return SYSERR;
  }
  if (nargs < 1) {
    fprintf(stderr, "%s: too few arguments\n", args[0]);
    fprintf(stderr, "Try '%s --help' for more information\n", args[0]);
    return SYSERR;
  }

  /* Print hello and string to command line */
  printf("Hello %s, Welcome to the world of Xinu!!\n",args[1]);
 
  return OK;
}
