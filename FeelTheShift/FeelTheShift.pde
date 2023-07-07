/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import gifAnimation.*;
/* end library imports *************************************************************************************************/  



/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/  



/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           rendering_force                     = false;
float             radsPerDegree                       = 0.01745;
/* end device block definition *****************************************************************************************/

/* world size in pixels */
int w = 1000;
int h = 400;
Gif backgroundGif;
Gif splashGif;
Gif endGif;

/* title font */
PFont title_font;
String title_text = "FEEL THE SHIFT";
int title_font_size = 64;

/* brake, gas, clutch position definitions in pixels*/
int gas_x = 200;
int gas_y = 220;
int brake_x = gas_x - 80;
int clutch_x = gas_x - 80*2;

Meter brake, gas, clutch;
PImage brakeImg, clutchImg, gasImg;

SoundFile pedal_sound;

/* rpm & speed sensor size definitons in pixels */
int rpm_x = 60;
int rpm_y = 50;
int rpm_w = 200;
int rpm_h = 100;
int MAX_RPM = 8000;
int MIN_RPM = 1000;

int speed_x = rpm_x;
int speed_y = 150;
int speed_w = 200;
int speed_h = 100;
int MAX_SPEED = 160; // km/h

int rpm_font_size = 40;
int pedal_font_size = 12;

/* game components */
int game_time = 0;
int game_score = 0;
int high_score = 0;

int game_state = 0; // 0: menu, 1: game, 2: game over
int game_text_x = 820;
int game_text_y = 50;
int game_text_sep = 100;

int game_text_font_size = 24;

int button_x = 820;
int button_y = 325;
int button_w = 100;
int button_h = 40;
int button_sep = button_w + 20;

int button_font_size = 24;

int arrow_x = 780;
int arrow_y = 70;
int arrow_sep = 75;
PImage up_arrow_img, down_arrow_img;

final String[] target_gears = { "1", "2", "3", "4", "5", "R" };
/*

Easy sequence: 1, 2, 3, 4, 5 (acceleration)
Easy sequence: 4, 3, 2, 1, N (deceleration)

Med Sequence: 1, 2, 3, 2, 1, R, N (acceleration, deceleration, reverse)

Hard sequence: 1, 2, 1, R, N, 2 (acceleration, deceleration, reverse)

*/

StringList gear_seq = new StringList(new String[] {
  "1","2", "3", "4", "5",
  "4", "3", "2", "1", "N",
  "1", "2", "3", "2", "1", "R", "N",
  "1", "2", "1", "R", "N", "2"
  });
int gear_seq_index = 0;

SoundFile engine_rev_sound, engine_idle_sound, engine_shift_sound;
SoundFile engine_start, start_screen_sound, main_screen_sound, end_screen_sound;
float background_volume = 0.01; // background music volume
float engine_volume = 0.10; // background engine volume

/* define sensors */
Meter target_text, score_text, time_text, rpm_sensor, speed_sensor;
Meter end_button, reset_button;
Meter up_arrow, down_arrow;

// for endscreen uses
Meter grade_text, record_text1 ,record_text2, total_score_text, timeend_text;
// set up initial endscreen to show the end result (0), before scoreboard (1)
int endscreen_state = 0;
String user_name = "";
String tmp_name = "____";

JSONArray scores_object;
// endscreen use ends


int current_time = 0;
long last_time = 0;

/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerMeter                 = 4000;

