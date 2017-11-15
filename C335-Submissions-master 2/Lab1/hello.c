// This is a program that outputs Hello World
// Created by Brandon Wynne
// Created on Janurary 16, 2014

// including libraries
#include <stdio.h>
#include <unistd.h>
int main()
{

  //creating an array
  char* x = new char[100];

  //creating infinite loop
  while (1) {
    printf("Hello World \n");
    // implimenting sleep function from <unistd.h>
    sleep(3);

  }

      return 0;
}
