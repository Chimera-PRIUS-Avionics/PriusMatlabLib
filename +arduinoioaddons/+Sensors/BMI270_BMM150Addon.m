classdef BMI270_BMM150Addon < matlabshared.addon.LibraryBase
    properties(Access = private, Constant = true)
        BMI270_BMM150_ADDON_CREATE =        hex2dec('0001');

        BMI270_BMM150_ADDON_GYO_READ =      hex2dec('0010');
        BMI270_BMM150_ADDON_ACC_READ =      hex2dec('0100');
        BMI270_BMM150_ADDON_MAG_READ =      hex2dec('1000');
        BMI270_BMM150_ADDON_READ_N =        hex2dec('1110');

        MAX_NUMBER_SENSORS = 1;
    end

    properties(Access = protected, Constant = true)
        LibraryName = 'Sensors/BMI270_BMM150Addon'
        DependentLibraries = {}
        LibraryHeaderFiles = 'Arduino_BMI270_BMM150/src/Arduino_BMI270_BMM150.h'
        CppHeaderFile = fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'BMI270_BMM150Addon.h')
        CppClassName = 'BMI270_BMM150Addon'
    end
    
    properties(Access = private)
        ReadMode;

        AccSampleRate = 99.84;
        gyroSampleRate = 99.84;
        magSampleRate = 10;

        SamplesPerRead;

        ResourceOwner = 'Sensors/BMI270_BMM150Addon';
    end

    properties(Access = private)
        DefaultReadMode = "Continous";

        DefaultSamplesPerRead = 200;
    end

    methods
        function obj = BMI270_BMM150Addon(parentObj, varargin)
            obj.Parent = parentObj;

            p = inputParser;
            p.CaseSensitive = 0;
            p.PartialMatching = 1;
            addParameter(p, 'ReadMode', obj.DefaultReadMode);
            addParameter(p, 'SamplesPerRead', obj.DefaultSamplesPerRead);
            parse(p, varargin{:});

            obj.ReadMode = p.Results.ReadMode;
            obj.SamplesPerRead = p.Results.SamplesPerRead;

            count = getResourceCount(obj.Parent, obj.ResourceOwner);
            % Since this example allows implementation of only 1 LCD
            % shield, error out if resource count is more than 0
            if count >= obj.MAX_NUMBER_SENSORS
                error('Arduino:BMI270_BMM150:ValueError', 'Maximum supported number of BMI270_BMM150 sensors (= %d) has been reached.', obj.MAX_NUMBER_SENSORS);
            end

            incrementResourceCount(obj.Parent, obj.ResourceOwner);

            if(~create(obj))
                error("BMI270_BMM150 Created Failed")
            end
        end
    end

    methods(Access = private)
        function [isCreated] = create(obj)
            cmdID = obj.BMI270_BMM150_ADDON_CREATE;

            data = [uint8(obj.SamplesPerRead)];

            isCreated =  logical(uint8(sendCommand(obj, obj.LibraryName, cmdID, uint8(data))));
        end
    end

    methods(Access = public)
        function [x, y, z, n] = readN(obj)
            
            cmdID = obj.BMI270_BMM150_ADDON_READ_N;
            
            try
                data = [];
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