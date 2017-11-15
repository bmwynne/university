/*
 *Assignment name: Lab 5 Nordic Wireless
 *Author: Geralyn Dierfeldt (gbdierfe) & Brandon Wynne (bmwynne)
 *Date of Creation: February 20, 2015
 *Modifier: Brandon Wynne
 *Last date modified: March 5, 2015
 *
 */

#include "ch.h"
#include "hal.h"
#include "chprintf.h"
#include "nrf24l01.h"
#include "shell.h" 
#include <chstreams.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <math.h>


typedef struct{
  uint8_t seq_num; //0 or 1
  char address[5];
  uint8_t msg_type; //0=data; 1=ack
  uint8_t length;
  char payload[21];  
} packet;

static thread_t *shelltp1;
#define UNUSED(x) (void)(x)
static THD_WORKING_AREA(waShell,2048);

#define UNUSED(x) (void)(x)

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

static THD_WORKING_AREA(recieverWorkingArea, 128);

/* GLOBAL VARIABLES */
static NRF24L01Driver nrf24l01;
static mutex_t nrfMutex;
static uint8_t addr[5] = "METEO"; //initialized addr for sending
packet rxlist[10]; //global array for log of received messages
uint8_t rxnum = 0; //count for the number of messages logged in rxlist

static void nrfExtCallback(EXTDriver *extp, expchannel_t channel) {
  UNUSED(extp);
  UNUSED(channel);
  nrf24l01ExtIRQ(&nrf24l01);
}

void initNRF24L01(NRF24L01Driver *nrfp) {
  nrf24l01EnableDynamicSize(nrfp);
  nrf24l01EnableDynamicPipeSize(nrfp, 0x3f);
  
  nrf24l01SetTXAddress(nrfp, addr);
  nrf24l01SetRXAddress(nrfp, 0, addr);
  nrf24l01SetPayloadSize(nrfp, 0, 32);
  nrf24l01SetChannel(nrfp, 10);
 
  nrf24l01FlushRX(nrfp);
  nrf24l01FlushTX(nrfp);
  nrf24l01ClearIRQ(nrfp, NRF24L01_RX_DR | NRF24L01_TX_DS | NRF24L01_MAX_RT);

  nrf24l01PowerUp(nrfp);
}

