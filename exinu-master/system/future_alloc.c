// future alloc

static int futnew(void);
future* future_alloc(int future_flag)
{
  future *ftr_ptr; 
  int fid; 
  
  fid = futnew();

  if (SYSERR == (int)fid)
  {     
    printf("BAD ALLOC\n");
    return (future *) SYSERR;
  }

  ftr_ptr = &futtab[fid];
  *ftr_ptr->value = NULL;
  ftr_ptr->flag = future_flag;
  ftr_ptr->state = FUTURE_WAITING;
  ftr_ptr->tid = FUTURE_NO_TID;
  ftr_ptr->fid = fid;
  init_que(&ftr_ptr->get_queue); 
  init_que(&ftr_ptr->set_queue);

  return ftr_ptr;

}
static int futnew(void)
{
  int fid;
  int nextfid = 0;

  for (fid = 0; fid < N_FUTURES; fid++)         /* check all NTHRAD slots */
    {
      nextfid = fid % N_FUTURES;
      if (FUTURE_EMPTY == futtab[nextfid].state)
	return nextfid;
    }
  return SYSERR;
}
