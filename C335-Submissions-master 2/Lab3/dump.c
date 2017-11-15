//
// dump.c
//
#include <stdio.h>
void dump_memory(void *p, int len)
{
  int i;

  for (i = 0; i < len; i++) {
    printf("%8p %c %#4x %5d %10d %f %f \n",
	   p + i, *(unsigned char *)(p + i),
	   *(char *)(p + i),*(short *)(p + i),*(int *)(p + i),*(float *)(p + i),
	   *(double *)(p + i));
  }
}