/* data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           pos_ee                              = new PVector(0, 0);
PVector           f_ee                                = new PVector(0, 0); 
PVector           prev_pos_ee                        = new PVector(0, 0);


/* define gear mechanism */
GearShifter mechanism;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 400);
  backgroundGif = new Gif(this, "../imgs/bg_gameplay.gif");
  splashGif = new Gif(this, "../imgs/bg_splash.gif");
  // endGif = new Gif(this, "../imgs/bg_end.gif");
  
  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */


   /*************************************************************************/
   haplyBoard          = new Board(this,  Serial.list()[3], 0);
   widgetOne           = new Device(widgetOneID, haplyBoard);
   pantograph          = new Pantograph();
  
   widgetOne.set_mechanism(pantograph);
  
   ////start: added to fix inverse motion of the ball
  //  widgetOne.add_actuator(1, CCW, 2);
  //  widgetOne.add_actuator(2, CW, 1);

  //  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  //  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  

  ///////////////
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CCW, 1);
 
  widgetOne.add_encoder(1, CW, 168, 4880, 2);
  widgetOne.add_encoder(2, CW, 12, 4880, 1); 
  //////////////


  widgetOne.device_set_parameters();
   /*************************************************************************/

  // game text
  target_text = new Meter(game_text_x, game_text_y, rpm_w, rpm_h, METER_TYPE.TEXT);
  score_text = new Meter(game_text_x, game_text_y + game_text_sep, rpm_w, rpm_h, METER_TYPE.TEXT);
  time_text = new Meter(game_text_x, game_text_y + game_text_sep*2, rpm_w, rpm_h, METER_TYPE.CLOCK);

  target_text.setName("TARGET");
  score_text.setName("SCORE");
  time_text.setName("TIME");

  target_text.setFontSize(game_text_font_size);
  score_text.setFontSize(game_text_font_size);
  time_text.setFontSize(game_text_font_size);

  target_text.setValue("GEAR " + gear_seq.get(gear_seq_index));

  // end game condition texts
  // screen 1 with grade conclusion, records, and name
  grade_text = new Meter(32 + 32, 16+title_font_size+19+32+5, -1, -1, METER_TYPE.GRADE);
  grade_text.setName("GRADE");
  grade_text.setFontSize(32);

  // first record text 
  record_text1 = new Meter(226+32, 16+title_font_size+19+32, -1, -1, METER_TYPE.RECORD);
  record_text1.setName("GREAT SHIFT");
  record_text1.setFontSize(32);

  record_text2 = new Meter(record_text1.x, record_text1.y+textWidth(record_text1.name), -1, -1, METER_TYPE.RECORD);
  record_text2.setName("POOR SHIFT");
  record_text2.setFontSize(32);

  total_score_text= new Meter(record_text2.x, record_text2.y+textWidth(record_text2.name), -1, -1, METER_TYPE.RECORD);
  total_score_text.setName("TOTAL");
  total_score_text.setFontSize(32);
  
  timeend_text= new Meter(w-32-32- 32 - 32*4, total_score_text.y, 2, 30, METER_TYPE.TIME);
  timeend_text.setName("TIME");
  timeend_text.setFontSize(16);

  record_text1.setShift(true); // good shift text
  record_text2.setShift(false); // bad shift text


  // start & reset buttons
  end_button = new Meter(button_x + button_sep/2, button_y, button_w*0.75, button_h, METER_TYPE.BUTTON);
  reset_button = new Meter(button_x - button_sep/2, button_y, button_w, button_h, METER_TYPE.BUTTON);

  end_button.setName("END");
  reset_button.setName("RESET");

  end_button.setFontSize(button_font_size);
  reset_button.setFontSize(button_font_size);

  end_button.setValue("HOLD E");
  reset_button.setValue("R");

  // shift arrows
  up_arrow_img = loadImage("../imgs/arrow_upshift.png");
  down_arrow_img = loadImage("../imgs/arrow_downshift.png");

  up_arrow = new Meter(arrow_x, arrow_y, up_arrow_img.width, up_arrow_img.height, METER_TYPE.ICON);
  down_arrow = new Meter(arrow_x, arrow_y, down_arrow_img.width, down_arrow_img.height, METER_TYPE.ICON);
  
  up_arrow.setIcon(up_arrow_img);
  down_arrow.setIcon(down_arrow_img);

  // rpm & speed sensors
  rpm_sensor = new Meter(rpm_x, rpm_y, rpm_w, rpm_h, METER_TYPE.RPM);
  speed_sensor = new Meter(speed_x, speed_y, speed_w, speed_h, METER_TYPE.SPEED);

  rpm_sensor.setRange(MIN_RPM, MAX_RPM);
  speed_sensor.setRange(0, MAX_SPEED);

  rpm_sensor.setFontSize(rpm_font_size);
  speed_sensor.setFontSize(rpm_font_size);

  rpm_sensor.setValue(MIN_RPM);
  
  // pedels icons
  clutchImg = loadImage("../imgs/clutch_white.png");
  brakeImg = loadImage("../imgs/brake_white.png");
  gasImg = loadImage("../imgs/gas_white.png");

  
  // setup pedals
  clutch = new Meter(clutch_x, gas_y, clutchImg.width, clutchImg.height, METER_TYPE.PEDAL); // draw brake pedel
  clutch.setIcon(clutchImg);
  clutch.setName("CLUTCH");
  clutch.setValue("");
  clutch.setFontSize(pedal_font_size);
  
  brake = new Meter(brake_x, gas_y, brakeImg.width, brakeImg.height, METER_TYPE.PEDAL); // draw brake pedel
  brake.setIcon(brakeImg); 
  brake.setName("BRAKE");
  brake.setValue("");
  brake.setFontSize(pedal_font_size);
  
  gas = new Meter(gas_x, gas_y, gasImg.width, gasImg.height, METER_TYPE.PEDAL); // draw brake pedel
  gas.setIcon(gasImg);
  gas.setName("GAS");
  gas.setValue("");
  gas.setFontSize(pedal_font_size);


  // setup title font
  title_font = createFont("../fonts/Disco Duck 3D Italic.otf", title_font_size, true);

  // ! create the instance of mechanism, passing through world dimensions, world instance, reference frame
  mechanism = new GearShifter(w, h, pixelsPerMeter);
  mechanism.setMinMaxRpm(MIN_RPM, MAX_RPM);

  // engage the clutch
  clutch.press();
  mechanism.setClutch(true);
  
  /* Haptic Tool Initialization */
  mechanism.create_ee();

  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);

  // start the gif
  splashGif.loop(); // play the gif
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(rendering_force == false && game_state == 1){ // game screen
    imageMode(CORNER);
    tint(255*0.6); // darken the background a bit by 60%
    image(backgroundGif, -50 ,-50, w+50, h+50);
    
    clutch.draw();
    brake.draw();
    gas.draw();

    mechanism.draw();
    mechanism.draw_ee(pos_ee.x, pos_ee.y);

    // // check the gear
    // GEAR cur_gear = mechanism.getGear(pos_ee);
    // String target_gear_str = gear_seq.get(gear_seq_index);
    // GEAR target_gear = getGearFromString(target_gear_str);

    // checkGear(cur_gear);

  }else if(rendering_force == false && game_state == 0){ // splash screen
    imageMode(CORNER);
    image(splashGif, -50 ,-50, w+50, h+50);

    // draw the title
    textFont(title_font, title_font_size); // specify font
    fill(255);
    stroke(0);
    textAlign(CENTER, TOP);
    text(title_text, w/2, 16);

    // create a gradient for the text
    color c1 = #E85959;
    color c2 = #F4A862;

    // draw a rotating circle at the center of the screen
    pushMatrix();
    translate(w/2, h/2);
    rotate(frameCount * 0.01); // rotate every frame
    noFill();
    stroke(c2);
    strokeWeight(8);

    ellipseMode(CENTER); // first two points are the x,y of the centre of the ellipse

    // draw the arcs
    int num_arcs = 4; // number of long arcs (total arcs = num_arcs*2)
    float short_angle = PI/num_arcs/3.0; // angle of the short arcs (num_arcs * (x*2 + x) = 180 solve for x)
    float long_angle = short_angle*2;
    // empty angle between arcs
    float empty_angle = PI/(num_arcs*2.0);

    float start_angle = 0;
    for(int i = 0; i < num_arcs; i++){ // draw the arcs
      arc(0,0,140,140, start_angle, start_angle + long_angle); // long arc
      start_angle += long_angle + empty_angle; // skip empty space and long arc
      arc(0,0,140,140, start_angle, start_angle  + short_angle); // short arc
      start_angle += short_angle + empty_angle; // skip empty spaces and short arc
    }
    popMatrix();

    // check if the knob is in the centre
    PVector pos = mechanism.getPosReltoCustomSpace(pos_ee);
    boolean is_in_centre = pos.sub(new PVector(w/2, h/2)).mag() < 10.0;

    // draw insert knob text
    String insert_knob_text = "INSERT KNOB";
    textFont(score_text.getFont(), game_text_font_size); // specify font

    fill(lerpColor(c1, c2, 0.5*sin( radians(frameCount % 360)) + 0.5)); // set fill colour for text
    textAlign(CENTER, CENTER);

    if(!is_in_centre && sin( 10*radians(frameCount % 360)) >=0  )
      text(insert_knob_text, w/2, h/2 + 100);

    // draw press x to start text
    String start_text = "PRESS X TO START";
    textFont(score_text.getFont(), game_text_font_size); // specify font
    fill(lerpColor(c1, c2, 0.5*sin( radians(frameCount % 360)) + 0.5)); // set fill colour for text
    textAlign(CENTER, CENTER);
    
    if(is_in_centre && sin( 10*radians(frameCount % 360)) >=0  )
      text(start_text, w/2, h/2 + 100);

    // draw the knob
    mechanism.draw_ee(pos_ee.x, pos_ee.y);

  }
}
/* end draw section ****************************************************************************************************/

