#pragma once
#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_GC9A01A.h>
#include "config.h"

// Colores 16-bit 5-6-5 RGB
#define COL_BLACK    0x0000
#define COL_WHITE    0xFFFF
#define COL_RED      0xF800
#define COL_GREEN    0x07E0
#define COL_BLUE     0x001F
#define COL_CYAN     0x07FF
#define COL_MAGENTA  0xF81F
#define COL_YELLOW   0xFFE0
#define COL_ORANGE   0xFD20
#define COL_DARKGREY 0x7BEF

class Display {
public:
    Display();
    bool begin();
    void splash();
    void imuData(float ax, float ay, float az, float temp);
    void showTime(uint8_t h, uint8_t m, uint8_t s, bool showColon);
    void showSteps(uint32_t steps);
    void showHome(uint8_t h, uint8_t m, bool showColon);
    void showHomeWithNotif(uint8_t h, uint8_t m, bool showColon, uint8_t count);
    void showMenu(uint8_t cursor, bool hasNotif);
    void showNotification(const char* title, const char* msg, uint8_t remaining);
    void btStatus(const char* msg);
    void clear();
    void off();
    void on();
    void screenChanged();

private:
    Adafruit_GC9A01A* tft;
    bool homeInit = false;
    bool menuInit = false;
    bool imuInit = false;
    bool timeInit = false;
    bool stepsInit = false;
    bool notifInit = false;
    int textWidth(const char* s);
    void centreText(const char* s, int x, int y, int size);
};
