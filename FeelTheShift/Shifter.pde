import java.util.Map;


enum GEAR{REVERSE, NEUTRAL, ONE, TWO, THREE, FOUR, FIVE}; // types of meters

HashMap<String,Integer> min_rpms = new HashMap<String,Integer>();
HashMap<String,Integer> max_rpms = new HashMap<String,Integer>();




// class the creates and displays the gear shifting mechanisim
public class GearShifter{

    int w,h; // width and height of the canvas in pixels
    float yinitial =0.02214294; //this is in term of meter.
    float slotA_W = 0.1;
    float slotA_h = 0.20;

    float slotE_W2 = 0.15 - slotA_W;

    float xa = 0.5-0.45/2, ya = 0.15; // coordinate for A
    float yb = 0.05; // y coordinate for B

    boolean initialFlag = false;

    float yaa = 1 - ya;
    float ybb = 1 - yb;
    
    // ****************************** //
    // Bereket's parameters
    float kpwall = 800*10; // Bereket: I need to multiply by 10 to make it work
    float kiwall = 200*10;
    float kismooth= 700*10;
    float kdwall = 650*10;
    float curvefactor = 0.05*2;
    float neutralRecoveryForce = 2.5*75; // Bereket : I need to multiply by 75 to make it work
    // ****************************** //

    // ****************************** //
    // uncomment this to use the old parameters
    //  float kpwall = 800;
    //  float kiwall = 200;
    //  float kismooth= 700;
    //  float kdwall = 650;
    //  float curvefactor = 0.1;
    //  float neutralRecoveryForce = 2.5;
    // ****************************** //
    
    float initial_offset = 0.0;
    float ballCreationYPosition = 0.0;
    float cumerrorwx = 0.0;
    float cumerrorwy = 0.0;
    PVector cumpenWall = new PVector(0,0);

    float scale;
    GEAR prev_gear = GEAR.NEUTRAL; // previous state of the gear shifter
    boolean clutch = false; // clutch is pressed or not
    
    PVector penWall = new PVector(0, 0);
    PVector fWall   = new PVector(0, 0);
    PVector fEE    = new PVector(0, 0);

    boolean showForce = false;

    //  this is the endeffector part
    PShape endEffector;
    float rEE = 0.012;//in terms of meter
    float curveREEallowance = 0.004;

    // regarding to the differentiator
    // used to compute the time difference between two loops for differentiation
    long oldtime = 0;
    long oldtimew = 0;
    //for exponential filter on differentiation
    PVector velWall = new PVector(0, 0);
    PVector smoothwall = new PVector(0, 0);
    float diffwx = 0;
    float diffwy = 0;
    float buffwx = 0;
    float buffwy = 0;
    float diffx = 0;
    float diffy = 0;
    float buffx = 0;
    float buffy = 0;
    float smoothingw = 0.90;
    float smoothing = 0.80;
    // checking everything run in less than 1ms
    long timetaken= 0;

    // set loop time in usec (note from Antoine, 500 is about the limit of my computer max CPU usage)
    int looptime = 500;
    
    // for D
    float oldexw = 0.0f;
    float oldeyw = 0.0f;
    float oldex = 0.0f;
    float oldey = 0.0f;

    // font
    int font_size = 32;
    PFont font = createFont("../fonts/PressStart.ttf", this.font_size, true);

    // the coordinates of curve to draw; must have 2n enteries so that (x/w,y/h) = topCoords[i], topCoords[i+1]
    // top left to top right
    float[] topCoords = {
        xa,                                 ya,                                 // A
        xa + slotA_W/2,                     yb,                                 // B
        xa + slotA_W,                       ya,                                 // C
        xa + slotA_W,                       ya + slotA_h,                       // D
        xa + slotA_W + slotE_W2*0.75,       ya + slotA_h + slotE_W2,            // E
        xa + slotA_W + slotE_W2*1.5,        ya + slotA_h,                       // F

        xa                              + (slotA_W + slotE_W2*1.5),        ya,                                 // G
        xa + slotA_W/2                  + (slotA_W + slotE_W2*1.5),        yb,                                 // H
        xa + slotA_W                    + (slotA_W + slotE_W2*1.5),        ya,                                 // I
        xa + slotA_W                    + (slotA_W + slotE_W2*1.5),        ya + slotA_h,                       // J
        xa + slotA_W + slotE_W2*0.75    + (slotA_W + slotE_W2*1.5),        ya + slotA_h + slotE_W2,            // K
        xa + slotA_W + slotE_W2*1.5     + (slotA_W + slotE_W2*1.5),        ya + slotA_h,                       // L

        xa                              + 2*(slotA_W + slotE_W2*1.5),        ya,                                 // M
        xa + slotA_W/2                  + 2*(slotA_W + slotE_W2*1.5),        yb,                                 // N
        xa + slotA_W                    + 2*(slotA_W + slotE_W2*1.5),        ya,                                 // O

    };

