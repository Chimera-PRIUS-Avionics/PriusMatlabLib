classdef OpenLogAddon < matlabshared.addon.LibraryBase
    properties(Access = private, Constant = true)
        OPENLOG_ADDON_CREATE = hex2dec('01')
        OPENLOG_ADDON_DELETE = hex2dec('02')
        OPENLOG_ADDON_READ_FILE   = hex2dec('03')
        OPENLOG_ADDON_READ_CHAR = hex2dec('04')
        OPENLOG_ADDON_WRITE_FILE   = hex2dec('05')
        OPENLOG_ADDON_WRITE_STRING = hex2dec('06')
        OPENLOG_ADDON_WRITE_LINE = hex2dec('07')

        MAX_NUMBER_OPENLOGS = 4
    end



    properties(Access = protected, Constant = true)
        LibraryName = 'Storage/OpenLog'
        DependentLibraries = {}
        LibraryHeaderFiles = {'ADXL357/ADXL357.h'}
        CppHeaderFile =  fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'OpenLogAddon.h')
        CppClassName = 'OpenLogAddon'
    end

    properties(Access = private)
        OpenLogID;
        ResetPin = uint8(0);
        RxPin = uint8(0);
        TxPin = uint8(0);
        ResourceOwner = 'Storage/OpenLog';
    end

    properties(Access = private)
        status;
    end
    

    methods
        function obj = OpenLogAddon(parentObj, ResetPin, RxPin, TxPin)
                obj.Parent = parentObj;

                obj.ResetPin = ResetPin;
                obj.RxPin = RxPin;
                obj.TxPin = TxPin;

                count = getResourceCount(obj.Parent,obj.ResourceOwner);
                % Since this example allows implementation of only 1 LCD
                % shield, error out if resource count is more than 0
                if count >= obj.MAX_NUMBER_OPENLOGS
                    error('Sparkfun:OpenLog:ValueError', 'Maximum supported number of OpenLog SD Card reader/writer (= %d) has been reached.', obj.MAX_NUMBER_OPENLOGS);
                end

                obj.OpenLogID = count;

                incrementResourceCount(obj.Parent, obj.ResourceOwner);

                if(~createOpenlog(obj))
                    error("OpenLog Created Failed")
                end
        end
    end

    methods(Access = protected)
        function delete(obj)
            try
                parentObj = obj.Parent;
                % Decrement the resource count for the Openlog
                decrementResourceCount(parentObj, obj.ResourceOwner);
                obj.deleteOpenlog();
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
        end
    end

    methods(Access = private)

        function [isCreated] = createOpenlog(obj)
            cmdID = obj.OPENLOG_ADDON_CREATE;
            data = [obj.OpenLogID, obj.RxPin, obj.TxPin, obj.ResetPin];
            isCreated = logical(sendCommand(obj, obj.LibraryName, cmdID, uint8(data)));
            isCreated = isCreated(1);
        end
        

        function deleteOpenlog(obj)
            cmdID = obj.OPENLOG_ADDON_DELETE;
            data = [obj.OpenLogID];
            sendCommand(obj, obj.LibraryName, cmdID, uint8(data));
        end
    end

    methods(Access = public)
        function readFile(obj, filename)
            
            cmdID = obj.OPENLOG_ADDON_READ_FILE;
            
            try
                if(length(filename) > 12)
                    error('Sparkfun:OpenLog:ParameterError', 'Maximum lenght of filename (= %d) has been reached.', 12)
                end

                data = [obj.OpenLogID, length(filename), uint8(filename)];
                sendCommand(obj, obj.LibraryName, cmdID, data);

                obj.status = 'reading';
            catch e
                throwAsCaller(e);
            end
        end

        function [c] = readChar(obj)
            
            cmdID = obj.OPENLOG_ADDON_READ_CHAR;
            
            try
                if(obj.status ~= 'reading')
                    error('Sparkfun:OpenLog:RuntimeError', 'Current stauts (= %s) not support reading file.', obj.status)
                end

                data = [obj.OpenLogID];
                val = sendCommand(obj, obj.LibraryName, cmdID, data);
                c = char(uint8(val));

            catch e
                throwAsCaller(e);
            end
        end
    end

    methods(Access = public)
        function writeFile(obj, filename)
            
            cmdID = obj.OPENLOG_ADDON_WRITE_FILE;
            
            try
                if(length(filename) > 12)
                    error('Sparkfun:OpenLog:ParameterError', 'Maximum lenght of filename (= %d) has been reached.', 12)
                end

                data = [obj.OpenLogID, length(filename), uint8(filename)];
                sendCommand(obj, obj.LibraryName, cmdID, data);

                obj.status = 'writing';
            catch e
                throwAsCaller(e);
            end
        end

        function writeString(obj, s)
            
            cmdID = obj.OPENLOG_ADDON_WRITE_STRING;
            
            try
                if(obj.status ~= 'writing')
                    error('Sparkfun:OpenLog:RuntimeError', 'Current stauts (= %s) not support writing file.', obj.status)
                end

                if(length(s) > 255)
                    error('Sparkfun:OpenLog:RuntimeError', 'Maximum lenght of s (= %d) has been reached.', 255)
                end

                data = [obj.OpenLogID, uint8(length(s)) , uint8(s)];
                sendCommand(obj, obj.LibraryName, cmdID, uint8(data));
                
            catch e
                throwAsCaller(e);
            end
        end

        function writeLine(obj, s)
            
            cmdID = obj.OPENLOG_ADDON_WRITE_LINE;
            
            try
                if(obj.status ~= 'writing')
                    error('Sparkfun:OpenLog:RuntimeError', 'Current stauts (= %s) not support writing file.', obj.status)
                end

                if(length(s) > 255)
                    error('Sparkfun:OpenLog:RuntimeError', 'Maximum lenght of s (= %d) has been reached.', 255)
                end

                data = [obj.OpenLogID, uint8(length(s)) , uint8(s)];
                sendCommand(obj, obj.LibraryName, cmdID, uint8(data));
                
            catch e
                throwAsCaller(e);
            end
        end
    end


end