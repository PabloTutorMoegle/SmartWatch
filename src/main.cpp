#include <Arduino.h>
#include <Wire.h>
#include "config.h"
#include "mpu.h"
#include "display.h"
#include "ble_smartwatch.h"

MPU mpu;
Display display;
SmartWatchBLE ble;

enum Screen { SCR_OFF, SCR_IMU, SCR_BT };
Screen screen = SCR_BT;

int lastBtn = HIGH;
unsigned long timeout = 0;
unsigned long lastBleNotify = 0;
unsigned long lastScreenUpdate = 0;
unsigned long lastMpuRead = 0;

void onCommand(uint8_t cmd) {
    switch (cmd) {
        case CMD_SHOW_IMU:
            screen = SCR_IMU;
            timeout = millis() + 5000;
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
    display.btStatus("waiting");
}

void loop() {
    unsigned long now = millis();

    if (now - lastMpuRead >= 50) {
        lastMpuRead = now;
        mpu.read();
    }

    int btn = digitalRead(BUTTON_PIN);
    if (lastBtn == HIGH && btn == LOW) {
        screen = SCR_IMU;
        timeout = now + 5000;
        ble.sendButton("PRESSED");
    }
    lastBtn = btn;

    if (ble.connected()) {
        if (now - lastBleNotify >= 500) {
            lastBleNotify = now;
            ble.sendIMU(mpu.ax, mpu.ay, mpu.az, mpu.gx, mpu.gy, mpu.gz);
            ble.sendTemp(mpu.celsius);
        }
    }

    if (now - lastScreenUpdate >= 200) {
        lastScreenUpdate = now;

        if (screen == SCR_IMU && now < timeout) {
            display.imuData(mpu.ax_g, mpu.ay_g, mpu.az_g, mpu.celsius);
        } else if (screen == SCR_IMU) {
            screen = ble.connected() ? SCR_BT : SCR_OFF;
        }

        if (screen == SCR_BT) {
            display.btStatus(ble.connected() ? "connected" : "waiting");
        }

        if (screen == SCR_OFF) {
            if (mpu.az_g > 0.8) {
                screen = SCR_IMU;
                timeout = now + 5000;
            } else {
                display.clear();
            }
        }
    }

    delay(20);
}
