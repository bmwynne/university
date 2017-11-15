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
#include <math.h>

#define UNUSED(x) (void)(x)
static THD_WORKING_AREA(waShell,2048);

static thread_t *shelltp1;

/* SPI configuration, sets up PortA Bit 8 as the chip select for the pressure sensor */
static SPIConfig pressure_cfg = {
  NULL,
  GPIOA,
  8,
  SPI_CR1_BR_2 | SPI_CR1_BR_1,
  0
};

/* SPI configuration, sets up PortE Bit 3 as the chip select for the gyro */
static SPIConfig gyro_cfg = {
  NULL,
  GPIOE,
  3,
  SPI_CR1_BR_2 | SPI_CR1_BR_1,
  0
};

uint8_t pressure_read_register (uint8_t address) {
  uint8_t receive_data;

  address = address | 0x80;            /* Set the read bit (bit 7)         */
  spiAcquireBus(&SPID1);               /* Acquire ownership of the bus.    */
  spiStart(&SPID1, &pressure_cfg);     /* Setup transfer parameters.       */
  spiSelect(&SPID1);                   /* Slave Select assertion.          */
  spiSend(&SPID1, 1, &address);        /* Send the address byte */
  spiReceive(&SPID1, 1,&receive_data); 
  spiUnselect(&SPID1);                 /* Slave Select de-assertion.       */
  spiReleaseBus(&SPID1);               /* Ownership release.               */
  return (receive_data);
}

void pressure_write_register (uint8_t address, uint8_t data) {
  address = address & (~0x80);         /* Clear the write bit (bit 7)      */
  spiAcquireBus(&SPID1);               /* Acquire ownership of the bus.    */
  spiStart(&SPID1, &pressure_cfg);     /* Setup transfer parameters.       */
  spiSelect(&SPID1);                   /* Slave Select assertion.          */
  spiSend(&SPID1, 1, &address);        /* Send the address byte */
  spiSend(&SPID1, 1, &data); 
  spiUnselect(&SPID1);                 /* Slave Select de-assertion.       */
  spiReleaseBus(&SPID1);               /* Ownership release.               */
}

uint8_t gyro_read_register (uint8_t address) {
  uint8_t receive_data;

  address = address | 0x80;            /* Set the read bit (bit 7)         */
  spiAcquireBus(&SPID1);               /* Acquire ownership of the bus.    */
  spiStart(&SPID1, &gyro_cfg);         /* Setup transfer parameters.       */
  spiSelect(&SPID1);                   /* Slave Select assertion.          */
  spiSend(&SPID1, 1, &address);        /* Send the address byte */
  spiReceive(&SPID1, 1,&receive_data); 
  spiUnselect(&SPID1);                 /* Slave Select de-assertion.       */
  spiReleaseBus(&SPID1);               /* Ownership release.               */
  return (receive_data);
}

void gyro_write_register (uint8_t address, uint8_t data) {
  address = address & (~0x80);         /* Clear the write bit (bit 7)      */
  spiAcquireBus(&SPID1);               /* Acquire ownership of the bus.    */
  spiStart(&SPID1, &gyro_cfg);         /* Setup transfer parameters.       */
  spiSelect(&SPID1);                   /* Slave Select assertion.          */
  spiSend(&SPID1, 1, &address);        /* Send the address byte            */
  spiSend(&SPID1, 1, &data); 
  spiUnselect(&SPID1);                 /* Slave Select de-assertion.       */
  spiReleaseBus(&SPID1);               /* Ownership release.               */
}

/* Thread that blinks North LED as an "alive" indicator */
static THD_WORKING_AREA(waCounterThread,128);
static THD_FUNCTION(counterThread,arg) {
  UNUSED(arg);
  while (TRUE) {
    palSetPad(GPIOE, GPIOE_LED3_RED);
    chThdSleepMilliseconds(500);
    palClearPad(GPIOE, GPIOE_LED3_RED);
    chThdSleepMilliseconds(500);
  }
  return 0;
}

static void cmd_myecho(BaseSequentialStream *chp, int argc, char *argv[]) {
  int32_t i;

  (void)argv;

  for (i=0;i<argc;i++) {
    chprintf(chp, "%s\n\r", argv[i]);
  }
}

