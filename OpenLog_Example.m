clear all
a = arduino('COM3','Uno', 'libraries', 'Storage/OpenLog','ForceBuildOn',true, 'Trace',true);
openlog = addon(a, 'Storage/OpenLog', 4, 6, 7);

writeFile(openlog, 'text2.txt');
writeString(openlog, 'Hello ');
writeString(openlog, ['World!', newline]);

writeLine(openlog, 'This is PRIUS!');

writeLine(openlog, ['Current Time: ', char(datetime("now"))]);

readFile(openlog, 'text2.txt');
readChar(openlog);
