#include <Wire.h>
//#include <Adafruit_BMP085.h>
//#include "SparkFunCCS811.h"

//Adafruit_BMP085 bmp;

//#define CCS811_ADDR 0x5B //Default I2C Address
//CCS811 CO2Sensor(CCS811_ADDR);

#define LED 13
#define BUTTON 10

#define THIS_ADDRESS 0x8
#define OTHER_ADDRESS 0x9

boolean last_state = HIGH;

float alt = 0;

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
/*
  CCS811Core::status returnCode = CO2Sensor.beginCore();
  Serial.print("beginCore exited with: ");
  switch ( returnCode )
  {
    case CCS811Core::SENSOR_SUCCESS:
      Serial.print("SUCCESS");
      break;
    case CCS811Core::SENSOR_ID_ERROR:
      Serial.print("ID_ERROR");
      break;
    case CCS811Core::SENSOR_I2C_ERROR:
      Serial.print("I2C_ERROR");
      break;
    case CCS811Core::SENSOR_INTERNAL_ERROR:
      Serial.print("INTERNAL_ERROR");
      break;
    case CCS811Core::SENSOR_GENERIC_ERROR:
      Serial.print("GENERIC_ERROR");
      break;
    default:
      Serial.print("Unspecified error.");
  }*/
  
/*
  if (!bmp.begin()) {
    Serial.println("ERROR");
  } else {
    Serial.println("SUCCESS");
  }*/
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
    //boolean b = Wire.read();
    //Serial.print(b, DEC);
    //digitalWrite(LED, !b);
    Serial.print("New Data: ");
    char c = Wire.read();
    Serial.println(c);
    input += c;
  }
  Serial.print("Full data: ");
  Serial.println(input);
  Serial.println();
}
