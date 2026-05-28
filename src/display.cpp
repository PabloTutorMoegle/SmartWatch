#include <Arduino.h>
#include "config.h"
#include "display.h"

Display::Display() {
    tft = new Adafruit_GC9A01A(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);
}

bool Display::begin() {
    Serial.println("DISPLAY: init start");
    tft->begin();
    Serial.println("DISPLAY: begin ok");
    tft->setRotation(0);
    tft->fillScreen(COL_RED);
    Serial.println("DISPLAY: red fill done");
    delay(500);
    tft->fillScreen(COL_BLACK);
    return true;
}

int Display::textWidth(const char* s) {
    int16_t x1, y1;
    uint16_t w, h;
    tft->getTextBounds(s, 0, 0, &x1, &y1, &w, &h);
    return w;
}

void Display::centreText(const char* s, int x, int y, int size) {
    tft->setTextSize(size);
    tft->setCursor(x - textWidth(s) / 2, y);
    tft->print(s);
}

void Display::splash() {
    tft->fillScreen(COL_BLACK);
    tft->drawCircle(120, 120, 117, COL_DARKGREY);
    tft->drawCircle(120, 120, 116, COL_CYAN);
    tft->setTextColor(COL_WHITE);
    centreText("SmartWatch", 120, 90, 3);
    tft->setTextColor(COL_CYAN);
    centreText("v0.3 BLE", 120, 130, 2);
}

void Display::imuData(float ax, float ay, float az, float temp) {
    if (!imuInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->setTextSize(2);
        tft->setTextColor(COL_CYAN);
        centreText("MPU6050", 120, 14, 2);
        imuInit = true;
    }

    char buf[20];
    tft->fillRect(20, 35, 200, 140, COL_BLACK);

    tft->setTextSize(2);
    tft->setTextColor(COL_MAGENTA);
    centreText("X", 50, 50, 2);
    tft->setTextColor(COL_WHITE);
    snprintf(buf, sizeof(buf), "%+06.2f g", ax);
    centreText(buf, 150, 50, 2);

    tft->setTextColor(COL_GREEN);
    centreText("Y", 50, 80, 2);
    tft->setTextColor(COL_WHITE);
    snprintf(buf, sizeof(buf), "%+06.2f g", ay);
    centreText(buf, 150, 80, 2);

    tft->setTextColor(COL_BLUE);
    centreText("Z", 50, 110, 2);
    tft->setTextColor(COL_WHITE);
    snprintf(buf, sizeof(buf), "%+06.2f g", az);
    centreText(buf, 150, 110, 2);

    tft->setTextColor(COL_YELLOW);
    snprintf(buf, sizeof(buf), "Temp: %.1f C", temp);
    centreText(buf, 120, 155, 2);
}

void Display::showTime(uint8_t h, uint8_t m, uint8_t s, bool showColon) {
    if (!timeInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->drawCircle(120, 120, 116, COL_CYAN);
        timeInit = true;
    }

    char buf[9];
    snprintf(buf, sizeof(buf), "%02u%c%02u%c%02u",
             h, showColon ? ':' : ' ',
             m, showColon ? ':' : ' ',
             s);

    tft->fillRect(10, 75, 220, 55, COL_BLACK);
    tft->setTextSize(4);
    tft->setTextColor(COL_WHITE);
    centreText(buf, 120, 95, 4);
}

void Display::showSteps(uint32_t steps) {
    if (!stepsInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->drawCircle(120, 120, 116, COL_CYAN);
        tft->setTextSize(2);
        tft->setTextColor(COL_CYAN);
        centreText("CONTADOR", 120, 20, 2);
        stepsInit = true;
    }

    char buf[12];
    snprintf(buf, sizeof(buf), "%lu", steps);
    tft->fillRect(10, 60, 220, 80, COL_BLACK);
    tft->setTextSize(4);
    tft->setTextColor(COL_WHITE);
    centreText(buf, 120, 88, 4);

    tft->setTextSize(2);
    tft->setTextColor(COL_CYAN);
    centreText("pasos", 120, 150, 2);
}

