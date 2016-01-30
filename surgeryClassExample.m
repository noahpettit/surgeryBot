%% surgery class example script
% an example / test script for how to use the surgery class

s = surgery(surgery_getSettings_rig2);

%% get the xyz coordinates and display them

[x,y,z] = s.getXYZ;

%% move one of the steppers

s.driveStepper(2,0,100,4,500);

%% calibrate the steppers

