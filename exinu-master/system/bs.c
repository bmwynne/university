/* This file implements the memory "block store" for use by the in-memory filesystem */

#include <kernel.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <bufpool.h>

extern int dev0_numblocks;
extern int dev0_blocksize;
extern char *dev0_blocks;
int dev0 = 0;

#if FS
#include <fs.h>

int mkbsdev(int dev, int blocksize, int numblocks) {

  if (dev != 0) {
    printf("Unsupported device: %d\n", dev);
    return SYSERR;
  }

  if (blocksize != 0) {
    dev0_blocksize = blocksize;
  }
  else {
    dev0_blocksize = MDEV_BLOCK_SIZE;
  }

  if (numblocks != 0) {
    dev0_numblocks =  numblocks;
  }
  else {
    dev0_numblocks =  MDEV_NUM_BLOCKS;
  }

  if ( (dev0_blocks = memget(dev0_numblocks * dev0_blocksize)) == (void *)SYSERR) {
    printf("mkbsdev memgetfailed\n");
    return SYSERR;
  }

  return OK;

}

int 
bread(int dev, int block, int offset, void *buf, int len) {
  char *bbase;

  if (dev != 0) {
    printf("Unsupported device\n");
    return SYSERR;
  }
  if (offset >= dev0_blocksize) {
    printf("Bad offset\n");
    return SYSERR;
  }

  bbase = &dev0_blocks[block * dev0_blocksize];

  memcpy(buf, (bbase+offset), len);

  return OK;

}


int 
bwrite(int dev, int block, int offset, void * buf, int len) {
  char *bbase;

  if (dev != 0) {
    printf("Unsupported device\n");
    return SYSERR;
  }
  if (offset >= dev0_blocksize) {
    printf("Bad offset\n");
    return SYSERR;
  }

  bbase = &dev0_blocks[block * dev0_blocksize];

  memcpy((bbase+offset), buf, len);
  
  return OK;

}

#endif /* FS */