uint8_t bufsize = sizeof(packet);
packet outgoingBuf;
static msg_t receiverThread(void *arg) {
  //receive message
  //format: {1byte msg seq},{5byte sender's addr},{1byte msg type},{msg length},{20byte max msg payload length}

  packet incomingBuf;
  int i;
  uint8_t seq = 0; //initialize seq num to 0
  uint8_t seqFlag = 0;

  UNUSED (arg);
  chRegSetThreadName("receiver");

  while (TRUE) {
    //make sure memory is clear of garbage
    memset(&incomingBuf, 0, sizeof(incomingBuf));
    memset(&outgoingBuf, 0, sizeof(outgoingBuf));

    //chprintf((BaseSequentialStream*)&SD1, "reading...\n\r");

    //receive message    
    chMtxLock(&nrfMutex);
    size_t s = chnReadTimeout(&nrf24l01.channels[0], (uint8_t*)&incomingBuf, bufsize, MS2ST(10));
    chMtxUnlock(&nrfMutex);

    //if something received, test input
    if (s) {

      //chprintf((BaseSequentialStream*)&SD1, "incoming.seq_num: %d\n\r", incomingBuf.seq_num);    
      chprintf((BaseSequentialStream*)&SD1, "Message Received!\n\r");

      //test for type data with matching sequence number
      if(incomingBuf.msg_type == 0){ 
	//if data received, send ack & read input

	//build outbuf
	outgoingBuf.seq_num = incomingBuf.seq_num; //send corresponding seq num

	//read sender address for ack send
	uint8_t target_addr[5];
	for(i = 0; i<5; i++){
	  //get address that sent message
	  target_addr[i] = (uint8_t)incomingBuf.address[i];
	  //attach own address to message being sent
	  outgoingBuf.address[i] = (char)addr[i];
	}

	//chprintf((BaseSequentialStream*)&SD1, "stored targetaddr\n\r");
	chThdSleepMilliseconds(1);    
       
	//outgoingBuf.address[5] = '\0';
	outgoingBuf.msg_type = 1; //send ack

	uint8_t msg_len = incomingBuf.length;
	//ensure max size of 20 bytes
	if (msg_len > 20)
	  msg_len = 20;

	outgoingBuf.length = msg_len; //refill msg_len

	chThdSleepMilliseconds(1);    

	//send original message back
	//and store message for log
	for(i=0; i<msg_len; i++)
	  outgoingBuf.payload[i] = incomingBuf.payload[i];
	outgoingBuf.payload[msg_len] = '\0';

	//chprintf((BaseSequentialStream*)&SD1, "filled payload\n\r");
	chThdSleepMilliseconds(1);    

	//<addr><msg><msglen>
	//5byte+20byte+1byte
	//with brackets += 6
	// = 32 = max entry length


	//build message entry for rx list queue
	//chprintf((BaseSequentialStream*) &SD1, "\n\rEntry: <%s><%s><%d>\n\r", incomingBuf.address, incomingBuf.payload, incomingBuf.length);
           
	uint8_t* tmpBuf = (uint8_t*)&outgoingBuf;

	//for(i=0;i<bufsize;i++)
	chprintf((BaseSequentialStream*)&SD1, "Received: %s\n\r", incomingBuf.payload);
	chThdSleepMilliseconds(10);   

	uint8_t bytes_transferred;

	nrf24l01SetTXAddress(&nrf24l01, target_addr);
	nrf24l01SetPayloadSize(&nrf24l01, 0, bufsize);    
	chMtxLock(&nrfMutex);
	bytes_transferred = chnWriteTimeout(&nrf24l01.channels[0], tmpBuf, bufsize, MS2ST(200));
	chMtxUnlock(&nrfMutex);
	
	if(bytes_transferred){
	  chprintf((BaseSequentialStream*)&SD1, "ACK SENT!\n\r");
	  if (incomingBuf.seq_num == seq)
	    seqFlag = 1;
	  else 
	    seqFlag = 0;
	  seq = !seq;
	}

	if(seqFlag){
	  
	  //log message in rxlist queue
	  if (rxnum < 10) {
	    //add to rxlist
	    rxlist[rxnum] = incomingBuf;
	    rxnum++;
	    chThdSleepMilliseconds(1);    
	    
	  } else if (rxnum == 10) {
	    
	    //queue full, fifo
	    //pop rxlist[0], move entries up, push to rxlist[9]
	    int j;
	  //move entries up
	    for( j=0;j<9;j++){
	      rxlist[j] = rxlist[j+1];
	    }
	    //add new entry at end
	    rxlist[9] = incomingBuf;
	    
	  } else {
	    rxnum = 10;
	  }

	  seq = 0; //restart seq num

	} else {
	  //don't log message
	}

      } else {
	//not a msg type data
	//do nothing
      }

      chSchDoYieldS(); //yield to higher priority threads
    } //else nothing read

  }
  chThdSleepMilliseconds(10);
  return 0;
}

static void cmd_myecho(BaseSequentialStream *chp, int argc, char *argv[]) {
  int32_t i;

  (void)argv;

  for (i=0;i<argc;i++) {
    chprintf(chp, "%s\n\r", argv[i]);
  }
}


static void cmd_channel(BaseSequentialStream *chp, int argc, char *argv[]){
  if (argc == 1){
    uint8_t new_ch = atoi(argv[0]);
    nrf24l01SetChannel(&nrf24l01, new_ch);
  } else {
    chprintf(chp, "Invalid input.\n\r");
  }
}

static void cmd_address(BaseSequentialStream *chp, int argc, char *argv[]){
  if (argc == 1){
    int i;
    for(i = 0; i < 5; i++)
      addr[i] = (uint8_t)argv[0][i];
    nrf24l01SetRXAddress(&nrf24l01, 0, addr);
  } else {
    chprintf(chp, "Invalid input.\n\r");
  }
}

