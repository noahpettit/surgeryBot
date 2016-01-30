function settings = surgery_getSettings_rig2()
%% surgery class settings function
% this function contains all of the hardcoded information about the
% surgery bot

settings.arduinoComPort = 3; % the serial port number for the arduino
settings.acuriteComPort = 1; % the serial port number for the acurite
settings.nMotors = 3; % number of motors
settings.nStepsPerMotor = 200; % resolution of each motor
settings.stepStyleToUse = [1,2,3,4]; % choose which step styles will be available to the program
settings.stepperSpeedRange = [1, 100]; % in rpm - the speed range available to each stepper


%% DO NOT EDIT
settings.stepStyleNames = {'SINGLE', 'DOUBLE', 'INTERLEAVE', 'MICROSTEP');



end