static void cmd_check(BaseSequentialStream *chp, int argc, char *argv[]){
  int count = 10000;
  if(!strcmp(argv[0], "g")){
    while(count > 1000){
      chprintf(chp, "Register 28 = 0x%02x\n\r",gyro_read_register(0x28));
      count--;
    }
  } else if(!strcmp(argv[0], "p")) {
    while(count>1000){
      chprintf(chp, "Register 28 = 0x%02x\n\r",pressure_read_register(0x28));
      count--;
    }
  }
}

static void cmd_gyro(BaseSequentialStream *chp, int argc, char *argv[]){
  if(argc == 2 || argc == 3){
    if(argc == 3){
      if(!strcmp(argv[0],"w"))
	gyro_write_register(strtol(argv[1], NULL, 16), strtol(argv[2], NULL, 16));
      else chprintf(chp,"Invalid Input: \n\r Param2: {r/w} \n\r");
    } else {
      if(!(strcmp(argv[0], "r") || strcmp(argv[1], "all"))){
	chprintf(chp, "Register 28 = 0x%02x\n\r", gyro_read_register(0x28));
	chprintf(chp, "Register 29 = 0x%02x\n\r", gyro_read_register(0x29));
	chprintf(chp, "Register 2A = 0x%02x\n\r", gyro_read_register(0x2A));
	chprintf(chp, "Register 2B = 0x%02x\n\r", gyro_read_register(0x2B));
	chprintf(chp, "Register 2C = 0x%02x\n\r", gyro_read_register(0x2C));
	chprintf(chp, "Register 2D = 0x%02x\n\r", gyro_read_register(0x2D));
      } else if(!strcmp(argv[0],"r")) 
	chprintf(chp, "Register = 0x%02x\n\r", gyro_read_register(strtol(argv[1],NULL,16))); 
      else {
	chprintf(chp, "Invalid Inputtt \n\r");
      }
    }
  } else {
    chprintf(chp, "Invalid Input \n\r");
  }
}


static void cmd_press(BaseSequentialStream *chp, int argc, char *argv[]){
  if(argc == 2 || argc == 3){
    if(argc == 3){
      if(!strcmp(argv[0],"w")){
	pressure_write_register(strtol(argv[1], NULL, 16), strtol(argv[2], NULL, 16));
	chprintf(chp, "Reg wrote = 0x%02x, Data = 0x%02x\n\r",strtol(argv[1], NULL, 16),strtol(argv[2],NULL,16));
      }
      else chprintf(chp,"Invalid Input: \n\r Param2: {r/w} \n\r");
    } else {
      if(!(strcmp(argv[0], "r") || strcmp(argv[1], "all"))){
	chprintf(chp, "Register 28 = 0x%02x\n\r", pressure_read_register(0x28));
	chprintf(chp, "Register 29 = 0x%02x\n\r", pressure_read_register(0x29));
	chprintf(chp, "Register 2A = 0x%02x\n\r", pressure_read_register(0x2A));
      } else if(!strcmp(argv[0],"r")) {
	chprintf(chp, "Register = 0x%02x\n\r", pressure_read_register(strtol(argv[1], NULL, 16)));
	//chprintf(chp, "Register read = 0x%02x\n\r",strtol(argv[1], NULL, 16));
      }
      else {
	chprintf(chp, "Invalid Inputtt \n\r");
      }
    }
  } else {
    chprintf(chp, "Invalid Input \n\r");
  }
}

static double mb_ft(float mb){
   return (1-pow((mb/1013.25),0.190284))*145366.45;
}

static void cmd_alt(BaseSequentialStream *chp, int argc, char *argv[]){
  if(argc == 1){
    int left = pressure_read_register(0x2A);
    int mid = pressure_read_register(0x29);
    int right = pressure_read_register(0x28);
    int ones = mid/16;
    int wholeNum = (left/16 * 256) + (left%16 * 16) + ones;
    int tenths = mid%16 * 256;
    float decNum = (tenths+right)/4096.0;
    int trial = (int) 4000 * pow(10, -2);
    double power = mb_ft(wholeNum+decNum);
    int feet = (int) power;
    
    
    
    chprintf(chp, "Register 2A = 0x%02x\n\r", left);
    chprintf(chp, "Register 29 = 0x%02x\n\r", mid);
    chprintf(chp, "Register 28 = 0x%02x\n\r", right);
    chprintf(chp, "Register 2A = %d\n\r", left);
    chprintf(chp, "Register 29 = %d\n\r", mid);
    chprintf(chp, "Register 28 = %d\n\r", right);
    chprintf(chp, "one place from 29 = %d\n\r", ones);
    chprintf(chp, "tenths place from 29 = %d\n\r", tenths);
    chprintf(chp, "whole num = %d\n\n\n\n\r", wholeNum);
    //    chprintf(chp, "decimal num = %d\n\r", decNum);
    
    if(!strcmp(argv[0],"f")){
      chprintf(chp, "mb to feet = %d\n\r", feet);
    } else if(!strcmp(argv[0],"m")){
      int meters = (int) power*0.3048;
      chprintf(chp, "mb to meters = %d\n\r", meters);
    } else {
      chprintf(chp, "Invalid Input \n\r");
    }
  } else {
    chprintf(chp, "Invalid Input \n\r");
  }
}


