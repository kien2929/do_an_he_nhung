configuration TestCM5000C {
}
implementation {
  components MainC, TestCM5000P as App, LedsC;

	// Main c  
  MainC.Boot <- App;
	App.Leds 					-> LedsC;

	// Radio
	components ActiveMessageC as Radio;
  App.RadioControl 	-> Radio;
  
  components new AMSenderC(TestCM5000_AM_ID);
	App.ThlSend 	-> AMSenderC;
	App.Packet 		-> AMSenderC;
 
	// Timers
	components new TimerMilliC() as SampleTimer;
	App.SampleTimer 	-> SampleTimer;
 
 // Sensors
	components new Msp430InternalVoltageC() as SensorVref;  // Voltage    
  App.Vref -> SensorVref;
 
  components new SensirionSht11C() as SensorHT;           // Humidity/Temperature    
  App.Temperature 	-> SensorHT.Temperature;  
  App.Humidity 			-> SensorHT.Humidity;
      
  components new HamamatsuS1087ParC() as SensorPhoto; 	  // Photosynthetically Active Radiation
  App.Photo 				-> SensorPhoto;

  components new HamamatsuS10871TsrC() as SensorTotal;    // Total Solar Radiation  
  App.Radiation 		-> SensorTotal;
 
}
