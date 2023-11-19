addpath('./')

a = arduino('COM3','Uno', 'libraries', 'Sensors/ADXL357Addon','ForceBuildOn',false, 'Trace',true);
sensor = addon(a, 'Sensors/ADXL357Addon', false, bin2dec('01'));
[x, y, z] = sensor.read();