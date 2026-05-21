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

## Para setear la hora 

Una vez conectado el bluetooth con el telefono medieante una de las apps (yo uso LightBlue) ir a buscar la CHAR_COMMAND_UUID el codigo numerico que termina en ea07361b26ab y teniendo en cuente el tipo de escritura que use poner la hora. En mi caso uso hexadecimal asi que para poner la hora debo poner:
```
01 = comando CMD_SHOW_TIME (fijo)
HH = hora en hex (0x00 a 0x17)
MM = minuto en hex (0x00 a 0x3B)
SS = segundo en hex (0x00 a 0x3B)
```
Ejemplo:
```
Hora	    Bytes a escribir (hex)
14:30:00      01 0E 1E 00
09:15:00      01 09 0F 00
12:00:00      01 0C 00 00
18:45:30      01 12 2D 1E
```



* Made by PabloTutorMoegle 