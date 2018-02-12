import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

PeasyCam cam;

void setup()  {
  size(640, 360, P3D);
  noStroke();
  fill(204);
  cam = new PeasyCam(this, 400);
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
  box(160);
  translate(0, 0, 0);
  
  stroke(255,0,0);
  line(0,0,0,300,0,0);
  
  stroke(0,255,0);
  line(0,0,0,0,300,0);
  
  stroke(0,0,255);
  line(0,0,0,0,0,300);
  
  noStroke();
}