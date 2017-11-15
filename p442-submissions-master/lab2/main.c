// Created by     : Brandon Wynne
// Partner        : Max Hollingsworth
// Created on     : Friday, Janurary 23, 2015
// Last edited by : Brandon Wynne
// Last edited on : Saturday, Janurary 24, 2015
// File Description:
//    This is the main.c file for lab2 of P442 Embedded Digital Systems. The goal of this lab is to create
//    commands for the ChibiOS shell.


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

#include "ch.h"
#include "hal.h"
#include "test.h"
#include "shell.h" 
#include "chprintf.h"
#include <chstreams.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

#define UNUSED(x) (void)(x)
int32_t timer_length;  
int32_t timer_input;
int32_t timer_length_storage;


static THD_WORKING_AREA(waShell,2048);

static thread_t *shelltp1;

/* Thread that blinks North LED as an "alive" indicator */
static THD_WORKING_AREA(waCounterThread,128);
static THD_FUNCTION(counterThread,arg) {
  timer_length = arg;
  timer_length = timer_length * 10;
  while (timer_length > 0) {
    palSetPad(GPIOE, GPIOE_LED3_RED);
    chThdSleepMilliseconds(50);
    palClearPad(GPIOE, GPIOE_LED3_RED);
    chThdSleepMilliseconds(50);
    timer_length--;
    //if (th->p_u.exitcode == 1) chThdExit(0);
    if (timer_length == 0) {
      // Set LED Light PINS After Egg Timer completes
      palSetPad(GPIOE, GPIOE_LED3_RED);
      palSetPad(GPIOE, GPIOE_LED4_BLUE);
      palSetPad(GPIOE, GPIOE_LED5_ORANGE);
      palSetPad(GPIOE, GPIOE_LED6_GREEN);
      palSetPad(GPIOE, GPIOE_LED7_GREEN);
      palSetPad(GPIOE, GPIOE_LED8_ORANGE);
      palSetPad(GPIOE, GPIOE_LED9_BLUE);
      palSetPad(GPIOE, GPIOE_LED10_RED);
    }
  }
  return 0;
}

  static int lookup(char* dir) {
    char *table[8] = {"N","NE","E","SE","S","SW","W","NW"};
    uint8_t i; 
    for (i = 0; i < 8; i++) {
      if (strcmp(table[i], dir) == 0) {
	return i;
      }
    }
    return 0;
  }

  static int cmd_timer(BaseSequentialStream *chp, int argc, char *argv[]) {
    (void)argv;
    thread_t *tp;

    if (strcmp(argv[0], "set") == 0) {
      timer_input = atoi(argv[1]);
      if ((timer_input < 0) || (timer_input > 10000)) chprintf((BaseSequentialStream*)&SD1, "Timeout value not within parameters. \n");
      tp = chThdCreateStatic(waCounterThread, sizeof(waCounterThread), NORMALPRIO+1, counterThread, timer_input);
      return timer_input;
    }
    if (strcmp(argv[0], "gettime") == 0) {
	if (timer_length == -1) {
	  chprintf((BaseSequentialStream*)&SD1,"Time: %d \n", timer_length_storage);
	} else {
	  chprintf((BaseSequentialStream*)&SD1,"Time: %d \n", timer_length);
	}
    }
    if (strcmp(argv[0], "stop") == 0) {
      timer_length_storage = timer_length;
      timer_length = 0;
    }
    if (strcmp(argv[0], "start") == 0) {
      timer_length = timer_length_storage;
      tp = chThdCreateStatic(waCounterThread, sizeof(waCounterThread), NORMALPRIO+1, counterThread, timer_length);
      
    }
  }


  static void cmd_ledset(BaseSequentialStream *chp, int argc, char *argv[]) {
    (void)argv;
    int on = 0;
    if (strcmp(argv[1],"on") == 0) {
      on = 1;
    }
    switch (lookup(argv[0])) {
    case 0 :
      palClearPad(GPIOE, GPIOE_LED3_RED);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED3_RED);
      }
      break;
    case 1 :
      palClearPad(GPIOE, GPIOE_LED5_ORANGE);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED5_ORANGE);
      }
      break;
    case 2 :
      palClearPad(GPIOE, GPIOE_LED7_GREEN);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED7_GREEN);
      }
      break;
    case 3 :
      palClearPad(GPIOE, GPIOE_LED9_BLUE);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED9_BLUE);
      }
      break;
    case 4 :
      palClearPad(GPIOE, GPIOE_LED10_RED);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED10_RED);
      }
      break;
    case 5 :
      palClearPad(GPIOE, GPIOE_LED8_ORANGE);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED8_ORANGE);
      }
      break;
    case 6 :
      palClearPad(GPIOE, GPIOE_LED6_GREEN);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED6_GREEN);
      }
      break;
    case 7 :
      palClearPad(GPIOE, GPIOE_LED4_BLUE);
      if (on) {
	palSetPad(GPIOE, GPIOE_LED4_BLUE);
      }
      break;
    }  
  }

  static void cmd_ledread(BaseSequentialStream *chp, int argc, char *argv[]) {
    (void)argv;
  
    switch (lookup(argv[0])) {
    case 0 :
      if (palReadPad(GPIOE, GPIOE_LED3_RED)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 1 :
      if (palReadPad(GPIOE, GPIOE_LED5_ORANGE)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 2 :
      if (palReadPad(GPIOE, GPIOE_LED7_GREEN)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 3 :
      if (palReadPad(GPIOE, GPIOE_LED9_BLUE)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 4 :
      if (palReadPad(GPIOE, GPIOE_LED10_RED)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 5 :
      if (palReadPad(GPIOE, GPIOE_LED8_ORANGE)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 6 :
      if (palReadPad(GPIOE, GPIOE_LED6_GREEN)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    case 7 :
      if (palReadPad(GPIOE, GPIOE_LED4_BLUE)) {
	chprintf((BaseSequentialStream*)&SD1, "ON\n\r");
      } else {
	chprintf((BaseSequentialStream*)&SD1, "OFF\n\r");
      }
      break;
    }

  }
  static void cmd_myecho(BaseSequentialStream *chp, int argc, char *argv[]) {
    int32_t i;

    (void)argv;

    for (i=0;i<argc;i++) {
      chprintf(chp, "%s\n\r", argv[i]);
    }
  }

  static const ShellCommand commands[] = {
    {"ledset", cmd_ledset},
    {"ledread", cmd_ledread},
    {"myecho", cmd_myecho},
    {"timer", cmd_timer},
    {NULL, NULL}
  };

  static const ShellConfig shell_cfg1 = {
    (BaseSequentialStream *)&SD1,
    commands
  };

  static void termination_handler(eventid_t id) {

    (void)id;
    chprintf((BaseSequentialStream*)&SD1, "Shell Died\n\r");

    if (shelltp1 && chThdTerminatedX(shelltp1)) {
      chThdWait(shelltp1);
      chprintf((BaseSequentialStream*)&SD1, "Restarting from termination handler\n\r");
      chThdSleepMilliseconds(100);
      shelltp1 = shellCreate(&shell_cfg1, sizeof(waShell), NORMALPRIO);
    }
  }

  static evhandler_t fhandlers[] = {
    termination_handler
  };

  /*
   * Application entry point.
   */

  int main(void) {
    event_listener_t tel;
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
    chprintf((BaseSequentialStream*)&SD1, "\n\rUp and Running\n\r");

    /* Initialize the command shell */ 
    shellInit();

    /* 
     *  setup to listen for the shell_terminated event. This setup will be stored in the tel  * event listner structure in item 0
     */
    chEvtRegister(&shell_terminated, &tel, 0);

    shelltp1 = shellCreate(&shell_cfg1, sizeof(waShell), NORMALPRIO);
    chThdCreateStatic(waCounterThread, sizeof(waCounterThread), NORMALPRIO+1, counterThread, NULL);

    while (TRUE) {
      chEvtDispatch(fhandlers, chEvtWaitOne(ALL_EVENTS));
    }
  }


