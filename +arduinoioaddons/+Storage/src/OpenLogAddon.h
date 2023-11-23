#include <string.h>
#include <stdlib.h> 
#include <inttypes.h>

#include <SoftwareSerial.h>
#include "LibraryBase.h"


#define MAX_NUMBER_OPENLOGS 4

#define OPENLOG_ADDON_CREATE       (0x01)
#define OPENLOG_ADDON_DELETE       (0x02)
#define OPENLOG_ADDON_READ_FILE    (0x03)
#define OPENLOG_ADDON_FILE_SIZE    (0x04)
#define OPENLOG_ADDON_WRITE_FILE   (0x05)
#define OPENLOG_ADDON_WRITE_STRING (0x06)
#define OPENLOG_ADDON_WRITE_LINE   (0x07)

const char DEBUG_MSG_CREATE[] PROGMEM = "openlogs[%d]= s(%d, %d); Rest Pin at %d";
const char DEBUG_MSG_READ_FILE[] PROGMEM = "openlogs[%d]->print(\"read %s %" PRId32 " %d 3 \");";
const char DEBUG_MSG_WRITE_FILE[] PROGMEM = "openlogs[%d]->print(\"write %s\");";
const char DEBUG_MSG_WRITE_CONTENT[] PROGMEM = "openlogs[%d]->print(\"%s\");";
const char DEBUG_MSG_FILE_SIZE[] PROGMEM = "file size: %d byte(s);";
const char DEBUG_MSG_LINE[] PROGMEM = "executeline: %d";
const char DEBUG_MSG_CHAR[] PROGMEM = "%d:%c";

void gotoCommandMode(SoftwareSerial* OpenLog) {
  //Send three control z to enter OpenLog command mode
  //Works with Arduino v1.0
  OpenLog->write(26);
  OpenLog->write(26);
  OpenLog->write(26);

  //Wait for OpenLog to respond with '>' to indicate we are in command mode
  while(1) {
    if(OpenLog->available()){
            char c = OpenLog->read();
        if(c == '>') break;
    }
  }

}

void resetOpenlog(SoftwareSerial* OpenLog, uint8_t ResetPin) {
    OpenLog->write(26);
    OpenLog->write(26);
    OpenLog->write(26);
    delay(100);

    digitalWrite(ResetPin, LOW);
    delay(50);
    digitalWrite(ResetPin, HIGH);


    while(1) {
        if(OpenLog->available()){
            char c = OpenLog->read();
            if(c == '<') break;
        }
            
    }
}


class OpenLogAddon : public LibraryBase
{
private:
    // sensor[0] for lower i2c address(0x1D), sensor[1] for higher i2c address(0x53)
    SoftwareSerial* openlogs[MAX_NUMBER_OPENLOGS];

    bool createOpenlog(uint8_t sensorIdx, uint8_t RxPin, uint8_t TxPin, uint8_t ResetPin){
        if(openlogs[sensorIdx]){
            return false;
        }

        openlogs[sensorIdx] = new SoftwareSerial(RxPin, TxPin);
        
        debugPrint(DEBUG_MSG_CREATE, sensorIdx, RxPin, TxPin, ResetPin);
        
        pinMode(ResetPin, OUTPUT);

        openlogs[sensorIdx]->begin(9600);

        resetOpenlog(openlogs[sensorIdx], ResetPin);

        return true;
    }

