classdef OpenLogAddon < matlabshared.addon.LibraryBase
    properties(Access = private, Constant = true)
        OPENLOG_ADDON_CREATE = hex2dec('01')
        OPENLOG_ADDON_DELETE = hex2dec('02')
        OPENLOG_ADDON_READ_FILE   = hex2dec('03')
        OPENLOG_ADDON_FILE_SIZE = hex2dec('04')
        OPENLOG_ADDON_WRITE_FILE   = hex2dec('05')
        OPENLOG_ADDON_WRITE_STRING = hex2dec('06')
        OPENLOG_ADDON_WRITE_LINE = hex2dec('07')

        MAX_NUMBER_OPENLOGS = 4
    end



    properties(Access = protected, Constant = true)
        LibraryName = 'Storage/OpenLog'
        DependentLibraries = {}
        LibraryHeaderFiles = {}
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
        function [text] = readFile(obj, filename, options)
            arguments
               obj
               filename char
               options.start (1,1)  int32 = 0
               options.fileLength (1,1) int32 = -1
               options.readingLength (1,1) int32 = -1
            end
            
            cmdID = obj.OPENLOG_ADDON_READ_FILE;
            
            try
                if(length(filename) > 12)
                    error('Sparkfun:OpenLog:ParameterError', 'Maximum lenght of filename (= %d) has been reached.', 12)
                end

                if(options.fileLength == -1)
                    options.fileLength = obj.getFileSize(filename);
                end

                if(options.readingLength == -1)
                    options.readingLength = options.fileLength - options.start;
                end

                thisTimeReadingLength = uint8(255);

                if(options.readingLength >= 255)
                    thisTimeReadingLength = uint8(255);
                else
                    thisTimeReadingLength = uint8(options.readingLength);
                end

                if(options.readingLength == 0)
                    text = '';
                    return;
                end

                remainLength = options.readingLength - int32(thisTimeReadingLength);

                data = [obj.OpenLogID, typecast(options.start, 'uint8'), uint8(thisTimeReadingLength), uint8(length(filename)), uint8(filename)];
                    text = char(uint8(sendCommand(obj, obj.LibraryName, cmdID, data))');
                remain = obj.readFile(filename, ...
                        fileLength = options.fileLength, ...
                        start = options.start + int32(thisTimeReadingLength), ...
                        readingLength = remainLength);

                text = [text, remain];
                obj.status = 'reading';
            catch e
                throwAsCaller(e);
            end
        end

        function  [size] = getFileSize(obj, filename)
            
            cmdID = obj.OPENLOG_ADDON_FILE_SIZE;
            
            try
                if(length(filename) > 12)
                    error('Sparkfun:OpenLog:ParameterError', 'Maximum lenght of filename (= %d) has been reached.', 12)
                end

                data = [obj.OpenLogID, length(filename), uint8(filename)];
                size = typecast(uint8(sendCommand(obj, obj.LibraryName, cmdID, data)), 'int32');

                obj.status = 'reading';
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