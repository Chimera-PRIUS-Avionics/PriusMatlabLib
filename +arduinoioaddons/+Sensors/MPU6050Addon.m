classdef MPU6050Addon < matlabshared.addon.LibraryBase
    properties(Access = private, Constant = true)
        ADXL357_ADDON_CREATE = hex2dec('01')
        ADXL357_ADDON_READ   = hex2dec('02')
        ADXL357_ADDON_DELETE = hex2dec('03')

        MAX_NUMBER_SENSORS = 2
    end

    properties(Access = protected, Constant = true)
        LibraryName = 'Sensors/MPU6050Addon'
        DependentLibraries = {}
        LibraryHeaderFiles = {}
        CppHeaderFile = {fullfile(PRIUSMatlabLib.getInstallationLocation("mpu6050"), 'mpu6050-master', 'src', 'MPU6050.h'), ...
                        fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'MPU6050Addon.h')}
        CppClassName = 'MPU6050Addon'
    end

    properties(Access = private)
        SensorIdx;
        Range;
        ResourceOwner = 'Sensors/MPU6050Addon';
    end
    

    methods
        function obj = ADXL357Addon(parentObj)
                obj.Parent = parentObj;

                count = getResourceCount(obj.Parent,obj.ResourceOwner);
                % Since this example allows implementation of only 1 LCD
                % shield, error out if resource count is more than 0
                if count >= obj.MAX_NUMBER_SENSORS
                    error('AnologDevice:ADXL357:ValueError', 'Maximum supported number of ADXL357 sensors (= %d) has been reached.', obj.MAX_NUMBER_SENSORS);
                end

                incrementResourceCount(obj.Parent, obj.ResourceOwner);

                if(~createADXL(obj, isHigherAddress, range))
                    error("ADXL Created Failed")
                end
        end
    end

    methods(Access = protected)
        function delete(obj)
            try
                parentObj = obj.Parent;
                % Decrement the resource count for the ADXL
                decrementResourceCount(parentObj, obj.ResourceOwner);
                obj.deleteADXL();
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
        end
    end

    methods(Access = private)

        function [isCreated] = createADXL(obj, isHigherAddress, range)
            cmdID = obj.ADXL357_ADDON_CREATE;

            if(range == 40)
                obj.Range = obj.Range_40_G;
            elseif(range == 20)
                obj.Range = obj.Range_40_G;
            elseif(range == 10)
                obj.Range = obj.Range_40_G;
            else
                isCreated = false;
                return;
            end

            data = [isHigherAddress, obj.Range];
            val = typecast(uint8(sendCommand(obj, obj.LibraryName, cmdID, data)), 'int8');
            if(val)
                isCreated = false;
                return;    
            end

            obj.SensorIdx = val;
            isCreated = true;
        end
        

        function deleteADXL(obj)
            cmdID = obj.ADXL357_ADDON_DELETE;
            data = [obj.SensorIdx];
            sendCommand(obj, obj.LibraryName, cmdID, data);
        end
    end

    methods(Access = public)
        function [x, y, z] = read(obj)
            
            cmdID = obj.ADXL357_ADDON_READ;
            
            try
                data = [obj.SensorIdx, obj.Range];
                val = sendCommand(obj, obj.LibraryName, cmdID, data);


                val = double(typecast(uint8(val), 'single'));

                x = val(1);
                y = val(2);
                z = val(3);
            catch e
                throwAsCaller(e);
            end
        end
    end


end