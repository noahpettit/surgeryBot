classdef surgery < handle
    %SURGERY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public)
        acurite
        arduino
        usbcam
        position
        steppers
        data
        settings
    end
    
    methods
        % class constructor
        function s = surgery(settings)
            % check to see if settings is empty or is a string
            
            % acurite settings
            s.acurite = serial(['COM' num2str(settings.acuriteComPort)]);
            f.open(s.acurite);
            
            % arduino settings
            s.arduino = serial(['COM' num2str(settings.arduinoComPort)]);
            fopen(s.arduino);
            pause(2); % not sure why this pause is needed but it is, just to amke sure the port is initialized correctly
            
            % stepper settings
            s.steppers.nSteps = settings.nStepsPerMotor;
            s.steppers.nMotors = settings.nStepsPerMotor;
            s.steppers.stepStyleNames = settings.stepStyleNames;
            s.steppers.stepStyleToUse = settings.stepStyleToUse;
            s.steppers.minSpeed = settings.stepperSpeedRange(1);
            s.steppers.maxSpeed = settings.stepperSpeedRange(2);
            
            % save the settings
            s.settings = settings;
            
            % get the position
            s.getXYZ();
        end
        
        % load settings from a settings .mat file
        function loadSettings(s,fileName)
            % load settings from a settings file without having to create a
            % new object. this will overwrite exisiting parameters
        end
        
        % save object settings to a settings .mat file
        function saveSettings(s,fileName)
            % save object settings parameters to a .mat file
        end
        
        % get the current XYZ coordinates from the accurite
        function [x,y,z] = getXYZ(s)
            % query
            fwrite(s.acurite,2);
            % read value
            a = fread(s.acurite,48);
            % close port
            fclose(s.acurite);
            % convert ASCII to double
            x = str2num(char(a(3:12))');
            y = str2num(char(a(19:28))');
            z = str2num(char(a(35:44))');
            s.position = [x,y,z];
        end
        
        % for directly sending commands to stepper motors
        function driveStepper(s,motorN,direction,speed,stepStyle,nSteps)
            % note that once this method is called, steps sent to the
            % stepper cannot be undone, stopped, or paused, and arduino
            % execution will be paused. MATLAB control, however, will
            % resume as soon as the command is sent.
            
            % check that the serial port is open
            if strcmp(s.arduino.Status, 'closed');
                fopen(s.arduino);
                pause(2);% this pause is needed for the output to work properly - still not sure why
            end
            
            % 
            fwrite(s.arduino,[int8(motorN),int8(direction),int8(speed),int8(stepStyle)],'uint8');
            % final two bytes encode nSteps as 16-bit int
            fwrite(s.arduino,int16(nSteps),'int16');
        end
        
        % calibrate steppers
        function calibrateSteppers(s)
            % method for testing each stepper and getting speed curve, step
            % size, etc.
        end
        
        % get Image and save it tot he structure
        function img = takeImg(s,idx,primary,display)
            % img = takeImg(s,idx) takes an image and saves it to the
            % object as the (idx)th image - this will be set as the primary
            % image by default if setPrimaryImg has not been called
        end
        
        % select the primary skull image to use
        function imgIdx = setPrimaryImg(s,idx)
        end
        
        % take an image stack and save it
        function imgStack = takeStack(s,zRange,idx,primary,display)
        end
        
        % select the primary stack to use
        function stackIdx = selectPrimaryStack(s,idx)
        end
        
        % make a 3d model using the 
        function surfacePoints = make3dModel(s, imgStackIdx)
        end
        
        % make a deep focus composite image from an image stack
        function img = makeComposite(s,imgStackIdx)
        end
        
        % make a pseudocolor depth image from an image stack
        function img = makeDepthImg(s,imgStackIdx);
        end
        
        function previewCam(s)
            % preview the camera
        end
        
        % set the pixels per micron and 
        function calibrateCamera(s)
            % use stepper control and image registration to compute pixels
            % per um
        end
        
        % manually set bregma point that will be used
        function setBregma(s)
        end
        
        % manually set lambda point that will be used
        function setLambda(s)
        end
        
        % go to a coordinate
        function goto(x,y,z)
        end
        
        % fit bregma by drawing over the coronal suture
        function fitCoronalSuture()
        end
        
        % fit the midline by drawing over the saggital suture
        function fitMidlineSuture()
        end
        
        % fit a straight line by drawing over the lambdoid suture
        function fitLambdoidSuture()
        end
        
        
        
        
    end
    
end

