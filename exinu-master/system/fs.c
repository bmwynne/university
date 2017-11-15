// Created by: Brandon Wynne


#include <kernel.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <bufpool.h>

#if FS
#include <fs.h>

static struct fsystem fsd;
int dev0_numblocks;
int dev0_blocksize;
char *dev0_blocks;

extern int dev0;

char block_cache[512];


#define SB_BLK 0
#define BM_BLK 1
#define RT_BLK 2

#define NUM_FD 16

struct filetable ftcontainer[NUM_FD];
int next_open_fd = 0;

struct id_linked_list inode_head;
struct id_linked_list inode_tail;
struct id_linked_list inode_list[DEFAULT_NUM_INODES];

#define INODES_PER_BLOCK (fsd.blocksz / sizeof(struct inode))
#define NUM_INODE_BLOCKS (( (fsd.ninodes % INODES_PER_BLOCK) == 0) ? fsd.ninodes / INODES_PER_BLOCK : (fsd.ninodes / INODES_PER_BLOCK) + 1)
#define FIRST_INODE_BLOCK 2


int fileblock_to_diskblock(int dev, int fd, int fileblock);

/* Your code goes here! */

int get_block(void) {
    int blck_id;
    int free_block = 0;
    for (blck_id = 0; blck_id < dev0_numblocks; blck_id++) {
        free_block = (free_block + 1) % dev0_numblocks;
        if (!getmaskbit(free_block)) {
            setmaskbit(free_block);
            return free_block;
        }
    }
    return SYSERR;
}

int get_inode(void) {
    struct id_linked_list *next_id_node;
    next_id_node = inode_head.next_node;
    if (next_id_node->current_node == -1 || next_id_node->current_node > fsd.ninodes) {
        return SYSERR;
    }
    inode_head.next_node = next_id_node->next_node;
    fsd.inodes_used++;
    return next_id_node->current_node;
}

int get_fd(void) {
    return next_open_fd++;
}

int fopen(char *filename, int flags) {
    int fd;
    ftcontainer[fd].state = FSTATE_OPEN;
    return OK;
}

int fclose(int fd) {
    ftcontainer[fd].state = FSTATE_CLOSED;
    return OK;
}


int fcreate(char *filename, int mode) {
    int new_inode_id;
    struct dirent file;
    struct inode node;
    file.inode_num = new_inode_id;
    memcpy(file.name, filename, FILENAMELEN);
    
    node.id = new_inode_id;
    node.type = INODE_TYPE_FILE;
    node.nlink = 1;
    node.device = 0;
    
    int fd = get_fd();
    ftcontainer[fd].state = FSTATE_OPEN;
    ftcontainer[fd].fileptr = 0;
    ftcontainer[fd].de = &file;
    
    setmaskbit(new_inode_id);
    fsd.root_dir.numentries++;
    fsd.root_dir.entry[fd] = file;
    setmaskbit(new_inode_id);
    return new_inode_id;
}

int fseek(int fd, int offset) {
    ftcontainer[fd].fileptr = ftcontainer[fd].fileptr + offset;
    return ftcontainer[fd].fileptr;
}

int fread(int fd, void *buf, int nbytes) {
    return NULL;
}

int fwrite(int fd, void *buf, int nbytes) {
    return NULL;
}

int mkfs(int dev, int num_inodes) {
  int i;

  if (dev == 0) {
    fsd.nblocks = dev0_numblocks;
    fsd.blocksz = dev0_blocksize;
  }
  else {
    printf("Unsupported device\n");
    return SYSERR;
  }

  if (num_inodes < 1) {
    fsd.ninodes = DEFAULT_NUM_INODES;
  }
  else {
    fsd.ninodes = num_inodes;
  }

  i = fsd.nblocks;
  while ( (i % 8) != 0) {i++;}
  fsd.freemaskbytes = i / 8;

  if ((fsd.freemask = memget(fsd.freemaskbytes)) == (void *)SYSERR) {
    printf("mkfs memget failed.\n");
    return SYSERR;
  }

  /* zero the free mask */
  for(i=0;i<fsd.freemaskbytes;i++) {
    fsd.freemask[i] = '\0';
  }

  fsd.inodes_used = 0;

  /* write the fsystem block to SB_BLK, mark block used */
  setmaskbit(SB_BLK);
  bwrite(dev0, SB_BLK, 0, &fsd, sizeof(struct fsystem));

  /* write the free block bitmask in BM_BLK, mark block used */
  setmaskbit(BM_BLK);
  bwrite(dev0, BM_BLK, 0, fsd.freemask, fsd.freemaskbytes);

  return 1;
}

