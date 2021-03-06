#include "SparkFunCCS811.h"
#include "Wire.h"

#define LED 13
#define THIS_ADDRESS 0x9
#define MASTER_ADDRESS 0x8

#define CCS811_ADDR 0x5B //Default I2C Address
CCS811 CO2Sensor(CCS811_ADDR);

float CO2Level, TVOCLevel;
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

  CCS811Core::status returnCode = CO2Sensor.beginCore();
  Serial.print("beginCore exited with: ");
  switch ( returnCode ) {
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
  }

  Serial.println("Starting loop...");
}

void loop() {

  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis > interval) {
    previousMillis = currentMillis;

    sendMaster(deviceType, "CO2", String(CO2Level));
    delay(10); // let the bus recover
    sendMaster(deviceType, "TVOC", String(TVOCLevel));

  }

  if (CO2Sensor.dataAvailable()) {
    //If so, have the sensor read and calculate the results.
    //Get them later
    CO2Sensor.readAlgorithmResults();

    CO2Level = CO2Sensor.getCO2();
    TVOCLevel = CO2Sensor.getTVOC();

    Serial.print("CO2[");
    //Returns calculated CO2 reading
    Serial.print(CO2Level);
    Serial.print("] tVOC[");
    //Returns calculated TVOC reading
    Serial.print(TVOCLevel);
    Serial.print("] millis[");
    //Simply the time since program start
    Serial.print(millis());
    Serial.print("]");
    Serial.println();
  }
}

void receiveEvent(int howMany) {
  Serial.println("Received Data");
  while (Wire.available() > 0) {
  }
  Serial.println();
}

// Device Type: sen (sensor)
// Key: CO2 (Carbon dioxide)
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
