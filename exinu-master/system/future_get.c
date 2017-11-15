// future get
#include <future.h>
#include <que.h>

/**                                                                                                                                               
 * Get the value of a future set by an operation and 
 * change the state of future from FUTURE_VALID to FUTURE_EMPTY. 
 * @return OK on success SYSERR on failure
 */

syscall future_get(future* fptr, int *value)
{
  irqmask im;

  //if(value != NULL) 
  // {
      if(fptr->flag == FUTURE_EXCLUSIVE)
	{
	  fptr->tid = thrcurrent;
	  wait(set);
	  value = (int *) fptr->value;
      
	  im = disable();
	  printf("future_get() = %d\n", (int) *value);
	  restore(im);
      
	  return OK;
	}
      else if(fptr->flag == FUTURE_SHARED)  
	{
	  enque(&fptr->get_queue, thrcurrent);
	  suspend(thrcurrent);
	  value = (int *) fptr->value;
      
	  im = disable();
	  printf("future_get() = %d\n", (int) *value);
	  restore(im);
      
	  return OK;
	}
      else if(fptr->flag == FUTURE_QUEUE) 
	{
	  if(is_empty(&fptr->set_queue))
	    {
	      enque(&fptr->get_queue, thrcurrent);
	      suspend(thrcurrent);
	      value = (int *) fptr->value;
	      
	      im = disable();
	      printf("future_get() = %d\n", (int) *value);
	      restore(im);
	      
	      return OK;
	    }
	  else 
	    {
	      tid_typ thread;
	      thread = pop(&fptr->set_queue);
	      resume(thread);
	      suspend(thrcurrent);
	      value = (int *) fptr->value;

	      im = disable();
	      printf("future_get() = %d\n", (int) *value);
	      restore(im);
	      
	      return OK;
	    }
	}
      else 
	{
	  return SYSERR;
	}
      // }  
      //return SYSERR;
    
}

