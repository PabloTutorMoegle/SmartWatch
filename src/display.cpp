#include <Arduino.h>
#include "config.h"
#include "display.h"

Display::Display() {
    oled = new Adafruit_SSD1306(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
}

bool Display::begin() {
    return oled->begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
}

void Display::splash() {
    oled->clearDisplay();
    oled->setTextSize(1);
    oled->setTextColor(SSD1306_WHITE);
    oled->setCursor(16, 20);
    oled->println("SmartWatch");
    oled->setCursor(28, 35);
    oled->println("v0.2 BLE");
    oled->display();
}

void Display::imuData(float ax, float ay, float az, float temp) {
    oled->clearDisplay();
    oled->setTextSize(1);

    oled->setCursor(16, 0);
    oled->println("MPU6050 DATA");
    oled->drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

    char buf[20];
    oled->setCursor(0, 16);
    snprintf(buf, sizeof(buf), "X: %+06.2f g", ax);
    oled->println(buf);

    oled->setCursor(0, 26);
    snprintf(buf, sizeof(buf), "Y: %+06.2f g", ay);
    oled->println(buf);

    oled->setCursor(0, 36);
    snprintf(buf, sizeof(buf), "Z: %+06.2f g", az);
    oled->println(buf);

    oled->setCursor(0, 50);
    oled->print("Temp: ");
    oled->print(temp, 1);
    oled->print(" C");
    oled->display();
}

void Display::showTime(uint8_t h, uint8_t m, uint8_t s, bool showColon) {
    oled->clearDisplay();
    oled->setTextSize(2);
    oled->setTextColor(SSD1306_WHITE);

    char buf[9];
    snprintf(buf, sizeof(buf), "%02u%c%02u%c%02u",
             h, showColon ? ':' : ' ',
             m, showColon ? ':' : ' ',
             s);

    int16_t x1, y1;
    uint16_t w, ht;
    oled->getTextBounds(buf, 0, 0, &x1, &y1, &w, &ht);
    oled->setCursor((SCREEN_WIDTH - w) / 2, (SCREEN_HEIGHT - ht) / 2);
    oled->print(buf);
    oled->display();
}

void Display::showSteps(uint32_t steps) {
    oled->clearDisplay();
    oled->setTextSize(1);
    oled->setCursor(20, 0);
    oled->println("CONTADOR");
    oled->drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

    oled->setTextSize(3);
    char buf[12];
    snprintf(buf, sizeof(buf), "%lu", steps);

    int16_t x1, y1;
    uint16_t w, ht;
    oled->getTextBounds(buf, 0, 0, &x1, &y1, &w, &ht);
    oled->setCursor((SCREEN_WIDTH - w) / 2, (SCREEN_HEIGHT - ht) / 2 + 8);
    oled->print(buf);

    oled->setTextSize(1);
    oled->setCursor(30, 54);
    oled->print("pasos");
    oled->display();
}

void Display::showHome(uint8_t h, uint8_t m, uint8_t s, bool showColon, float temp, uint32_t steps) {
    oled->clearDisplay();
    oled->setTextSize(1);

    char buf[16];

    snprintf(buf, sizeof(buf), "%lu p", steps);
    oled->setCursor(0, 0);
    oled->print(buf);

    snprintf(buf, sizeof(buf), "%.1fC", temp);
    int16_t x1, y1;
    uint16_t w, ht;
    oled->getTextBounds(buf, 0, 0, &x1, &y1, &w, &ht);
    oled->setCursor(SCREEN_WIDTH - w - 1, 0);
    oled->print(buf);

    oled->drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

    oled->setTextSize(2);
    snprintf(buf, sizeof(buf), "%02u%c%02u%c%02u",
             h, showColon ? ':' : ' ',
             m, showColon ? ':' : ' ',
             s);
    oled->getTextBounds(buf, 0, 0, &x1, &y1, &w, &ht);
    oled->setCursor((SCREEN_WIDTH - w) / 2, (SCREEN_HEIGHT - ht) / 2 + 6);
    oled->print(buf);

    oled->display();
}

void Display::btStatus(const char* msg) {
    oled->clearDisplay();
    oled->setTextSize(1);
    oled->setTextColor(SSD1306_WHITE);

    if (strcmp(msg, "waiting") == 0) {
        oled->setCursor(8, 20);
        oled->println("Bluetooth");
        oled->setCursor(4, 30);
        oled->println("Esperando...");
    } else if (strcmp(msg, "connected") == 0) {
        oled->setCursor(8, 20);
        oled->println("BT Conectado!");
        oled->setCursor(0, 35);
        oled->println("App lista");
    } else {
        oled->setCursor(0, 0);
        oled->println(msg);
    }
    oled->display();
}

void Display::clear() {
    oled->clearDisplay();
    oled->display();
}