    // going from bottom left to bottom right
    float[] bottomCoords = {
        xa,                                 yaa,                                 // A
        xa + slotA_W/2,                     ybb,                                 // B
        xa + slotA_W,                       yaa,                                 // C
        xa + slotA_W,                       yaa - slotA_h,                       // D
        xa + slotA_W + slotE_W2*0.75,       yaa - slotA_h - slotE_W2,            // E
        xa + slotA_W + slotE_W2*1.5,        yaa - slotA_h,                       // F

        xa                              + (slotA_W + slotE_W2*1.5),        yaa,                                 // G
        xa + slotA_W/2                  + (slotA_W + slotE_W2*1.5),        ybb,                                 // H
        xa + slotA_W                    + (slotA_W + slotE_W2*1.5),        yaa,                                 // I
        xa + slotA_W                    + (slotA_W + slotE_W2*1.5),        yaa - slotA_h,                       // J
        xa + slotA_W + slotE_W2*0.75    + (slotA_W + slotE_W2*1.5),        yaa - slotA_h - slotE_W2,            // K
        xa + slotA_W + slotE_W2*1.5     + (slotA_W + slotE_W2*1.5),        yaa - slotA_h,                       // L

        xa                              + 2*(slotA_W + slotE_W2*1.5),        yaa,                                 // M
        xa + slotA_W/2                  + 2*(slotA_W + slotE_W2*1.5),        ybb,                                 // N
        xa + slotA_W                    + 2*(slotA_W + slotE_W2*1.5),        yaa,                                 // O

    };

