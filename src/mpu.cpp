#include <Arduino.h>
#include <Wire.h>
#include "config.h"
#include "mpu.h"

bool MPU::begin() {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x6B);
    Wire.write(0);
    return Wire.endTransmission(true) == 0;
}

void MPU::read() {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B);
    if (Wire.endTransmission(false) != 0) {
        Wire.end();
        Wire.begin(I2C_SDA, I2C_SCL);
        return;
    }

    uint8_t count = Wire.requestFrom((uint8_t)MPU_ADDR, (size_t)14, true);
    if (count < 14) {
        Wire.end();
        Wire.begin(I2C_SDA, I2C_SCL);
        return;
    }

    ax = Wire.read() << 8 | Wire.read();
    ay = Wire.read() << 8 | Wire.read();
    az = Wire.read() << 8 | Wire.read();
    temp_raw = Wire.read() << 8 | Wire.read();
    gx = Wire.read() << 8 | Wire.read();
    gy = Wire.read() << 8 | Wire.read();
    gz = Wire.read() << 8 | Wire.read();

    ax_g = ax / 16384.0f;
    ay_g = ay / 16384.0f;
    az_g = az / 16384.0f;
    celsius = (temp_raw / 340.0f) + 17.5f;

    updateStepCount();
}

void MPU::updateStepCount() {
    unsigned long now = millis();
    if (now - lastStepTime < 250) return;

    float mag = sqrt(ax_g * ax_g + ay_g * ay_g + az_g * az_g);

    if (mag > 1.15f && !stepDetected) {
        stepDetected = true;
    }

    if (stepDetected && mag < 0.85f) {
        stepCount++;
        stepDetected = false;
        lastStepTime = now;
    }
}

void MPU::resetSteps() {
    stepCount = 0;
    stepDetected = false;
}

uint32_t MPU::getStepCount() const {
    return stepCount;
}