int fileblock_to_diskblock(int dev, int fd, int fileblock) {
  int diskblock;

  if (fileblock >= INODEBLOCKS - 2) {
    printf("No indirect block support\n");
    return SYSERR;
  }

  diskblock = ftcontainer[fd].in.blocks[fileblock]; //get the logical block address

  return diskblock;
}

/* read in an inode and fill in the pointer */
int
get_inode_by_num(int dev, int inode_number, struct inode *in) {
  int bl, inn;
  int inode_off;

  if (dev != 0) {
    printf("Unsupported device\n");
    return SYSERR;
  }
  if (inode_number > fsd.ninodes) {
    printf("get_inode_by_num: inode %d out of range\n", inode_number);
    return SYSERR;
  }

  bl = inode_number / INODES_PER_BLOCK;
  inn = inode_number % INODES_PER_BLOCK;
  bl += FIRST_INODE_BLOCK;

  inode_off = inn * sizeof(struct inode);

  /*
  printf("in_no: %d = %d/%d\n", inode_number, bl, inn);
  printf("inn*sizeof(struct inode): %d\n", inode_off);
  */

  bread(dev0, bl, 0, &block_cache[0], fsd.blocksz);
  memcpy(in, &block_cache[inode_off], sizeof(struct inode));

  return OK;

}

int
put_inode_by_num(int dev, int inode_number, struct inode *in) {
  int bl, inn;

  if (dev != 0) {
    printf("Unsupported device\n");
    return SYSERR;
  }
  if (inode_number > fsd.ninodes) {
    printf("put_inode_by_num: inode %d out of range\n", inode_number);
    return SYSERR;
  }

  bl = inode_number / INODES_PER_BLOCK;
  inn = inode_number % INODES_PER_BLOCK;
  bl += FIRST_INODE_BLOCK;

  /*
  printf("in_no: %d = %d/%d\n", inode_number, bl, inn);
  */

  bread(dev0, bl, 0, block_cache, fsd.blocksz);
  memcpy(&block_cache[(inn*sizeof(struct inode))], in, sizeof(struct inode));
  bwrite(dev0, bl, 0, block_cache, fsd.blocksz);

  return OK;
}

/* specify the block number to be set in the mask */
int setmaskbit(int b) {
  int mbyte, mbit;
  mbyte = b / 8;
  mbit = b % 8;

  fsd.freemask[mbyte] |= (0x80 >> mbit);
  return OK;
}

/* specify the block number to be read in the mask */
int getmaskbit(int b) {
  int mbyte, mbit;
  mbyte = b / 8;
  mbit = b % 8;

  return( ( (fsd.freemask[mbyte] << mbit) & 0x80 ) >> 7);
  return OK;

}

/* specify the block number to be unset in the mask */
int clearmaskbit(int b) {
  int mbyte, mbit, invb;
  mbyte = b / 8;
  mbit = b % 8;

  invb = ~(0x80 >> mbit);
  invb &= 0xFF;

  fsd.freemask[mbyte] &= invb;
  return OK;
}

/* This is maybe a little overcomplicated since the lowest-numbered
   block is indicated in the high-order bit.  Shift the byte by j
   positions to make the match in bit7 (the 8th bit) and then shift
   that value 7 times to the low-order bit to print.  Yes, it could be
   the other way...  */

void printfreemask(void) {
  int i,j;

  for (i=0; i < fsd.freemaskbytes; i++) {
    for (j=0; j < 8; j++) {
      printf("%d", ((fsd.freemask[i] << j) & 0x80) >> 7);
    }
    if ( (i % 8) == 7) {
      printf("\n");
    }
  }
  printf("\n");
}

#endif /* FS */
