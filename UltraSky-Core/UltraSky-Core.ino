#include <Wire.h>
#include <SPI.h>
//#include <SD.h>
#include <WiFi.h>
#include "SparkFunCCS811.h"

#define CCS811_ADDR 0x5B //Default I2C Address

char ssid[] = "Ryan's iPhone";      // your network SSID (name)
char pass[] = "sailboat70";   // your network password

int status = WL_IDLE_STATUS;
int CO2Level, TVOCLevel; //CO2 in ppm (?) and TVOC in ____ (?)
float pm25; //2.5um particles detected in ug/m3
float pm10; //10um particles detected in ug/m3
const int SD_CS = 4;
long previousMillis = 0; // for i2c updates
long interval = 1000; // i2c request interval

WiFiServer server(9440);
CCS811 CO2Sensor(CCS811_ADDR);

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
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
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
    //Serial.println("new client");
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
          client.println("\"millis\":" + String(millis()) + ",");
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
    // give the web browser time to receive the data
    delay(1);

    // close the connection:
    client.stop();
    //Serial.println("client disonnected");
  }

  // Update levels every time we get new data:
  if (CO2Sensor.dataAvailable()) {
    
    CO2Sensor.readAlgorithmResults();

    CO2Level = CO2Sensor.getCO2();
    TVOCLevel = CO2Sensor.getTVOC();
    /*
    Serial.print("CO2[");
    Serial.print(CO2Level);
    Serial.print("] tVOC[");
    Serial.print(TVOCLevel);
    Serial.print("] millis[");
    Serial.print(millis());
    Serial.print("]");
    Serial.println();*/
    Serial.println("got data");
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


void printWifiStatus() {
  /*
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");

  Serial.println("SUCCESS: WiFi network connected");
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

