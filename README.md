# surgeryBot
Code for motorized control of kopf 1900 stereotaxic  

key features:
- easily removable for cleaning / autoclaving
- adjustable gear ratio with simple, friction-fit parts
- even with motor mounted and gears engaged, you can still move stereotax manually (unlike some other motorized sterotaxes). 
- stepper is self-calibrating based on encoder feedback
- ~1um accuracy (same as encoder readout)
- closed-loop control using either computer and/or microcontroller
- matlab library for easy integration into more complex control programs (such as automated surgery bot).


# Hardware
The basic hardware consists of a laser-cut mount(s) to drive one or more axes with nema 17 stepper motors.

![image](https://github.com/noahpettit/surgeryBot/assets/16245463/eb0d5dd7-00ae-43ca-8ddf-b8886ce2e0ec)
![image](https://github.com/noahpettit/surgeryBot/assets/16245463/aead8b45-1d7f-45fc-957d-1a44aa73204d)
![image](https://github.com/noahpettit/surgeryBot/assets/16245463/c305b220-39c1-45ab-a879-697b602f680e)
![image](https://github.com/noahpettit/surgeryBot/assets/16245463/3cbd9db0-c6c7-47e2-9905-e59e88d3c714)

## Stepper Motor Mount
![image](https://github.com/noahpettit/surgeryBot/assets/16245463/bcbb6075-2ffc-498d-b590-24d853326967)

Mount hardware laser cut from 1/4" acrylic. The gears that fit onto the knob are friction fit so adjust the internal diameter if neccessary (or add tape/ shim) to get a tight fit so that they don't slip. 

laser-cutter ready designs in https://github.com/noahpettit/surgeryBot/blob/master/Hardware/Stepper_mount/StepperMountAndGears_v2_lasercutter.pdf 

I think all screws are M3, so non-through holes need to be M3 tapped.

## Stepper motor

I believe I used this one: https://www.adafruit.com/product/324
Although slightly more powerful motors would probably be better, especially if your axis is a bit sticky. 

## Stepper motor driver

I used this: https://www.adafruit.com/product/1438 with an arduino uno. It needs to have its own power source that provides enough current to drive whatever steppers you are using. I also STRONGLY suggest having an inline power switch so that you can quickly turn off the system if something goes wrong. The last thing you want is for a bug in your code to cause the stepper motor to drive the arm too fast or beyond its limits and potentially damage it. If using long-term, consider incorporating limit switches.

## Cables
computer to arduino USB
power cable for stepper motor driver
wires to connect stepper with stepper motor driver
serial to serial or serial to USB to connect accurite with computer and get position read-out


# Software

The basic idea is thatyou initialize a matlab surgery object that handles communication with the hardware. it reads in position data from the accurite and directs the stepper to move forwards or backwards. 
The object can self-calibrate using encoder feedback to get um per step of the stepper, and then also operates in closed-loop during execution to ensure that targets are reached and not exceeded. 

Test all the code yourself and use at your own risk!

Using that object as a simple interface with the harware, you can write matlab scripts that contain cells that you might execute during particular stages of your surgery (see Protocols folder for an example). 





