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

/* resets the CYCLECOUNTER reg to 0 */
#define SCB_DEMCR  (*(volatile uint32_t *)0xE000EDFC)
#define DWT_CYCCNT (*(volatile uint32_t *)0xE0001004)
#define DWT_CTRL   (*(volatile uint32_t *)0xE0001000)
#define CPU_RESET_CYCLECOUNTER    do { SCB_DEMCR = SCB_DEMCR | 0x01000000; \
    DWT_CYCCNT = 0;							\
    DWT_CTRL = DWT_CTRL | 1 ; } while(0)

/* MAX represents number of datum that can be logged to memory */
#define MAX 3000

/* state */
static uint8_t FIRST = 1;
static uint8_t LOGGING = 0;

// instead of using structure, just used short and attach time later
static int DATA[MAX];


/* prototypes */
static double mb_ft(float mb);
static void turnOnLights();
static void turnOffLights();
static int getPresFt();
uint8_t pressure_read_register(uint8_t address);
void pressure_write_register (uint8_t address, uint8_t data);
uint8_t gyro_read_register(uint8_t address);
void gyro_write_register (uint8_t address, uint8_t data);
static void gyroConfig();
static void pressConfig();


/* Triggered when the button is pressed or released. */
static void extcb1(EXTDriver *extp, expchannel_t channel) {

  (void)extp;
  (void)channel;

  FIRST = (FIRST) ? 0 : 1;
  if(!FIRST) LOGGING = (LOGGING) ? 0 : 1;
  if(LOGGING) turnOnLights();
  else turnOffLights();
  
  chSysLockFromISR();
  chSysUnlockFromISR();
}

static const EXTConfig extcfg = {
  {
    {EXT_CH_MODE_BOTH_EDGES | EXT_CH_MODE_AUTOSTART | EXT_MODE_GPIOA, extcb1},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL}
  }
};



/* THREADS*/

#define UNUSED(x) (void)(x)
static THD_WORKING_AREA(waShell,2048);

static thread_t *shelltp1;
static thread_t *dataThd;

/* Thread that write the status of the user button to the south LED */
static THD_WORKING_AREA(waDataThread,128);
static THD_FUNCTION(dataThread,arg) {
  UNUSED(arg);
  //should be 7,169,538
  int wait = 7169538; 
  int index = 0;
  int offset = 4;
  int cycles;
  while(index < MAX){
    while(LOGGING){
      CPU_RESET_CYCLECOUNTER;
      if(!(index < MAX)) break;
      wait += DWT_CYCCNT;
      while(DWT_CYCCNT < wait);
      DATA[index] = getPresFt();
      index++;  
      //chprintf((BaseSequentialStream*)&SD1, "cycles %d\n\r", DWT_CYCCNT);
    }
    if(!(index < MAX)){
      LOGGING = 0;
      turnOffLights();
    }
    chThdSleepMilliseconds(1);
  }
 
}






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



/* SHELL COMMANDS */

static void cmd_mysave(BaseSequentialStream *chp, int argc, char *argv[]) {
  /* FILE *file_path; // File Path to Save Data */
  /* int index; */
  /* file_path = fopen("data.dat","w"); */
  /* if (file_path == NULL) { */
  /*   chprintf(chp,"data.dat failed to open for writing. \n"); // exits if file fails to create */
  /* } */
  /* for (index = 0; index < MAX; index++) { */
  /*   fprintf(file_path, "index: %d : %d \n\r", index, DATA[index]); */
  /* } */
}

static void cmd_myprint(BaseSequentialStream *chp, int argc, char *argv[]){
  int index;
  for(index = 0; index < MAX; index++){
    chprintf(chp, "index %d:       %d\n\r", index, DATA[index]);
  }
  /* int cycles; */
  /* int offset = 4; */
  /* CPU_RESET_CYCLECOUNTER; */
  /*                            */
  /* cycles = DWT_CYCCNT - offset; */
  /* chprintf((BaseSequentialStream*)&SD1, "LOG = %d Cycles\r\n", cycles); */
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


static void cmd_alt(BaseSequentialStream *chp, int argc, char *argv[]){
  if(argc == 1){
    int feet = getPresFt();
    if(!strcmp(argv[0],"f")){
      chprintf(chp, "mb to feet = %d\n\r", feet);
    } else if(!strcmp(argv[0],"m")){
      int meters = (int) feet*0.3048;
      chprintf(chp, "mb to meters = %d\n\r", meters);
    } else {
      chprintf(chp, "Invalid Input \n\r");
    }
  } else {
    chprintf(chp, "Invalid Input \n\r");
  }
}


static const ShellCommand commands[] = {
  {"print", cmd_myprint},
  {"altitude", cmd_alt},
  {"press", cmd_press},
  {"gyro", cmd_gyro},
  {"check", cmd_check},
  {"myecho", cmd_myecho},
  {"save", cmd_mysave},
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




/* Application entry point. */
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

  /* Configure gyro and altimeter registers for reading */
  gyroConfig();
  pressConfig();

  /* Initialize the command shell */ 
  shellInit();
  
  /* Activate EXT driver 1 */
  extStart(&EXTD1, &extcfg);

  /* 
   *  setup to listen for the shell_terminated event. This setup will be stored in the tel  * event listner structure in item 0
   */
  chEvtRegister(&shell_terminated, &tel, 0);
  
  
  shelltp1 = shellCreate(&shell_cfg1, sizeof(waShell), NORMALPRIO);
  dataThd = chThdCreateStatic(waDataThread, sizeof(waDataThread), NORMALPRIO+1, dataThread, NULL);
  
  while (TRUE) {
    chEvtDispatch(fhandlers, chEvtWaitOne(ALL_EVENTS));
  }
}





















/* HELPERS */




static void turnOnLights(){
  palSetPad(GPIOE, GPIOE_LED3_RED);
  palSetPad(GPIOE, GPIOE_LED4_BLUE);
  palSetPad(GPIOE, GPIOE_LED5_ORANGE);
  palSetPad(GPIOE, GPIOE_LED7_GREEN);
  palSetPad(GPIOE, GPIOE_LED9_BLUE);
  palSetPad(GPIOE, GPIOE_LED10_RED);
  palSetPad(GPIOE, GPIOE_LED8_ORANGE);
  palSetPad(GPIOE, GPIOE_LED6_GREEN);
}

static void turnOffLights(){
  palClearPad(GPIOE, GPIOE_LED3_RED);
  palClearPad(GPIOE, GPIOE_LED4_BLUE);
  palClearPad(GPIOE, GPIOE_LED5_ORANGE);
  palClearPad(GPIOE, GPIOE_LED7_GREEN);
  palClearPad(GPIOE, GPIOE_LED9_BLUE);
  palClearPad(GPIOE, GPIOE_LED10_RED);
  palClearPad(GPIOE, GPIOE_LED8_ORANGE);
  palClearPad(GPIOE, GPIOE_LED6_GREEN);
}


static double mb_ft(float mb){
  return (1-pow((mb/1013.25),0.190284))*145366.45;
}


static int getPresFt(){
  int left = pressure_read_register(0x2A);
  int mid = pressure_read_register(0x29);
  int right = pressure_read_register(0x28);
  int wholeNum = (left/16 * 256) + (left%16 * 16) + mid/16;
  int tenths = mid%16 * 256;
  float decNum = (tenths+right)/4096.0;
  double feet = mb_ft(wholeNum+decNum);
  return (int) feet;
}


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


static void gyroConfig(){
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
}
static void pressConfig(){
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
}
