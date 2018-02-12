import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

PeasyCam cam;
Table table;

void setup()  {
  size(640, 360, P3D);
  noStroke();
  fill(204);
  cam = new PeasyCam(this, 400);
  
  table = loadTable("data.csv", "header");
  
  println(table.getRowCount() + " total rows in table"); 

  for (TableRow row : table.rows()) {
    
    int CO2 = row.getInt("CO2");
    float alt = row.getFloat("altitude");
    float lat = row.getFloat("latMod");
    float lon = row.getFloat("lonMod");
    
    println("CO2: " + CO2 + ", Alt: " + alt + ", lat: " + lat + ", lon: " + lon); 
  }
}

void draw()  {
  
  background(0);
  lights();
  
  /*
  float fov = PI/3.0; 
  float cameraZ = (height/2.0) / tan(fov/2.0); 
  perspective(fov, float(width)/float(height), cameraZ/2.0, cameraZ*2.0); 
  */
  translate(width/2, height/2, 0);
  rotateX(-PI/6); 
  rotateY(PI/3); 
  //box(160);
  translate(0, 0, 0);
  
  stroke(255,0,0);
  line(0,0,0,300,0,0);
  
  stroke(0,255,0);
  line(0,0,0,0,300,0);
  
  stroke(0,0,255);
  line(0,0,0,0,0,300);
  
  noStroke();
  
  for (TableRow row : table.rows()) {
    
    int CO2 = row.getInt("CO2");
    float alt = row.getFloat("altitude");
    float lat = row.getFloat("latMod");
    float lon = row.getFloat("lonMod");
    
    pushMatrix();
    translate(lat, (lon - 600) * 2, (-alt) * 8);
    
    float CO2HSB = map(CO2, 400,700, 0, 90); //1295
    
    colorMode(HSB);
    fill(CO2HSB,255,255);
    colorMode(RGB);
    
    box(10);
    translate(0, 0, 0);
    popMatrix();
    //println("CO2: " + CO2 + ", Alt: " + alt + ", lat: " + lat + ", lon: " + lon); 
  }
  delay(10);
}