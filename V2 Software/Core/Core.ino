#include <Wire.h>
#include <SD.h>
#include <SPI.h>

#define LED 13
#define BUTTON 10

#define THIS_ADDRESS 0x8
#define OTHER_ADDRESS 0x9

boolean last_state = HIGH;

float alt = 0;

const int SD_CS = 10;

void setup() {
  delay(1000); // slow down for serial monitor
  Serial.begin(9600);
  Serial.println("starting up!");
  
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  pinMode(BUTTON, INPUT);
  digitalWrite(BUTTON, HIGH);

  Wire.begin(THIS_ADDRESS);
  Wire.setSDA(18);
  Wire.setSCL(19);

  Wire.onReceive(receiveEvent);

  if (!SD.begin(SD_CS)) {
    Serial.println(F("ERROR: Card failed, or not present"));
    while(1);
  }
  Serial.println(F("SUCCESS: SD card initialized."));

  String dataString = "\n\n\n -- SYSTEM INITIATED, NEW DATALOG -- ";
  File dataFile = SD.open("datalog.txt", FILE_WRITE);
  
  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
  } else {
    Serial.println(F("ERROR: opening datalog.txt"));
    while(1);
  }
  Serial.print(F("File ready to datalog to!"));

  Serial.println("starting loop!");
}

void loop() {
  if (digitalRead(BUTTON) != last_state) {
    last_state = digitalRead(BUTTON);
    Wire.beginTransmission(OTHER_ADDRESS);
    Wire.write(last_state);
    Wire.endTransmission();
  }

  //alt = bmp.readAltitude();
  //Serial.println(alt);
  //Serial.println("loop");
  //delay(100);
}

void receiveEvent(int howMany) {
  String input = "";
  while (Wire.available() > 0) {
    Serial.print("New Data: ");
    char c = Wire.read();
    Serial.println(c);
    input += c;
  }
  Serial.print("Full data: ");
  Serial.println(input);

  String key = getVal(input,':',0);
  String value = getVal(input,':',1);

  Serial.println("Key: " + key + ", value: " + value);
  
  Serial.println();

  String dataString = input;
  File dataFile = SD.open("datalog.txt", FILE_WRITE);
  
  if (dataFile) {
    dataFile.println(dataString);
    dataFile.close();
  } else {
    Serial.println(F("ERROR: opening datalog.txt"));
  }
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
