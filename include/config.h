#pragma once

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define I2C_SDA 21
#define I2C_SCL 22

#define MPU_ADDR 0x68
#define OLED_ADDR 0x3C

#define BUTTON_PIN 23

#define BLE_DEVICE_NAME "SmartWatch-Pro"

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_IMU_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_TEMP_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define CHAR_BUTTON_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26aa"
#define CHAR_COMMAND_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26ab"
#define CHAR_TIME_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26ac"

#define CMD_SHOW_TIME   0x01
#define CMD_SHOW_IMU    0x02
#define CMD_SCREEN_OFF  0x03
#define CMD_VIBRATE     0x04
