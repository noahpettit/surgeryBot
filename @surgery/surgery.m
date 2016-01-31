classdef surgery < handle
    %SURGERY Class for handling control of motorized stereotaxic, as well
    %as aquiring images and data during the surgery, and perfomring
    %operations on them (such as fitting bregma).
    %   To do notes: Think about creating separate class just for
    %   controlling stereotaxic, that can be called by a more general class
    %   designed for data aquisition and processing during the surgery.
    %   Calibration data should ultimately be stored in settings field so
    %   that it can be loaded from a settings file
    
    properties (SetAccess = public)
        metadata % information specific to the current surgery, such as animal name, weight, notes, etc
        acurite % the serial object for communicating with the acurite
        arduino % arduino object for communicating with the arduino
        usbcam % image aquisition object 
        position % current position information
        steppers % settings for the steppers
        data % all data including images, stacks, 
        settings % hardcoded settings information specific to each surgery rig
        axis % calibration data for each axis - includes um per step, speed curves, etc
    end
    
    methods
        % class constructor
        function s = surgery(settings)
            % check to see if settings is empty or is a string
            
            % acurite settings
            s.acurite = serial(['COM' num2str(settings.acuriteComPort)]);
            fopen(s.acurite);
            
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
        function xyz = getXYZ(s)
            % query
            fwrite(s.acurite,2);
            % read value
            a = fread(s.acurite,48);
            % convert ASCII to double
            x = str2num(char(a(3:12))');
            y = str2num(char(a(19:28))');
            z = str2num(char(a(35:44))');
            xyz = [x,y,z];
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
            
            % check which axis each motor controls
            for motorN = 1:3
                % check which axis we are controlling
                %get initial position
                xyz0 = s.getXYZ;
                % step 10 steps in each step style 
                for stepStyle = s.settings.stepStyleToUse;
                s.driveStepper(motorN,1,round(max(s.settings.stepperSpeedRange)/2),stepStyle,10);
                end
                s.waitforMove;
                xyz1 = s.getXYZ;
                % figure out which axis moved
                [~,idx] = max(abs(xyz0-xyz1));
                if idx == 1
                    s.xMotorIdx = motorN;
                elseif idx ==2
                    s.yMotorIdx = motorN;
                elseif idx ==3;
                    s.zMotorIdx = motorN;
                end
            end
            
            s.xyzMotorIdx = [s.xMotorIdx, s.yMotorIdx, s.zMotorIdx]; 
            
            % Now for each axis let's get mm / min, um per step
            % for each of the different step style and for a range of
            % speeds
            
            speeds = s.settings.stepperSpeedRange(1):10:s.settings.stepperSpeedRange(2);
            
            % for each axis (x,y,z is 1,2,3)
            for axis = 1:3   
                % for each style of step
                stylei = 0;
                for stepStyle = s.settings.stepStyleToUse;
                    stylei = stylei+1;
                    % for every 10th speed value in the range
                    spi = 0;
                    for sp = speeds;
                        spi = spi+1;
                        % get initial position
                        xyz0 = s.getXYZ;
                        % send motor command for 50 steps
                        nSteps = 50;
                        t0 = tic;
                        s.driveStepper(s.xyzMotorIdx(axis),1,sp,stepStyle,nSteps);
                        % record movement relative to xyz1 and t1 in space
                        % and time, respectively, at 10 Hz
                        [mTrace, tTrace] = s.recordMovement(t0, xyz0, 10);  
                        % compute amount moved
                        
                        s.axis(axis).calibrationCurves{spi,stylei} = [mTrace; tTrace];
                        
                    end
                end
            end
        end
        
       
        function [mTrace, tTrace] = recordMovement(s, axisIdx, t0, xyz0, Hz)
        % simple function to start recording single axis movement immediately until the movement has
        % stopped for at least 1 second, or mTrace has exceeded 1000000
        % (1 million) values. Return warning if samples are dropped
        % returns movement trace for specified axis, and the approximate time points at which those samples were collected (relative to t0); 
        % - REWRITE using timer obj
            interval = 1/Hz;
            mTrace = [];
            tTrace(1) = toc(t0);
            xyz1 = s.getXYZ-xyz0;
            mTrace = [mTrace, xyz1(axisIdx)];
            timeSinceLastMove = 0;
            
            while length(mTrace)<1000000 && timeSinceLastMove<1
                % check to see if the time since last sample is greater than the
                % interval
                if (toc(t0)-tTrace(end))>interval
                    % add timepoint 
                    tTrace = [tTrace, toc(t0)];
                    xyz1 = s.getXYZ-xyz0;
                    mTrace = [mTrace, xyz1(axisIdx)];
                    if mTrace(end)~=mTrace(end-1)
                        % then it moved - reset the time to 0
                        timeSinceLastMove = 0;
                    else
                        % otherwise there was not a movement so increase
                        % the counter
                        timeSinceLastMove = timeSinceLastMove+diff(tTrace(end-1:end));
                    end
                end
            end
            
            % once while loop is broken, return. 
            
            
        end
        
        % block command line execution until stereotax movement has stopped
        % for at least 1 second 
        function waitForMove(s)
            xyz0 = s.getXYZ;
            pause(1);
            xyz1 = s.getXYZ;
            while sum(abs(xyz0-xyz1))>0
                pause(1);
                xyz0 = xyz1;
                xyz1 = s.getXYZ;
            end
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
        function goto(s,x,y,z)
        end
        
        % fit bregma by drawing over the coronal suture
        function fitCoronalSuture(s)
        end
        
        % fit the midline by drawing over the saggital suture
        function fitMidlineSuture(s)
        end
        
        % fit a straight line by drawing over the lambdoid suture
        function fitLambdoidSuture(s)
        end
        
        
        % show a GUI motor control panel
        function controlPanel(s)
        end
        
        % quit the surgery session, clase all serial port communications
        function quit(s)
            fclose(s.arduino);
            fclose(s.acurite);
        end
        
        
    end
    
end

