#include <Wire.h>

#define LED 13
#define THIS_ADDRESS 0x15
#define MASTER_ADDRESS 0x8

const int sensorPin = A0;
int sensorValue = 0;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");

  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  Serial.println("Starting loop...");

}

void loop() {
  // put your main code here, to run repeatedly:

  sensorValue = analogRead(sensorPin);
  sendMaster("CO", String(sensorValue));
  delay(1000);

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
