// future prod
/*                                                                                                                                                              
 * @file     future_prod.c                                                                                                                                 
 *                
 */
/* Embedded Xinu, Copyright (C) 2015.  All rights reserved. */

#include <future.h>

void future_prod(future* fut) 
{
  irqmask im;
  int status;
  int msg_ptr;
  
  msg_ptr = 1000;

  status = future_set(fut, &msg_ptr);
  if(status < 1) 
  {
    im = disable();
    printf("SYSERR \n");
    restore(im);
  }
}
