// future cons

/*                                                                                                                                   
 * @file     future_cons.c                                                                                                        
 *                                                                                                                                      
 */
/* Embedded Xinu, Copyright (C) 2008.  All rights reserved. */

#include <future.h>

void future_cons(future* ftr)
{
  irqmask im;
  int *msg_ptr;
  int status;

  status = future_get(ftr, msg_ptr);
  
  im = disable();
  if (status < 1) 
    printf("cons SYSERR\n");
  else    
    printf("cons = %d\n", *msg_ptr);
  restore(im);
  
  if(ftr->get_queue.tail == 0)
  { 
    future_free(ftr);
  }
}

