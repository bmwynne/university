  //
  // poly.c
  //
#include<stdio.h>
  typedef union {
    unsigned char ccc[8];
    short sss[4];
    int iii[2];
    float fff[2];
    double ddd;
  } Poly;

  extern void dump_memory(void *, int);

  int main() {
    int i;
    Poly rawdata[6];

    for (i = 0; i < 8; i++) rawdata[0].ccc[i] = 'a' + i;
    for (i = 0; i < 8; i++) rawdata[1].ccc[i] = 42 + i;
    for (i = 0; i < 4; i++) rawdata[2].sss[i] = 5280 + i;
    for (i = 0; i < 2; i++) rawdata[3].iii[i] = 'A' + i;
    rawdata[4].fff[0] = 6.022e+23;
    rawdata[4].fff[1] = 2.9979245833e+8 ;
    rawdata[5].ddd = 3.14159265358979323846264;

    dump_memory(rawdata, sizeof(rawdata));

    return 0;
  }
