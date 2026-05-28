#pragma once

// GC9A01A round TFT (SPI)
#define SCREEN_WIDTH  240
#define SCREEN_HEIGHT 240

#define TFT_CS    5
#define TFT_DC    19
#define TFT_RST   4
#define TFT_MOSI  23
#define TFT_SCLK  18
// BL conectado directamente a 3.3V

// I2C (MPU6050)
#define I2C_SDA 21
#define I2C_SCL 22

#define MPU_ADDR 0x68

#define BUTTON_PIN 15

#define BLE_DEVICE_NAME "SmartWatch-Pro"

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_IMU_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_TEMP_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define CHAR_BUTTON_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26aa"
#define CHAR_COMMAND_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26ab"
#define CHAR_TIME_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26ac"
#define CHAR_STEPS_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26ad"

#define CMD_SHOW_TIME   0x01
#define CMD_SHOW_IMU    0x02
#define CMD_SCREEN_OFF  0x03
#define CMD_VIBRATE     0x04
#define CMD_SHOW_STEPS  0x05
#define CMD_RESET_STEPS        0x06
#define CMD_SEND_NOTIFICATION  0x0B
#define CMD_CLEAR_NOTIFICATIONS 0x0C

#define VIBRATE_PIN 2
#define VIBRATE_MS 200

#define BTN_HOLD_MS 1000
//#define BTN2_PIN 4

#define NOTIF_QUEUE_MAX 5
#define NOTIF_TITLE_MAX 20
#define NOTIF_MSG_MAX   50
