// class the creates and displays sensor data
public class Meter {

  float w, h; // width and height of the box in pixels
  float radius;
  float x, y; // centre x,y position in pixels
  String value; // the printed value
  PShape sensor;  // The PShape object
  PShape border;
  PFont font;
  String name; // either "RPM" or "KM/HR"
  boolean show_icon = false;
  PImage icon;

  // constructor
  public Meter(float x, float y, float w, float h, float radius, color c, String name) {
    this.w = w;
    this.h = h;
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.value = "-1";
    this.name = name;

    rectMode(CENTER);
    this.border = createShape(RECT, this.x, this.y, this.w, this.h, this.radius);
    this.sensor = createShape(RECT, this.x, this.y, this.w/2, this.h/2, this.radius);

    this.border.setFill(c);
    this.border.setStroke(true);

    this.sensor.setFill(c);
    this.sensor.setStroke(false);


    this.font = createFont("Arial", 50, true);
  }


  public void setValue(String value) {
    this.value = value;
  }
  
  public void setIcon(PImage img){
    this.icon = img;
    this.show_icon = true;
  }

  public void draw() {
    if (this.name.equals("") && !this.show_icon) { // no text, so we draw the borders
      shape(this.border); // draw border
      shape(this.sensor); // draw the box
    }
    
    if(this.show_icon){
      this.drawIcon(); // draw the image, for example a break
    }else{
      this.drawText(); // draw the text
    }
  }

  private void drawText() {
    textFont(this.font, 50); // specify font
    fill(0); // set fill colour for text
    textAlign(LEFT, CENTER);
    text(this.value, this.x, this.y); // draw this text in the center of the box
    textFont(this.font, 25); // specify font
    text(this.name, this.x + 50, this.y + 50);
  }
  
  private void drawIcon(){
    imageMode(CENTER);
    image(this.icon, this.x, this.y, this.w, this.h);
  }
}
