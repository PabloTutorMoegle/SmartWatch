#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define MPU_ADDR 0x68

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

int16_t ax, ay, az, gx, gy, gz, temp_raw;

void setup() {
    Serial.begin(115200);
    Serial.println("SmartWatch v0.1");

    Wire.begin(21, 22);

    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 no encontrado");
        while (true) delay(10);
    }
    Serial.println("SSD1306 listo");

    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x6B);
    Wire.write(0);
    if (Wire.endTransmission(true) != 0) {
        Serial.println("MPU6050 no responde en 0x68");
        display.clearDisplay();
        display.setCursor(0, 0);
        display.println("MPU6050 NO");
        display.println("DETECTADO");
        display.display();
        while (true) delay(10);
    }
    Serial.println("MPU6050 listo");

    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
}

void leer_mpu() {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_ADDR, 14, true);

    ax = Wire.read() << 8 | Wire.read();
    ay = Wire.read() << 8 | Wire.read();
    az = Wire.read() << 8 | Wire.read();
    temp_raw = Wire.read() << 8 | Wire.read();
    gx = Wire.read() << 8 | Wire.read();
    gy = Wire.read() << 8 | Wire.read();
    gz = Wire.read() << 8 | Wire.read();
}

void printScreen(int16_t ax, int16_t ay, int16_t az, int16_t gx, int16_t gy, int16_t gz, int16_t temp_raw) {
    float ax_g = ax / 16384.0;
    float ay_g = ay / 16384.0;
    float az_g = az / 16384.0;
    float celsius = (temp_raw / 340.0) + 17.5;
    
    display.clearDisplay();

    display.setCursor(16, 0);
    display.println("MPU6050 DATA");
    display.drawFastHLine(0, 10, SCREEN_WIDTH, SSD1306_WHITE);

    char buf[20];
    display.setCursor(0, 16);
    snprintf(buf, sizeof(buf), "X: %+06.2f g", ax_g);
    display.println(buf);

    display.setCursor(0, 26);
    snprintf(buf, sizeof(buf), "Y: %+06.2f g", ay_g);
    display.println(buf);

    display.setCursor(0, 36);
    snprintf(buf, sizeof(buf), "Z: %+06.2f g", az_g);
    display.println(buf);

    display.setCursor(0, 50);
    display.print("Temp: ");
    display.print(celsius, 1);
    display.print(" C");

    display.display();
}

void loop() {
    leer_mpu();

    printScreen(ax, ay, az, gx, gy, gz, temp_raw);

    delay(100);
}
