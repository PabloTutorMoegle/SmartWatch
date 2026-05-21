#include <Arduino.h>
#include <Wire.h>
#include "config.h"
#include "mpu.h"
#include "display.h"
#include "ble_smartwatch.h"

MPU mpu;
Display display;
SmartWatchBLE ble;

enum Screen { SCR_OFF, SCR_IMU, SCR_BT, SCR_TIME };
Screen screen = SCR_BT;

int lastBtn = HIGH;
unsigned long timeout = 0;
unsigned long lastBleNotify = 0;
unsigned long lastScreenUpdate = 0;
unsigned long lastMpuRead = 0;

uint8_t hours = 0, minutes = 0, seconds = 0;
unsigned long lastTimeTick = 0;

bool lastWakeState = false;
unsigned long tDiag = 0;

void onCommand(uint8_t cmd, uint8_t* data, size_t len) {
    switch (cmd) {
        case CMD_SHOW_TIME:
            if (len >= 4) {
                hours = data[1];
                minutes = data[2];
                seconds = data[3];
                lastTimeTick = millis();
                ble.setTimeValue(hours, minutes, seconds);
            }
            screen = SCR_TIME;
            break;
        case CMD_SHOW_IMU:
            screen = SCR_IMU;
            timeout = millis() + 7000;
            break;
        case CMD_SCREEN_OFF:
            screen = SCR_OFF;
            break;
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("SmartWatch v0.2 BLE");

    Wire.begin(I2C_SDA, I2C_SCL);

    if (!display.begin()) {
        Serial.println("SSD1306 no encontrado");
        while (true) delay(10);
    }

    if (!mpu.begin()) {
        Serial.println("MPU6050 no responde");
        display.btStatus("MPU6050 NO");
        delay(2000);
    }

    pinMode(BUTTON_PIN, INPUT_PULLUP);
    display.splash();
    delay(1500);

    ble.begin();
    ble.onCommand(onCommand);
    ble.onTimeReceived([](uint8_t h, uint8_t m, uint8_t s) {
        hours = h;
        minutes = m;
        seconds = s;
        lastTimeTick = millis();
        ble.setTimeValue(hours, minutes, seconds);
        screen = SCR_TIME;
        timeout = millis() + 7000;
    });
    display.btStatus("waiting");
    timeout = millis() + 7000;
}

void loop() {
    unsigned long now = millis();

    if (now - lastMpuRead >= 50) {
        lastMpuRead = now;
        mpu.read();
    }

    int btn = digitalRead(BUTTON_PIN);
    if (lastBtn == HIGH && btn == LOW) {
        Serial.print("Boton PRESIONADO (GPIO");
        Serial.print(BUTTON_PIN);
        Serial.println(")");
        screen = SCR_IMU;
        timeout = millis() + 7000;
    } else if (lastBtn == LOW && btn == HIGH) {
        Serial.println("Boton LIBERADO");
    }
    lastBtn = btn;

    if (now - tDiag >= 3000) {
        tDiag = now;
        Serial.print("GPIO");
        Serial.print(BUTTON_PIN);
        Serial.print(" = ");
        Serial.print(btn);
        Serial.print("  |  az_g = ");
        Serial.println(mpu.az_g, 3);
    }

    if (ble.connected()) {
        if (now - lastBleNotify >= 500) {
            lastBleNotify = now;
            ble.sendIMU(mpu.ax, mpu.ay, mpu.az, mpu.gx, mpu.gy, mpu.gz);
            ble.sendTemp(mpu.celsius);
        }
    }

    if (now - lastTimeTick >= 1000) {
        lastTimeTick = now;
        seconds++;
        if (seconds >= 60) {
            seconds = 0;
            minutes++;
            if (minutes >= 60) {
                minutes = 0;
                hours = (hours + 1) % 24;
            }
        }
        ble.setTimeValue(hours, minutes, seconds);
    }

    if (now - lastScreenUpdate >= 200) {
        lastScreenUpdate = now;

        // --- Render / transition based on current screen ---
        if (screen == SCR_IMU) {
            display.imuData(mpu.ax_g, mpu.ay_g, mpu.az_g, mpu.celsius);
        }

        if (screen == SCR_TIME) {
            if (ble.connected()) {
                display.showTime(hours, minutes, seconds, seconds % 2 == 0);
            } else {
                screen = SCR_BT;
                timeout = now + 7000;
            }
        }

        if (screen == SCR_BT) {
            if (ble.connected()) {
                screen = SCR_TIME;
                timeout = now + 7000;
            } else {
                display.btStatus("waiting");
            }
        }

        if (screen == SCR_OFF) {
            display.clear();
        }

        // --- Unified timeout: any active screen turns off after 7s ---
        if (screen != SCR_OFF && now >= timeout) {
            screen = SCR_OFF;
        }
    }

    // --- Wake-on-motion: rising edge of az_g > 0.85 (checked every loop) ---
    {
        bool currentWake = (mpu.az_g > 0.95f);
        if (screen == SCR_OFF && currentWake && !lastWakeState) {
            screen = ble.connected() ? SCR_TIME : SCR_IMU;
            timeout = millis() + 7000;
        }
        lastWakeState = currentWake;
    }

    delay(20);
}
