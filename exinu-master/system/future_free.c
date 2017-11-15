// future free

#include <future.h>


syscall future_free(future* futre)
{
  irqmask im;                                          
  im = disable(); 

  futre->state = FUTURE_EMPTY;
  restore(im);
  return OK;
}
