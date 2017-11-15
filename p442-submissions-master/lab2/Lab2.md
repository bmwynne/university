###Created by: Brandon Wynne
###Partner   : Max Hollingsworth
###Date      : 1/28/2015
###Course    : P442 Digital Systems

# Lab 2: Chibios Command Shell

## Introduction:  
The purpose of this lab was to implement shell commands in Chibios. The purpose
of these shell commands are to both control the LEDs positioned on the discovery board, and start the egg timer. 

## LED Commands:
* led [set] [state]: Sets the egg timer timeout value between 0 and 100000ms.
* timer [reset]    : Starts the egg timer from the beginning.
* timer [start]    : Starts the egg timer from the current count.
* timer [stop]     : Stops the egg timer.
* timer [gettime]  : Reports ms remaining until the egg timer expires.

## Implementation:
The LED and egg timer commands manage the timer and LEDs by spawning 
dynamic threads. These threads are managed in conditional blocks. They search for characters that return 0 via the strcmp() function. 

## Results:
The results in this lab were great. The commands were created without hassle. We continued to fine tune our abilities to manage threads within the egg timer and LEDs.




