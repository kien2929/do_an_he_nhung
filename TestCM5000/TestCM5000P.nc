#include "TestCM5000.h"

module TestCM5000P @safe() {
  uses {
  
  	// Main, Leds
    interface Boot;
    interface Leds;
    
		// Radio
    interface SplitControl as RadioControl;
    interface AMSend		   as ThlSend;
		interface Packet;
	
	

		// Timers
		interface Timer<TMilli>  as SampleTimer;
		
		// Sensors    
		interface Read<uint16_t> as Vref;
  		interface Read<uint16_t> as Temperature;    
  		interface Read<uint16_t> as Humidity;    
		interface Read<uint16_t> as Photo;
		interface Read<uint16_t> as Radiation;
  }
}

implementation
{
  
/*****************************************************************************************
 * Global Variables
*****************************************************************************************/  
	uint8_t   numsensors;
	THL_msg_t data;
	message_t auxmsg;
	
/*****************************************************************************************
 * Task & function declaration
*****************************************************************************************/
  task void sendThlMsg();

/*****************************************************************************************
 * Boot
*****************************************************************************************/

  event void Boot.booted() {
  	call SampleTimer.startPeriodic(DEFAULT_TIMER); // Start timer
  }

/*****************************************************************************************
 * Timers
*****************************************************************************************/

	event void SampleTimer.fired() {
		numsensors = 0;
		call Vref.read();
		call Temperature.read();
		call Humidity.read();
		call Photo.read();
		call Radiation.read();
	}
	
/*****************************************************************************************
 * Sensors
*****************************************************************************************/

	event void Vref.readDone(error_t result, uint16_t value) {
    data.vref = value;										// put data into packet 
		if (++numsensors == MAX_SENSORS) {		
			call RadioControl.start();					// start radio if this is last sensor
		}
  }

	event void Temperature.readDone(error_t result, uint16_t value) {
    data.temperature = value;							// put data into packet 
		if (++numsensors == MAX_SENSORS) {		
			call RadioControl.start();					// start radio if this is last sensor
		}
	}

	event void Humidity.readDone(error_t result, uint16_t value) {
    data.humidity = value;								// put data into packet 
		if (++numsensors == MAX_SENSORS) {		
			call RadioControl.start();					// start radio if this is last sensor
		}
  }    

	event void Photo.readDone(error_t result, uint16_t value) {
    data.photo = value;										// put data into packet 
		if (++numsensors == MAX_SENSORS) {		
			call RadioControl.start();					// start radio if this is last sensor
		}
  }  
  
	event void Radiation.readDone(error_t result, uint16_t value) {
    data.radiation = value;								// put data into packet 
		if (++numsensors == MAX_SENSORS) {		
			call RadioControl.start();					// start radio if this is last sensor
		}
  }

/*****************************************************************************************
 * Radio
*****************************************************************************************/

	event void RadioControl.startDone(error_t err) {
		if (err == SUCCESS) {	
			post sendThlMsg();					// Radio started successfully, send message
		}else	{
			call RadioControl.start();
		}
	}

	task void sendThlMsg()	{
		THL_msg_t* aux;
		aux = (THL_msg_t*)
		call Packet.getPayload(&auxmsg, sizeof(THL_msg_t));
					
		aux -> vref 			 = data.vref;
		aux -> temperature = data.temperature;
		aux -> humidity		 = data.humidity;
		aux -> photo       = data.photo; 
		aux -> radiation	 = data.radiation; 			
							
		if (call ThlSend.send(AM_BROADCAST_ADDR, &auxmsg, sizeof(THL_msg_t))!= SUCCESS)	{
			post sendThlMsg();
		}
	}
	
	event void ThlSend.sendDone(message_t* msg, error_t error) {
		if (error == SUCCESS)	{
			call RadioControl.stop();	// Msg sent, stop radio
		}else
		{
			post sendThlMsg();
		}
	}
	
	event void RadioControl.stopDone(error_t err) {
		if (err != SUCCESS) {
			call RadioControl.stop();
		}
	}



}// End  
