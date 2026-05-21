#include "ble_smartwatch.h"
#include "config.h"

void SmartWatchBLE::ServerHandler::onConnect(BLEServer* s) {
    parent->deviceConnected = true;
    Serial.println("[BLE] Cliente conectado");
}

void SmartWatchBLE::ServerHandler::onDisconnect(BLEServer* s) {
    parent->deviceConnected = false;
    Serial.println("[BLE] Cliente desconectado");
    BLEDevice::startAdvertising();
}

void SmartWatchBLE::CommandHandler::onWrite(BLECharacteristic* c) {
    std::string value = c->getValue();
    if (value.length() > 0 && parent->cmdCallback) {
        parent->cmdCallback((uint8_t)value[0], (uint8_t*)value.data(), value.length());
    }
}

void SmartWatchBLE::TimeHandler::onWrite(BLECharacteristic* c) {
    std::string value = c->getValue();
    if (value.length() >= 3 && parent->timeCallback) {
        parent->timeCallback((uint8_t)value[0], (uint8_t)value[1], (uint8_t)value[2]);
    }
}

void SmartWatchBLE::begin() {
    BLEDevice::init(BLE_DEVICE_NAME);

    server = BLEDevice::createServer();
    ServerHandler* sh = new ServerHandler();
    sh->parent = this;
    server->setCallbacks(sh);

    service = server->createService(SERVICE_UUID);

    charIMU = service->createCharacteristic(
        CHAR_IMU_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    charIMU->addDescriptor(new BLE2902());

    charTemp = service->createCharacteristic(
        CHAR_TEMP_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    charTemp->addDescriptor(new BLE2902());

    charButton = service->createCharacteristic(
        CHAR_BUTTON_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    charButton->addDescriptor(new BLE2902());

    charCommand = service->createCharacteristic(
        CHAR_COMMAND_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
    );
    CommandHandler* ch = new CommandHandler();
    ch->parent = this;
    charCommand->setCallbacks(ch);

    charTime = service->createCharacteristic(
        CHAR_TIME_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR | BLECharacteristic::PROPERTY_NOTIFY
    );
    charTime->addDescriptor(new BLE2902());
    TimeHandler* th = new TimeHandler();
    th->parent = this;
    charTime->setCallbacks(th);

    service->start();

    BLEAdvertising* adv = BLEDevice::getAdvertising();
    adv->addServiceUUID(SERVICE_UUID);
    adv->setScanResponse(true);
    adv->setMinPreferred(0x06);
    adv->setMaxPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.printf("[BLE] Servicio iniciado: %s\n", BLE_DEVICE_NAME);
}

void SmartWatchBLE::sendIMU(int16_t ax, int16_t ay, int16_t az,
                            int16_t gx, int16_t gy, int16_t gz) {
    if (!deviceConnected) return;
    char buf[48];
    snprintf(buf, sizeof(buf), "%d,%d,%d,%d,%d,%d", ax, ay, az, gx, gy, gz);
    charIMU->setValue(buf);
    charIMU->notify();
}

void SmartWatchBLE::sendTemp(float celsius) {
    if (!deviceConnected) return;
    char buf[8];
    snprintf(buf, sizeof(buf), "%.2f", celsius);
    charTemp->setValue(buf);
    charTemp->notify();
}

void SmartWatchBLE::sendButton(const char* state) {
    if (!deviceConnected) return;
    charButton->setValue(state);
    charButton->notify();
}

bool SmartWatchBLE::connected() {
    return deviceConnected;
}

void SmartWatchBLE::onCommand(std::function<void(uint8_t, uint8_t*, size_t)> cb) {
    cmdCallback = cb;
}

void SmartWatchBLE::onTimeReceived(std::function<void(uint8_t, uint8_t, uint8_t)> cb) {
    timeCallback = cb;
}

void SmartWatchBLE::setTimeValue(uint8_t h, uint8_t m, uint8_t s) {
    if (!charTime) return;
    uint8_t buf[3] = { h, m, s };
    charTime->setValue(buf, 3);
    charTime->notify();
}
