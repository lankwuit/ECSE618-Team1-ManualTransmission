// class the creates and displays the gear shifting mechanisim
public class Meter{

    float w,h; // width and height of the box in pixels
    float radius;
    float x,y; // centre x,y position in pixels
    String value; // the printed value
    PShape sensor;  // The PShape object
    PShape border;
    PFont font;

    // constructor
    public Meter(float x, float y, float w, float h, float radius){
        this.w = w;
        this.h = h;
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.value = "-1";

        rectMode(CENTER);
        this.border = createShape(RECT, this.x, this.y, this.w, this.h, this.radius);
        this.sensor = createShape(RECT, this.x, this.y, this.w/2, this.h/2, this.radius);

        this.border.setFill(153);
        this.border.setStroke(true);

        this.sensor.setFill(255);
        this.sensor.setStroke(false);
        

        this.font = createFont("Arial",16,true);
    }


    public void setValue(String value){
        this.value = value;
    }

    public void draw(){
        shape(this.border); // draw border
        shape(this.sensor); // draw the box
        textFont(this.font,16); // specify font
        fill(0); // set fill colour for text
        textAlign(CENTER, CENTER);
        text(this.value, this.x, this.y); // draw this text in the center of the box
    }

}
