// future set

#include <stddef.h>
#include <future.h>
#include <que.h>


void resume_one_get_q(que* get_q);
void resume_get_q(que* get_q);
/**                                                                                                                                               
 * Set a value in a future and 
 * changes state from FUTURE_EMPTY or FUTURE_WAITING to FUTURE_VALID 
 * @return OK on success SYSERR on failure
 */
syscall future_set(future* fptr, int *value)
{
  if(value != NULL)
    {
      if(fptr->flag == FUTURE_EXCLUSIVE)
	{
	  printf("1\n");
	  fptr->value = (int *) value;
	  fptr->state = FUTURE_VALID;                  /* change from EMPTY or WAITING to VALID */
	  fptr->tid = FUTURE_NO_TID;
	  signal(set);
  
	  return OK;
	}
      else if(fptr->flag == FUTURE_SHARED)
	{
	  int tail = fptr->set_queue.tail;
	  printf("2 : tial = %d\n", tail);
	  if(tail == 0)
	    {
	      fptr->value = (int *) value;
	      fptr->state = FUTURE_VALID;

	      resume_get_q(&fptr->get_queue);
	      return OK;
	    }
	  else 
	    {
	      printf("Cannot call ftr.set() again\n");
	      return SYSERR;
	    }
	}
      else if(fptr->flag == FUTURE_QUEUE)
	{
	  printf("3\n");
	  int get_is_empty = is_empty(&fptr->get_queue);                                  
	  int set_is_empty = is_empty(&fptr->set_queue);                                    
                                                                                         
	  if(get_is_empty)                                                             
	    {                                                                                        
	      enque(&fptr->set_queue, thrcurrent);  
	      suspend(thrcurrent);                                             
	    }                                                        
	  fptr->value = (int *) value;                                                       
	  fptr->state = FUTURE_VALID;                                                       
          
	  pop(&fptr->set_queue);                                                             
	  resume_one_get_q(&fptr->get_queue);
	  
	  return OK;                                                     	    
	} 
      else 
	{
	  return SYSERR;
	}
    }
  else 
    {
      return SYSERR;
    }
}


void resume_one_get_q(que* get_q){                                                                                                                                    
  tid_typ thread;                                                                                                                                                                                                
  thread = pop(get_q);                                                                                                                                                                                
  resume(thread);                                                                                                                                                                                        
}    


void resume_get_q(que* get_q){
  tid_typ thread;
  while(!is_empty(get_q))
  {
      thread = pop(get_q);
      resume(thread);
  }
}
