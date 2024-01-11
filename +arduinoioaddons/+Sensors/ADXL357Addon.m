classdef ADXL357Addon < matlabshared.addon.LibraryBase
    properties(Access = private, Constant = true)
        ADXL357_ADDON_CREATE = hex2dec('01')
        ADXL357_ADDON_READ   = hex2dec('02')
        ADXL357_ADDON_DELETE = hex2dec('03')

        ADXL357_ADDON_READ_N = hex2dec('04')

        MAX_NUMBER_SENSORS = 2

        Range_40_G =  bin2dec('11')
        Range_20_G =  bin2dec('10')
        Range_10_G =  bin2dec('01')

        ODR_LPF_4000         = bin2dec('0000') %, /*!< ODR: 4000 Hz and LPF: 1000 Hz */
        ODR_LPF_2000         = bin2dec('0001') %, /*!< ODR: 1000 Hz and LPF: 500 Hz */
        ODR_LPF_1000         = bin2dec('0010') %, /*!< ODR: 1000 Hz and LPF: 250 Hz */
        ODR_LPF_500          = bin2dec('0011') %, /*!< ODR: 500 Hz and LPF: 125 Hz */
        ODR_LPF_250          = bin2dec('0100') %, /*!< ODR: 250 Hz and LPF: 62.5 Hz */
        ODR_LPF_125          = bin2dec('0101') %, /*!< ODR: 125 Hz and LPF: 31.25 Hz */
        ODR_LPF_62_5         = bin2dec('0110') %, /*!< ODR: 62.5 Hz and LPF: 15.625 Hz */
        ODR_LPF_31_25        = bin2dec('0111') %, /*!< ODR: 31.25 Hz and LPF: 7.813 Hz */
        ODR_LPF_15_625       = bin2dec('1000') %, /*!< ODR: 15.625 Hz and LPF: 3.906 Hz */
        ODR_LPF_7_813        = bin2dec('1001') %, /*!< ODR: 7.813 Hz and LPF: 1.953 Hz */
        ODR_LPF_3_906        = bin2dec('1010') %, /*!< ODR: 3.906 Hz and LPF: 0.977 Hz */
    end

    properties(Access = protected, Constant = true)
        LibraryName = 'Sensors/ADXL357Addon'
        DependentLibraries = {}
        LibraryHeaderFiles = 'ADXL357/ADXL357.h'
        CppHeaderFile = fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'ADXL357Addon.h')
        CppClassName = 'ADXL357Addon'
    end

    properties(Access = private)
        SensorIdx;
        Range;
        Fq;
        ResourceOwner = 'Sensors/ADXL357Addon';
    end
    

    methods
        function obj = ADXL357Addon(parentObj, isHigherAddress, range, fq)
                obj.Parent = parentObj;

                count = getResourceCount(obj.Parent,obj.ResourceOwner);
                % Since this example allows implementation of only 1 LCD
                % shield, error out if resource count is more than 0
                if count >= obj.MAX_NUMBER_SENSORS
                    error('AnologDevice:ADXL357:ValueError', 'Maximum supported number of ADXL357 sensors (= %d) has been reached.', obj.MAX_NUMBER_SENSORS);
                end

                incrementResourceCount(obj.Parent, obj.ResourceOwner);

                if(~createADXL(obj, isHigherAddress, range, fq))
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

        function [isCreated] = createADXL(obj, isHigherAddress, range, fq)
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

            if(fq == 4000)
                obj.Fq = obj.ODR_LPF_4000;
            elseif(fq == 2000)
                obj.Fq = obj.ODR_LPF_2000;   
            elseif(fq == 1000)
                obj.Fq = obj.ODR_LPF_1000;
            elseif(fq == 500)
                obj.Fq = obj.ODR_LPF_500;
            elseif(fq == 250)
                obj.Fq = obj.ODR_LPF_250;
            elseif(fq == 125)
                obj.Fq = obj.ODR_LPF_125;
            elseif(fq == 62.5)
                obj.Fq = obj.ODR_LPF_62_5;
            elseif(fq == 31.25)
                obj.Fq = obj.ODR_LPF_31_25;
            elseif(fq == 15.625)
                obj.Fq = obj.ODR_LPF_15_625;
            elseif(fq == 7.813)
                obj.Fq = obj.ODR_LPF_7_813;
            elseif(fq == 3.906)
                obj.Fq = obj.ODR_LPF_3_906;
            else
                isCreated = false;
                return;
            end

            data = [isHigherAddress, obj.Range, obj.Fq];
            val = typecast(uint8(sendCommand(obj, obj.LibraryName, cmdID, uint8(data))), 'int8');
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

        function [x, y, z, n] = readN(obj)
            
            cmdID = obj.ADXL357_ADDON_READ_N;
            
            try
                data = [obj.SensorIdx];
                val = sendCommand(obj, obj.LibraryName, cmdID, data);

                n = val(1);
                data32 = single(typecast(uint8(val(5:end)), 'int32'));

                x  = data32(1:n/3);
                y  = data32(33:33 + n/3 - 1);
                z  = data32(65:65 + n/3 - 1);

            catch e
                throwAsCaller(e);
            end
        end
    end


end