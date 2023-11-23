clear all
a = arduino('COM3','Uno', 'libraries', 'Storage/OpenLog');
openlog = addon(a, 'Storage/OpenLog', 4, 6, 7);

filename = 'test2103.txt';

writeFile(openlog, filename); % Write to file with filename test.txt. The maximun lenght of filename is 12.


writeString(openlog, 'Hello ');


writeString(openlog, ['World!', newline]); % Two ways to change line
writeLine(openlog, 'This is PRIUS!');

writeLine(openlog, ['Current Time: ', char(datetime("now"))]);  % Construct the contents

getFileSize(openlog, filename)  % Read the file length.

readFile(openlog, filename)   % Read the file CONTENTS
