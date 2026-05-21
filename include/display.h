#pragma once
#include <Arduino.h>
#include <Adafruit_SSD1306.h>
#include "config.h"

class Display {
public:
    Display();
    bool begin();
    void splash();
    void imuData(float ax, float ay, float az, float temp);
    void showTime(uint8_t h, uint8_t m, uint8_t s, bool showColon);
    void showSteps(uint32_t steps);
    void showHome(uint8_t h, uint8_t m, uint8_t s, bool showColon, float temp, uint32_t steps);
    void btStatus(const char* msg);
    void clear();

private:
    Adafruit_SSD1306* oled;
};
