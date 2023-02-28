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
    float slotA_W = 0.1;
    float slotA_h = 0.20;

    float slotE_W2 = 0.15 - slotA_W;

    float xa = 0.5-0.45/2, ya = 0.15; // coordinate for A
    float yb = 0.05; // y coordinate for B

    float yaa = 1 - ya;
    float ybb = 1 - yb;

    float scale;
    FLine myLine;

    //  this is the endeffector part
    PShape endEffector;
    float rEE = 1;

    // wall part



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
    public GearShifter(int w, int h, float pixelsPerCm){
        this.w = w - 1;
        this.h = h - 1;

        this.scale = pixelsPerCm;
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



        // FLine leftLine = new FLine(this.scale * this.w * topCoords[0], this.scale * this.h * topCoords[1], this.scale * this.w * bottomCoords[0], this.scale * this.h * bottomCoords[1]);
        // FLine rightLine = new FLine(this.scale * this.w * topCoords[topCoords.length - 2], this.scale * this.h * topCoords[topCoords.length - 1],
        // this.scale * this.w * bottomCoords[bottomCoords.length - 2], this.scale * this.h * bottomCoords[bottomCoords.length - 1]);

        // this.world.add(leftLine);
        // this.world.add(rightLine);

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
        xE = scale * xE *100;
        yE = scale * yE *100; // for conversion betewwen centimeter scale to meter scale
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
        this.endEffector = createShape(ELLIPSE, (xa + slotA_W/2+ (slotA_W + slotE_W2*1.5))*scale*2+w/2, -50.0, 2*rEE*scale, 2*rEE*scale);
        println(xa + slotA_W/2+ (slotA_W + slotE_W2*1.5));
        this.endEffector.setStroke(color(0));
        this.endEffector.setStrokeWeight(5);
        this.endEffector.setFill(color(255,0,0));
    }   

    public PVector forcerender(PVector pos_ee){
        // Start definition of wall, look into vertical walls only first

        /* forces due to walls on end effector */
        PVector fWall = new PVector(0, 0);

        PVector curr_point = new PVector(0, 0);

        float k = 1e4;
        float m1 = 1.0;
        float m2 = 1.0; // needs be negative to mimic the replusion of opposite charges

        // force threshold distance
        float threshold = 0.25*rEE/100.0;
        // top half
        for (int i = 0; i < topCoords.length; i += 2) { // draw the curve that is the slots


            // the current point we care about that we will use to calculate the force from
            // offset x since the new zero is at the centre
            curr_point.set((topCoords[i] - 0.5) * this.w / (this.scale * 100.0), topCoords[i+1] * this.h / (this.scale * 100.0));

            PVector force = PVector.sub(pos_ee, curr_point); // obtain the directtion vecor (final - inital). From end effecor <---- curr_point
            float distance = force.mag();
            
            println(pos_ee);
            //println(distance);
            
            if(distance < threshold){
              float repulsive_f = (k * m1 * m2) / (distance * distance); // model the interaction like gravity/electrostatics float m = (G * mass1 * mass2) / (distance * distance);with replusion
              force.normalize();
              force.mult(repulsive_f);
              fWall = fWall.add(force);
              
              //println(fWall); 
            }
        }

        // bottom half
        for (int i = bottomCoords.length - 2; i >= 0; i -= 2) { // draw the curve
            // offset x since the new zero is at the centre
            curr_point.set((bottomCoords[i] - 0.5) * this.w / (this.scale * 100.0), bottomCoords[i+1] * this.h / (this.scale * 100.0));

            PVector force = PVector.sub(pos_ee, curr_point); // obtain the directtion vecor (final - inital). From end effecor <---- curr_point
            float distance = force.mag();
            
            if(distance < threshold){
              float repulsive_f = (k * m1 * m2) / (distance * distance); 
              force.normalize();
              force.mult(repulsive_f);
              fWall = fWall.add(force);
            }
            

        }
               
      
        return fWall;
    }

    /**
     * @description:  For the first step of the funtion, bringing the end-effector to the center of the workspace
     * @return {*}
     */
    public void resetdevice(){


    }

}
