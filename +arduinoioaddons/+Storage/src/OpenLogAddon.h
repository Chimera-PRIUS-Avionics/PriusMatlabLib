#include <string.h>

#include <SoftwareSerial.h>
#include "LibraryBase.h"


#define MAX_NUMBER_OPENLOGS 4

#define OPENLOG_ADDON_CREATE       (0x01)
#define OPENLOG_ADDON_DELETE       (0x02)
#define OPENLOG_ADDON_READ_FILE    (0x03)
#define OPENLOG_ADDON_READ_CHAR    (0x04)
#define OPENLOG_ADDON_WRITE_FILE   (0x05)
#define OPENLOG_ADDON_WRITE_STRING (0x06)
#define OPENLOG_ADDON_WRITE_LINE   (0x07)

const char DEBUG_MSG_CREATE[] PROGMEM = "openlogs[%d]= s(%d, %d); Rest Pin at %d";
const char DEBUG_MSG_READ_FILE[] PROGMEM = "openlogs[%d]->print(\"read %s\");";
const char DEBUG_MSG_WRITE_FILE[] PROGMEM = "openlogs[%d]->print(\"write %s\");";
const char DEBUG_MSG_WRITE_CONTENT[] PROGMEM = "openlogs[%d]->print(\"%s\");";

void gotoCommandMode(SoftwareSerial* OpenLog) {
  //Send three control z to enter OpenLog command mode
  //Works with Arduino v1.0
  OpenLog->write(26);
  OpenLog->write(26);
  OpenLog->write(26);

  //Wait for OpenLog to respond with '>' to indicate we are in command mode
  while(1) {
    if(OpenLog->available())
      if(OpenLog->read() == '>') break;
  }
}

void resetOpenlog(SoftwareSerial* OpenLog, uint8_t ResetPin) {
    digitalWrite(ResetPin, LOW);
    delay(100);
    digitalWrite(ResetPin, HIGH);


    while(1) {
        if(OpenLog->available())
            if(OpenLog->read() == '<') break;
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

                gotoCommandMode(openlogs[sensorIdx]);

                uint8_t fileNameLength = dataIn[1];
                char* filenameIn = reinterpret_cast<char *>(&(dataIn[2]));

                char filename[13];

                strncpy(filename, filenameIn, fileNameLength);

                openlogs[sensorIdx]->print("read ");
                openlogs[sensorIdx]->print(filename);
                openlogs[sensorIdx]->write(13);

                debugPrint(DEBUG_MSG_READ_FILE, sensorIdx,  filename);

                while (1)
                {
                    if(openlogs[sensorIdx]->available())
                        if(openlogs[sensorIdx]->read() == '\r') break;
                }
                
                sendResponseMsg(cmdID, 0, 0);
                break;
            }

            case OPENLOG_ADDON_READ_CHAR: {
                uint8_t sensorIdx = dataIn[0];
                char c;

                while(openlogs[sensorIdx]->available()) {
                    c = openlogs[sensorIdx]->read();
                }

                sendResponseMsg(cmdID, reinterpret_cast<byte *>(&c), 1);
                break;
            }

            case OPENLOG_ADDON_WRITE_FILE: {
                //Send three control z to enter OpenLog command mode
                //Works with Arduino v1.0
                uint8_t sensorIdx = dataIn[0];

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