static void cmd_tx(BaseSequentialStream *chp, int argc, char *argv[]){

  uint8_t target_addr[5];
  int i;
  uint8_t send_count = 0;
  uint8_t msg_len = 0;
  uint8_t seq = 0; //alternating bit seq
  packet sendBuf;
  packet incomingBuf;
  //make sure buffer is clear
  memset(&sendBuf, 0, sizeof(sendBuf));

  //read input
  if (argc == 2){
    //fill target address
    for(i=0;i<5;i++){
      target_addr[i] = (uint8_t)argv[0][i];
    }

    /* build outgoing buffer */
    sendBuf.seq_num = seq;  
    for(i=0; i<5; i++)
      sendBuf.address[i] = (char)addr[i];

    chprintf(chp, "Current Address: %s\n\r", sendBuf.address);

    //fill message type to data
    sendBuf.msg_type = 0;
    
    msg_len = strlen(argv[1]);
    if (msg_len > 20) msg_len = 20;
    sendBuf.length = msg_len;

    //fill message string & record length
    for(i=0; i<msg_len; i++)
      sendBuf.payload[i] = argv[1][i];
    sendBuf.payload[msg_len] = '\0';

    //transmit message
    //format: {1byte msg seq},{5byte sender's addr},{1byte msg type},{msg length},{20byte max msg payload length}
    // 0 12345 6 7 8-28

  } else { //incorrect number of arguments
    chprintf(chp, "Invalid input.\n\r");
  }

  //only send 5 times
  while(argc==2 && send_count < 5) {
    sendBuf.seq_num = seq; //update seq num

    chprintf(chp, "sending...\n\r");

    nrf24l01SetTXAddress(&nrf24l01, target_addr);
    nrf24l01SetPayloadSize(&nrf24l01, 0, bufsize);
    chMtxLock(&nrfMutex);
    //set thread timeout for 200 ms
    int bytes_transferred = chnWriteTimeout(&nrf24l01.channels[0], (uint8_t*)&sendBuf, bufsize, MS2ST(200));
    chMtxUnlock(&nrfMutex);

    if (bytes_transferred == 0) {
      //print failure
      //chprintf(chp, "Sending failed...Resending...\n\r");
    } else { //listen for ack
      //chprintf(chp, "Message Sent! Send_count: %d\n\r", send_count);
      size_t s;

      //receive ack
      chMtxLock(&nrfMutex);
      s = chnReadTimeout(&nrf24l01.channels[0], (uint8_t*)&incomingBuf, bufsize, MS2ST(200));
      chMtxUnlock(&nrfMutex);

      send_count++;

      if (s){
	//msg received
	//bit 0 = seq num
	//bit 6 = ack || "nak"
	chprintf(chp, "Incoming msg type: %d\n\r", incomingBuf.msg_type);
	//test if ack and correct seq num
	if(incomingBuf.seq_num == seq && incomingBuf.msg_type == 1){
	  chprintf(chp, "Message send successful!");
	  send_count = 5; //break out of tx while loop
	  //seq = !seq; //needed?
	}
      } else {
	//no msg received
	//change seq num
	chprintf(chp, "No ACK received\r\n");
	seq = !seq;
      }

     }
    
  }    

}

static void cmd_rxlist(BaseSequentialStream *chp, int argc, char *argv[]){
  int i;
  //print all entries in rxlist queue
  //print in reverse b/c rxlist[0] = oldest and rxlist[9] = newest
  if(rxnum == 0) {
    chprintf(chp, "Nothing in queue.\n\r");
  } else {
    packet curr;
    for(i = 1; i<(rxnum+1); i++){
      curr = rxlist[rxnum-i];
      chprintf(chp, "%d. <%s><%s><%d>\n\r", i, curr.address, curr.payload, curr.length);
    }
  }
}

static void cmd_rx(BaseSequentialStream *chp, int argc, char *argv[]){
  if(rxnum == 0) {
    chprintf(chp, "Nothing yet received.\n\r");
  } else {
    packet last_entry = rxlist[rxnum-1]; 
    chprintf(chp, "<%s><%s><%d>\n\r", last_entry.address, last_entry.payload, last_entry.length);
    
    //delete last entry
    memset(&rxlist[rxnum-1], 0, sizeof(last_entry));
    rxnum--;
  }

}

static const ShellCommand commands[] = {
  {"myecho", cmd_myecho},
  {"nrfch", cmd_channel},
  {"nrfaddr", cmd_address},
  {"nrftx", cmd_tx},
  {"rxlist", cmd_rxlist},
  {"nrfrx", cmd_rx},
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

int main(void) {
  event_listener_t tel;
  halInit();
  chSysInit();
  //  uint8_t i;

  // Serial Port Setup 
  sdStart(&SD1, NULL);
  palSetPadMode(GPIOC, 4, PAL_MODE_ALTERNATE(7));
  palSetPadMode(GPIOC, 5, PAL_MODE_ALTERNATE(7));

  chprintf((BaseSequentialStream*)&SD1, "Up and Running\n\r");

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

  /* Initialize the command shell */ 
  shellInit();
  /* 
   *  setup to listen for the shell_terminated event. This setup will be stored in the tel  
   * event listner structure in item 0
   */
  chEvtRegister(&shell_terminated, &tel, 0);

  shelltp1 = shellCreate(&shell_cfg1, sizeof(waShell), NORMALPRIO);

  chThdCreateStatic(recieverWorkingArea, sizeof(recieverWorkingArea), NORMALPRIO, receiverThread, NULL);

  for (;;) {
    chEvtDispatch(fhandlers, chEvtWaitOne(ALL_EVENTS));
    chThdSleepMilliseconds(1);

  }
}
