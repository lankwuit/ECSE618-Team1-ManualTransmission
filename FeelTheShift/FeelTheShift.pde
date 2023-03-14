/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;
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

/* brake, gas, clutch position definitions in pixels*/
int clutch_x = 50;
int brake_x = 50 + 75;
int gas_x = 50 + 75*2;
int gas_y = 300;

Meter brake, gas, clutch;
PImage brakeImg, clutchImg, gasImg;

/* rpm & speed sensor size definitons in pixels */
int rpm_x = 800;
int rpm_y = 50;
int rpm_w = 200;
int rpm_h = 100;

int speed_x = 800;
int speed_y = 150;
int speed_w = 200;
int speed_h = 100;

/* define sensors */
Meter game_sensor, rpm_sensor, speed_sensor;

int rpm_value = 500;
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
  // haplyBoard          = new Board(this, "COM9", 0);
  // widgetOne           = new Device(widgetOneID, haplyBoard);
  // pantograph          = new Pantograph();
  
  // widgetOne.set_mechanism(pantograph);
  
  // //start: added to fix inverse motion of the ball
  // widgetOne.add_actuator(1, CCW, 2);
  // widgetOne.add_actuator(2, CW, 1);

  // widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  // widgetOne.add_encoder(2, CW, -61, 10752, 1);
  

  // widgetOne.device_set_parameters();

  //game_sensor = = new Meter(150,150, 200, 100, 10, color(153);
  rpm_sensor = new Meter(rpm_x, rpm_y, rpm_w, rpm_h, METER_TYPE.RPM); // 
  speed_sensor = new Meter(speed_x, speed_y, speed_w, speed_h, METER_TYPE.SPEED);
  
  // pedels
  clutchImg = loadImage("../imgs/clutch.png");
  brakeImg = loadImage("../imgs/brake.png");
  gasImg = loadImage("../imgs/gas.png");
  
 
  
  clutch = new Meter(clutch_x, gas_y, clutchImg.width*0.15, clutchImg.height*0.15, METER_TYPE.PEDAL); // draw brake pedel
  clutch.setIcon(clutchImg);
  
  brake = new Meter(brake_x, gas_y, brakeImg.width*0.15, brakeImg.height*0.15, METER_TYPE.PEDAL); // draw brake pedel
  brake.setIcon(brakeImg); 
  
  gas = new Meter(gas_x, gas_y, gasImg.width*0.15, gasImg.height*0.15, METER_TYPE.PEDAL); // draw brake pedel
  gas.setIcon(gasImg);  
  
  rpm_sensor.setValue(nf(0, 4,0)); // format like 0000;
  speed_sensor.setValue(nf(0, 3, 0)); // format like 000
  

  // ! create the instance of mechanism, passing through world dimensions, world instance, reference frame
  mechanisim = new GearShifter(w, h, pixelsPerMeter);
  
  /* Haptic Tool Initialization */
  
  mechanisim.draw();
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
  
  if(rendering_force == false){
    background(255);
    
    rpm_sensor.draw();
  
    clutch.draw();
    brake.draw();
    gas.draw();
    
    mechanisim.draw();
    mechanisim.draw_ee(pos_ee.x, pos_ee.y);

    // current_time = millis();
    // if(current_time - last_time > 1000){
    //   last_time = current_time;
    //   rpm_value+=100;
    //   rpm_sensor.setValue(nf(rpm_value, 4,0));
    //   speed_sensor.setValue(nf(rpm_value/10.0, 3, 0));
    // }
  }
}
/* end draw section ****************************************************************************************************/

void keyPressed(){
  
  if(key == 'a' || key == 'A')
    clutch.press();
  if(key == 's' || key == 'S')
    brake.press();
  if(key == 'd' || key == 'D')
    gas.press();
}

void keyReleased(){
  
  if(key == 'a' || key == 'A')
    clutch.release();
  if(key == 's' || key == 'S')
    brake.release();
  if(key == 'd' || key == 'D')
    gas.release();
}

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    rendering_force = true;
    
    // if(haplyBoard.data_available()){
    //   /* GET END-EFFECTOR STATE (TASK SPACE) */
    //   widgetOne.device_read_data();
    
    //   angles.set(widgetOne.get_device_angles()); 
    //   pos_ee.set(widgetOne.get_device_position(angles.array()));
    //   pos_ee.set(mechanisim.device_to_graphics(pos_ee));  


    //   // TODO add relavent force feedback codes right here
    //   mechanisim.forcerender(pos_ee);

    //   //TODO end

    // }    
    // torques.set(widgetOne.set_device_torques(mechanisim.fEE.array()));
    // widgetOne.device_write_torques();
  
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/
