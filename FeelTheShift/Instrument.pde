
enum METER_TYPE{RPM, SPEED, PEDAL, OTHER}; // types of meters

// class the creates and displays sensor data
public class Meter {

  float w, h; // width and height of the box in pixels
  float radius; // radius of the corners for the box
  float x, y; // centre x,y position in pixels
  String value; // the printed value
  PShape sensor;  // The PShape object
  PShape border; // The PShape object
  PFont font; // the font used to display the text
  int font_size;
  String name; // either "RPM" or "KM/HR"
  boolean show_icon = false; // if true, show an icon instead of text
  PImage icon;
  boolean pressed = false; // is the button pressed?
  METER_TYPE type;

  // constructor
  public Meter(float x, float y, float w, float h, METER_TYPE type) {
    this.w = w;
    this.h = h;
    this.x = x;
    this.y = y;
    this.radius = 10;
    this.value = "-1";
    this.type = type;
    this.font_size = 50;


    switch (this.type) {
      case RPM:
        this.font = createFont("Arial", this.font_size, true);
        this.name = "RPM";
        break;
      case SPEED:
        this.font = createFont("Arial", this.font_size, true);
        this.name = "KM/HR";
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


  public void setValue(String value) {
    this.value = value;
  }
  
  public void setIcon(PImage img){
    this.icon = img;
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
    this.pressed = true;
  }
  
  public void release(){
    this.pressed = false;
  }
}
