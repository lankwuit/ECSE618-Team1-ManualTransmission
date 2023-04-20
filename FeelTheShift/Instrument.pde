import processing.sound.*;

enum METER_TYPE{RPM, SPEED, PEDAL, BUTTON, TEXT, ICON, GRADE, RECORD, TIME, CLOCK, OTHER}; // types of meters

// class the creates and displays sensor data
public class Meter {

  float w, h; // width and height of the box in pixels
  float radius; // radius of the corners for the box
  float x, y; // centre x,y position in pixels


  String value; // the printed value
  int value_int;
  int font_size;
  int title_size;
  String name; // either "RPM" or "KM/HR"

  PShape sensor;  // The PShape object
  PShape border; // The PShape object
  PFont font; // the font used to display the text
  color font_color = color(255); // the color of the text

  color font_color_bad = #E85959;
  color font_color_good = #30D65F;
  color font_color_ok = #F4A862;



  boolean show_icon = false; // if true, show an icon instead of text
  PImage icon;
  boolean pressed = false; // is the button pressed?

  SoundFile sound = null; // the sound to play when the button is pressed

  char Grading = 'Z';
  
  // min and max values for value
  int min_value = Integer.MIN_VALUE;
  int max_value = Integer.MAX_VALUE;

  boolean shift; // to determine if the previous is a good shift or a bad shift
  int shiftCount; // count for shift

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
    this.font_size = 30;
    this.font = createFont("../fonts/PressStart.ttf", this.font_size, true);


