#include "LibraryBase.h"
#include "ADXL357.h"

#define MAX_NUMBER_SENSORS 2

#define ADXL357_ADDON_CREATE           0x01
#define ADXL357_ADDON_READ             0x02
#define ADXL357_ADDON_DELETE           0x03

class ADXL357Addon : public LibraryBase
{
typedef union{
    float numbers[3];
    byte bytes[12];
}values;

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
    void commandHandler(byte cmdID, byte* dataIn, unsigned int payload_size)
    {
        switch (cmdID)
        {
            case ADXL357_ADDON_CREATE: {
                bool isHigherAddress = static_cast<bool>(dataIn[0]);

                adxl357_range_t range = static_cast<adxl357_range_t>(dataIn[1]);

                int8_t sensorIdx = -1;

                if(!isHigherAddress){ // Lower Address
                    sensorIdx = 0;
                }else // Higher Address
                {
                    sensorIdx = 1;
                }

                if(sensors[sensorIdx]){
                    sendResponseMsg(cmdID, static_cast<int8_t>(-1), 1);
                    break;
                }

                sensors[sensorIdx] = new ADXL357(isHigherAddress);
                
                sensors[sensorIdx]->setRange(range);
                sensors[sensorIdx]->begin();

                sendResponseMsg(cmdID, static_cast<uint8_t>(sensorIdx), 1);
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

                switch (range)
                {
                case adxl357_range_t::Range_40_G:
                    scale = ADXL357_SCL_40G;
                    break;
                case adxl357_range_t::Range_20_G:
                    scale = ADXL357_SCL_20G;
                    break;
                case adxl357_range_t::Range_10_G:
                    scale = ADXL357_SCL_10G;
                    break;
                
                default:
                    scale = 0;
                    break;
                }

                float xf, yf, zf;

                xf = x*scale;
                yf = y*scale;
                zf = z*scale;

                values vals = {xf, yf, zf};
                sendResponseMsg(cmdID, vals.bytes, 12);
                break;
            }
            
            default: {
                // Print debug string
                break;
            }
        }
    }
};