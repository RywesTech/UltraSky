#include <Wire.h>
#include <SD.h>
#include <SPI.h>

#define LED_R 22
#define LED_G 21
#define LED_B 20
#define BUTTON 10

#define THIS_ADDRESS 0x8
#define OTHER_ADDRESS 0x9

boolean datalogging = false;

float alt = 0;
float GPSX, GPSY;

float CO, CO2, TVOC;

int pointID; // ID of the datapoint

long previous1HzMillis = 0;
long interval1Hz = 1000;

const int SD_CS = 10;

void setup() {
  delay(1000); // slow down for serial monitor
  Serial.begin(9600);
  Serial.println("starting up!");

  initLED();
  modeError(); // Error unless otherwise stated

  pinMode(BUTTON, INPUT);
  digitalWrite(BUTTON, HIGH);

  Wire.begin(THIS_ADDRESS);
  Wire.setSDA(18);
  Wire.setSCL(19);

  Wire.onReceive(receiveEvent);

  if (!SD.begin(SD_CS)) {
    Serial.println(F("ERROR: Card failed, or not present"));
    while (1);
  }
  Serial.println(F("SUCCESS: SD card initialized."));

  String dataString = "\n\n\n -- SYSTEM INITIATED, NEW DATALOG -- ";
  File dataFile = SD.open("datalog.txt", FILE_WRITE);

  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
  } else {
    Serial.println(F("ERROR: opening datalog.txt"));
    //while(1);
  }
  Serial.print(F("File ready to datalog to!"));

  modeGood();
  Serial.println("starting loop!");
}

void loop() {

  unsigned long currentMillis = millis();

  if (currentMillis - previous1HzMillis > interval1Hz) {
    previous1HzMillis = currentMillis;
    if (datalogging) {
      modeDatalogging();

      String dataString = String(millis()) + "," + String(GPSX) + "," + String(GPSY) + "," + String(alt) + "," + String(CO) + "," + String(CO2) + "," + String(TVOC);

      File dataFile = SD.open("datalog.txt", FILE_WRITE);

      if (dataFile) {
        dataFile.println(dataString);
        dataFile.close();
      } else {
        Serial.println(F("ERROR: opening datalog.txt"));
      }
    } else {
      modeGood();
    }
  }
}

void receiveEvent(int howMany) {
  String input = "";
  while (Wire.available() > 0) {
    char c = Wire.read();
    input += c;
  }
  Serial.print("Received: ");
  Serial.println(input);

  String key = getVal(input, ':', 0);
  String value = getVal(input, ':', 1);

  Serial.println("Key: " + key + ", value: " + value);

  Serial.println();

  if (key == "com-datalog") {
    if (value == "start") {
      datalogging = true;
      Serial.println("Starting datalog");
    } else if (value == "stop") {
      datalogging = false;
      Serial.println("Stoping datalog.");
    } else {
      Serial.println("Unknown key");
    }

  } else if (key == "com-GPSX") {
    GPSX = value.toFloat();
    
  } else if (key == "com-GPSY") {
    GPSY = value.toFloat();

  } else if (key == "com-ALT") {
    alt = value.toFloat();

  } else if (key == "sen-CO") {
    CO = value.toFloat();
    Serial.println("raw val: " + value);
    Serial.println("CO val: " + String(CO));

  } else if (key == "sen-CO2") {
    CO2 = value.toFloat();

  } else if (key == "sen-TVOC") {
    TVOC = value.toFloat();

  } else {
    Serial.println("Unknown key");
  }

}

// https://stackoverflow.com/questions/9072320/split-string-into-string-array
String getVal(String data, char separator, int index) {
  int found = 0;
  int strIndex[] = {0, -1};
  int maxIndex = data.length() - 1;

  for (int i = 0; i <= maxIndex && found <= index; i++) {
    if (data.charAt(i) == separator || i == maxIndex) {
      found++;
      strIndex[0] = strIndex[1] + 1;
      strIndex[1] = (i == maxIndex) ? i + 1 : i;
    }
  }

  return found > index ? data.substring(strIndex[0], strIndex[1]) : "";
}

void initLED() {
  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);

  analogWrite(LED_R, 0);
  analogWrite(LED_G, 0);
  analogWrite(LED_B, 0);
}

void modeGood() {
  analogWrite(LED_R, 0);
  analogWrite(LED_G, 0);
  analogWrite(LED_B, 255 / 2);
}

void modeError() {
  analogWrite(LED_R, 255 / 2);
  analogWrite(LED_G, 0);
  analogWrite(LED_B, 0);
}

void modeDatalogging() {
  analogWrite(LED_R, 0);
  analogWrite(LED_G, 255 / 2);
  analogWrite(LED_B, 0);
}