    // constructor
    public GearShifter(int w, int h, float pixelsPerMeter){
        this.w = w - 1;
        this.h = h - 1;

        this.scale = pixelsPerMeter;
        this.ballCreationYPosition = (0-yinitial)*scale;
    }

  
    public void draw(){
        noFill();
        stroke(255);
        strokeWeight(4);  // default is 4

        // top half
        for (int i = 0; i < topCoords.length; i += 2) { // draw the curve that is the slots

            if(i > 0 && abs(topCoords[i] - topCoords[i-2]) < 0.001){
                line(this.w * topCoords[i-2], this.h * topCoords[i - 1], this.w * topCoords[i], this.h * topCoords[i + 1]); // vertical lines inside
            }
            else if(i > 2 && (topCoords[i+1] - topCoords[i+1-2]) > 0 && abs(topCoords[i+1] - topCoords[i+1-2 -2]) < 0.00001 ){ // top arcs
                ellipseMode(RADIUS);
                arc(this.w * topCoords[i- 2], this.h * topCoords[i + 1 - 2 - 2], 0.5*slotA_W*this.w, (ya - yb)*this.h, PI, 2*PI);
            }
            else if(i > 2 && (topCoords[i+1] - topCoords[i+1-2]) < 0 && abs(topCoords[i+1] - topCoords[i+1-2 -2]) < 0.00001 ){ // bottom arcs
                ellipseMode(RADIUS);
                arc(this.w * topCoords[i- 2], this.h * topCoords[i + 1 - 2 - 2], 0.75*slotE_W2*this.w, slotE_W2*this.h, 2*PI, 3*PI);
            }
        }

        // bottom half
        for (int i = bottomCoords.length - 4; i >= 0; i -= 2) { // draw the curve

            if(abs(bottomCoords[i] - bottomCoords[i+2]) < 0.001){ // compare this and previous one
                line(this.w * bottomCoords[i+2], this.h * bottomCoords[i + 1 + 2], this.w * bottomCoords[i], this.h * bottomCoords[i + 1]); // verical line that is inside
            }
            else if(i < bottomCoords.length - 4 && (bottomCoords[i+1] - bottomCoords[i+1+2]) > 0 && abs(bottomCoords[i+1] - bottomCoords[i+1 + 2 + 2]) < 0.00001 ){ // top arcs
                ellipseMode(RADIUS);
                arc(this.w * bottomCoords[i + 2], this.h * bottomCoords[i + 1 + 2 + 2], 0.75*slotE_W2*this.w, slotE_W2*this.h, PI, 2*PI);
            }
            else if(i < bottomCoords.length - 4 && (bottomCoords[i+1] - bottomCoords[i+1 + 2]) < 0 && abs(bottomCoords[i+1] - bottomCoords[i+1 + 2 + 2]) < 0.00001 ){ // bottom arcs
                ellipseMode(RADIUS);
                arc(this.w * bottomCoords[i + 2], this.h * bottomCoords[i + 1 + 2 + 2], 0.5*slotA_W*this.w, (ya - yb)*this.h, 2*PI, 3*PI);
            }
            
        }

        // side lines
        line(this.w * topCoords[0], this.h * topCoords[1], this.w * bottomCoords[0], this.h * bottomCoords[1]);
        line(this.w * topCoords[topCoords.length - 2], this.h * topCoords[topCoords.length - 1], this.w * bottomCoords[bottomCoords.length - 2], this.h * bottomCoords[bottomCoords.length - 1]);


        // highlighting the interesection points of the pattern
        strokeWeight(4); //back to default
        ellipseMode(CENTER);

        // draw the gear numbers on the pattern
        float height_scale = 0.1;
        fill(255);
        textFont(this.font, this.font_size); // specify font
        textAlign(CENTER, CENTER);

        text("N", this.w/2, this.h/2);

        text("1", this.w * topCoords[2], this.h * topCoords[3] + this.h *  height_scale );
        text("2", this.w * bottomCoords[2], this.h * bottomCoords[3] - this.h *  height_scale  );

        text("3", this.w * topCoords[14], this.h * topCoords[15] + this.h *  height_scale );
        text("4", this.w * bottomCoords[14], this.h * bottomCoords[15] - this.h *  height_scale );

        text("5", this.w * topCoords[topCoords.length - 4], this.h * topCoords[topCoords.length - 4 + 1] + this.h *  height_scale );
        text("R", this.w * bottomCoords[bottomCoords.length - 4], this.h * bottomCoords[bottomCoords.length - 4 + 1] - this.h *  height_scale );

        
    }

    /**
     * @description: Draw function specifally for the end_effector
     * @return {*}
     */    
    public void draw_ee(float xE, float yE){
        PVector posEE = new PVector(xE, yE);
        xE = scale * xE;
        yE = scale * yE; // multiplying scale for converting meter scale to pixels
        
        pushMatrix();
        translate(xE,yE);
        shape(this.endEffector);
        popMatrix();
        
        // draw current gear on shifter
        PVector posReltoCustomSpace = new PVector(0, 0);
        posReltoCustomSpace.set(posEE.x+this.w / 2 / this.scale, posEE.y - this.yinitial);
        GEAR cur_gear = getGear(posEE);

        
        if(game_state == 0)
            cur_gear = GEAR.NEUTRAL;

        fill(255);
        textFont(this.font, 40); // specify font
        textAlign(CENTER, CENTER);

        float x = posReltoCustomSpace.x * this.scale;
        float y = posReltoCustomSpace.y * this.scale;

        switch(cur_gear){
            case REVERSE:
                text("R", x, y);
                break;
            case NEUTRAL:
                text("N", x, y);
                break;
            case ONE:
                text("1", x, y);
                break;
            case TWO:
                text("2", x, y);
                break;
            case THREE:
                text("3", x, y);
                break;
            case FOUR:
                text("4", x, y);
                break;
            case FIVE:
                text("5", x, y);
                break;
        }


        // draw the force vector on the end effector
        if(showForce){
            pushMatrix();
            strokeWeight(2);
            stroke(255);

            float l = fWall.mag(); // length of the force vector

            translate(xE,yE); // translate to the centre of the end effector
            rotate(atan2(fWall.x, fWall.y)); // rotate the force vector to the direction of the force vector
            line(0, 0, l, 0); // draw a line from the centre of the end effector to the end of the force vector
            
            translate(l, 0); // translate to the end of the force vector
            float a = radians(150);
            float x1 = 8 * cos(a);
            float y1 = 8 * sin(a);
            line(0, 0, -x1, y1); // draw the top part of the arrow
            line(0, 0, -x1, -y1); // draw the bottom part of the arrow
            popMatrix();
        }
    }
    

