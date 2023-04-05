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

/* brake, gas, clutch position definitions in pixels*/
int gas_x = 175;
int gas_y = 250;
int brake_x = gas_x - 60;
int clutch_x = gas_x - 60*2;

Meter brake, gas, clutch;
PImage brakeImg, clutchImg, gasImg;

SoundFile pedal_sound;

/* rpm & speed sensor size definitons in pixels */
int rpm_x = 50;
int rpm_y = 50;
int rpm_w = 200;
int rpm_h = 100;
int MAX_RPM = 8000;

int speed_x = rpm_x;
int speed_y = 150;
int speed_w = 200;
int speed_h = 100;
int MAX_SPEED = 160; // km/h

int rpm_font_size = 64;

/* game components */
int game_time = 0;
int game_score = 0;
int high_score = 0;

int game_state = 0; // 0: menu, 1: game, 2: game over
int game_text_x = 820;
int game_text_y = 50;
int game_text_sep = 100;

int game_text_font_size = 42;

int button_x = 820;
int button_y = 325;
int button_w = 100;
int button_h = 40;
int button_sep = button_w + 20;

int button_font_size = 32;

int arrow_x = 225;
int arrow_y = 50;
int arrow_sep = 75;
PImage up_arrow_img, down_arrow_img;


SoundFile engine_rev_sound, engine_idle_sound;
SoundFile engine_start, start_screen_sound, main_screen_sound;
float background_volume = 0.05; // background music volume
float engine_volume = 0.1; // background engine volume

/* define sensors */
Meter target_text, score_text, time_text, rpm_sensor, speed_sensor;
Meter end_button, reset_button;
Meter up_arrow, down_arrow;

int current_time = 0;
int last_time = 0;

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


