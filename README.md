# SmartWatch

Reloj inteligente con ESP32, acelerómetro MPU6050 y display OLED SSD1306.

## Hardware

| Componente | Pin I2C (ESP32) |
|-----------|-----------------|
| SSD1306 OLED | SDA=GPIO21, SCL=GPIO22 |
| MPU6050     | SDA=GPIO21, SCL=GPIO22 |

Ambos dispositivos comparten el bus I2C. Alimentación: 3.3V y GND.

## Esquema de conexión

```
ESP32           SSD1306    MPU6050  Button
GPIO21 (SDA) ── SDA ────── SDA
GPIO22 (SCL) ── SCL ────── SCL
GPIO23 ────────────────────────────── PIN
3.3V ────────── VCC ────── VCC
GND ─────────── GND ────── GND ────── GND
```

## Dependencias

- [Adafruit SSD1306](https://github.com/adafruit/Adafruit_SSD1306)
- [Adafruit MPU6050](https://github.com/adafruit/Adafruit_MPU6050)

Se instalan automáticamente al compilar con PlatformIO.


## Compilar y subir

```bash
pio run -t upload
pio device monitor  #ver monitor serial para ver log y prints
```

## Para setear la hora 
(Por el momento)
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
------
## App companion (Android / iOS)

Aplicación Flutter para controlar el reloj desde el teléfono vía BLE.

### Stack

- **Framework:** Flutter 3.38 (Dart)
- **BLE:** `flutter_blue_plus` — escaneo, conexión, suscripción a notificaciones
- **Estado:** `provider` (ChangeNotifier)
- **Estructura:** `app/` en la raíz del monorepo

### Arrancar

```bash
cd app
flutter pub get
flutter run
```

Requiere un dispositivo físico (Android o iOS) con BLE. No funciona en emulador.

### Funcionalidades

| Pantalla       | Descripción |
|----------------|-------------|
| Scanner        | Busca dispositivos `SmartWatch-Pro` y conecta |
| Dashboard      | Hora del reloj, temperatura, IMU en vivo, pasos |
| Comandos       | Botones para cambiar pantallas, sync hora, reset pasos |

### BLE Protocol

Mismo servicio/characteristics que el firmware:

| Characteristic | UUID | Propiedad | Formato |
|---------------|------|-----------|---------|
| IMU (ax,ay,az,gx,gy,gz) | `...b26a8` | Notify | CSV `"ax,ay,az,gx,gy,gz"` |
| Temperatura | `...b26a9` | Notify | String `"25.3"` |
| Botón | `...b26aa` | Notify | String |
| Comando | `...b26ab` | Write | `[cmd, data...]` |
| Hora | `...b26ac` | Write/Notify | `[h, m, s]` |

Comandos disponibles: `0x01` (Show Time), `0x02` (Show IMU), `0x03` (Screen Off), `0x04` (Vibrate), `0x05` (Show Steps), `0x06` (Reset Steps).

------

Made by PabloTutorMoegle 