// repeattest.c:

extern void repeat_msg(unsigned int msg_id, unsigned int num_repetitions);

int main()
{
  repeat_msg(0, 4);
  repeat_msg(1, 6);
}
