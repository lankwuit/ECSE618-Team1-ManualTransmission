/*
 *                        _oo0oo_
 *                       o8888888o
 *                       88" . "88
 *                       (| -_- |)
 *                       0\  =  /0
 *                     ___/`---'\___
 *                   .' \\|     |// '.
 *                  / \\|||  :  |||// \
 *                 / _||||| -:- |||||- \
 *                |   | \\\  - /// |   |
 *                | \_|  ''\---/''  |_/ |
 *                \  .-\__  '-'  ___/-. /
 *              ___'. .'  /--.--\  `. .'___
 *           ."" '<  `.___\_<|>_/___.' >' "".
 *          | | :  `- \`.;`\ _ /`;.`/ - ` : | |
 *          \  \ `_.   \_ __\ /__ _/   .-` /  /
 *      =====`-.____`.___ \_____/___.-`___.-'=====
 *                        `=---='
 * 
 * 
 *      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *      NO BUG PLS
 */

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
    
    float kpwall = 700;
    float kiwall = 500;
    float kismooth =300;
    float curvefactor = 0.06;
    float initial_offset = 0.0;
    float ballCreationYPosition = 0.0;

    float scale;
    
    PVector penWall = new PVector(0, 0);
    PVector fWall   = new PVector(0, 0);
    PVector fEE    = new PVector(0, 0);

    //  this is the endeffector part
    PShape endEffector;
    float rEE = 0.014;//in terms of meter
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
    float smoothingw = 0.40;
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
        stroke(0);

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
        fill(255, 0, 0);
        noStroke();
        ellipseMode(CENTER);
        for (int i = 0; i < topCoords.length; i += 2) { // show the coordinate points chosen in red
            ellipse(this.w * topCoords[i], this.h * topCoords[i + 1], 3, 3);
        }

        fill(0, 255, 0);
        for (int i = bottomCoords.length - 2; i >= 0; i -= 2) { // // show the coordinate points chosen in green
            ellipse(this.w * bottomCoords[i], this.h * bottomCoords[i + 1], 3, 3);
        }

        
    }

    /**
     * @description: Draw function specifally for the end_effector
     * @return {*}
     */    
    public void draw_ee(float xE, float yE){
        xE = scale * xE;
        yE = scale * yE; // multiplying scale for converting meter scale to pixels
        
        translate(xE,yE);
        shape(this.endEffector);
        
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
        this.endEffector.setFill(color(255,0,0));
    }   
    
    float[] curvecenter = {
        topCoords[2], topCoords[1], //below B
        topCoords[14], topCoords[13], //below H
        topCoords[26], topCoords[25], //below N
        bottomCoords[2], bottomCoords[1], //above B
        bottomCoords[14], bottomCoords[13], //above H
        bottomCoords[26], bottomCoords[25] //above N
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

        /*change coordinate of the posEE to the actual coordinate that we are using */
        PVector posReltoCustomSpace = new PVector(0, 0);
        posReltoCustomSpace.set(posEE.x+w/2/scale, posEE.y-yinitial);

        //check if the initial position tuning has passed
        //if (!initialFlag){
        //    initialHandler(posReltoCustomSpace);
        //    return;
        //}

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
        }else if (bottomCoords[1]*h/scale < posReltoCustomSpace.y  && posReltoCustomSpace.y < bottomCoords[3]*h/scale){
            if(bottomCoords[0]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[8]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[6],curvecenter[7]);
            }else if(bottomCoords[8]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[20]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[8],curvecenter[9]);
            }else if(bottomCoords[20]*w/scale < posReltoCustomSpace.x && posReltoCustomSpace.x < bottomCoords[28]*w/scale){
                penWall = curveforcerender(posReltoCustomSpace,curvecenter[10],curvecenter[11]);
            };
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
        }else if(topCoords[1]*h/scale<=posReltoCustomSpace.y && posReltoCustomSpace.y< bottomCoords[7]*h/scale){
            penWall.set(
                abs(topCoords[0]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[0]*w/scale>posReltoCustomSpace.x ? (topCoords[0]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[0]*w/scale-posReltoCustomSpace.x+rEE)):(
                                    abs(topCoords[28]*w/scale- posReltoCustomSpace.x)<rEE ? (topCoords[28]*w/scale>posReltoCustomSpace.x ? (topCoords[28]*w/scale-posReltoCustomSpace.x-rEE):(topCoords[28]*w/scale-posReltoCustomSpace.x+rEE)):0
                                )
            ,0);
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
        }else{
            penWall.set(0,0);
        }
        
        temp = penWall.x;
        //for DEF, JKL etc.
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
        temp2 = penWall.y;
        penWall.set(temp,temp2);
        //finding force
        forcePDcompute();
        PDSmoothing(posEE);
        fWall = fWall.add(penWall.mult(-kpwall));  
        fWall = fWall.add(velWall.mult(kiwall));  
        fWall = fWall.add(smoothwall.mult(-kismooth));  
        println(fWall);
        
        fEE = (fWall.copy()).mult(-1);
        fEE.set(graphics_to_device(fEE));
        /* end haptic wall force calculation */
    }

    private void forcePDcompute(){
        long timedif = System.nanoTime()-oldtimew;

        float dist_X = penWall.x;
        float dist_Y = penWall.y;
        
        if(timedif > 0) {
            buffwx = (dist_X-oldexw)/timedif*1000*1000;
            buffwy = (dist_Y-oldeyw)/timedif*1000*1000;            

            diffwx = smoothing*diffwx + (1.0-smoothing)*buffwx;
            diffwy = smoothing*diffwy + (1.0-smoothing)*buffwy;
            oldexw = dist_X;
            oldeyw = dist_Y;
            oldtimew=System.nanoTime();
        };
        velWall.set(diffwx,diffwy);

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

    PVector device_to_graphics(PVector deviceFrame){
        return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
    }


    PVector graphics_to_device(PVector graphicsFrame){
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