static const ShellCommand commands[] = {
  {"altitude", cmd_alt},
  {"press", cmd_press},
  {"gyro", cmd_gyro},
  {"check", cmd_check},
  {"myecho", cmd_myecho},
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

  /* 
   *  Setup the pins for the spi link on the GPIOA. This link connects to the pressure sensor and the gyro.  
   * 
   */

  palSetPadMode(GPIOA, 5, PAL_MODE_ALTERNATE(5));     /* SCK. */
  palSetPadMode(GPIOA, 6, PAL_MODE_ALTERNATE(5));     /* MISO.*/
  palSetPadMode(GPIOA, 7, PAL_MODE_ALTERNATE(5));     /* MOSI.*/
  palSetPadMode(GPIOA, 8, PAL_MODE_OUTPUT_PUSHPULL);  /* pressure sensor chip select */
  palSetPadMode(GPIOE, 3, PAL_MODE_OUTPUT_PUSHPULL);  /* gyro chip select */
  palSetPad(GPIOA, 8);                                /* Deassert the pressure sensor chip select */
  palSetPad(GPIOE, 3);                                /* Deassert the gyro chip select */

  chprintf((BaseSequentialStream*)&SD1, "\n\rUp and Running\n\r");
  chprintf((BaseSequentialStream*)&SD1, "Gyro Whoami Byte = 0x%02x\n\n\r",gyro_read_register(0x0F));
  chprintf((BaseSequentialStream*)&SD1, "Pressure Whoami Byte = 0x%02x\n\n\r",pressure_read_register(0x0F));
  // CTRL1 Register 
  // Bit 7:6 Data Rate: Datarate 0
  // Bit 5:4 Bandwidth: Bandwidth 3
  // Bit 3: Power Mode: Active
  // Bit 2:0 Axes Enable: X,Y,Z enabled
  uint8_t ctrl1; // == 0111111
  ctrl1 |= (uint8_t) (((uint8_t)0x00) |\
                     ((uint8_t)0x30) |\
		     ((uint8_t)0x08) |\
	  	     ((uint8_t)0x07));
  // CTRL4 Register 
  // Bit 7 Block Update: Continuous */
  // Bit 6 Endianess: LSB first  */
  // Bit 5:4 Full Scale: 500 dps */
  uint8_t ctrl4; // == 0010000
  ctrl4 |= (uint8_t) (((uint8_t)0x00) |\
                      ((uint8_t)0x00) |\
		      ((uint8_t)0x10));
  gyro_write_register(0x20, ctrl1);
  gyro_write_register(0x23, ctrl4); 
  chprintf((BaseSequentialStream*)&SD1, "Gyro Register 20 = 0x%02x\n\r",gyro_read_register(0x20));
  chprintf((BaseSequentialStream*)&SD1, "Gyro Register 23 = 0x%02x\n\r",gyro_read_register(0x23));

  // CTRL1 Register 
  // Bit 7: Power Mode: Active
  // Bit 6:4 Output Data Rate: Press 25, Temp 1 (Hz)
  // Bit 3: Interrupt Circuit: Disabled
  // Bit 2: Block Data Update: Disabled
  // Bit 1: Delta Pressure: Disabled 
  // Bit 0: Serial Interface Mode: 4 wire
  // == 1100000
  int reg_ctrl1;
  reg_ctrl1 |= (uint8_t) (((uint8_t)0x80) |\
			 ((uint8_t)0x40) |\
			 ((uint8_t)0x00) |\
		         ((uint8_t)0x00) |\
	                 ((uint8_t)0x00) |\
	  	         ((uint8_t)0x00));
  pressure_write_register(0x20, reg_ctrl1);
  chprintf((BaseSequentialStream*)&SD1, "Pressure Register 20 = 0x%02x\n\r",pressure_read_register(0x20));


  

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