    switch (this.type) {
      case RPM:
        this.name = "RPM";
        this.setValue(0);
        break;
      case SPEED:
        this.name = "KM/H";
        this.setValue(0);
        break;

      case PEDAL:
      case ICON:
        this.show_icon = true;
        break;

      case BUTTON:
      case TEXT:
      case CLOCK:
        this.setValue(0);
        break;

      case OTHER:
        break;

      case GRADE:
        break;

      case RECORD:
        this.setValue(0);
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
      case TEXT:
      case RECORD:
      case TIME:
        this.value = nf(value, 4, 0);
        break;

      case CLOCK:
        int minutes = value / 60;
        int seconds = value % 60;
        this.value = nf(minutes, 2, 0) + ":" + nf(seconds, 2, 0);
        break;

    }
  }

  public void setValue(String value) {
    this.value = value;
  }

  public int getValue() {
    if(this.type == METER_TYPE.CLOCK)
      return value_int;
    return int(this.value);
  }

  public void setFontSize(int size){
    this.font_size = size;
  }

  public void setGradeFont (int size){
    this.title_size = size;
  }

  public void setName(String name){
    this.name = name;
  }
  
  public void setRange(int min, int max) {
    this.min_value = min;
    this.max_value = max;
  }


  public void increaseValue(int val){
    if(this.type == METER_TYPE.CLOCK){
      value_int++;
      this.setValue(value_int);
      return;
    }

    int cur_val = int(this.value);
    cur_val += val;
    if (cur_val > this.max_value) // clamp the value to the max value
        cur_val = this.max_value - 1;
    this.setValue(cur_val);
  }

  public void decreaseValue(int val){
    int cur_val = int(this.value);
    cur_val -= val;
    if (cur_val < this.min_value)
        cur_val = this.min_value;
    this.setValue(cur_val);
  }


  public void increaseValue() {
    float val = float(this.value);

    switch (this.type) {
      case RPM:
        val += (1-val/this.max_value)*this.max_value*0.1; // increase the value by 10% of the max value initally, then slowly increase afterwards
        if (val > this.max_value) // clamp the value to the max value
          val = this.max_value - 1;
        if(val % 100 != 0)
          val -= val % 100; // round to the nearest 100
        break;
      case SPEED:
        val += (1-val/this.max_value)*this.max_value*0.02; // increase the value by 1% of the max value initally, then slowly increase afterwards
        if (val > this.max_value) // clamp the value to the max value
          val = this.max_value - 1;
        break;
    }

    this.setValue((int) val); // update the value


    if (this.sound != null){
        float loc = this.sound.duration()*( 0.9 ); // set the start location the sound
        // this.sound.stop();
        // this.sound.amp( 0.7 ); // set the volume
        this.sound.jump(loc); // play the sound
    }
  }

  public void decreaseValue() {
    // apply damping to the value
    float val = float(this.value);

    switch (this.type) {
      case RPM:
        val -= (val/this.max_value)*0.001; // decrease the value
        // clamp the value to the min value
        if(val <= this.min_value)
          val = this.min_value;
          
        if(val % 100 != 0)
          val -= val % 100; // round to the nearest 100
        break;
      case SPEED:
        val -= (val/this.max_value)*0.01;
        if(val <= this.min_value)
          val = this.min_value;
        break;
    }

    this.setValue((int) val); // update the value
  }
  
  public void setIcon(PImage img){
    this.icon = img;
  }

  public void setGrading(int score){
    int scores = score;
    if (scores > 400){
      this.Grading = 'A';
    } else if (scores > 300){
      this.Grading = 'B';
    }else if (scores > 200){
      this.Grading = 'C';
    }else if (scores > 50){
      this.Grading = 'D';
    }else{
      this.Grading = 'F';
    }
  }
  public void setSound(SoundFile sound){
    this.sound = sound;
  }

  public void draw() {
    switch (this.type) {
      case RPM:
      case SPEED:
        this.drawValue(); // draw the text
        break;

      case CLOCK:
      case TEXT:
        this.drawGameText(); // draw the text
        break;

      case BUTTON:
        //shape(this.sensor); // draw the box
        this.drawButton();
        this.drawText(); // draw the text
        break;
      
      case PEDAL:
        this.drawPedal(); // draw the pedal
        break;
      case ICON:
        this.drawIcon(); // draw the image, for example a break
        break;

      case OTHER:
        break;

      case GRADE:
        this.drawGrade();
        break;

      case RECORD:
        this.drawRecord();
        break;
      case TIME:
        this.drawTime();
        break;
    }
  }

  private void drawButton(){
    rectMode(CENTER);
    fill(0);
    strokeWeight(4);
    if(this.pressed)
      stroke(0);
     else
      stroke(255);
    rect(this.x + this.w/2, this.y + this.h/2, this.w, this.h, this.radius);

    // draw value below
    fill(this.font_color); // set fill colour for text
    textFont(this.font, this.font_size*0.5); // specify font
    text(this.value, this.x + this.w/2, this.y + this.h + this.font_size * 0.5);
  }

  private void drawText(){
    textFont(this.font, this.font_size); // specify font
    fill(this.font_color); // set fill colour for text
    textAlign(CENTER, CENTER);
    text(this.name, this.x + this.w/2, this.y + this.h/2);
  }
  
  private void drawGrade(){
    textFont(this.font, this.font_size); // specify font
    fill(255); // set fill colour for text
    float name_size = textWidth(this.name);
    textAlign(LEFT, CENTER);
    text(this.name, this.x, this.y);

    textAlign(CENTER, CENTER);
    textFont(this.font, 80); // specify font for grading character
    text(this.Grading, this.x + 0.5*name_size, this.y + this.font_size*1.8);
  }

  private void setShift(boolean stat){
    this.shift = stat;
  }


  public void addShiftCount(){
    this.shiftCount++;
  }
  private void drawRecord(){
    textFont(this.font, this.font_size); // specify font 
    fill(255); // set fill colour for text   

    if(this.name == "TOTAL"){
      textAlign(RIGHT, CENTER);
      text(this.value, 945, this.y);  
      return;
    }
    
    // draw the shift count
    textAlign(LEFT, CENTER);
    String temp = nf(this.shiftCount,3);
    text(temp, this.x, this.y);

    // draw the name
    float count_size = textWidth(temp);
    textAlign(LEFT, CENTER);
    text(this.name, this.x + count_size+40, this.y);

    // draw the score
    textAlign(RIGHT, CENTER);
    if(this.shift)
      text("+"+ this.value, 945, this.y);
    else
      text("-"+ this.value, 945, this.y);
  }  
  private void drawTime(){
    textFont(this.font, this.font_size); // specify font 
    fill(255); // set fill colour for text   
    

    int time = Integer.parseInt(this.value);
    String minute_text = str(time/60) +" MINUTE(S)";
    String second_text = str(time%60) +" SECOND(S)";

    textAlign(RIGHT, CENTER);
    text(minute_text, this.x, this.y);    

    textAlign(RIGHT, CENTER);
    text(second_text, this.x, this.y+20);


    float time_size = textWidth(minute_text);
    textAlign(RIGHT, CENTER);
    text(this.name + ":", this.x-time_size - 4, this.y);
  }


  private void drawGameText() {
    fill(this.font_color); // set fill colour for text
    textFont(this.font, this.font_size); // specify font
    float name_size = textWidth(this.name);
    String top_text = "TARGET";
    if(!this.name.equals(top_text)){
      name_size = textWidth(top_text);
      textAlign(RIGHT, CENTER);
      text(this.name, this.x + textWidth(top_text), this.y); // draw this text in the center of the box
    }else{
      textAlign(LEFT, CENTER);
      text(this.name, this.x, this.y); // draw this text in the center of the box
    }

    textAlign(RIGHT, CENTER);
    textFont(this.font, this.font_size); // specify font
    text(this.value, this.x + name_size, this.y + this.font_size*1.4);
  }

  private void drawValue() {
    textFont(this.font, this.font_size); // specify font
    fill(this.font_color); // set fill colour for text

    textAlign(RIGHT, CENTER);
    float value_size = textWidth("0000");
    text(this.value, this.x + value_size, this.y); // draw this text in the center of the box

    textAlign(RIGHT, CENTER);
    textFont(this.font, this.font_size * 0.4); // specify font
    text(this.name, this.x + value_size, this.y + this.font_size * 1.1);
  }
  
  private void drawIcon(){
    imageMode(CORNER);
    
    if(this.pressed)
      tint(255, 255);
     else
       tint(255, 120); // make the image transparent to show it is pressed
       
    image(this.icon, this.x, this.y, this.w, this.h);
  }

  private void drawPedal(){
    this.drawIcon();

    // draw the text below the pedal
    fill(this.font_color); // set fill colour for text
    textAlign(CENTER, CENTER);
    textFont(this.font, this.font_size); // specify font
    text(this.name, this.x + this.icon.width/2, this.y + this.icon.height + this.font_size * 1);
    textFont(this.font, this.font_size); // specify font
    text(this.value, this.x + this.icon.width/2, this.y + this.icon.height + this.font_size * 2.5);
  }

  // adjust the colour of the text based on the min and max values
  void adjustColour(float min, float max) {
    float val = float(this.value);

    if (val <= min) {
      this.font_color = this.font_color_bad;
    } else if (val < 1.3*min) {
      this.font_color = this.font_color_ok;
    } else if (val > 0.8*max) {
      this.font_color = this.font_color_ok;
    } else if (val > max) {
      this.font_color = this.font_color_bad;
    } else {
      this.font_color = this.font_color_good;
    }
  }

  public PFont getFont() {
    return this.font;
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
