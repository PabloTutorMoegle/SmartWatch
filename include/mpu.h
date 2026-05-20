#pragma once
#include <Arduino.h>

class MPU {
public:
    bool begin();
    void read();

    int16_t ax, ay, az;
    int16_t gx, gy, gz;
    int16_t temp_raw;
    float ax_g, ay_g, az_g;
    float celsius;
};
