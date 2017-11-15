// Created by     : Brandon Wynne
// Partner        : Paul Conway
// Created on     : Friday, Janurary 16, 2015
// Last edited by : Brandon Wynne
// Last edited on : Friday, Janurary 19, 2015
// File Description:
//    This is the main.c file for lab1 of P442 Embedded Digital Systems. The goal of this lab is to create an Egg Timer.

/*
  ChibiOS - Copyright (C) 2006-2014 Giovanni Di Sirio

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

// Headers
#include "ch.h"
#include "hal.h"
#include "test.h"
#include "chprintf.h"
#include <chstreams.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

// Macros
#define UNUSED(x) (void)(x)

/* This is a thread declaration for a thread that 
   is constantly polling for a 's' characters 
*/
static THD_WORKING_AREA(wa_in_thread, arg) {
    char line[1];
    while (1) {
	chnRead((BaseSequentialStream*)&SD1, &line[0], 1);
	if (line[0] == 's') {
	    chnWrite((BaseSequentialStream*)&SD1, &line[0], 1);
	    chprintf((BaseSequentialStream*)&SD1, "\n");
	    return 1;
	}
    }
}

/* Thread that blinks North LED */
static THD_WORKING_AREA(waCounterThread,128);
static THD_FUNCTION(counterThread,arg) {
    int input_1 = arg;
    input_1 = input_1 * 10;
    thread_t *th;
    th = chThdCreateStatic(wa_in_thread, sizeof(wa_in_thread), NORMALPRIO+1, inThread, NULL);
    while (input_1 > 0) {
	palSetPad(GPIOE, GPIOE_LED3_RED);
	chThdSleepMilliseconds(50);
	palClearPad(GPIOE, GPIOE_LED3_RED);
	chThdSleepMilliseconds(50);
	input_1--;
	if (th->p_u.exitcode == 1) chThdExit(0);
    }
    // Set LED Light PINS After Egg Timer completes
    palSetPad(GPIOE, GPIOE_LED3_RED);
    palSetPad(GPIOE, GPIOE_LED4_BLUE);
    palSetPad(GPIOE, GPIOE_LED5_ORANGE);
    palSetPad(GPIOE, GPIOE_LED6_GREEN);
    palSetPad(GPIOE, GPIOE_LED7_GREEN);
    palSetPad(GPIOE, GPIOE_LED8_ORANGE);
    palSetPad(GPIOE, GPIOE_LED9_BLUE);
    palSetPad(GPIOE, GPIOE_LED10_RED);
    int my_boolean = 1;
    while (my_boolean) {
	if (palReadPad(GPIOA, GPIOA_BUTTON)) {
	    // Clear LED Lights for Blinking
	    palClearPad(GPIOE, GPIOE_LED4_BLUE);
	    palClearPad(GPIOE, GPIOE_LED5_ORANGE);
	    palClearPad(GPIOE, GPIOE_LED6_GREEN);
	    palClearPad(GPIOE, GPIOE_LED7_GREEN);
	    palClearPad(GPIOE, GPIOE_LED8_ORANGE);
	    palClearPad(GPIOE, GPIOE_LED9_BLUE);
	    palClearPad(GPIOE, GPIOE_LED10_RED);
	    my_boolean = 0;
	}
    }
    return 0;
}

/* Thread that write the status of the user button to the south LED */
static THD_WORKING_AREA(waButtonThread,128);
static THD_FUNCTION(buttonThread,arg) {
    UNUSED(arg);
    while (TRUE) {
	if (palReadPad(GPIOA, GPIOA_BUTTON)) { 
	    palSetPad(GPIOE, GPIOE_LED10_RED); 
	}
	else {
	    palClearPad(GPIOE, GPIOE_LED10_RED); 
	}
	chThdSleepMilliseconds(10);
    }
    return 0;
}

