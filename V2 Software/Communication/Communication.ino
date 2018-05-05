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

float GPSX, GPSY, alt;
long previous1HzMillis = 0;
long interval1Hz = 1000;

String deviceType = "com"; // communication device

// CAN Stuff:
uint32_t currTime, attiTime, otherTime, clockTime;
char dateTime[20];
uint32_t messageId;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  // Begin I2C:
  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  // Begin Bluetooth:
  BTLEserial.setDeviceName("UltSky");
  BTLEserial.begin();

  // Begin CAN:
  NazaCanDecoder.begin();

  Serial.println("Starting loop...");
}

aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;

void loop() {

  //Bluetooth code:
  // Tell the nRF8001 to do whatever it should be working on.
  BTLEserial.pollACI();
  // Ask what is our current status
  aci_evt_opcode_t status = BTLEserial.getState();
  // If the status changed...
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
      // OK while we still have something to read, get a character and print it out
    String input = "";
    while (BTLEserial.available()) {
      Serial.print("New Data: ");
      char c = BTLEserial.read();
      Serial.println(c);
      input += c;
    }
    Serial.print("Full data: ");
    Serial.println(input);
    String key = getVal(input, ':', 0);
    String value = getVal(input, ':', 1);
    Serial.println("Key: " + key + ", value: " + value);

    Serial.println();

    if (key == "datalog"){
      if (value == "start") {
        sendMaster(deviceType, "datalog", "start");
      } else if (value == "stop"){
        sendMaster(deviceType, "datalog", "stop");
      }
    } else if (key == "data"){
      
    } else {
      Serial.println("Unknown key");
    }
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

  // CAN code:
  messageId = NazaCanDecoder.decode();
  //  if(messageId) { Serial.print("Message "); Serial.print(messageId, HEX); Serial.println(" decoded"); }

  currTime = millis();
  /*
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
  }*/

  NazaCanDecoder.heartbeat();


  //1Hz message sending:

  unsigned long currentMillis = millis();

  if (currentMillis - previous1HzMillis > interval1Hz) {
    previous1HzMillis = currentMillis;

    sendMaster(deviceType, "GPSX", String(GPSX));
    sendMaster(deviceType, "GPSY", String(GPSY));
    sendMaster(deviceType, "ALT", String(alt));

  }

}

// Received I2C data:
void receiveEvent(int howMany) {
  Serial.println("Received Data over I2C:");
  while (Wire.available() > 0) {
  }
  Serial.println();
}


// Device Type: com (communication)
// Key: key
// Value: value of key
void sendMaster(String deviceType, String key, String value) {
  digitalWrite(LED, HIGH);
  delay(100);
  digitalWrite(LED, LOW);

  String data = deviceType + "-" + key + ":" + value;
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

// https://stackoverflow.com/questions/9072320/split-string-into-string-array
String getVal(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length()-1;

  for(int i=0; i<=maxIndex && found<=index; i++){
    if(data.charAt(i)==separator || i==maxIndex){
        found++;
        strIndex[0] = strIndex[1]+1;
        strIndex[1] = (i == maxIndex) ? i+1 : i;
    }
  }

  return found>index ? data.substring(strIndex[0], strIndex[1]) : "";
}

