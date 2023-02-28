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
    
    PVector penWall = new PVector(0, 0);

    //  this is the endeffector part
    PShape endEffector;
    float rEE = 0.02;



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
        yE = scale * yE; // for conversion betewwen centimeter scale to meter scale
        
        ellipseMode(CENTER);
        fill(0, 255, 0);
        ellipse(topCoords[14]*w,topCoords[15]*h,scale *0.02,0.02*scale);
        translate(xE,yE);
        println(xE,yE);
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
        this.endEffector = createShape(ELLIPSE, topCoords[14]*w, -50.0, rEE*scale, rEE*scale);
        this.endEffector.setStroke(color(0));
        this.endEffector.setStrokeWeight(5);
        this.endEffector.setFill(color(255,0,0));
    }   

    public void forcerender(PVector posEE){
        // Start definition of wall, look into vertical walls only first
        // sarting from the left most wall
        // * topcord 是按照 % width 来做的，width 为常量关于pixel的 posEE是按照米的 ，rEE 是按照M的
        posEE.x =posEE.x*scale;
        posEE.y =posEE.y*scale;
        if (topCoords[3]*w < posEE.y * scale && posEE.y*scale < topCoords[1]*w){
            //TODO adding the half circle forceback here
        }else if(posEE.y*scale < topCoords[7]*w){
            penWall.set(
                abs(topCoords[0]*w/scale- posEE.x)<rEE ? (topCoords[0]*w/scale>posEE.x ? (topCoords[0]*w/scale-posEE.x-rEE):(-topCoords[0]*w/scale+posEE.x+rEE)):(
                    abs(topCoords[4]*w/scale- posEE.x)<rEE ? (topCoords[4]*w/scale>posEE.x ? (topCoords[4]*w/scale-posEE.x-rEE):(-topCoords[4]*w/scale+posEE.x+rEE)):(
                        abs(topCoords[10]*w/scale- posEE.x)<rEE ? (topCoords[10]*w/scale>posEE.x ? (topCoords[10]*w/scale-posEE.x-rEE):(-topCoords[10]*w/scale+posEE.x+rEE)):(
                            abs(topCoords[16]*w/scale- posEE.x)<rEE ? (topCoords[16]*w/scale>posEE.x ? (topCoords[16]*w/scale-posEE.x-rEE):(-topCoords[16]*w/scale+posEE.x+rEE)):(
                                abs(topCoords[22]*w/scale- posEE.x)<rEE ? (topCoords[22]*w/scale>posEE.x ? (topCoords[22]*w/scale-posEE.x-rEE):(-topCoords[22]*w/scale+posEE.x+rEE)):(
                                    abs(topCoords[28]*w/scale- posEE.x)<rEE ? (topCoords[28]*w/scale>posEE.x ? (topCoords[28]*w/scale-posEE.x-rEE):(-topCoords[28]*w/scale+posEE.x+rEE)):0
                                )
                            )
                        ) 
                    )
                )
            ,0);
        }
    }

    /**
     * @description:  For the first step of the funtion, bringing the end-effector to the center of the workspace
     * @return {*}
     */
    public void resetdevice(){

        return;
    }

}