    /**
     * @description: create the shape of the end-effector
     *
     * @return 
     */
    public void create_ee(){
        // creating the end effector at middle - top of the canvas initially
        // initial x position is refferred to the coordinate of H
        this.endEffector = createShape(ELLIPSE, topCoords[14]*w, ballCreationYPosition, 2*rEE*scale, 2*rEE*scale);
        this.endEffector.setStroke(color(0));
        this.endEffector.setStrokeWeight(5);
        this.endEffector.setFill(color(0,0,0));
    }   
    
    float[] curvecenter = {
        topCoords[2], topCoords[1], //below B
        topCoords[14], topCoords[13], //below H
        topCoords[26], topCoords[25], //below N
        bottomCoords[2], bottomCoords[1], //above B
        bottomCoords[14], bottomCoords[13], //above H
        bottomCoords[26], bottomCoords[25] //above N
    };
    
    float[] neutralCenter ={
        topCoords[14], (topCoords[15]+bottomCoords[15])/2
    };
    
    PVector curveforcerender(PVector posReltoCustomSpace, float centerx, float centery){
        //这个方程在已经进入那么所在区之后进行条件判断
        //什么时候turned on呢， 判断euclidean distance 在圆弧范围之内的时候
        PVector temp = new PVector(centerx*w/scale,centery*h/scale);
        float distance =PVector.dist(posReltoCustomSpace,temp);
        float penamount = rEE-curveREEallowance +distance - slotA_W;
        if(PVector.dist(posReltoCustomSpace,temp)<rEE){ // see if this is the right curve that is near the right ee
            PVector angle=PVector.sub(posReltoCustomSpace,temp); // for angle calculation
            temp.set(penamount* curvefactor*angle.normalize().x, penamount*curvefactor*angle.normalize().y);
        }else{
            temp.set(0,0);
        }
        return temp;

    }

