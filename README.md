# SmartWatch

Reloj inteligente con ESP32, acelerómetro MPU6050 y pantalla redonda GC9A01A (1.28", 240x240, 65K colores).

## Hardware

| Componente | Interface | Pines (ESP32) |
|------------|-----------|----------------|
| GC9A01A TFT (round) | SPI | CS=GPIO5, DC=GPIO19, RST=GPIO4, MOSI=GPIO23, SCK=GPIO18, BL=3.3V |
| MPU6050 | I2C | SDA=GPIO21, SCL=GPIO22 |
| Botón | GPIO | GPIO15 (INPUT_PULLUP) |
| Motor vibración | GPIO | GPIO2 |

## Esquema de conexión

```
ESP32               GC9A01A       MPU6050      Button     Motor
GPIO5   (CS)  ──── CS
GPIO19  (DC)  ──── DC
GPIO4   (RST) ──── RST
GPIO23  (MOSI) ──── SDA (DIN)
GPIO18  (SCK)  ──── SCL (CLK)
GPIO21  (SDA) ────────────────── SDA
GPIO22  (SCL) ────────────────── SCL
GPIO15  ──────────────────────────────────────── PIN
GPIO2   ────────────────────────────────────────────────── VIB (+)
3.3V    ──────── BL ──────────── VCC
3.3V    ──────── VCC
GND     ──────── GND ────────── GND ──────────── GND ──── GND (-)
```

## Dependencias

- [Adafruit GC9A01A](https://github.com/adafruit/Adafruit_GC9A01A) — driver específico para la pantalla GC9A01A
- [Adafruit GFX](https://github.com/adafruit/Adafruit-GFX-Library) — librería gráfica (incluida automáticamente)

Se instalan automáticamente al compilar con PlatformIO.

Los pines de la pantalla se definen en `include/config.h` y se pasan directamente al constructor de la clase `Display`.

## Compilar y subir

```bash
pio run -t upload
pio device monitor   # Puerto serie a 115200 baud
```

## Pantallas del reloj

| Pantalla     | Descripción |
|--------------|-------------|
| HOME         | Hora grande, temperatura y pasos |
| MENU         | Navegación: Home, IMU, Steps, Time, Notif. |
| IMU          | Datos del acelerómetro en tiempo real |
| STEPS        | Contador de pasos |
| TIME         | Hora digital grande |
| NOTIFICATION | Notificaciones recibidas vía BLE |
| OFF          | Pantalla apagada (ahorro de energía) |

- **Auto-apagado:** 7 segundos de inactividad.
- **Despertar:** Movimiento brusco (aceleración Z > 0.95g) o pulsar el botón.
- **Notificaciones:** Círculo rojo indica notificaciones no leídas.

## Botón

| Acción | Duración | Función |
|--------|----------|---------|
| Pulsación corta | < 400ms | Home → Menú → siguiente ítem / avanzar notificación |
| Pulsación larga | ≥ 400ms | Seleccionar ítem del menú / Home ↔ Off / volver |

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

### Enviar hora manualmente (LightBlue)

Conectar vía BLE, buscar CHAR_COMMAND_UUID (`...b26ab`) y escribir en hexadecimal:

```
01 HH MM SS
```

Ejemplos:

| Hora       | Bytes (hex)   |
|------------|---------------|
| 14:30:00   | `01 0E 1E 00` |
| 09:15:00   | `01 09 0F 00` |
| 12:00:00   | `01 0C 00 00` |
| 18:45:30   | `01 12 2D 1E` |

---

Made by PabloTutorMoegle
