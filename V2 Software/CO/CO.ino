#include <Wire.h>

#define LED 12
#define THIS_ADDRESS 0x15
#define MASTER_ADDRESS 0x8

const int sensorPin = A3;

int COLevel = 0;
String deviceType = "sen"; // Sensor

// timing values:
long previousMillis = 0;
long interval = 1000;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");

  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  Serial.println("Starting loop...");

}

void loop() {
  // put your main code here, to run repeatedly:

  COLevel = analogRead(sensorPin);

  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis > interval) {
    previousMillis = currentMillis;

    sendMaster(deviceType, "CO", String(COLevel));
    
  }

}


void receiveEvent(int howMany) {
  Serial.println("Received Data");
  while (Wire.available() > 0) {
  }
  Serial.println();
}

// Device Type: sen (sensor)
// Key: CO (Carbon monoxide)
// Value: value of sensor
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
