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

/* world size in pixels */
int w = 1000;
int h = 400;

/* define gear mechanisim */
GearShifter mechanisim;

/* define sensors */
Meter game_sensor, rpm_sensor, speed_sensor;
Meter brake, gas, clutch;

PImage brakeImg, clutchImg, gasImg;

int rpm_value = 500;
int current_time = 0;
int last_time = 0;

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
  haplyBoard          = new Board(this, "COM9", 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  
  //start: added to fix inverse motion of the ball
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);

  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  

  widgetOne.device_set_parameters();
  mechanisim = new GearShifter(1000, 400);

  //game_sensor = = new Meter(150,150, 200, 100, 10, color(153);
  rpm_sensor = new Meter(800, 50, 200, 100, 10, color(255), "RPM"); // 
  speed_sensor = new Meter(800, 150, 200, 100, 10, color(255), "KM/HR");
  
  // pedels
  clutchImg = loadImage("../imgs/clutch.png");
  brakeImg = loadImage("../imgs/brake.png");
  gasImg = loadImage("../imgs/gas.png");
  
 
  
  clutch = new Meter(950 - 75*2, 300, clutchImg.width*0.15, clutchImg.height*0.15, 10, color(255), ""); // draw brake pedel
  clutch.setIcon(clutchImg);
  
  brake = new Meter(950 - 75, 300, brakeImg.width*0.15, brakeImg.height*0.15, 10, color(255), ""); // draw brake pedel
  brake.setIcon(brakeImg); 
  
  gas = new Meter(950, 300, gasImg.width*0.15, gasImg.height*0.15, 10, color(255), ""); // draw brake pedel
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
    mechanisim.draw();
    mechanisim.draw_ee(pos_ee.x, pos_ee.y);
  speed_sensor.draw();
  
  clutch.draw();
  brake.draw();
  gas.draw();

  current_time = millis();
  if(current_time - last_time > 1000){
    last_time = current_time;
    rpm_value+=100;
    rpm_sensor.setValue(nf(rpm_value, 4,0));
    speed_sensor.setValue(nf(rpm_value/10.0, 3, 0));
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
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      pos_ee.set(widgetOne.get_device_position(angles.array()));
      pos_ee.set(mechanisim.device_to_graphics(pos_ee));  
      // println(pos_ee);


      // TODO add relavent force feedback codes right here
      mechanisim.forcerender(pos_ee);

      //TODO end

    }    
    torques.set(widgetOne.set_device_torques(mechanisim.fEE.array()));
    widgetOne.device_write_torques();
  
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/
