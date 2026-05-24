#pragma once
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <functional>

class SmartWatchBLE {
public:
    void begin();
    void sendAll(int16_t ax, int16_t ay, int16_t az, int16_t gx, int16_t gy, int16_t gz, float celsius, uint32_t steps, uint8_t h, uint8_t m, uint8_t s);
    void sendButton(const char* state);
    bool connected();
    void onCommand(std::function<void(uint8_t, uint8_t*, size_t)> cb);
    void onTimeReceived(std::function<void(uint8_t, uint8_t, uint8_t)> cb);
    void setTimeValue(uint8_t h, uint8_t m, uint8_t s);

private:
    BLEServer* server = nullptr;
    BLEService* service = nullptr;
    BLECharacteristic* charIMU = nullptr;
    BLECharacteristic* charTemp = nullptr;
    BLECharacteristic* charButton = nullptr;
    BLECharacteristic* charCommand = nullptr;
    BLECharacteristic* charTime = nullptr;
    BLECharacteristic* charSteps = nullptr;
    bool deviceConnected = false;
    std::function<void(uint8_t, uint8_t*, size_t)> cmdCallback;
    std::function<void(uint8_t, uint8_t, uint8_t)> timeCallback;

    class ServerHandler : public BLEServerCallbacks {
    public:
        SmartWatchBLE* parent;
        void onConnect(BLEServer* s) override;
        void onDisconnect(BLEServer* s) override;
    };

    class CommandHandler : public BLECharacteristicCallbacks {
    public:
        SmartWatchBLE* parent;
        void onWrite(BLECharacteristic* c) override;
    };

    class TimeHandler : public BLECharacteristicCallbacks {
    public:
        SmartWatchBLE* parent;
        void onWrite(BLECharacteristic* c) override;
    };
};
