/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 13 has an LED connected on most Arduino boards.
// Pin 11 has the LED on Teensy 2.0
// Pin 6  has the LED on Teensy++ 2.0
// Pin 13 has the LED on Teensy 3.0
// give it a name:
int led = 5;
double hz = 1000;
int freeze = 1;
double uS = 1000000;

// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  pinMode(led, OUTPUT);     
}

// the loop routine runs over and over again forever:
void loop() {
  digitalWrite(led, HIGH);   // urn the LED on (HIGH is the voltage level)
  if(!freeze){
  delayMicroseconds(int(1/(hz*2)*uS));               // wait for a second
  digitalWrite(led, LOW);    // turn the LED off by making the voltage LOW
  delayMicroseconds(int(1/(hz*2)*uS));               // wait for a second
                 // wait for a second
  }
}
