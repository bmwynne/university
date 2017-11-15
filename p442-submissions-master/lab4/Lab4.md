<pre>
Created by      : Brandon Wynne
Partner         : Paul Conway
Date Created    : February 12, 2015
Last modified by: Brandon Wynne
Last modified on: February 12, 2015
</pre>


#Overview:#
In this lab we created a portable atlimeter using the F3 Discovery Board and the STEVAL mki12v1 pressure sensor. Utilizing a 9V battery, the F3 board was taken around different elevators around the IU Bloomington campus to measure altitude.  


#Requirements:#
To achieve this lab's goal we needed to further enhance our code base from the previous lab -- lab3.
The system was required to: start and stop logging utilizing the blue user button, a visual indication of the state of the device via LEDs, stamped data with a tick count that has a period resolution of 100mS or less, and the ability to retrieve the logged data from a shell command.


#Taking Data Using Our System:#

Utilizing our existing code base allowed us to fulfill the requirements. Two states were created: logging and non-logging. State setting is done by the systemhandler. This aided ussyncing both CPU cycles and logging with the cycle count register, instead of initializing a new thread and interrupts.  This also allowed our time measuring to be as accurate as we believe possible. The board's LEDs were mapped to these states. When the user button is pressed all of the LEDs light up and the system is logging. After five minutes the LEDs turn off and the system is done logging. Resetting the board with the reset button resets the state of the program and the data stored in memory. 

#Difficulties:#
Utilizing the system handler to get accurate time stamps was the most difficult task. Through resetting the cycle counter we were able to achieve accurate measurements.

#Results:#

###GPIO PINS:###
<pre>
__________________________________
|  Pins   |      Altimeter       |
|_________|______________________|
|  PA5    |         SCL          |
|  PA6    |         SDO          |
|  PA7    |         SDA          |
|  PA8    |         CS           |
|  PC4    |         RX           |
|  PC5    |         TX           |
|  GND    |         GND          |
|_________|______________________|
</pre>

###Graphs:###
#####Lindley Hall Elevator#####
![Image](https://github.iu.edu/bmwynne/p442-submissions/blob/master/lab4/Lindley.png?raw=true)
This elevators speed was undetermined because we were unable to achieve clear results. We believe this was because we could only go up to the second floor.

#####Ballentine Hall Elevator#####
![Image](https://github.iu.edu/bmwynne/p442-submissions/blob/master/lab4/Ballentine.png?raw=true)
This elevators top speed was the first wave with a speed of 3.85 feet/second.

#####IMU Elevator#####
![Image](https://github.iu.edu/bmwynne/p442-submissions/blob/master/lab4/Union.png?raw=true)
The fastest slope in this graph was the third wave increase  with a speed of 2.14 feet/second.