/* define gear mechanisim */
GearShifter mechanisim;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 400);
  backgroundGif = new Gif(this, "../imgs/bg_gameplay.gif");
  splashGif = new Gif(this, "../imgs/bg_splash.gif");
  splashGif.loop(); // play the gif
  endGif = new Gif(this, "../imgs/bg_end.gif");
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
  //  haplyBoard          = new Board(this, "/dev/cu.usbmodem141301", 0);
  //  widgetOne           = new Device(widgetOneID, haplyBoard);
  //  pantograph          = new Pantograph();
  
  //  widgetOne.set_mechanism(pantograph);
  
  //  //start: added to fix inverse motion of the ball
  //  widgetOne.add_actuator(1, CCW, 2);
  //  widgetOne.add_actuator(2, CW, 1);

  //  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  //  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  

  //  widgetOne.device_set_parameters();

  // engine sound
  engine_rev_sound = new SoundFile(this, "../audio/rev_01.wav");
  engine_idle_sound = new SoundFile(this, "../audio/engine_idle.wav");
  //engine_idle_sound.loop();

  engine_start = new SoundFile(this, "../audio/engine-start.wav");
  main_screen_sound = new SoundFile(this, "../audio/main_audio.wav");
  start_screen_sound = new SoundFile(this, "../audio/title_audio.wav");
  start_screen_sound.amp(background_volume);
  start_screen_sound.loop(); // play the sound while in game_state 0


  // game text
  target_text = new Meter(game_text_x, game_text_y, rpm_w, rpm_h, METER_TYPE.TEXT);
  score_text = new Meter(game_text_x, game_text_y + game_text_sep, rpm_w, rpm_h, METER_TYPE.TEXT);
  time_text = new Meter(game_text_x, game_text_y + game_text_sep*2, rpm_w, rpm_h, METER_TYPE.TEXT);

  target_text.setName("TARGET");
  score_text.setName("SCORE");
  time_text.setName("TIME");

  target_text.setFontSize(game_text_font_size);
  score_text.setFontSize(game_text_font_size);
  time_text.setFontSize(game_text_font_size);

  score_text.setRange(0, 999);

  target_text.setValue("GEAR N");

  
  // start & reset buttons
  end_button = new Meter(button_x + button_sep/2, button_y, button_w*0.75, button_h, METER_TYPE.BUTTON);
  reset_button = new Meter(button_x - button_sep/2, button_y, button_w, button_h, METER_TYPE.BUTTON);

  end_button.setName("END");
  reset_button.setName("RESET");

  end_button.setFontSize(button_font_size);
  reset_button.setFontSize(button_font_size);

  end_button.setValue("E");
  reset_button.setValue("R");

  // shift arrows
  up_arrow_img = loadImage("../imgs/arrow_upshift.png");
  down_arrow_img = loadImage("../imgs/arrow_downshift.png");

  up_arrow = new Meter(arrow_x, arrow_y, up_arrow_img.width, up_arrow_img.height, METER_TYPE.ICON);
  down_arrow = new Meter(arrow_x, arrow_y + arrow_sep, down_arrow_img.width, down_arrow_img.height, METER_TYPE.ICON);
  
  up_arrow.setIcon(up_arrow_img);
  down_arrow.setIcon(down_arrow_img);

  // rpm & speed sensors
  rpm_sensor = new Meter(rpm_x, rpm_y, rpm_w, rpm_h, METER_TYPE.RPM);
  speed_sensor = new Meter(speed_x, speed_y, speed_w, speed_h, METER_TYPE.SPEED);

  rpm_sensor.setRange(1000, MAX_RPM);
  speed_sensor.setRange(0, MAX_SPEED);

  rpm_sensor.setFontSize(rpm_font_size);
  speed_sensor.setFontSize(rpm_font_size);

  //rpm_sensor.setSound(engine_rev_sound);
  
  // pedels icons
  clutchImg = loadImage("../imgs/clutch_white.png");
  brakeImg = loadImage("../imgs/brake_white.png");
  gasImg = loadImage("../imgs/gas_white.png");

  // pedal sounds
  pedal_sound = new SoundFile(this, "../audio/pedal.mp3");
  
  // setup pedals
  clutch = new Meter(clutch_x, gas_y, clutchImg.width, clutchImg.height, METER_TYPE.PEDAL); // draw brake pedel
  clutch.setIcon(clutchImg);
  clutch.setSound(pedal_sound);
  clutch.setName("CLUTCH");
  clutch.setValue("A");
  
  brake = new Meter(brake_x, gas_y, brakeImg.width, brakeImg.height, METER_TYPE.PEDAL); // draw brake pedel
  brake.setIcon(brakeImg); 
  brake.setSound(pedal_sound);
  brake.setName("BRAKE");
  brake.setValue("S");
  
  gas = new Meter(gas_x, gas_y, gasImg.width, gasImg.height, METER_TYPE.PEDAL); // draw brake pedel
  gas.setIcon(gasImg);
  gas.setSound(pedal_sound);  
  gas.setName("GAS");
  gas.setValue("D");

  // ! create the instance of mechanism, passing through world dimensions, world instance, reference frame
  mechanisim = new GearShifter(w, h, pixelsPerMeter);
  
  /* Haptic Tool Initialization */
  mechanisim.create_ee();

  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(rendering_force == false && game_state == 1){
    imageMode(CORNER);
    tint(255*0.6); // darken the background a bit by 60%
    image(backgroundGif, 0 ,0, w, h);
    
    rpm_sensor.draw();
    speed_sensor.draw();

    target_text.draw();
    score_text.draw();
    time_text.draw();
  
    clutch.draw();
    brake.draw();
    gas.draw();

    end_button.draw();
    reset_button.draw();

    up_arrow.draw();
    down_arrow.draw();
    
    mechanisim.draw();
    mechanisim.draw_ee(pos_ee.x, pos_ee.y);

    // check the gear
    GEAR cur_gear = mechanisim.getGear(pos_ee);
    if(mechanisim.getPrevGear() != cur_gear){ // check if the gear has changed, add 500ms delay to avoid multiple gear changes
      boolean isGoodShift = shiftGear(cur_gear);

      if(isGoodShift){
        // good shift
        println("Good shift! Current gear: " + cur_gear);
        score_text.increaseValue(10); // 10 points for a good shift
      }else{
        // bad shift

        println("Bad shift!");
        score_text.decreaseValue(10); // 10 points penalty for a bad shift
      }
    }

    // decrase rpm value every 2 frames
    if(frameCount % 2 == 0){
      rpm_sensor.decreaseValue();
    }

    // decrase speed value every 10 frames
    if(frameCount % 10 == 0){
      speed_sensor.decreaseValue();
    }

    // increase time every 5 frames
    if(frameCount % 10 == 0)
      time_text.increaseValue(1);


  }else if(rendering_force == false && game_state == 0){
    imageMode(CORNER);
    image(splashGif, 0 ,0, w, h);

    // draw a rotatign circle at the center of the screen
    pushMatrix();
    translate(w/2, h/2);
    rotate(frameCount * 0.01);
    fill(0);
    ellipse(0, 0, 140 + 10*sin( radians(frameCount % 360))  , 140 + 10*sin( radians(frameCount % 360)) );
    popMatrix();

    mechanisim.draw_ee(pos_ee.x, pos_ee.y);

  } else if (rendering_force == false && game_state == 2){
    // end screen
    imageMode(CORNER);
    image(endGif, 0 ,0, w, h);
  }
}
/* end draw section ****************************************************************************************************/

