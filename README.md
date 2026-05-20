# SmartWatch

Reloj inteligente con ESP32, acelerómetro MPU6050 y display OLED SSD1306.

## Hardware

| Componente | Pin I2C (ESP32) |
|-----------|-----------------|
| SSD1306 OLED | SDA=GPIO21, SCL=GPIO22 |
| MPU6050     | SDA=GPIO21, SCL=GPIO22 |

Ambos dispositivos comparten el bus I2C. Alimentación: 3.3V y GND.

## Dependencias

- [Adafruit SSD1306](https://github.com/adafruit/Adafruit_SSD1306)
- [Adafruit MPU6050](https://github.com/adafruit/Adafruit_MPU6050)

Se instalan automáticamente al compilar con PlatformIO.

## Compilar y subir

```bash
pio run -t upload
pio device monitor
```

## Esquema de conexión

```
ESP32           SSD1306    MPU6050  Button
GPIO21 (SDA) ── SDA ────── SDA
GPIO22 (SCL) ── SCL ────── SCL
GPIO23 ────────────────────────────── PIN
3.3V ────────── VCC ────── VCC
GND ─────────── GND ────── GND ────── GND
```
