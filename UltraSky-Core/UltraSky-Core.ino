#include <Wire.h>
#include <SPI.h>
//#include <SD.h>
#include <WiFi.h>
#include "SparkFunCCS811.h"
#include <Adafruit_BMP085.h>

#define CCS811_ADDR 0x5B //Default I2C Address

char ssid[] = "Ryan's iPhone"; // network SSID
char pass[] = "sailboat70";    // network password

int status = WL_IDLE_STATUS;

float CO2Level, TVOCLevel; //CO2 in ppm and TVOC in ppb
float pm25;                //2.5um particles detected in ug/m3
float pm10;                //10um particles detected in ug/m3
float ambientTemp = 0;
float pressure = 0;
float alt = 0;

const int SD_CS = 4;
long previousMillis = 0;   // for i2c updates
long interval = 1000;      // i2c request interval

WiFiServer server(9440);
CCS811 CO2Sensor(CCS811_ADDR);
Adafruit_BMP085 bmp;

void setup() {
  pinMode(5, OUTPUT); // Red
  pinMode(6, OUTPUT); // Blue
  modeBoot();
  
  Serial.begin(9600);
  Wire.begin();

  CCS811Core::status returnCode = CO2Sensor.begin();
  if (returnCode != CCS811Core::SENSOR_SUCCESS) {
    Serial.println("ERROR 001");
    modeError();
    while (true); //Hang if there was a problem.
  }
  Serial.println(F("SUCCESS: Sensors connected"));
  /*
  // see if the card is present and can be initialized:
  if (!SD.begin(SD_CS)) {
    //modeError();
    Serial.println("ERROR: 002");
    // don't do anything more:
    //return;
  }
  Serial.println(F("SUCCESS: SD card connected"));

  File dataFile = SD.open("UltraSky_Datalog.txt", FILE_WRITE);
  if (dataFile) {
    dataFile.println("TESTING");
    dataFile.close();
    Serial.println(F("SUCCESS: Wrote to SD Card"));
  } else {
    Serial.println("ERROR: 003");
    //modeError();
  }*/

  if (!bmp.begin()) {
    Serial.println("ERROR: 002");
    modeError();
    while(true);
  }

  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("ERROR: 004");
    modeError();
    // don't continue:
    while (true);
  }
  Serial.println(F("SUCCESS: WiFi shield connected"));

  String fv = WiFi.firmwareVersion();
  if ( fv != "1.1.0" )
    Serial.println("ERROR: upgrade firmware");
    modeError();

  // attempt to connect to Wifi network:
  while ( status != WL_CONNECTED) {
    Serial.print(F("Connecting to SSID: "));
    Serial.println(ssid);
    status = WiFi.begin(ssid, pass);

    // wait 5 seconds for connection:
    delay(5000);
  }
  server.begin();
  
  // you're connected now, so print out the status:
  printWifiStatus();
}


void loop() {
  // listen for incoming clients
  WiFiClient client = server.available();
  
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {

          client.println("{");
          client.println("\"status\":\"good\",");
          client.println("\"CO2Level\":" + String(CO2Level) + ",");
          client.println("\"TVOCLevel\":" + String(TVOCLevel) + ",");
          client.println("\"temp\":" + String(ambientTemp) + ",");
          client.println("\"pressure\":" + String(pressure) + ",");
          client.println("\"altitude\":" + String(alt) + ",");
          client.println("\"freeRam\":" + String(freeRam()) + ",");
          client.println("\"millis\":" + String(millis()));
          client.println("}");
          
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        }
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the client time to receive the data
    delay(1);

    // close the connection:
    client.stop();
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
 /*
  if(currentMillis - previousMillis > interval) {
    previousMillis = currentMillis; 
    Serial.println(F("Requesting data..."));
    Wire.requestFrom(2, 60);    // request 6 bytes from slave device #8

    while (Wire.available()) {  // slave may send less than requested
      char c = Wire.read(); // receive a byte as character
      Serial.print(c);         // print the character
    }
    Serial.println();
  }*/
  
  modeGood();
}

int freeRam () {
  extern int __heap_start, *__brkval; 
  int v; 
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}


void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print(F("SSID: "));
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print(F("IP Address: "));
  Serial.println(ip);

  // print the received signal strength:
  /*
  long rssi = WiFi.RSSI();
  Serial.print(F("signal strength (RSSI):"));
  Serial.print(rssi);
  Serial.println(F(" dBm"));
  */
}

void modeBoot() {
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(300);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(300);
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(300);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(300);
  analogWrite(5, 0);
  analogWrite(6, 255);
  delay(300);
  analogWrite(5, 255);
  analogWrite(6, 0);
  delay(300);
  analogWrite(5, 0);
  analogWrite(6, 255);
}

void modeError(){
  analogWrite(6, 0);
  analogWrite(5, 255);
}

void modeGood(){
  analogWrite(6, 255);
  analogWrite(5, 0);
}

