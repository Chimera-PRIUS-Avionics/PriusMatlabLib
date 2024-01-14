function plan = buildfile
import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

% Create a plan from task functions
plan = buildplan(localfunctions);

plan.DefaultTasks = "package";

end

function packageTask(~)
% ToolBox Package
version_num = getenv("PRIUS_MATLAB_LIB_VERSION_NUM");

if(isempty(version_num))
    version_num = '0';
end

opts = matlab.addons.toolbox.ToolboxOptions('./',"PRIUSMatlabLib");

opts.ToolboxName = "PRIUS Matlab Lib";

opts.ToolboxVersion = version_num;

opts.SupportedPlatforms.Win64 = true;
opts.SupportedPlatforms.Maci64 = true;
opts.SupportedPlatforms.Glnxa64 = true;
opts.SupportedPlatforms.MatlabOnline = true;

opts.ToolboxFiles = {'./+arduinoioaddons', ...
                     './QuickStart.mlx'};

opts.ToolboxGettingStartedGuide = './QuickStart.mlx';

opts.OutputFile = "PRIUS Matlab Lib";

opts.RequiredAdditionalSoftware = [ ...
    struct("Name", "ADXL357", ...
           "Platform", {'win64', 'glnxa64', 'maci64'},...
           "DownloadURL", "https://github.com/Chimera-PRIUS-Avionics/ADXL357/archive/refs/heads/main.zip", ...
           "LicenseURL", "https://mit-license.org/"), ...
    struct("Name", "mpu6050", ...
           "Platform", {'win64', 'glnxa64', 'maci64'},...
           "DownloadURL", "https://github.com/ElectronicCats/mpu6050/archive/refs/heads/master.zip", ...
           "LicenseURL", "https://raw.githubusercontent.com/ElectronicCats/mpu6050/master/LICENSE"),
        struct("Name", "Arduino_BMI270_BMM150", ...
           "Platform", {'win64', 'glnxa64', 'maci64'},...
           "DownloadURL", "https://github.com/arduino-libraries/Arduino_BMI270_BMM150/archive/refs/heads/master.zip", ...
           "LicenseURL", "https://raw.githubusercontent.com/arduino-libraries/Arduino_BMI270_BMM150/master/LICENSE")];

matlab.addons.toolbox.packageToolbox(opts)
end