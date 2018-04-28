#include <Wire.h>
#include <SPI.h>
#include "Adafruit_BLE_UART.h"

#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9

Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

#define LED 13

#define THIS_ADDRESS 0x11
#define MASTER_ADDRESS 0x8

boolean last_state = HIGH;

float GPSX, GPSY;
long previous1HzMillis = 0;
long interval1Hz = 1000;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  BTLEserial.setDeviceName("UltSky");
  BTLEserial.begin();

  Serial.println("Starting loop...");
}

aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;

void loop() {

  // Tell the nRF8001 to do whatever it should be working on.
  BTLEserial.pollACI();

  // Ask what is our current status
  aci_evt_opcode_t status = BTLEserial.getState();
  // If the status changed....
  if (status != laststatus) {
    // print it out!
    if (status == ACI_EVT_DEVICE_STARTED) {
      Serial.println(F("* Advertising started"));
    }
    if (status == ACI_EVT_CONNECTED) {
      Serial.println(F("* Connected!"));
    }
    if (status == ACI_EVT_DISCONNECTED) {
      Serial.println(F("* Disconnected or advertising timed out"));
    }
    // OK set the last status change to this one
    laststatus = status;
  }

  if (status == ACI_EVT_CONNECTED) {
    // Lets see if there's any data for us!
    if (BTLEserial.available()) {
      Serial.print("* "); Serial.print(BTLEserial.available()); Serial.println(F(" bytes available from BTLE"));
    }
    // OK while we still have something to read, get a character and print it out
    while (BTLEserial.available()) {
      char c = BTLEserial.read();
      Serial.print(c);
    }

    // Next up, see if we have any data to get from the Serial console

    if (Serial.available()) {
      // Read a line from Serial
      Serial.setTimeout(100); // 100 millisecond timeout
      String s = Serial.readString();

      // We need to convert the line to bytes, no more than 20 at this time
      uint8_t sendbuffer[20];
      s.getBytes(sendbuffer, 20);
      char sendbuffersize = min(20, s.length());

      Serial.print(F("\n* Sending -> \"")); Serial.print((char *)sendbuffer); Serial.println("\"");

      // write the data
      BTLEserial.write(sendbuffer, sendbuffersize);
    }
  }

  unsigned long currentMillis = millis();

  if (currentMillis - previous1HzMillis > interval1Hz) {
    // save the last time you blinked the LED
    previous1HzMillis = currentMillis;

    sendMaster("GPSX", String(GPSX));
    sendMaster("GPSY", String(GPSY));

  }

}

void receiveEvent(int howMany) {
  Serial.println("Received Data");
  while (Wire.available() > 0) {
    //boolean b = Wire.read();
    //Serial.print(b, DEC);
    //digitalWrite(LED, !b);
  }
  Serial.println();
}

void sendHeartbeatData() {

  digitalWrite(LED, HIGH);
  delay(100);
  digitalWrite(LED, LOW);
  Wire.beginTransmission(MASTER_ADDRESS);
  Wire.write("COM_HEARTBEAT:1");
  Wire.endTransmission();

  Serial.println("Sent Data");

}

void sendMaster(String key, String value) {
  digitalWrite(LED, HIGH);
  delay(100);
  digitalWrite(LED, LOW);

  String data = key + ":" + value;
  int dataLength = data.length() + 1;

  Serial.println("Data to send: " + data);

  char dataBuff[dataLength];
  data.toCharArray(dataBuff, dataLength);
  
  Wire.beginTransmission(MASTER_ADDRESS);
  Wire.write(dataBuff);
  Wire.endTransmission();

  Serial.println("Sent Data");
}

