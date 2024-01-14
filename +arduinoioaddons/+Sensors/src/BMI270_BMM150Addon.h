#include "LibraryBase.h"
#include "Arduino_BMI270_BMM150.h"

#include <inttypes.h>


#define BMI270_BMM150_ADDON_CREATE      0b0001

#define BMI270_BMM150_ADDON_GYO_READ    0b0010
#define BMI270_BMM150_ADDON_ACC_READ    0b0100
#define BMI270_BMM150_ADDON_MAG_READ    0b1000
#define BMI270_BMM150_ADDON_READ_N      0b1110

const char DEBUG_MSG_BMI270_BMM150_SamplesPerRead[] PROGMEM = "this->SamplesPerRead = %" PRIu8 "\n";
const char DEBUG_MSG_BMI270_BMM150_CREATE[] PROGMEM = "createBMI270_BMM150 returns %s\n";

class BMI270_BMM150Addon : public LibraryBase
{
public:
    // Constructor
    BMI270_BMM150Addon(MWArduinoClass& a);

    void commandHandler(byte cmdID, byte* dataIn, unsigned int payload_size);

private:
    bool createBMI270_BMM150();

private:
    uint8_t SamplesPerRead = 1;
};


BMI270_BMM150Addon::BMI270_BMM150Addon(MWArduinoClass& a)
{
    // Define the library name
    libName = "Sensors/BMI270_BMM150Addon";
    // Register the library to the server
    a.registerLibrary(this);
}


void BMI270_BMM150Addon::commandHandler(byte cmdID, byte* dataIn, unsigned int payload_size)
{
    switch (cmdID)
        {
            case BMI270_BMM150_ADDON_CREATE: {

                this->SamplesPerRead = static_cast<uint8_t>(dataIn[0]);
                debugPrint(DEBUG_MSG_BMI270_BMM150_SamplesPerRead, this->SamplesPerRead);

                bool results = this->createBMI270_BMM150();
                debugPrint(DEBUG_MSG_BMI270_BMM150_CREATE, results ? "true" : "false");

                sendResponseMsg(cmdID, reinterpret_cast<byte *>(&results), 1);
                break;
            }
            default: {
                break;
            }
        }
}


bool BMI270_BMM150Addon::createBMI270_BMM150(){
    return IMU.begin();
}

