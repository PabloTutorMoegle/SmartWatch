#include <Arduino.h>
#include <cstring>
#include <Wire.h>
#include "config.h"
#include "mpu.h"
#include "display.h"
#include "ble_smartwatch.h"

MPU mpu;
Display display;
SmartWatchBLE ble;

enum Screen { SCR_OFF, SCR_HOME, SCR_IMU, SCR_STEPS, SCR_TIME, SCR_NOTIFICATION };
Screen screen = SCR_HOME;

int lastBtn = HIGH;
unsigned long timeout = 0;
unsigned long lastBleNotify = 0;
unsigned long lastScreenUpdate = 0;
unsigned long lastMpuRead = 0;

uint8_t hours = 0, minutes = 0, seconds = 0;
unsigned long lastTimeTick = 0;

bool lastWakeState = false;
unsigned long tDiag = 0;

struct Notification {
    char title[NOTIF_TITLE_MAX];
    char msg[NOTIF_MSG_MAX];
};
Notification notifQueue[NOTIF_QUEUE_MAX];
int notifHead = 0;
int notifTail = 0;
int notifCount = 0;

int notifViewIdx = 0;

bool pushNotification(const char* title, const char* msg) {
    if (notifCount >= NOTIF_QUEUE_MAX) return false;
    Notification* n = &notifQueue[notifTail];
    strncpy(n->title, title, NOTIF_TITLE_MAX - 1);
    n->title[NOTIF_TITLE_MAX - 1] = '\0';
    strncpy(n->msg, msg, NOTIF_MSG_MAX - 1);
    n->msg[NOTIF_MSG_MAX - 1] = '\0';
    notifTail = (notifTail + 1) % NOTIF_QUEUE_MAX;
    notifCount++;
    return true;
}

void clearNotifications() {
    notifHead = 0;
    notifTail = 0;
    notifCount = 0;
    notifViewIdx = 0;
}

int notifUnreadCount() {
    return notifCount;
}

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
            timeout = millis() + 7000;
            break;
        case CMD_SHOW_IMU:
            screen = SCR_IMU;
            timeout = millis() + 7000;
            break;
        case CMD_SCREEN_OFF:
            screen = SCR_OFF;
            break;
        case CMD_SHOW_STEPS:
            screen = SCR_STEPS;
            timeout = millis() + 7000;
            break;
        case CMD_RESET_STEPS:
            mpu.resetSteps();
            break;
        case CMD_SEND_NOTIFICATION: {
            if (len < 3) break;
            uint8_t tlen = data[1];
            if (tlen >= len - 2) break;
            uint8_t mlen = data[2 + tlen];
            if (2 + tlen + 1 + mlen > len) break;
            char tbuf[NOTIF_TITLE_MAX];
            char mbuf[NOTIF_MSG_MAX];
            int tcopy = (tlen < NOTIF_TITLE_MAX - 1) ? tlen : NOTIF_TITLE_MAX - 1;
            memcpy(tbuf, &data[2], tcopy);
            tbuf[tcopy] = '\0';
            int mcopy = (mlen < NOTIF_MSG_MAX - 1) ? mlen : NOTIF_MSG_MAX - 1;
            memcpy(mbuf, &data[2 + tlen + 1], mcopy);
            mbuf[mcopy] = '\0';
            if (pushNotification(tbuf, mbuf)) {
                if (screen == SCR_HOME || screen == SCR_OFF) {
                    notifViewIdx = notifHead;
                    screen = SCR_NOTIFICATION;
                    timeout = millis() + 7000;
                }
            }
            break;
        }
        case CMD_CLEAR_NOTIFICATIONS:
            clearNotifications();
            if (screen == SCR_NOTIFICATION) {
                screen = SCR_HOME;
                timeout = millis() + 7000;
            }
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
    });
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
        if (screen == SCR_NOTIFICATION) {
            if (notifCount > 1) {
                notifHead = (notifHead + 1) % NOTIF_QUEUE_MAX;
                notifCount--;
                notifViewIdx = notifHead;
                timeout = millis() + 7000;
            } else {
                clearNotifications();
                screen = SCR_HOME;
                timeout = millis() + 7000;
            }
        } else if (screen == SCR_HOME) {
            screen = SCR_IMU;
        } else if (screen == SCR_IMU) {
            screen = SCR_STEPS;
        } else if (screen == SCR_STEPS) {
            screen = SCR_TIME;
        } else {
            screen = SCR_HOME;
        }
        timeout = millis() + 7000;
    }
    lastBtn = btn;

    if (ble.connected()) {
        if (now - lastBleNotify >= 500) {
            lastBleNotify = now;
            ble.sendAll(mpu.ax, mpu.ay, mpu.az, mpu.gx, mpu.gy, mpu.gz,
                        mpu.celsius, mpu.getStepCount(),
                        hours, minutes, seconds);
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
    }

    if (now - lastScreenUpdate >= 200) {
        lastScreenUpdate = now;

        // --- Render / transition based on current screen ---
        if (screen == SCR_HOME) {
            if (notifCount > 0) {
                display.showHomeWithNotif(hours, minutes, seconds, seconds % 2 == 0, mpu.celsius, mpu.getStepCount(), notifCount);
            } else {
                display.showHome(hours, minutes, seconds, seconds % 2 == 0, mpu.celsius, mpu.getStepCount());
            }
        }

        if (screen == SCR_IMU) {
            display.imuData(mpu.ax_g, mpu.ay_g, mpu.az_g, mpu.celsius);
        }

        if (screen == SCR_STEPS) {
            display.showSteps(mpu.getStepCount());
        }

        if (screen == SCR_TIME) {
            display.showTime(hours, minutes, seconds, seconds % 2 == 0);
        }

        if (screen == SCR_NOTIFICATION) {
            if (notifCount > 0) {
                Notification* n = &notifQueue[notifViewIdx];
                display.showNotification(n->title, n->msg, notifCount);
            } else {
                screen = SCR_HOME;
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
            screen = SCR_HOME;
            timeout = millis() + 7000;
        }
        lastWakeState = currentWake;
    }

    delay(20);
}