void keyPressed(){
  
  if(key == 'a' || key == 'A'){
    clutch.press();
    mechanisim.setClutch(true); // engage the clutch
  }
  if(key == 's' || key == 'S'){
    brake.press();
    up_arrow.press();
    down_arrow.press();

    rpm_sensor.decreaseValue(); // decrease the rpm value
    speed_sensor.decreaseValue(); // decrease the speed value
  }
  if(key == 'd' || key == 'D'){
    gas.press();
    rpm_sensor.increaseValue(); // increase the rpm value
    speed_sensor.increaseValue(); // increase the speed value
  }

  if(key == 'x' || key == 'X'){
    if(game_state == 0){
      engine_start.amp(engine_volume);
      start_screen_sound.amp(background_volume*0.5);
      engine_start.play();
      delay((int) (engine_start.duration() * 1000)); // wait for the engine start sound to finish
      start_screen_sound.stop();
      splashGif.stop();
      
      main_screen_sound.amp(background_volume);
      main_screen_sound.loop();
      engine_idle_sound.amp(engine_volume);
      engine_idle_sound.loop();

      game_state = 1; // start game
      backgroundGif.loop(); // play the gif
    }
  }

  if(key == 'r' || key == 'R'){
    // if(game_state == 1){
    //   game_state = 0; // reset game
    //   backgroundGif.stop(); // stop the gif
    //   main_screen_sound.stop();
    //   engine_idle_sound.stop();
    //   start_screen_sound.amp(background_volume);
    //   start_screen_sound.loop();
    //   score_text.setValue(0);
    //   time_text.setValue(0);
    //   high_score_text.setValue(0);
    // }
    reset_button.press();
  }

  if(key == 'e' || key == 'E'){
    end_button.press();
  }


}

void keyReleased(){
  
  if(key == 'a' || key == 'A'){
    clutch.release();
    mechanisim.setClutch(false); // disengage the clutch
  }
  if(key == 's' || key == 'S'){
    brake.release();
    up_arrow.release();
    down_arrow.release();
  }
  if(key == 'd' || key == 'D'){
    gas.release();
  }


  if(key == 'r' || key == 'R'){

    reset_button.release();
  }

  if(key == 'e' || key == 'E'){
    end_button.release();

    // stop the game audio  
    main_screen_sound.stop();
    engine_idle_sound.stop();


    game_state = 2; // end game
    endGif.loop(); // play the gif
  }
}

// helper to shift gears
boolean shiftGear(GEAR gear){
  boolean isGoodShift = mechanisim.setGear(gear);

  if(isGoodShift){

    int min_rpm = mechanisim.getMinRPM();
    int max_rpm = mechanisim.getMaxRPM();
    rpm_sensor.setRange(min_rpm, max_rpm);
  }

  return isGoodShift;
}

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    rendering_force = true;
    
    //  if(haplyBoard.data_available()){
    //   /* GET END-EFFECTOR STATE (TASK SPACE) */
    //   widgetOne.device_read_data();
    
    //   angles.set(widgetOne.get_device_angles()); 
    //   pos_ee.set(widgetOne.get_device_position(angles.array()));
    //   pos_ee.set(mechanisim.device_to_graphics(pos_ee));  


    //   if(game_state == 1)
    //     mechanisim.forcerender(pos_ee);


    //  }    
    //  torques.set(widgetOne.set_device_torques(mechanisim.fEE.array()));
    //  widgetOne.device_write_torques();
  
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/
