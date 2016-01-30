/* 
This is a test sketch for the Adafruit assembled Motor Shield for Arduino v2
It won't work with v1.x motor shields! Only for the v2's with built in PWM
control

For use with the Adafruit Motor Shield v2 
---->	http://www.adafruit.com/products/1438
*/


#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_PWMServoDriver.h"

// Create the motor shield object with the default I2C address
Adafruit_MotorShield AFMS1 = Adafruit_MotorShield(); 
Adafruit_MotorShield AFMS2 = Adafruit_MotorShield(0x61); 
// Or, create it with a different I2C address (say for stacking)
// Adafruit_MotorShield AFMS = Adafruit_MotorShield(0x61); 

// Connect a stepper motor with 200 steps per revolution (1.8 degree)
// to motor port #2 (M3 and M4)
Adafruit_StepperMotor *myStepper1 = AFMS1.getStepper(200, 1);
Adafruit_StepperMotor *myStepper2 = AFMS1.getStepper(200, 2);
Adafruit_StepperMotor *myStepper3 = AFMS2.getStepper(200, 2);

// for merging two bytes into a 16 bit int - used for 
union u_tag {
    byte b[2];
    int ival;
} u;

// intialize stepper variables

int motorN = 1; // stepper motor number (typically 1 = x, 2 = y, 3 = z);
int stepStyle = 1; // step type
int stepperDir = 0; // direction of the stepper (can be 1 or 0)
int stepperSteps = 0; // number of steps to take
int stepperSpeed = 0; // speed of the stepper in rpm 
uint8_t styleStrings[] = {SINGLE, DOUBLE, INTERLEAVE, MICROSTEP};
uint8_t dirStrings[] = {BACKWARD, FORWARD};

void setup() {
  Serial.begin(9600);           // set up Serial library at 9600 bps
  //Serial.println("Stepper test!");

  AFMS1.begin();  // create with the default frequency 1.6KHz
  AFMS2.begin(); // start second shield
  //AFMS.begin(1000);  // OR with a different frequency, say 1KHz
  
  // change the ic2 clock to 400 KHz - WHY??
  TWBR = ((F_CPU /400000l) - 16) / 2;

  // set all motors to a default speed of 10 rpm
  myStepper1->setSpeed(10); // 10 rpm  
  myStepper2->setSpeed(10); // 10 rpm 
  myStepper3->setSpeed(10); // 10 rpm  
  
}

void loop() {

  // read in info from the serial port

    if (Serial.available() > 5) {
      // matlab will write 6 bytes to the serial port:
      // 1st byte: motor number 
      motorN = Serial.read();
      // 2nd byte: stepper direction
      stepperDir = Serial.read(); // 1 is forward, 0 is backwards
      // 3rd byte: stepper speed
      stepperSpeed = Serial.read();
      // 4th byte: step type (1: SINGLE, 2: DOUBLE, 3: INTERLEAVE, 4: MICROSTEP)
      stepStyle = Serial.read();
      // 5th and 6th byte: number of steps to make
      u.b[0] = Serial.read();
      u.b[1] = Serial.read();
      // merge two bytes into 16 bit int for n steps
      stepperSteps = u.ival; 
      
      

      // drive the motor
      if (motorN == 1) {
      myStepper1->setSpeed(stepperSpeed);
      myStepper1->step(stepperSteps, dirStrings[stepperDir],styleStrings[stepStyle-1]);
      } else if (motorN == 2) {
      myStepper2->setSpeed(stepperSpeed);
      myStepper2->step(stepperSteps, dirStrings[stepperDir],styleStrings[stepStyle-1]);  
      } else if (motorN == 3) {
      myStepper3->setSpeed(stepperSpeed);
      myStepper3->step(stepperSteps, dirStrings[stepperDir],styleStrings[stepStyle-1]);
      } else {
      // do nothing
      }
      
  }

  
}