void keyPressed(){
  if(key == 'x' || key == 'X'){
    if(game_state == 0){
      splashGif.stop();
      game_state = 1; // start game
      backgroundGif.loop(); // play the gif
    }
  }

  if(key == 'r' || key == 'R'){
    if(game_state == 1){
      mechanism.resetdevice();
    }
  }

  if(key == 'h' || key == 'H'){
    if(game_state == 1){
      mechanism.setKd(1.0);
    }
  }

  if(key == 'j' || key == 'J'){
    if(game_state == 1){
      mechanism.setKd(5.0);
    }
  }

  if(key == 'k' || key == 'K'){
    if(game_state == 1){
      mechanism.setKd(10.0);
    }
  }

  if(key == 'l' || key == 'L'){
    if(game_state == 1){
      mechanism.setKd(15.0);
    }
  }

  if(key == 'a' || key == 'A'){
    if(game_state == 1){
      mechanism.move(1);
    }
  }

  if(key == 's' || key == 'S'){
    if(game_state == 1){
      mechanism.move(0);
    }
  }

  if(key == 'd' || key == 'D'){
    if(game_state == 1){
      mechanism.move(2);
    }
  }

  if(key == 'w' || key == 'W'){
    if(game_state == 1){
      mechanism.move(-1);
    }
  }

  if(key == 'f' || key == 'F'){
    mechanism.showForce(true);
  }

}