void Display::showHome(uint8_t h, uint8_t m, bool showColon) {
    if (!homeInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->drawCircle(120, 120, 116, COL_CYAN);
        homeInit = true;
    }

    char buf[16];
    tft->fillRect(10, 75, 220, 65, COL_BLACK);
    tft->setTextSize(5);
    tft->setTextColor(COL_WHITE);
    snprintf(buf, sizeof(buf), "%02u%c%02u",
             h, showColon ? ':' : ' ',
             m);
    centreText(buf, 120, 90, 5);
}

void Display::screenChanged() {
    homeInit = false;
    menuInit = false;
    imuInit = false;
    timeInit = false;
    stepsInit = false;
    notifInit = false;
}

void Display::showHomeWithNotif(uint8_t h, uint8_t m, bool showColon, uint8_t count) {
    showHome(h, m, showColon);
    tft->fillCircle(SCREEN_WIDTH - 20, 22, 6, COL_RED);
}

void Display::btStatus(const char* msg) {
    tft->fillScreen(COL_BLACK);
    tft->drawCircle(120, 120, 117, COL_DARKGREY);
    tft->drawCircle(120, 120, 116, COL_CYAN);

    if (strcmp(msg, "waiting") == 0) {
        tft->setTextColor(COL_WHITE);
        centreText("SmartWatch", 120, 80, 3);
        tft->setTextColor(COL_CYAN);
        centreText("Esperando...", 120, 125, 2);
    } else if (strcmp(msg, "connected") == 0) {
        tft->setTextColor(COL_GREEN);
        centreText("Conectado", 120, 90, 3);
        tft->setTextColor(COL_WHITE);
        centreText("App lista", 120, 130, 2);
    } else {
        tft->setTextColor(COL_WHITE);
        centreText(msg, 120, 120, 2);
    }
}

void Display::showMenu(uint8_t cursor, bool hasNotif) {
    if (!menuInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->setTextSize(2);
        tft->setTextColor(COL_CYAN);
        centreText("MENU", 120, 12, 2);
        menuInit = true;
    }

    const char* items[5] = {"Home", "IMU", "Steps", "Time", "Notif."};
    tft->fillRect(40, 36, 160, 185, COL_BLACK);

    tft->setTextSize(2);
    for (int i = 0; i < 5; i++) {
        int y = 46 + i * 36;
        if (i == cursor) {
            tft->fillRoundRect(42, y - 3, 156, 26, 6, COL_CYAN);
            tft->setTextColor(COL_BLACK);
            centreText(items[i], 120, y, 2);
        } else {
            tft->setTextColor(COL_DARKGREY);
            centreText(items[i], 120, y, 2);
        }
    }

    if (hasNotif) {
        tft->fillCircle(SCREEN_WIDTH - 20, 20, 5, COL_RED);
    }
}

void Display::showNotification(const char* title, const char* msg, uint8_t remaining) {
    if (!notifInit) {
        tft->fillScreen(COL_BLACK);
        tft->drawCircle(120, 120, 117, COL_DARKGREY);
        tft->drawCircle(120, 120, 116, COL_CYAN);
        notifInit = true;
    }

    tft->fillRect(20, 6, 200, 22, COL_BLACK);
    tft->setTextSize(2);
    tft->setTextColor(COL_YELLOW);
    centreText(title, 120, 10, 2);

    int msglen = strlen(msg);
    int maxChars = 34;
    tft->fillRect(10, 35, 220, 130, COL_BLACK);
    tft->setTextSize(1);
    tft->setTextColor(COL_WHITE);
    if (msglen > maxChars) {
        char buf[38];
        memcpy(buf, msg, maxChars - 3);
        buf[maxChars - 3] = '.';
        buf[maxChars - 2] = '.';
        buf[maxChars - 1] = '.';
        buf[maxChars] = '\0';
        centreText(buf, 120, 60, 2);
    } else {
        centreText(msg, 120, 60, 2);
    }

    char footer[16];
    snprintf(footer, sizeof(footer), "%d / %d", remaining, NOTIF_QUEUE_MAX);
    tft->setTextSize(1);

    tft->fillRect(40, 170, 160, 20, COL_BLACK);
    tft->setTextColor(COL_DARKGREY);
    centreText(footer, 120, 182, 2);
}

void Display::clear() {
    tft->fillScreen(COL_BLACK);
}

void Display::off() {
    tft->sendCommand(0x10);
}

void Display::on() {
    tft->sendCommand(0x11);
    delay(120);
}