/* Thread that echos characters received from the console */
static THD_WORKING_AREA(waEchoThread,128);
static THD_FUNCTION(echoThread,arg) {
    UNUSED(arg);
    uint8_t ch;
    while (TRUE) {
	chnRead((BaseSequentialStream*)&SD1,&ch,1);
	chnWrite((BaseSequentialStream*)&SD1,&ch,1);
    }
    return 0;
}

// This is a character to integer function written for use in ChibiOS.
// This function effectively takes a previously parsed character and converts it to an integer.
static int atoi(char arr[], int is_negative, int index, int awnser) {
    char c = arr[0];
    if((c == '\n') && (index == 0)) return 0;
    else if(c == '\n') return (awnser / 10);
    else {
	int i = c - '0';
	int sub_size = 5 - (index + 1);
	char sub[sub_size];
	memcpy(sub, &arr[1], sub_size);
    
	if(c == '-') is_negative = 1;
	else awnser = awnser + 1;
	if (sub_size > 0) {
	    awnser = awnser * 10;
	    return atoi(sub, is_negative, index + 1, awnser);
	} else {
	    if(is_negative) return (0 - awnser);
	    else return awnser;
	}
    }
}

// This is the get_time() function which both prompts the user,
// and returns time in milliseconds. The time paramaters are
// range from 0-10000 milliseconds. 

static int get_time() {
    char number[5];
    chprintf((BaseSequentialStream*)&SD1, "Please enter time in milliseconds between 0-10000(ms): \n \r");
    int i;
    for (i = 0; i < 6; i++) {
	if (i == 5) {
	    char new_line[1];
	    new_line[0] = '\n';
	    chnWrite((BaseSequentialStream*)&SD1, &new_line[0], 1);
	} else {
	    chnRead((BaseSequentialStream*)&SD1, &number[i], 1);
	    chnWrite((BaseSequentialStream*)&SD1, &number[i], 1);
	    if (number[i] == '\n') i = 6;
	}
    }
    int length = atoi(number, 0, 0, 0);
    if ((length < 0) || (length > 10000)) return get_time();
    else return length;
}

/*
 * Application entry point
 */

// Main Function

int main(void) {
  
    /*
     * System initializations.
     * - HAL initialization, this also initializes the configured device drivers
     *   and performs the board-specific initializations.
     * - Kernel initialization, the main() function becomes a thread and the
     *   RTOS is active.
     */
    halInit();
    chSysInit();

 
    /*
     * Activates the serial driver 1 using the driver default configuration.
     * PC4(RX) and PC5(TX). The default baud rate is 9600.
     */
    sdStart(&SD1, NULL);
    palSetPadMode(GPIOC, 4, PAL_MODE_ALTERNATE(7));
    palSetPadMode(GPIOC, 5, PAL_MODE_ALTERNATE(7));

    // This is an array for character read from an input line
    char line[2];
    // The board says hello to the world. And we are happy because it does so.
    chprintf((BaseSequentialStream*)&SD1, "\n\rUp and Running!\n\r");
    // iterator
    int i;
    // LED time length variable
    int time_length;
    for (i = 0; i < 2; i++) {
	chnRead((BaseSequentialStream*)&SD1, &line[i], 1);
	chnWrite((BaseSequentialStream*)&SD1, &line[i], 1);
	if (line[i] == 's') {
	    chprintf((BaseSequentialStream*)&SD1, "\n");
	    time_length = get_time();
	    i = 2;
	} else {
	    i = 0;
	}
    }


    /*
     * Creates the threads.
     */
    thread_t *tp, *button_tp;
    tp = chThdCreateStatic(waCounterThread, sizeof(waCounterThread), NORMALPRIO+1,
			   counterThread, time_length);
  
  
    /*
      Main spins here while the threads do all of the work. 
    */ 
    while (TRUE) {
	chThdWait(tp);
	time_length = get_time();
	tp = chThdCreateStatic(waCounterThread, sizeof(waCounterThread), NORMALPRIO+1, counterThread, time_length);
    }
}
