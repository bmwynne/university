 #include <stddef.h>
 #include <stdio.h>   
 #include <semaphore.h>

/*Global variable for producer consumer*/
extern int n; /*this is just declaration*/
 
/* Declare the required semaphores */
extern semaphore consumed, produced;   

/*function Prototype*/
void consumer(int count);
void producer(int count);