    int readFile(uint8_t sensorIdx, char *fileName, char * stringBuffer, int bufferSize, int32_t startPos, uint8_t readingLength) {
        //Old way
        openlogs[sensorIdx]->print("read ");
        openlogs[sensorIdx]->print(fileName);
        openlogs[sensorIdx]->print(' ');
        openlogs[sensorIdx]->print(startPos);
        openlogs[sensorIdx]->print(' ');
        openlogs[sensorIdx]->print(readingLength);
        openlogs[sensorIdx]->print(' ');
        openlogs[sensorIdx]->print(3);
        openlogs[sensorIdx]->write(13); //This is \r

        debugPrint(DEBUG_MSG_READ_FILE, sensorIdx, fileName, startPos, readingLength);

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\r') break;
        }

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\r') break;
        }

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\n') break;
        }  

        //This will listen for characters coming from OpenLog and print them to the terminal
        //This relies heavily on the SoftSerial buffer not overrunning. This will probably not work
        //above 38400bps.
        //This loop will stop listening after 1 second of no characters received
        int spot = 0;
        for(int timeOut = 0 ; timeOut < 1000 ; timeOut++) {
            while(openlogs[sensorIdx]->available()) {
                stringBuffer[spot++] = openlogs[sensorIdx]->read();
                if(spot > bufferSize-2 || spot > readingLength-1){
                    stringBuffer[spot] = '\0';
                    return spot + 1;
                }
                timeOut = 0;
            }
            stringBuffer[spot] = '\0';
            delay(1);
        }
        return spot + 1;
    }

    int32_t getFileSize(uint8_t sensorIdx, char *fileName, char * stringBuffer, int bufferSize) {
        //Old wayr
        openlogs[sensorIdx]->print("size ");
        openlogs[sensorIdx]->print(fileName);
        openlogs[sensorIdx]->write(13); //This is \r

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\r') break;
        }

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\r') break;
        }

        while(1) {
            if(openlogs[sensorIdx]->available())
            if(openlogs[sensorIdx]->read() == '\n') break;
        }  

        //This will listen for characters coming from OpenLog and print them to the terminal
        //This relies heavily on the SoftSerial buffer not overrunning. This will probably not work
        //above 38400bps.
        //This loop will stop listening after 1 second of no characters received
        int spot = 0;
        for(int timeOut = 0 ; timeOut < 1000 ; timeOut++) {
            while(openlogs[sensorIdx]->available()) {
                stringBuffer[spot] = openlogs[sensorIdx]->read();
                if(spot > bufferSize-2){
                    spot++;
                    timeOut = 1000;
                    break;
                }
                if(stringBuffer[spot] == '\r'){
                    stringBuffer[spot] = '\0';
                    timeOut = 1000;
                    break;
                }
                spot ++;
                timeOut = 0;
            }
            stringBuffer[spot] = '\0';
            delay(1);
        }

        int32_t length = atoi(stringBuffer);

        debugPrint(DEBUG_MSG_WRITE_CONTENT, 0, stringBuffer);
        debugPrint(DEBUG_MSG_FILE_SIZE, length);
        
        while(openlogs[sensorIdx]->available()) {
            char c = openlogs[sensorIdx]->read();
        } 

        return length;
    }

public:
    // Constructor
    OpenLogAddon(MWArduinoClass& a):openlogs()
    {
        // Define the library name
        libName = "Storage/OpenLog";
        // Register the library to the server
        a.registerLibrary(this);
    }
    
