#include <Wire.h>

#define LED 13
#define BUTTON 10

#define THIS_ADDRESS 0x10
#define MASTER_ADDRESS 0x8

boolean last_state = HIGH;

void setup() {
  Serial.begin(9600);
  Serial.println("Booting...");
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

  pinMode(BUTTON, INPUT);
  digitalWrite(BUTTON, HIGH);

  Wire.begin(THIS_ADDRESS);
  Wire.onReceive(receiveEvent);

  Serial.println("Starting loop...");
}

void loop() {
  /*
    if (digitalRead(BUTTON) != last_state) {
    last_state = digitalRead(BUTTON);
    sendNewData();
    }*/

  sendNewData();
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

void sendNewData() {

  digitalWrite(LED, HIGH);
  delay(100);
  digitalWrite(LED, LOW);
  Wire.beginTransmission(MASTER_ADDRESS);
  Wire.write("PM:32.1");
  Wire.endTransmission();
  Serial.println("Sent Data");

}