void keyReleased(){

  if(key == 'f' || key == 'F'){
    //mechanism.showForce(false);
  }
}

// listen to typing during the end screen
void keyTyped() {
  if(game_state == 2)
    if(endscreen_state == 0){
      if (key == BACKSPACE) {
        if (user_name.length() > 0)
          user_name = user_name.substring(0, user_name.length()-1);
      } else if (key == ENTER) {
         if (user_name.length() > 0){
          endscreen_state = 1; // save score

          // write the current score to a file and read the file to display the scoreboard
          JSONObject current_score = new JSONObject();

          current_score.setString("time", time_text.value);
          current_score.setString("name", user_name);
          current_score.setString("score", score_text.value);
          current_score.setInt("score_int", score_text.getValue());

          scores_object.append(current_score);

          // sort the scores using a hashmap that maps the score to the index in the array
          HashMap<Float,Integer> map = new HashMap<Float,Integer>();
          float[] scores = new float[scores_object.size()];

          // populate the hashmap and array
          for(int i = 0; i < scores_object.size(); i++){
            JSONObject score = scores_object.getJSONObject(i);
            scores[i] = scores_object.getJSONObject(i).getInt("score_int");
            if(scores[i] < 0)
              scores[i] -= random(0.5f);
            else
              scores[i] += random(0.5f);
              
             map.put(scores[i], i);
          }

          scores = reverse(sort(scores)); // sort the scores in non ascending order

          // sort the scores in the json array
          JSONArray tmp = new JSONArray();
          for(int i = 0; i < scores.length; i++){
            tmp.setJSONObject(i, scores_object.getJSONObject(map.get(  scores[i]   )));
          }

          // save and reload the file
          saveJSONArray(tmp, "scores.json");
          scores_object = loadJSONArray("scores.json");
         }
      } else{
        if (user_name.length() < 4)
          user_name += key;
      }
    }
}

// helper to shift gears
boolean shiftGear(GEAR gear){
  boolean canChangeGear = mechanism.setGear(gear);
  return canChangeGear;
}

// helper to check if the user should shift up
boolean shouldShiftUp(GEAR cur_gear){
  GEAR target = GEAR.NEUTRAL;
  String target_gear = gear_seq.get(gear_seq_index);
  target = getGearFromString(target_gear);
  return cur_gear.ordinal() - target.ordinal() < 0; // should increase gear

}

boolean reachedTargetGear(GEAR cur_gear){
  GEAR target = GEAR.NEUTRAL;
  String target_gear = gear_seq.get(gear_seq_index);
  target = getGearFromString(target_gear);
  return cur_gear == target;
}

