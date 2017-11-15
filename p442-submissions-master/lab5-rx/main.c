/*
    Some Device Drivers for ChibiOS/RT

    Copyright (C) 2014 Konstantin Oblaukhov

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
#include "chstreams.h"
#include "nrf24l01.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>


#define UNUSED(x) (void)(x)

// Globals 
static NRF24L01Driver nrf24l01;
static mutex_t nrfMutex;
static uint8_t addr[5] = "METEO"; // was METEO
static char serialInBuf[32];




static THD_WORKING_AREA(waShell, 2048);
static THD_WORKING_AREA(recieverWorkingArea, 128);
static thread_t *shelltp1;
static thread_t *rxthd1;
 


// ----- Nordic Chip-----
static const SPIConfig nrf24l01SPI = {
    NULL,
    GPIOC,
    GPIOC_PIN1,
    SPI_CR1_BR_2|SPI_CR1_BR_1|SPI_CR1_BR_0,
    0
};

static const NRF24L01Config nrf24l01Config = {
    &SPID3,
    GPIOC,
    GPIOC_PIN2
};

static void nrfExtCallback(EXTDriver *extp, expchannel_t channel);
static const EXTConfig extcfg = {
  {
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_DISABLED, NULL},
    {EXT_CH_MODE_FALLING_EDGE | EXT_CH_MODE_AUTOSTART | EXT_MODE_GPIOC, nrfExtCallback},
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


static void nrfExtCallback(EXTDriver *extp, expchannel_t channel) {
  UNUSED(extp);
  UNUSED(channel);
  nrf24l01ExtIRQ(&nrf24l01);
}

void initNRF24L01(NRF24L01Driver *nrfp) {
  nrf24l01EnableDynamicSize(nrfp);
  nrf24l01EnableDynamicPipeSize(nrfp, 0x3f);
  
  nrf24l01SetTXAddress(nrfp, addr);         // TX Address
  nrf24l01SetRXAddress(nrfp, 0, addr);      // RX Address
  nrf24l01SetPayloadSize(nrfp, 0, 32);      // Message Size
  nrf24l01SetChannel(nrfp, 10);             // ------ RX Channel ------
 
  nrf24l01FlushRX(nrfp);
  nrf24l01FlushTX(nrfp);
  nrf24l01ClearIRQ(nrfp, NRF24L01_RX_DR | NRF24L01_TX_DS | NRF24L01_MAX_RT);

  nrf24l01PowerUp(nrfp);
}

static msg_t receiverThread(void *arg) {
  int i;
  UNUSED (arg);
  chRegSetThreadName("receiver");
  
  while (TRUE) {
    chMtxLock(&nrfMutex);
    size_t s = chnReadTimeout(&nrf24l01.channels[0], serialInBuf, 32, MS2ST(10));
    chMtxUnlock(&nrfMutex);
    if (s) {
      for (i=0;i<(int)s;i++) {
      	chprintf((BaseSequentialStream*)&SD1, "%d ", serialInBuf[i]);
      }
      chprintf((BaseSequentialStream*)&SD1, "\n\r", s);
    }
    chSchDoYieldS();
  }
  return 0;
}



// ----- shell----- 
static void cmd_nrf(BaseSequentialStream *chp, int argc, char *argv[]) {
  
  if ((argc <= 4) && (argc != 0 )) {
    if (strcmp(argv[0], "ch") == 0) {     
      uint8_t new_ch = atoi(argv[1]);
      nrf24l01SetChannel(&nrf24l01, new_ch);
      chprintf(chp, "Channel set to %d \n\r", new_ch);
    }
    if (strcmp(argv[0], "addr") == 0) {
      int i;
      for(i = 0; i < 5; i++)
	addr[i] = (uint8_t)argv[1][i];
      nrf24l01SetRXAddress(&nrf24l01, 0, addr);
      chprintf(chp, "Address set to %s \n\r", addr);
    }
    if (strcmp(argv[0], "rx") == 0) {
    
    }
  } else {
    chprintf(chp, "Invalid Command. Commands are: \n\r nrf ch <channel number> \n\r nrf addr <3-5 bit addr> \n\r nrf rx \n\r");
  }
}

static const ShellCommand commands[] = {
  {"nrf", cmd_nrf},
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



// ----- Main -----

int main(void) {
 
  event_listener_t tel;
 
  halInit();
  chSysInit(); 
  shellInit();
  
  sdStart(&SD1, NULL);
  palSetPadMode(GPIOC, 4, PAL_MODE_ALTERNATE(7));
  palSetPadMode(GPIOC, 5, PAL_MODE_ALTERNATE(7));

  chprintf((BaseSequentialStream*)&SD1, "Board is up and running! \n\r");

  palSetPadMode(GPIOB, 3, PAL_MODE_ALTERNATE(6));     /* SCK. */
  palSetPadMode(GPIOB, 4, PAL_MODE_ALTERNATE(6));     /* MISO.*/
  palSetPadMode(GPIOB, 5, PAL_MODE_ALTERNATE(6));     /* MOSI.*/
  palSetPadMode(GPIOC, GPIOC_PIN1, PAL_MODE_OUTPUT_PUSHPULL);
  palSetPad(GPIOC, GPIOC_PIN1);
  palSetPadMode(GPIOC, GPIOC_PIN2, PAL_MODE_OUTPUT_PUSHPULL);
  palClearPad(GPIOC, GPIOC_PIN2);
  palSetPadMode(GPIOC, GPIOC_PIN3, PAL_MODE_INPUT_PULLUP);
  spiStart(&SPID3, &nrf24l01SPI);
  
  chMtxObjectInit(&nrfMutex);

  extStart(&EXTD1, &extcfg);
  nrf24l01ObjectInit(&nrf24l01);
  nrf24l01Start(&nrf24l01, &nrf24l01Config);
  extChannelEnable(&EXTD1, 3);
  initNRF24L01(&nrf24l01);

  chEvtRegister(&shell_terminated, &tel, 0);
  shelltp1 = shellCreate(&shell_cfg1, sizeof(waShell), NORMALPRIO);
  rxthd1 = chThdCreateStatic(recieverWorkingArea, sizeof(recieverWorkingArea), NORMALPRIO, receiverThread, NULL); 
    
  return 0;
}


