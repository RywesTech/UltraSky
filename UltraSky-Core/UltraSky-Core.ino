#include <Wire.h>
#include <SPI.h>
#include "SparkFunCCS811.h"
#include "Adafruit_BLE_UART.h"
#include <Adafruit_BMP085.h>
//#include <SoftwareSerial.h>

#define CCS811_ADDR 0x5B //Default I2C Address

// BLE:
// Connect CLK/MISO/MOSI to hardware SPI
// e.g. On UNO & compatible: CLK = 13, MISO = 12, MOSI = 11
#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9
Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

float CO2Level, TVOCLevel; //CO2 in ppm and TVOC in ppb
float ambientTemp = 0;
float pressure = 0;
float alt = 0;
float pm25; //2.5um particles detected in ug/m3
float pm10; //10um particles detected in ug/m3

long previousMillis = 0;   // for i2c updates

CCS811 CO2Sensor(CCS811_ADDR);
Adafruit_BMP085 bmp;
//SoftwareSerial particleSensor(3, 4); // RX, TX

void setup() {
  pinMode(5, OUTPUT); // Red
  pinMode(6, OUTPUT); // Blue
  modeBoot();

  BTLEserial.setDeviceName("UltSky"); /* 7 characters max! */

  BTLEserial.begin();

  Serial.begin(9600);
  Wire.begin();

  CCS811Core::status returnCode = CO2Sensor.begin();
  if (returnCode != CCS811Core::SENSOR_SUCCESS) {
    Serial.println(F("ERROR 001"));
    modeError();
    while (true); //Hang if there was a problem.
  }
  Serial.println(F("SUCCESS: Sensors connected"));

  if (!bmp.begin()) {
    Serial.println(F("ERROR: 002"));
    modeError();
    //while (true);
  }
}

aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;

void loop() {
  modeGood(); // It will be good unless othereise said

  // Tell the nRF8001 to do whatever it should be working on.
  BTLEserial.pollACI();

  // Ask what is our current status
  aci_evt_opcode_t status = BTLEserial.getState();
  // If the status changed....
  if (status != laststatus) {
    // print it out!
    if (status == ACI_EVT_DEVICE_STARTED) {
      Serial.println(F("* Advertising started"));
      modeError();
    }
    if (status == ACI_EVT_CONNECTED) {
      Serial.println(F("* Connected!"));
    }
    if (status == ACI_EVT_DISCONNECTED) {
      Serial.println(F("* Disconnected or advertising timed out"));
      modeError();
    }
    // OK set the last status change to this one
    laststatus = status;
  }

  if (status == ACI_EVT_CONNECTED) {
    // Lets see if there's any data for us!
    /*
    if (BTLEserial.available()) {
      Serial.print("* "); Serial.print(BTLEserial.available()); Serial.println(F(" bytes available from BTLE"));
    }
    // OK while we still have something to read, get a character and print it out
    while (BTLEserial.available()) {
      char c = BTLEserial.read();
      Serial.print(c);
    }*/

    // Next up, see if we have any data to get from the Serial console

    if (Serial.available()) {
      Serial.setTimeout(100); // 100 millisecond timeout

      sendString(Serial.readString());
    }
  }

  // Update levels every time we get new data:
  if (CO2Sensor.dataAvailable()) {

    CO2Sensor.readAlgorithmResults();

    CO2Level = CO2Sensor.getCO2();
    TVOCLevel = CO2Sensor.getTVOC();

    ambientTemp = bmp.readTemperature();
    pressure = bmp.readPressure();
    alt = bmp.readAltitude();

    Serial.println(F("Got new data"));
  }

  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis > 1000) {
    previousMillis = currentMillis;

    String s = "CO2:" + String(CO2Level) + ",";
    sendString(s);

    s = "TVOC:" + String(TVOCLevel) + ",";
    sendString(s);

    s = "mil:" + String(millis()) + ",";
    sendString(s);

    s = "temp:" + String(ambientTemp) + ",";
    sendString(s);

    s = "alt:" + String(pressure) + ",";
    sendString(s);

    s = "pm25:" + String(pm25) + ","; // pm2.5
    sendString(s);

    s = "pm10:" + String(pm10) + ","; //pm 10
    sendString(s);

    s = "alt:" + String(alt) + ";";
    sendString(s);
  }
}

void sendString(String stringToSend) {
  aci_evt_opcode_t status = BTLEserial.getState();

  if (status == ACI_EVT_CONNECTED) {
    Serial.println(stringToSend);
    int length20 = stringToSend.length() / 20;

    for (int i = 0; i <= length20; i++) {
      //Serial.println("Ittera.: " + String(i) + ":");

      // We need to convert the line to bytes, no more than 20 at this time
      String s = stringToSend.substring(i * 19, (i * 19) + 20);
      uint8_t sendbuffer[20];
      s.getBytes(sendbuffer, 20);
      char sendbuffersize = min(20, s.length());

      //Serial.print(F("\n* Sending -> \""));
      //Serial.print((char *)sendbuffer);
      //Serial.println("\"");

      // write the data
      BTLEserial.write(sendbuffer, sendbuffersize);
    }
  } else {
    Serial.println(F("DEVICE NOT CONNECTED. COULD NOT SEND."));
  }

}

void modeBoot() {
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(200);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(200);
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(200);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(200);
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(200);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(200);
  analogWrite(5, 0);
  analogWrite(6, 255);
}

void modeError() {
  analogWrite(6, 0);
  analogWrite(5, 255);
}

void modeGood() {
  analogWrite(6, 255);
  analogWrite(5, 0);
}

/*
//Scans for incoming packet
//Times out after 1500 miliseconds
boolean dataAvailable(void){
  //Spin until we hear meassage header byte
  long startTime = millis();

  while (1)
  {
    while (!particleSensor.available())
    {
      delay(1);
      if (millis() - startTime > 1500) return (false); //Timeout error
    }

    if (particleSensor.read() == 0xAA) break; //We have the message header
  }

  //Read the next 9 bytes
  byte sensorValue[10];
  for (byte spot = 1 ; spot < 10 ; spot++)
  {
    startTime = millis();
    while (!particleSensor.available())
    {
      delay(1);
      if (millis() - startTime > 1500) return (false); //Timeout error
    }

    sensorValue[spot] = particleSensor.read();
  }

  //Check CRC
  byte crc = 0;
  for (byte x = 2 ; x < 8 ; x++) //DATA1+DATA2+...+DATA6
    crc += sensorValue[x];
  if (crc != sensorValue[8])
    return (false); //CRC error

  //Update the global variables
  pm25 = ((float)sensorValue[3] * 256 + sensorValue[2]) / 10;
  pm10 = ((float)sensorValue[5] * 256 + sensorValue[4]) / 10;

  return (true); //We've got a good reading!
}
*/
