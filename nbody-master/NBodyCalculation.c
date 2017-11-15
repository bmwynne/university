// Created by: Brandon Wynne
// Created on: 10/31/2014
// Last Modified by: Brandon Wynne
// Last Modified on: 11/21/2014
// File: NBodyCalculation.c
// Project: NBody-Problem
// Special thanks to Mathew Anderson for the compution help 
// Headers


#include "inc/Vector.h"
#include "inc/NBodyCalculation.h"
#include <hpx/hpx.h>

hpx_action_t _main                 = 0;
hpx_action_t _compute_accel        = 0;

// rand_lim Created by Jerry Coffin
double random_limit(double limit) {
    /* return a random number between 0 and limit inclusive.
     */
    double divisor = RAND_MAX/(limit+1);
    double retval;
    do {
        retval = rand() / divisor;
    }
    while (retval > limit);
    return retval;
}
// This function randomly seeds bodies
void random_body_generator(int number_of_bodies, Body *body_array) {
    int i;
    srand(time(NULL));
    for (i = 0; i < number_of_bodies; i++) {
        body_array[i].ID         = i;
        body_array[i].mass       = 1;
        body_array[i].position.x = i + random_limit(10);
        body_array[i].position.y = i + random_limit(10);
        body_array[i].position.z = i + random_limit(10);
        // Making sure the initial velocities are 0
        memset(&body_array[i].velocity, 0, sizeof(My_Vector));
    }
}

double distance(My_Vector *position1,My_Vector *position2) {
    double distance = sqrt(pow(position2->x - position1->x,2) + pow(position2->y - position1->y,2) + pow(position2->z - position1->z,2));
    return distance;
}



int _main_action(int number_of_bodies) {
  
  // Create acceleration arrays within a global address space such that -
  // different localities may utilize them.
  hpx_addr_t accel_array_x = hpx_gas_global_calloc(number_of_bodies, sizeof(double));
  hpx_addr_t accel_array_y = hpx_gas_global_calloc(number_of_bodies, sizeof(double));
  hpx_addr_t accel_array_z = hpx_gas_global_calloc(number_of_bodies, sizeof(double));

  // Broadcast the arrays to all localities
  hpx_bcast_sync(_compute_accel, &accel_array_x, sizeof(accel_array_x));
  hpx_bcast_sync(_compute_accel, &accel_array_y, sizeof(accel_array_y));
  hpx_bcast_sync(_compute_accel, &accel_array_z, sizeof(accel_array_z));

  // And Gate for Completion
  hpx_addr_t complete = hpx_lco_and_new(number_of_bodies);
  for (int i = 0; i < number_of_bodies; i++) {
    hpx_addr_t array_x = hpx_addr_add(accel_array_x, i*sizeof(double), sizeof(double));
    hpx_addr_t array_y = hpx_addr_add(accel_array_y, i*sizeof(double), sizeof(double));
    hpx_addr_t array_z = hpx_addr_add(accel_array_z, i*sizeof(double), sizeof(double));

    hpx_call(array_x, _compute_accel, complete, &i, sizeof(i));
    hpx_call(array_y, _compute_accel, complete, &i, sizeof(i));
    hpx_call(array_z, _compute_accel, complete, &i, sizeof(i));
  }
  
  hpx_lco_wait(complete);
  hpx_lco_delete(complete, HPX_NULL);
}
  

int _compute_accel_action(void *index, int number_of_bodies, Body *body_array) {
  
  hpx_addr_t local = hpx_thread_current_target();
  double *point = NULL;

  if (!hpx_gas_try_pin(local, (void**)&point)) {
    return HPX_RESEND;
  }

  int i = index;

  for (int j = 0; j < number_of_bodies; j++) {
    if (i != j) {
      double dx = body_array[j].position.x - body_array[i].position.x;
      double dy = body_array[j].position.y - body_array[i].position.y;
      double dz = body_array[j].position.z - body_array[i].position.z;
      double dist = distance(&body_array[i].position, &body_array[j].position);
      *point += (G * body_array[j].mass) * dx / pow(dist,3);
    }
  }
   // UPDATE
  for (i = 0; i < number_of_bodies; i++) {
    // Update Positions
    body_array[i].position.x = body_array[i].position.x + (body_array[i].velocity.x * Time_STEP) + (.5 * (*point) * pow(Time_STEP,2));
    body_array[i].position.y = body_array[i].position.y + (body_array[i].velocity.y * Time_STEP) + (.5 * (*point) * pow(Time_STEP,2));
    body_array[i].position.z = body_array[i].position.z + (body_array[i].velocity.z * Time_STEP) + (.5 * (*point) * pow(Time_STEP,2));
    // Update Velocities
    body_array[i].velocity.x = body_array[i].velocity.x + (*point * Time_STEP);
    body_array[i].velocity.y = body_array[i].velocity.y + (*point * Time_STEP);
    body_array[i].velocity.z = body_array[i].velocity.z + (*point * Time_STEP);
  
  hpx_gas_unpin(local);
  return HPX_SUCCESS;
  }
}


 
       