    public void forcerender(PVector posEE){
        // Start definition of wall, look into vertical walls only first
        // sarting from the left most wall


        /* haptic wall force calculation */
        this.fWall.set(0, 0);
        this.penWall.set(0,0);

        /*change coordinate of the posEE to the actual coordinate that we are using */
        PVector posReltoCustomSpace = new PVector(0, 0);
        posReltoCustomSpace.set(posEE.x+this.w / 2 / this.scale, posEE.y - this.yinitial);

        // * topcord 是按照 % width 来做的，width 为常量关于pixel的 posEE是按照米的 ，rEE 是按照M的
        float temp = 0.0, temp2=0.0;
        //force feedback for all vertical walls
        if (topCoords[3]*h/scale < posReltoCustomSpace.y  && posReltoCustomSpace.y < topCoords[1]*h/scale){
            if(topCoords[0]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < topCoords[8]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[0],curvecenter[1]);
            }else if(topCoords[8]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < topCoords[20]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[2],curvecenter[3]);
            }else if(topCoords[20]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < topCoords[28]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[4],curvecenter[5]);
            };
              
            fWall = fWall.add(velWall.mult(kdwall));  
            fWall = fWall.add(cumpenWall.mult(-kiwall));
        }else if (bottomCoords[1]*h/scale < posReltoCustomSpace.y  && posReltoCustomSpace.y < bottomCoords[3]*h/scale){
            if(bottomCoords[0]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[8]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[6],curvecenter[7]);
            }else if(bottomCoords[8]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[20]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[8],curvecenter[9]);
            }else if(bottomCoords[20]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[28]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[10],curvecenter[11]);
            };
        
            fWall = fWall.add(velWall.mult(kdwall));  
            fWall = fWall.add(cumpenWall.mult(-kiwall));
        }else if(topCoords[1]*h/scale<=posReltoCustomSpace.y && posReltoCustomSpace.y< topCoords[7]*h/scale){
            penWall.set(
                abs(topCoords[0]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[0]*w/scale>posReltoCustomSpace.x ? (topCoords[0]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[0]*w/scale-posReltoCustomSpace.x+rEE)):(
                    abs(topCoords[4]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[4]*w/scale>posReltoCustomSpace.x ? (topCoords[4]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[4]*w/scale-posReltoCustomSpace.x+rEE)):(
                        abs(topCoords[10]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[10]*w/scale>posReltoCustomSpace.x ? (topCoords[10]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[10]*w/scale-posReltoCustomSpace.x+rEE)):(
                            abs(topCoords[16]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[16]*w/scale>posReltoCustomSpace.x ? (topCoords[16]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[16]*w/scale-posReltoCustomSpace.x+rEE)):(
                                abs(topCoords[22]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[22]*w/scale>posReltoCustomSpace.x ? (topCoords[22]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[22]*w/scale-posReltoCustomSpace.x+rEE)):(
                                    abs(topCoords[28]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[28]*w/scale>posReltoCustomSpace.x ? (topCoords[28]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[28]*w/scale-posReltoCustomSpace.x+rEE)):0
                                )
                            )
                        ) 
                    )
                )
            ,0);
            cumpenWall.set(0,0);
            cumerrorwx=0.0;
            cumerrorwy=0.0;
        }else if(topCoords[1]*h/scale<=posReltoCustomSpace.y && posReltoCustomSpace.y< bottomCoords[7]*h/scale){
            penWall.set(
                abs(topCoords[0]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[0]*w/scale>posReltoCustomSpace.x ? (topCoords[0]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[0]*w/scale-posReltoCustomSpace.x+rEE)):(
                                    abs(topCoords[28]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[28]*w/scale>posReltoCustomSpace.x ? (topCoords[28]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[28]*w/scale-posReltoCustomSpace.x+rEE)):0
                                )
            ,0);
            cumpenWall.set(0,0);
            cumerrorwx=0.0;
            cumerrorwy=0.0;
        }else if(bottomCoords[7]*h/scale<=posReltoCustomSpace.y && posReltoCustomSpace.y< bottomCoords[1]*h/scale){
            penWall.set(
                abs(bottomCoords[0]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[0]*w/scale>posReltoCustomSpace.x ? (bottomCoords[0]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[0]*w/scale-posReltoCustomSpace.x+rEE)):(
                    abs(bottomCoords[4]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[4]*w/scale>posReltoCustomSpace.x ? (bottomCoords[4]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[4]*w/scale-posReltoCustomSpace.x+rEE)):(
                        abs(bottomCoords[10]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[10]*w/scale>posReltoCustomSpace.x ? (bottomCoords[10]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[10]*w/scale-posReltoCustomSpace.x+rEE)):(
                            abs(bottomCoords[16]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[16]*w/scale>posReltoCustomSpace.x ? (topCoords[16]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[16]*w/scale-posReltoCustomSpace.x+rEE)):(
                                abs(bottomCoords[22]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[22]*w/scale>posReltoCustomSpace.x ? (bottomCoords[22]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[22]*w/scale-posReltoCustomSpace.x+rEE)):(
                                    abs(bottomCoords[28]*w/scale- posReltoCustomSpace.x)<rEE ? (bottomCoords[28]*w/scale>posReltoCustomSpace.x ? (bottomCoords[28]*w/scale-posReltoCustomSpace.x-rEE):(bottomCoords[28]*w/scale-posReltoCustomSpace.x+rEE)):0
                                )
                            )
                        ) 
                    )
                )
            ,0);     
            cumpenWall.set(0,0);    
            cumerrorwx=0.0;
            cumerrorwy=0.0;   
        }else{
            penWall.set(0,0);
        }
        
        temp = penWall.x;
        //for DEF, JKL etc, including clutch interactions

        if(topCoords[6]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[10]*w/scale){
            penWall.set(0,
                abs(topCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (topCoords[7]*h/scale>posReltoCustomSpace.y ? (topCoords[7]*h/scale-posReltoCustomSpace.y+rEE):(topCoords[7]*h/scale-posReltoCustomSpace.y+rEE)):(
                    abs(bottomCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (bottomCoords[7]*h/scale>posReltoCustomSpace.y ? (bottomCoords[7]*h/scale-posReltoCustomSpace.y-rEE):(bottomCoords[7]*h/scale-posReltoCustomSpace.y-rEE)):0
                )
            );
        }else if(topCoords[18]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[22]*w/scale){
            penWall.set(0,
                abs(topCoords[19]*h/scale- posReltoCustomSpace.y)<rEE ? (topCoords[19]*h/scale>posReltoCustomSpace.y ? (topCoords[19]*h/scale-posReltoCustomSpace.y+rEE):(topCoords[19]*h/scale-posReltoCustomSpace.y+rEE)):(
                    abs(bottomCoords[19]*h/scale- posReltoCustomSpace.y)<rEE ? (bottomCoords[19]*h/scale>posReltoCustomSpace.y ? (bottomCoords[19]*h/scale-posReltoCustomSpace.y-rEE):(bottomCoords[19]*h/scale-posReltoCustomSpace.y-rEE)):0
                )
            );
        }

        if(!clutch){
            if(topCoords[0]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[4]*w/scale){
                penWall.add(0,
                    abs(topCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (topCoords[7]*h/scale-posReltoCustomSpace.y+rEE):(
                        abs(bottomCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (bottomCoords[7]*h/scale-posReltoCustomSpace.y-rEE):0
                    )
                );
            }else if(topCoords[12]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[16]*w/scale){
                penWall.add(0,
                    abs(topCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (topCoords[7]*h/scale-posReltoCustomSpace.y+rEE):(
                        abs(bottomCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (bottomCoords[7]*h/scale-posReltoCustomSpace.y-rEE):0
                    )
                );
            }else if(topCoords[24]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[28]*w/scale){
                penWall.add(0,
                    abs(topCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (topCoords[7]*h/scale-posReltoCustomSpace.y+rEE):(
                        abs(bottomCoords[7]*h/scale- posReltoCustomSpace.y)<rEE ? (bottomCoords[7]*h/scale-posReltoCustomSpace.y-rEE):0
                    )
                );
            }
        }

        //for center zone recovery
        if(topCoords[9]*h/scale<=posReltoCustomSpace.y && posReltoCustomSpace.y< bottomCoords[9]*h/scale && topCoords[0]*w/scale<=posReltoCustomSpace.x && posReltoCustomSpace.x<= topCoords[28]*w/scale){
            NeutralCentering(posEE);
        }



        temp2 = penWall.y;
        penWall.set(temp,temp2);
        //finding force
        forcePDcompute();
        PDSmoothing(posEE);
        fWall = fWall.add(penWall.mult(-kpwall));  
        fWall = fWall.add(smoothwall.mult(kismooth));  
        
        fEE = (fWall.copy()).mult(-1);
        fEE.set(graphics_to_device(fEE));
        /* end haptic wall force calculation */
    }



    private void forcePDcompute(){
        long timedif = System.nanoTime()-oldtimew;

        float dist_X = penWall.x;
        cumerrorwx += dist_X*timedif*0.000000001;
        float dist_Y = penWall.y;
        cumerrorwy += dist_Y*timedif*0.000000001;
        
        if(timedif > 0) {
            buffwx = (dist_X-oldexw)/timedif*1000*1000;
            buffwy = (dist_Y-oldeyw)/timedif*1000*1000;            

            diffwx = smoothingw*diffwx + (1.0-smoothingw)*buffwx;
            diffwy = smoothingw*diffwy + (1.0-smoothingw)*buffwy;
            oldexw = dist_X;
            oldeyw = dist_Y;
            oldtimew=System.nanoTime();
        };
        velWall.set(diffwx,diffwy);
        cumpenWall.set(cumerrorwx,cumerrorwy);

    }

    private void PDSmoothing(PVector posEE){
        long timedif = System.nanoTime()-oldtime;

        float dist_X = posEE.x;
        float dist_Y = posEE.y;
        
        if(timedif > 0) {
            buffx = (dist_X-oldex)/timedif*1000*1000;
            buffy = (dist_Y-oldey)/timedif*1000*1000;            

            diffx = smoothing*diffx + (1.0-smoothing)*buffx;
            diffy = smoothing*diffy + (1.0-smoothing)*buffy;
            oldex = dist_X;
            oldey = dist_Y;
            oldtime=System.nanoTime();
        };
        smoothwall.set(diffx,diffy);

    }

    private void NeutralCentering(PVector posEE){
        float dist_X = (posEE.x+w/2/scale) - neutralCenter[0]*w/scale;
        float dist_Y = (posEE.y-yinitial) - neutralCenter[1]*h/scale;
        
        if(abs(dist_X)>rEE){
            if(dist_X<0){
                fWall.add(-neutralRecoveryForce,0);
            }else{
                fWall.add(neutralRecoveryForce,0);
            }
        }
        if(abs(dist_Y*h/scale)>0.75*rEE){
            if(dist_Y<0){
                fWall.add(0,-neutralRecoveryForce);
            }else{
                fWall.add(0,neutralRecoveryForce);
            }

        }
        
    }

        public GEAR getGear(PVector posEE){

        /*change coordinate of the posEE to the actual coordinate that we are using */
        PVector posReltoCustomSpace = new PVector(0, 0);
        posReltoCustomSpace.set(posEE.x+this.w / 2 / this.scale, posEE.y - this.yinitial);

        // check the location of the handle to determine the gear
        GEAR cur_gear;
        if(posReltoCustomSpace.x < this.w * this.topCoords[8] / this.scale){ // E in our sketch
            // left half of the shifter
            if(posReltoCustomSpace.y < this.h * this.topCoords[7] / this.scale){ // D in our sketch
                // top half of the shifter
                cur_gear = GEAR.ONE;
            }
            else if(posReltoCustomSpace.y > this.h *this.bottomCoords[7] / this.scale){ // D in our sketch
                // bottom half of the shifter
                cur_gear = GEAR.TWO;
            }else{
                // center of the shifter
                cur_gear = GEAR.NEUTRAL;
            }

        }
        else if (posReltoCustomSpace.x > this.w * this.topCoords[20] / this.scale){ // K in our sketch
            // right half of the shifter
            if(posReltoCustomSpace.y < this.h * this.topCoords[19] / this.scale){ // J in our sketch
                // top half of the shifter
                cur_gear = GEAR.FIVE;
            }
            else if(posReltoCustomSpace.y > this.h * this.bottomCoords[19] / this.scale){ // J in our sketch
                // bottom half of the shifter
                cur_gear = GEAR.REVERSE;
            }else{
                // center of the shifter
                cur_gear = GEAR.NEUTRAL;
            }

        }
        else {
            // center of the shifter
             if(posReltoCustomSpace.y < this.h * this.topCoords[19] / this.scale ){ // J in our sketch
                // top half of the shifter
                cur_gear = GEAR.THREE;
            }
            else if(posReltoCustomSpace.y > this.h * this.bottomCoords[19] / this.scale){ // J in our sketch
                // bottom half of the shifter
                cur_gear = GEAR.FOUR;
            }else{
                // center of the shifter
                cur_gear = GEAR.NEUTRAL;
            }
        }
        return cur_gear;
    }



    public boolean setGear(GEAR g){
        this.prev_gear = g; // change the last gear

        if(this.clutch == false){ // clutch is not engaged
            // Grind Gear force added in the shifter section. Right now it is more of a wall effect
            // TODO: ADD SOUND EFFECT
            // TODO: ADD VISUAL EFFECT
            return false; // cannot change gear

        } 
        // TODO: ADD VISUAL EFFECT
        return true; // gear changed
    }

    public void setClutch(boolean clutch){
        this.clutch = clutch;
    }

    public GEAR getPrevGear(){
        return this.prev_gear; // get the last gear that was set
    }



    /*
    The minimum RPM to switch into a given gear
    */
    public int getMinRPM(GEAR cur_gear){
        switch(cur_gear){
            case ONE:
            case TWO:
            case THREE:
            case FOUR:
            case FIVE:
                return 3000;
            case REVERSE:
                return 1000;
            default:
                return 3000;
        }
    }


    /*
    The maximum RPM to switch into a given gear
    */
    public int getMaxRPM(GEAR cur_gear){

        switch(cur_gear){
            case ONE:
            case TWO:
            case THREE:
            case FOUR:
            case FIVE:
                return 7000;
            case REVERSE:
                return 1500;
            default:
                return 7000;
        }
    }


    /** 
    * This functions sets the showForce variable to true or false
    * @param showForce if set to true, the force will be shown on the screen as a vector
    */
    public void showForce(boolean showForce){
        this.showForce = showForce;
    }

    PVector device_to_graphics(PVector deviceFrame){
        return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
    }


    public PVector graphics_to_device(PVector graphicsFrame){
        return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
    }
    /**
     * @description:  For the first step of the funtion, bringing the end-effector to the center of the workspace
     * @return {*}
     */
    public void resetdevice(){
        widgetOne.device_set_parameters();
    }

}
