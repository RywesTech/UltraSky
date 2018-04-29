#include <Wire.h>
#include <SPI.h>
#include "Adafruit_BLE_UART.h"
#include "NazaCanDecoderLib.h"
#include "FlexCAN.h"

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


// CAN Stuff:
uint32_t currTime, attiTime, otherTime, clockTime;
char dateTime[20];
uint32_t messageId;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  BTLEserial.setDeviceName("UltSky");
  BTLEserial.begin();

  NazaCanDecoder.begin();

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


  messageId = NazaCanDecoder.decode();
//  if(messageId) { Serial.print("Message "); Serial.print(messageId, HEX); Serial.println(" decoded"); }

  currTime = millis();

  // Display attitude at 10Hz rate so every 100 milliseconds
  if(attiTime < currTime)
  {
    attiTime = currTime + 100;
    Serial.print("Pitch: "); Serial.print(NazaCanDecoder.getPitch());
    Serial.print(", Roll: "); Serial.println(NazaCanDecoder.getRoll());
  }

  // Display other data at 5Hz rate so every 200 milliseconds
  if(otherTime < currTime)
  {
    otherTime = currTime + 200;
    Serial.print("Mode: "); 
    switch (NazaCanDecoder.getMode())
    {
      case NazaCanDecoderLib::MANUAL:   Serial.print("MAN"); break;
      case NazaCanDecoderLib::GPS:      Serial.print("GPS"); break;
      case NazaCanDecoderLib::FAILSAFE: Serial.print("FS");  break;
      case NazaCanDecoderLib::ATTI:     Serial.print("ATT"); break;
      default:                          Serial.print("UNK");
    }
    Serial.print(", Bat: "); Serial.println(NazaCanDecoder.getBattery() / 1000.0, 2);

    Serial.print("Lat: "); Serial.print(NazaCanDecoder.getLat(), 7);
    Serial.print(", Lon: "); Serial.print(NazaCanDecoder.getLon(), 7);
    Serial.print(", GPS alt: "); Serial.print(NazaCanDecoder.getGpsAlt());
    Serial.print(", COG: "); Serial.print(NazaCanDecoder.getCog());
    Serial.print(", Speed: "); Serial.print(NazaCanDecoder.getSpeed());
    Serial.print(", VSI: "); Serial.print(NazaCanDecoder.getVsi());
    Serial.print(", Fix: ");
    switch (NazaCanDecoder.getFixType())
    {
      case NazaCanDecoderLib::NO_FIX:   Serial.print("No fix"); break;
      case NazaCanDecoderLib::FIX_2D:   Serial.print("2D");     break;
      case NazaCanDecoderLib::FIX_3D:   Serial.print("3D");     break;
      case NazaCanDecoderLib::FIX_DGPS: Serial.print("DGPS");   break;
      default:                          Serial.print("UNK");
    }
    Serial.print(", Sat: "); Serial.println(NazaCanDecoder.getNumSat());

    Serial.print("Alt: "); Serial.print(NazaCanDecoder.getAlt());
    Serial.print(", Heading: "); Serial.println(NazaCanDecoder.getHeading());
  }

  // Display date/time at 1Hz rate so every 1000 milliseconds
  if(clockTime < currTime)
  {
    clockTime = currTime + 1000;
    sprintf(dateTime, "%4u.%02u.%02u %02u:%02u:%02u", 
            NazaCanDecoder.getYear() + 2000, NazaCanDecoder.getMonth(), NazaCanDecoder.getDay(),
            NazaCanDecoder.getHour(), NazaCanDecoder.getMinute(), NazaCanDecoder.getSecond());
    Serial.print("Date/Time: "); Serial.println(dateTime); 
  }

  NazaCanDecoder.heartbeat();


  // Heartbeat and 1Hz message sending:
  
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

  Serial.println("Begining to send...");
  
  Wire.beginTransmission(MASTER_ADDRESS);
  Wire.write(dataBuff);
  Wire.endTransmission();

  Serial.println("Sent Data");
}

