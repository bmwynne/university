#include <prodcons.h>
int n;                            //Definition for global variable 'n'
semaphore consumed, produced;     //Defination for semaphores

/* Now global variables will be on Heap so they are accessible to all the processes i.e. consume and produce */

shellcmd xsh_prodcons(int nargs, char *args[])
{
  //Argument verifications and validations
/*         
  int count = 2000;             // local varible to hold count

  /*Initialise semaphores*/
/*  consumed = semcreate(1);      
  produced = semcreate(0);

  //check args[1] if present assign value to count
  count = atoi(args[1]); 
   
  //create the process produer and consumer and put them in ready queue.
  //Look at the definations of function create and resume in exinu/system folder for reference.      
  resume( create(producer, 1024, 20, "producer", 1, count) );
  resume( create(consumer, 1024, 20, "consumer", 1, count) );
*/




  future *f1, *f2, *f3;
 
  f1 = future_alloc(FUTURE_EXCLUSIVE);
  f2 = future_alloc(FUTURE_EXCLUSIVE);
  f3 = future_alloc(FUTURE_EXCLUSIVE);
 
  resume( create(future_cons, 1024, 20, "fcons1", 1, f1) );
  resume( create(future_prod, 1024, 20, "fprod1", 1, f1) );
  resume( create(future_cons, 1024, 20, "fcons2", 1, f2) );
  resume( create(future_prod, 1024, 20, "fprod2", 1, f2) );
  resume( create(future_cons, 1024, 20, "fcons3", 1, f3) );
  resume( create(future_prod, 1024, 20, "fprod3", 1, f3) );

uint future_prod(future *fut) {
  int i, j;
  j = (int)fut;
  for (i=0; i<1000; i++) {
    j += i;
  }
  future_set(fut, &j);
  return OK;
}

uint future_cons(future *fut) {

  int i, status;
  status = future_get(fut, &i);
  if (status < 1) {
    printf("future_get failed\n");
    return -1;
  }
  printf("it produced %d\n", i);
  return OK;
}
}

