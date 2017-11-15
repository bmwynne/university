// Created by: Brandon Wynne
// Created on: 10/31/2014
// Last Modified by: Brandon Wynne
// Last Modified on: 12/08/2014
// File: NBodyCalculation.h
// Project: NBody-Problem
// Special thanks to Mathew Anderson for the compution help 

#ifndef __NBody_Problem__nBodyCalculation__
#define __NBody_Problem__nBodyCalculation__

//------------------- Headers -------------------
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include "Vector.h"


// ------------------- Constants -------------------
#define Time_STEP .0001
#define G 1


//------------------- Structures -------------------
typedef struct {
    int ID;
    double mass;
    My_Vector position;
    My_Vector velocity;
}Body;


//------------------- Functions -------------------

double random_limit(double limit);
void random_body_generator(int number_of_bodies, Body *body_array);
double distance(My_Vector *position1,My_Vector *position2);
void update_bodies(Body *body_array, size_t sizeArgument);

#endif /* defined(__NBody_Problem__nBodyCalculation__) */