GEAR getGearFromString(String gear){
  GEAR target = GEAR.NEUTRAL;

  if(gear == "R")
    target = GEAR.REVERSE;
  else if(gear == "1")
    target = GEAR.ONE;
  else if(gear == "2")
    target = GEAR.TWO;
  else if(gear == "3")
    target = GEAR.THREE;
  else if(gear == "4")
    target = GEAR.FOUR;
  else if(gear == "5")
    target = GEAR.FIVE;

  return target;
}


// void checkGear(GEAR cur_gear){
//     if(mechanism.getPrevGear() != cur_gear){ // check if the gear has changed    
//       boolean canChangeGear = shiftGear(cur_gear);
//       boolean targetGearReached = reachedTargetGear(cur_gear);

//       boolean isGoodShift = true; // assume good shift
//       int cur_rpm = rpm_sensor.getValue();
//       if(cur_rpm < mechanism.getMinRPM(cur_gear) || cur_rpm > mechanism.getMaxRPM(cur_gear)){
//         isGoodShift = false; // outside the rpm range to shift
//       }

//       if(canChangeGear && isGoodShift && targetGearReached){ // have reached target gear and made a great shift

//         // reset the highlights
//         this.target_text.highlight(false); // reset the target gear highlight
//         this.clutch.highlight(false); // reset the clutch highlight
//         this.gas.highlight(false); // reset the rpm highlight


//         // good shift
//         println("Good shift! Current gear: " + cur_gear);
//         score_text.increaseValue(10); // 10 points for a good shift
//         record_text1.addShiftCount(); // add to the shift count
//         record_text1.increaseValue(10); // add to the shift score

//         // change the target to the next gear
//         gear_seq_index = gear_seq_index + 1 >= gear_seq.size() ? 0 : gear_seq_index + 1;
//         target_text.setValue("GEAR " + gear_seq.get(gear_seq_index));

        

//       }else if(canChangeGear && isGoodShift && cur_gear == GEAR.NEUTRAL){ // moved into neutral gear
//         // good shift
//         println("Good shift! Current gear: " + cur_gear);
//         score_text.increaseValue(10); // 10 points for a good shift
//         record_text1.addShiftCount(); // add to the shift count
//         record_text1.increaseValue(10); // add to the shift score
    
//       }else if(targetGearReached){ // reached target gear but made a bad shift

//         if(!canChangeGear){
//           println("Bad shift! Clutch not engaged");
//           score_text.decreaseValue(5); // 10 points penalty for a bad shift
//           record_text2.increaseValue(5); // add to the shift score
//           this.clutch.highlight(true); // highlight the clutch since it was not engaged
//         }
//         if(!isGoodShift){
//           println("Bad shift! Wrong RPM: " + cur_rpm);
//           score_text.decreaseValue(5); // 10 points penalty for a bad shift
//           record_text2.increaseValue(5); // add to the shift score
//           this.gas.highlight(true); // highlight the rpm sensor since it was not in the correct range
//         }

//         record_text2.addShiftCount(); // add to the shift count

//         // change the target to the next gear
//         gear_seq_index = gear_seq_index + 1 >= gear_seq.size() ? 0 : gear_seq_index + 1;
//         target_text.setValue("GEAR " + gear_seq.get(gear_seq_index));
//       }else { // did not reach target gear
//         println("Bad shift! Wrong gear: " + cur_gear);
//         score_text.decreaseValue(10); // 10 points penalty for a bad shift
//         record_text2.addShiftCount(); // add to the shift count
//         record_text2.increaseValue(10); // add to the shift score
//         this.target_text.highlight(true); // highlight the target gear since it was not reached
//       }
//     }
// }

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    rendering_force = true;
    
    /***************** HAPTIC SIMULATION *****************/
    if(haplyBoard.data_available()){
    widgetOne.device_read_data();
    
     angles.set(widgetOne.get_device_angles()); 
     pos_ee.set(widgetOne.get_device_position(angles.array()));
     pos_ee.set(mechanism.device_to_graphics(pos_ee));  

     if(game_state == 1){
       mechanism.forcerender(pos_ee, prev_pos_ee);
     }

    // set previous position
     prev_pos_ee.set(pos_ee);


    }    
    torques.set(widgetOne.set_device_torques(mechanism.fEE.array()));
    widgetOne.device_write_torques();
    /***************** END HAPTIC SIMULATION *****************/
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/
