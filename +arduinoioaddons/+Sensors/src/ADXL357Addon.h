#include "LibraryBase.h"
#include "ADXL357.h"

#include <inttypes.h>

#define MAX_NUMBER_SENSORS 2

#define ADXL357_ADDON_CREATE           0x01
#define ADXL357_ADDON_READ             0x02
#define ADXL357_ADDON_DELETE           0x03

#define ADXL357_ADDON_READ_N             0x04

const char ERROR_MSG_ADXL357_SET_RangeFailed[] PROGMEM = "ADXL 357 Set Range Failed";
const char DEBUG_MSG_ADXL357_CREATE_SensorIdxExisted[] PROGMEM = "sensors[%d] existed\n";
const char DEBUG_MSG_ADXL357_CREATE[] PROGMEM = "sensors[%d] = new ADXL357(%d);\n"
                                                "sensors[sensorIdx]->setRange(%" PRId8 ");\n"
                                                "sensors[sensorIdx]->begin();\n";


struct ADXL357FIFOData
{
    uint8_t n; // Numbers of Entities 1 byte
    uint8_t padding1; // Numbers of Entities 1 byte
    uint8_t padding2; // Numbers of Entities 1 byte
    uint8_t padding3; // Numbers of Entities 1 byte
    int32_t x[32];
    int32_t y[32];
    int32_t z[32];
};


class ADXL357Addon : public LibraryBase
{
typedef union{
    float numbers[3];
    byte bytes[12];
}values;

typedef union{
    struct ADXL357FIFOData data;
    byte bytes[388];
}readNResondUnion;

private:
    // sensor[0] for lower i2c address(0x1D), sensor[1] for higher i2c address(0x53)
    ADXL357* sensors[MAX_NUMBER_SENSORS];
    
public:
    // Constructor
    ADXL357Addon(MWArduinoClass& a):sensors()
    {
        // Define the library name
        libName = "Sensors/ADXL357Addon";
        // Register the library to the server
        a.registerLibrary(this);
    }
    
public:
    int8_t createADXL357(bool isHigherAddress, adxl357_range_t range){
        int8_t sensorIdx = -1;

        if(!isHigherAddress){ // Lower Address
            sensorIdx = 0;
        }else // Higher Address
        {
            sensorIdx = 1;
        }

        if(sensors[sensorIdx]){
            debugPrint(DEBUG_MSG_ADXL357_CREATE_SensorIdxExisted, sensorIdx);
            return sensorIdx;
        }

        sensors[sensorIdx] = new ADXL357(isHigherAddress);
        sensors[sensorIdx]->begin();


        sensors[sensorIdx]->setMode(false);

        if(!sensors[sensorIdx]->setRange(range)){
            debugPrint(ERROR_MSG_ADXL357_SET_RangeFailed);
            while(1);
        }

        sensors[sensorIdx]->setMode(true);

        debugPrint(DEBUG_MSG_ADXL357_CREATE, sensorIdx, isHigherAddress, static_cast<uint8_t>(range));
        return sensorIdx;
    }

    readNResondUnion readNFromADXL357(int8_t sensorIdx){
        readNResondUnion returnval;
        if(!sensors[sensorIdx]){
            // Return Failed
            returnval.data.n = 0;
            return returnval;
        }

        returnval.data.n = sensors[sensorIdx]->getAllFIFOData(returnval.data.x, returnval.data.y, returnval.data.z);

        return returnval;
    }

    void commandHandler(byte cmdID, byte* dataIn, unsigned int payload_size)
    {
        switch (cmdID)
        {
            case ADXL357_ADDON_CREATE: {
                bool isHigherAddress = static_cast<bool>(dataIn[0]);

                int8_t rangei = dataIn[1];

                adxl357_range_t range = static_cast<adxl357_range_t>(dataIn[1]);

                int8_t sensorIdx = createADXL357(isHigherAddress, range);

                sendResponseMsg(cmdID, reinterpret_cast<byte *>(&sensorIdx), 1);
                break;
            }
            
            case ADXL357_ADDON_DELETE: {
                int8_t sensorIdx = dataIn[0];

                if(!sensors[sensorIdx]){
                    break;
                }
                delete sensors[sensorIdx];
                sensors[sensorIdx] = nullptr;

                sendResponseMsg(cmdID, 0, 0);
                break;
            }
            
            case ADXL357_ADDON_READ: {
                int8_t sensorIdx = dataIn[0];
                adxl357_range_t range = static_cast<adxl357_range_t>(dataIn[1]);

                if(!sensors[sensorIdx]){
                    break;
                }

                int32_t x, y, z;
                if(!sensors[sensorIdx]->getXYZ(x, y, z)){
                    break;
                }

                double scale;

                scale = sensors[sensorIdx]->getScale();

                float xf, yf, zf;

                xf = x*scale;
                yf = y*scale;
                zf = z*scale;

                values vals = {xf, yf, zf};
                sendResponseMsg(cmdID, vals.bytes, 12);
                break;
            }
            
            case ADXL357_ADDON_READ_N: {
                int8_t sensorIdx = dataIn[0];

                readNResondUnion data = readNFromADXL357(sensorIdx);

                sendResponseMsg(cmdID, data.bytes, 388);

                break;
            }
            
            default: {
                // Print debug string
                break;
            }
        }
    }
};