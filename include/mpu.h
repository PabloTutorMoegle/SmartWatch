#pragma once
#include <Arduino.h>

class MPU {
public:
    bool begin();
    void read();
    void resetSteps();
    uint32_t getStepCount() const;

    int16_t ax, ay, az;
    int16_t gx, gy, gz;
    int16_t temp_raw;
    float ax_g, ay_g, az_g;
    float celsius;
    uint32_t stepCount = 0;

private:
    void updateStepCount();
    bool stepDetected = false;
    unsigned long lastStepTime = 0;
};
