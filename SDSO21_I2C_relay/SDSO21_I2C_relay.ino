/*
  Hardware Connections:
    5V(on Arduino) to Red(on SDS021)
    GND to Black
    10 to Blue (TX from sensor)
    11 to Yellow (RX into sensor)

*/

#include <SoftwareSerial.h>
#include <Wire.h>

SoftwareSerial particleSensor(10, 11); // RX, TX

float pm25; //2.5um particles detected in ug/m3
float pm10; //10um particles detected in ug/m3

void setup()
{
  Serial.begin(9600);
  Serial.println("Particle Sensor Startup");

  particleSensor.begin(9600); //SDS021 reports at 1Hz at 9600bps
  Wire.begin(2);                // join i2c bus with address #2
  Wire.onRequest(requestEvent); // register event
}

void loop()
{
  if (dataAvailable())
  {
    Serial.print("Particle Matter [2.5]:");
    Serial.print(pm25, 1);
    Serial.print("ug/m3 [10]:");
    Serial.print(pm10, 1);
    Serial.print("ug/m3");
    Serial.println();
  }
  else
  {
    Serial.println("Timeout or CRC error");
    Serial.println("Double check blue wire goes to pin 10");
  }

  delay(5);
}

void requestEvent() {
  //Wire.beginTransmission();
  char pm25result[8]; // Buffer big enough for 7-character float
  dtostrf(pm25, 6, 2, pm25result); // Leave room for too large numbers!
  char pm10result[8]; // Buffer big enough for 7-character float
  dtostrf(pm10, 6, 2, pm10result); // Leave room for too large numbers!
  
  Wire.write("pm25:");
  Wire.write(pm25result);
  Wire.write(";pm10:");
  Wire.write(pm10result);
  //Wire.endTransmission();
}

//Scans for incoming packet
//Times out after 1500 miliseconds
boolean dataAvailable(void)
{
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
