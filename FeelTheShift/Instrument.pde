import processing.sound.*;

enum METER_TYPE{RPM, SPEED, PEDAL, OTHER}; // types of meters

// class the creates and displays sensor data
public class Meter {

  float w, h; // width and height of the box in pixels
  float radius; // radius of the corners for the box
  float x, y; // centre x,y position in pixels


  String value; // the printed value
  int font_size;
  String name; // either "RPM" or "KM/HR"

  PShape sensor;  // The PShape object
  PShape border; // The PShape object
  PFont font; // the font used to display the text


  boolean show_icon = false; // if true, show an icon instead of text
  PImage icon;
  boolean pressed = false; // is the button pressed?

  SoundFile sound = null; // the sound to play when the button is pressed
  
  int min_value = 0;
  int max_value = 100;

  // the type of instrument
  METER_TYPE type;

  // constructor
  public Meter(float x, float y, float w, float h, METER_TYPE type) {
    this.w = w;
    this.h = h;
    this.x = x;
    this.y = y;
    this.radius = 10;
    this.value = "0";
    this.type = type;
    this.font_size = 50;


    switch (this.type) {
      case RPM:
        this.font = createFont("Arial", this.font_size, true);
        this.name = "RPM";
        this.setValue(0);
        break;
      case SPEED:
        this.font = createFont("Arial", this.font_size, true);
        this.name = "KM/HR";
        this.setValue(0);
        break;

      case PEDAL:
        this.show_icon = true;
        break;

      case OTHER:
        this.border = createShape(RECT, this.x, this.y, this.w, this.h, this.radius);
        this.sensor = createShape(RECT, this.x, this.y, this.w/2, this.h/2, this.radius);

        this.border.setFill(color(255));
        this.border.setStroke(true);

        this.sensor.setFill(color(255));
        this.sensor.setStroke(false);
        break;
    }
  }


  public void setValue(int value) {
    switch (this.type) {
      case RPM:
        this.value = nf(value, 4,0);
        break;
      case SPEED:
        this.value = nf(value, 3, 0);
        break;
    }
  }
  
  public void setRange(int min, int max) {
    this.min_value = min;
    this.max_value = max;
  }

  public void increaseValue() {
    // increase the value by a 
    float val = float(this.value);

    val += (1-val/this.max_value)*this.max_value*0.1; // increase the value by 10% of the max value initally, then slowly increase afterwards

    if (val > this.max_value) // clamp the value to the max value
      val = this.max_value - 1;

    if(val % 100 != 0)
      val -= val % 100; // round to the nearest 100
    
    this.setValue((int) val); // update the value

    if (this.sound != null){

      float start_loc = this.sound.duration()*(val/this.max_value); // set the start location the sound
      this.sound.jump(start_loc); // jump to the start location
      this.sound.play(1, val/this.max_value); // play the sound
    }
  }

  public void decreaseValue() {
    // apply damping to the value
    float val = float(this.value);
    
    val -= (val/this.max_value)*10; // decrease the value

    // clamp the value to the min value
    if(val <= this.min_value)
      val = this.min_value;

    if(val % 100 != 0)
      val -= val % 100; // round to the nearest 100

    this.setValue((int) val); // update the value
  }
  
  public void setIcon(PImage img){
    this.icon = img;
  }

  public void setSound(SoundFile sound){
    this.sound = sound;
  }

  public void draw() {
    switch (this.type) {
      case RPM:
      case SPEED:
        this.drawText(); // draw the text
        break;

      case OTHER:
        shape(this.border); // draw border
        shape(this.sensor); // draw the box
        break;
      
      case PEDAL:
        this.drawIcon(); // draw the image, for example a break
        break;
    }
  }

  private void drawText() {
    textFont(this.font, this.font_size); // specify font
    fill(0); // set fill colour for text
    textAlign(LEFT, CENTER);
    text(this.value, this.x, this.y); // draw this text in the center of the box
    textFont(this.font, this.font_size/2); // specify font
    text(this.name, this.x + this.font_size, this.y + this.font_size);
  }
  
  private void drawIcon(){
    imageMode(CENTER);
    
    if(this.pressed)
      tint(255, 255);
     else
       tint(255, 120); // make the image transparent to show it is pressed
       
    image(this.icon, this.x, this.y, this.w, this.h);
  }
  
  public void press(){
    // only play the sound if it is not already playing
    // otherwise we will get a lot of overlapping sounds
    if (this.sound != null && this.pressed == false)
      this.sound.play(); // play the sound
    this.pressed = true;
  }
  
  public void release(){
    this.pressed = false;
  }
}