public:
    void commandHandler(byte cmdID, byte* dataIn, unsigned int payload_size)
    {
        switch (cmdID)
        {
            case OPENLOG_ADDON_CREATE: {
                bool val [1] = {false};

                uint8_t sensorIdx = static_cast<uint8_t>(dataIn[0]);
                uint8_t RxPin = static_cast<uint8_t>(dataIn[1]);
                uint8_t TxPin = static_cast<uint8_t>(dataIn[2]);
                uint8_t ResetPin = static_cast<uint8_t>(dataIn[3]);

                val[0] = createOpenlog(sensorIdx, RxPin, TxPin, ResetPin);

                sendResponseMsg(cmdID, reinterpret_cast<byte *>(val), 1);
                break;
            }
            
            case OPENLOG_ADDON_DELETE: {
                uint8_t sensorIdx = dataIn[0];

                if(!openlogs[sensorIdx]){
                    break;
                }
                delete openlogs[sensorIdx];
                openlogs[sensorIdx] = nullptr;

                sendResponseMsg(cmdID, 0, 0);
                break;
            }
            
            case OPENLOG_ADDON_READ_FILE: {
                //Send three control z to enter OpenLog command mode
                //Works with Arduino v1.0
                uint8_t sensorIdx = dataIn[0];
                int32_t startPos;
                memcpy(&startPos, dataIn+1, 4);
                uint8_t readinglength = dataIn[5];
                uint8_t fileNameLength = dataIn[6];
                char* filenameIn = reinterpret_cast<char *>(&(dataIn[7]));
                char filename[13];

                strncpy(filename, filenameIn, fileNameLength);
                filename[fileNameLength] = '\0';

                resetOpenlog(openlogs[sensorIdx], 4);
                gotoCommandMode(openlogs[sensorIdx]);

                char stringBuffer[256];

                int length = readFile(sensorIdx, filename,  stringBuffer, sizeof(stringBuffer), startPos, readinglength);
                
                sendResponseMsg(cmdID, reinterpret_cast<byte *>(stringBuffer), length-1);
                break;
            }

            case OPENLOG_ADDON_FILE_SIZE: {
                uint8_t sensorIdx = dataIn[0];
                uint8_t fileNameLength = dataIn[1];
                char* filenameIn = reinterpret_cast<char *>(&(dataIn[2]));

                char filename[13];
                strncpy(filename, filenameIn, fileNameLength);
                filename[fileNameLength] = '\0';

                resetOpenlog(openlogs[sensorIdx], 4);
                gotoCommandMode(openlogs[sensorIdx]);

                char stringBuffer[256];

                int32_t length = getFileSize(sensorIdx, filename,  stringBuffer, sizeof(stringBuffer));
                
                sendResponseMsg(cmdID, reinterpret_cast<byte *>(&length), 4);
                break;
            }

            case OPENLOG_ADDON_WRITE_FILE: {
                //Send three control z to enter OpenLog command mode
                //Works with Arduino v1.0
                uint8_t sensorIdx = dataIn[0];

                resetOpenlog(openlogs[sensorIdx], 4);
                gotoCommandMode(openlogs[sensorIdx]);

                
                uint8_t fileNameLength = dataIn[1];
                char* filenameIn = reinterpret_cast<char *>(&(dataIn[2]));

                char filename[13];

                strncpy(filename, filenameIn, fileNameLength);
                filename[fileNameLength] = '\0';

                openlogs[sensorIdx]->print("new ");
                openlogs[sensorIdx]->print(filename);
                openlogs[sensorIdx]->write(13);

                while (1)
                {
                    if(openlogs[sensorIdx]->available())
                        if(openlogs[sensorIdx]->read() == '>') break;
                }

                openlogs[sensorIdx]->print("append ");
                openlogs[sensorIdx]->print(filename);
                openlogs[sensorIdx]->write(13);

                debugPrint(DEBUG_MSG_WRITE_FILE, sensorIdx,  filename);

                while (1)
                {
                    if(openlogs[sensorIdx]->available())
                        if(openlogs[sensorIdx]->read() == '<') break;
                }
                
                sendResponseMsg(cmdID, 0, 0);
                break;
            }

            case OPENLOG_ADDON_WRITE_STRING: {
                uint8_t sensorIdx = dataIn[0];
                uint8_t stringLength = dataIn[1];
                char* stringIn = reinterpret_cast<char *>(&(dataIn[2]));

                char stringline[256];

                strncpy(stringline, stringIn, stringLength);
                stringline[stringLength] = '\0';

                openlogs[sensorIdx]->print(stringline);

                debugPrint(DEBUG_MSG_WRITE_CONTENT, sensorIdx,  stringline);

                sendResponseMsg(cmdID,0, 0);
                break;
            }

            case OPENLOG_ADDON_WRITE_LINE: {
                uint8_t sensorIdx = dataIn[0];
                uint8_t stringLength = dataIn[1];
                char* stringIn = reinterpret_cast<char *>(&(dataIn[2]));

                char stringline[256];

                strncpy(stringline, stringIn, stringLength);
                stringline[stringLength] = '\0';

                openlogs[sensorIdx]->println(stringline);

                debugPrint(DEBUG_MSG_WRITE_CONTENT, sensorIdx,  stringline);

                sendResponseMsg(cmdID, 0, 0);
                break;
            }
            
            default: {
                // Print debug string
                break;
            }
        }
    }
};