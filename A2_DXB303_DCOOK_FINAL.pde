/*
DXB303 Programming for Visual Designer
 Assessment 2 - Majour Interactive Work - Playful Experience
 
 Daniel Cook N8404364
 
 This game is a homage to early 80's video games but using the 3D methods and rendering capabilities
 of Processing to optimise the code. Procedural generation has been used as much as possible.
 
 Game Play can be found at https://youtu.be/MenltahkZUY
 
 Sound Samples used:
 
 Laser noise: bubaproducer. 2012. Laser Shot Silenced. Retrieved May 23rd 2017 from http://www.freesound.org/people/bubaproducer/sounds/151022/
 Intro Music: frankum. 2016. Techno 80 - base loop. Retrieved May 23rd 2017 from http://www.freesound.org/people/frankum/sounds/346193/
 Booster noise: primeval_polypod. 2012. Rocket Launch. Retrieved May 23rd 2017 from http://www.freesound.org/people/primeval_polypod/sounds/158894/
 Drum'n'Bass track: sclr. 2009. drilla Rendered.wav. Retrieved May 23rd 2017 from http://www.freesound.org/people/sclr/sounds/66006/
 Explosion: Nbs Dark.2010. Explosion.wav. Retrieved May 23rd 2017 from http://www.freesound.org/people/Nbs%20Dark/sounds/94185/
 
 // The explosion class and the particle class were mostly taken from the processing tutorial
 // Shiffman. D. n.d. Simple Particle System. Retrieved May 23rd 2017 from https://processing.org/examples/simpleparticlesystem.html
 // and modified to suit the program. This included making it 3dimensional and changing the generation methods.

 // Code for the 3D shape draw routine has been heavily based around an example found here:
 // Vantomme. J. 2010. Drawing a Cylinder with Processing. Retrieved May 23rd 2017 from http://vormplus.be/blog/article/drawing-a-cylinder-with-processing
 // The code was assessed and seems to be the best way to generate the shape
 */


// Import Audio System
import ddf.minim.*;

// Configure Audio 
Minim minim;
AudioPlayer backgroundMusic, booster, dnbTrack;
AudioSample laser, explodeSound;

// Load fonts and graphic objects
PFont font, retroFont, gameOverFont, gameTextFont, retroFontSmall;
PShape ship, ufo;

// Global Game Variables ******************************************************************

// Turn on Debug data and graphics
boolean debug = false;

// Sky Variables
int skyArrayNum = 100; // density of sky objects
float[] skyArray=new float[skyArrayNum]; // arrays for Z position
float[] skyArrayHeight=new float[skyArrayNum]; // array for vertical variation
int skyGridSize = 100;
float skyLimitMax = 400;
float skyLimitMin = -8000;

// Ground Plane
int groundArrayNum = 20;
// Generate a 3 dimensional array for manipulating the ground plane
float[] xArray = new float[groundArrayNum]; // x positions
float[] zArray = new float[groundArrayNum]; // z positions
float[][] yArray = new float[groundArrayNum][groundArrayNum]; // height values
float maxHeight = 150; // Max height for terrain

// Ship Variables
float shipX, shipY, shipZ, shipPitch, shipRoll;
// a storage place for the mouse position when we fire the weapon
float originX, originY, targetX, targetY;
boolean weaponFired = false;
// the Z value of the weapon sight plane
float weaponSightPlane = 0;
// The actual 'tested' z value of the camera lens (critical for the 3D Trigonometry in targeting
float cameraZ = 467;
//The 'system' camera eye. I don't know why this isn't the same as the above. Seems silly that the eye isn't where you tell it.
float cameraEyeZ = 300;

// Enemy building variables
int maxBuildings = 50;
int numBuildings = 0;
int[] buildingX = new int[maxBuildings];
int[] buildingZ = new int[maxBuildings];
boolean[] buildingAlive = new boolean[maxBuildings];
int buildingsRemain = 0;
boolean genBuildings = true;


// Start number of buildings per level ********************************************************
int buildingsPerLevel = 4;

// Alien variables
// Start number of aliens per level 
int aliensPerLevel = 4;

int aliensRemaining = aliensPerLevel;
//create alien classes - max number at any time
int maxAliens = 50;
Alien[] alien = new Alien[maxAliens];
PVector alienLocation;

// Explosion class
Explosion explosion;
boolean explosionGo = false;
int explosionTimer;
int explosionTime = 1000;

// gain for booster noise
int boosterGain = -6;

// Central game mechanics
boolean gameRunning = false;
int level = 1;
int lives = 3;
int score = 0;
int lastScore = 0;
// Global game speed control
int gameSpeed =10;
boolean collision = false;
int collisionTimer;
int collisionTime = 3000;

// Targeting accuracy (degrees from camera)
float accuracy = 1.5;

boolean musicOneShotPlay = true;
boolean firstPlay = true;

int endGameTimer = 0;
int endGameTime = 4000;


void setup() { // --------------------------------------------------------------------------------
  size(800, 600, P3D);
  //Load in a space ship designed in tinkerCAD
  ship=loadShape("data/Ship/tinker.obj");
  ufo=loadShape("data/UFO/tinker.obj");

  font = createFont("Geneva", 12, true); 
  retroFont = createFont("spacerangerlasital.ttf", 72);
  retroFontSmall = createFont("spacerangerlasital.ttf", 30);
  gameOverFont = createFont("spacerangeracad.ttf", 96);
  gameTextFont = createFont("planetncompact.ttf", 18);
  textFont(retroFont);
  textAlign(CENTER, CENTER);

  // setup minim audio
  minim = new Minim(this); 
  // load some audio
  backgroundMusic = minim.loadFile("data/introMusic.mp3"); 
  dnbTrack = minim.loadFile("data/drilla.wav");
  booster = minim.loadFile("data/booster1.wav"); 
  laser = minim.loadSample("data/laser-gun.wav"); 
  explodeSound  = minim.loadSample("data/explosion.wav"); 
  
  // Set Audio levels for a balance of SFX and music
  laser.setGain(-15);
  booster.setGain(boosterGain);
  dnbTrack.setGain(-15);
  backgroundMusic.setGain(-10);

  // add lighting for scene
  lights();
  //initialise Ground and Sky generation
  initGroundSky();
  //Initialise Spaceship 
  resetShip();
  // Initialise the alien ships
  for (int i =1; i<aliensPerLevel; i++) {
    alien[i] = new Alien();
  }
  // set the temp variable for the aliens locations. Used in collision impact detection
  alienLocation = new PVector(0, 0, 0);
} //setup -------------------------------------------------------

void draw() { // -------------------------------------------------------

  // if the game is NOT running show the intro or level screen based on whether it is the first play
  if (!gameRunning) {
    background(0);
    // draw the generative ground
    ground();
    // Pause the game music, if it's not already playing, start the intro screen music
    dnbTrack.pause();
    if (musicOneShotPlay) {
      backgroundMusic.loop();
      // set the music start boolean to false to prevent retrigger of the music
      musicOneShotPlay = false;
    }
    
    // if it's the first go, show the intro and instructions
    if (firstPlay) {
      introBoard();
    } else {
      scoreBoard();
    }
    //reset scores and lives
    lives =3;
    score = 0;
    level = 1;
    
  } else { // ******************* Main Run Sequence ***********************

    // If the game is running - play the game
    //Set first play to false to lose the instructions next time around
    firstPlay = false;
    background(0);
    // change the background music over
    backgroundMusic.pause();
    if (musicOneShotPlay) {
      dnbTrack.loop();
      // and flip the boolean to stop it retriggering
      musicOneShotPlay = false;
    }

    // setup Camera with a bit of the ships movement 
    // (eyeX, eyeY, eyeZ, centerX, centerY, centerZ, TargetX, TargetY, TargetZ)
    camera(width/2.0+shipRoll, height/2.0+shipPitch, cameraEyeZ / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);

    // draw the sky
    sky();
    // Draw the ground plane
    ground();
    // Draw a ship
    ship();
    // generate the enemy buildings - pass the number of buildings to the generate procedure
    if (genBuildings) generateEnemyBuildings(buildingsPerLevel);
    // draw the enemy buildings on the landscape
    enemyBuildings();
    // Draw a weapon sight (takes a boolean for sight image change for game features)
    weaponSight(false);
    
    // check for shots fired to check the locations and angles for targeting / hits
    if (weaponFired) weaponFired();
    // if the buildings and aliens are all shot....
    if (buildingsRemain==0 && aliensRemaining <= 1) {
      //increment the number of aliens and buildings (check we're not at max though)
      if (buildingsPerLevel < maxBuildings)buildingsPerLevel +=3;
      if (aliensPerLevel < maxAliens) aliensPerLevel+=3;
      // Make the game move faster
      gameSpeed +=2;
      // Increment our level counter
      level++;
      // regenerate our buildings
      genBuildings=true;
      // regenerate our aliens
      for (int i =1; i<aliensPerLevel; i++) {
        alien[i] = new Alien();
      }
      aliensRemaining = aliensPerLevel;
    }
    // run our alien classes to move position , bounce off boundaries and get 
    for (int i =1; i<aliensPerLevel; i++) {
      alien[i].update();
      alien[i].checkEdges();
      alien[i].display();
    }

    // if an explosion has started, run the explosion class
    if (explosionGo) {
      explosion.run();
      // set a timer to switch off the explosion run
      explosionTimer = millis();
    }
    // check the explosion timer and switch off the explosion if longer than the preset time.
    if (millis() - explosionTimer>explosionTime) {
      explosionGo = false;
    }
    // use a timer to allow detecting collisons and prevent repeat additional collisions too soon.
    if (millis()-collisionTimer>collisionTime) {
      detectCollsions();
    }
    // Use a boolean to control the explosion events
    if (collision) {
      // Call our explosion function with the location of the explosion
      somethingExplodes(shipX, shipY, shipZ);
      // decrement lives
      lives--;
      // reset collision state
      collision = false; 
      //reset timer
      collisionTimer = millis();
    }

    // call the draw the screen information (lives, score, etc)
    screenText();

    // if the lives are out, reset the game and drop the user back to the game over screen
    if (lives ==0) {
      // go to the info screens
      gameRunning = false;
      // Flip the music
      musicOneShotPlay = true;
      // update the high score
      lastScore = score;
      //prevent accidental restarting of the next game (delay for key presses)
      endGameTimer = millis();
      // reset the game to start conditions
      // Start number of buildings per level
      buildingsPerLevel = 4;
      // Start number of aliens per level
      aliensPerLevel = 4;
      //reset speed
      gameSpeed =10;
      // Generate the new buildings
      genBuildings=true;
      // and generate the aliens
      aliensRemaining = aliensPerLevel;
      for (int i =1; i<aliensPerLevel; i++) {
        alien[i] = new Alien();
      }
    }
  } // GameRunning
} // end draw -----------------------------------------------------------------


/*
 *  Many functions for the game play 
 *  Functions have been kept modular for code portability and easy fault finding
 *
 *
 */

// displays the players information during the game.
void screenText() {
  stroke(128);
  noFill();
  pushMatrix();
  translate(0, 0, -10);
  rectMode(CENTER);
  stroke(100, 50, 0);
  // surrounding rectangle
  rect(width/2, height/2, width, height);
  // set our fonts for the text
  textFont(gameTextFont);
  textSize(20);
  fill(255);
  noStroke();
  textAlign(LEFT, CENTER);
  // Provide debug information if enabled.
  if (debug) text("FrameRate:"+int(frameRate), 10, 40, -10);
  if (debug) text("Enemies Left   Buildings:"+buildingsRemain + " Ships:"+ (aliensRemaining-1), 30, 30, -10);
  
  // write our data at the four corners of the screen
  fill(255, 200, 0);
  text("Lives: "+lives, 30, height -25, -10);
  fill(0, 200, 200);
  text("Score: "+score, 30, 25, -10);
  textAlign(RIGHT, CENTER);
  text("High Score: "+lastScore, width-50, 25, -10);
  fill(255, 200, 0);
  text("Level: "+level, width-50, height -25, -10);
  popMatrix();
} // screen text ------------------------


// Show the welcome screen and instructions
void introBoard() {
  textFont(retroFont);
  textAlign(CENTER, CENTER);
  fill(0, 200, 200);
  text("Vector Warrior", width/2, height/5);
  textFont(gameTextFont);
  fill(255, 200, 0);
  // use a common height for ease in changing it
  int textHeight = height/2-80;
  text("Commander, as the last pilot of the earth defense", width/2, textHeight);
  text("fleet you have been sent on a desperate final mission ", width/2, textHeight+30);
  text("to the hostile alien home planet of Flurg Prime -", width/2, textHeight+60);
  text("the source of the alien invasion threatening Earth.", width/2, textHeight+90);
  text("Shoot the towers and alien ships. Don't get hit!", width/2, textHeight+120);
  fill(200, 0, 0);
  text("Keys: A - Left,  D - Right,  W - Up, S - Down.", width/2, textHeight+180);
  text("Mouse to target and left click or Spacebar to fire.", width/2, textHeight+210);
  fill(0, 200, 200);
  textFont(retroFontSmall);
  text("Press any key to start", width/2, textHeight+290);
  // if a key is pressed, start the game!
  if (keyPressed) {
    // toggle the music
    musicOneShotPlay = true;
    // run the game section
    gameRunning=true;
    //initialise Ground and Sky generation
    initGroundSky();
    //Initialise Spaceship 
    resetShip();
  }
}

// show the user their score and get ready for a new game
void scoreBoard() {
  textFont(retroFont);
  textAlign(CENTER, CENTER);
  fill(0, 200, 200);
  text("Vector Warrior", width/2, height/5);
  textFont(gameOverFont);
  fill(255, 200, 0);
  text("Game Over!", width/2, height/5 *2);
  textFont(gameTextFont);
  fill(0, 200, 200);
  text("Score: " + lastScore, width/2, height/5*3);
  text("Press any key to start", width/2, height/5*3+100);

  // if key is pressed after a certain period restart the game, ignore keypresses otherwise
  if (millis() - endGameTimer > endGameTime) {
    if (keyPressed) {
      // reset the endgame timer
      endGameTimer = millis();
      // toggle the music
      musicOneShotPlay = true;
      // run the game
      gameRunning=true;
      //initialise Ground and Sky generation
      initGroundSky();
      //Initialise Spaceship 
      resetShip();
    }
  }
}

// detects the collisions - part 1
// uses the PVectors to store positions. The building side is a bit messy as this was done
// using arrays before I came across the PVector method. Hence I'm converting array data to PVectors
void detectCollsions() {
  //use shipX, shipY, shipZ to detect position of the ship
  PVector shipPV=new PVector(shipX, shipY, shipZ);

  // count through buildings.
  for (int i=0; i<buildingsPerLevel; i++) {
    //convert to PVectors
    PVector buildingPV = new PVector(xArray[buildingX[i]]-width, yArray[buildingX[i]][buildingZ[i]]-50, zArray[buildingZ[i]]);
    // Run the comparison between PVectors
    detectCollsionsCompare(shipPV, buildingPV);
  }
  // count through aliens.
  for (int i =1; i<aliensPerLevel; i++) {
    //set temp variable alienLocation to get the aliens location from the class
    alienLocation = alien[i].getLocation();
    //compare the vector 
    detectCollsionsCompare(shipPV, alienLocation);
  }
}

// detects the collisions - part 2
// takes the two PVectors and gets the distance between them. compares to ProximitySize
void detectCollsionsCompare(PVector ship, PVector enemy) {
  float ProximitySize = 50;
  float proxDistance = ship.dist(enemy);

  // if the ship and an enemy meet,  set collision to true
  if (proxDistance < ProximitySize) {
    if (debug)println(proxDistance);
    // boolean to handle the collision procedures
    collision = true;
  }
}

// function that makes stuff explode. See the classes tab for the method!
void somethingExplodes(float x, float y, float z) {
  // Setup the explosion class at the location of the enemy hit
  explosion = new Explosion(new PVector(x, y, z));
  // Generate all the particles
  explosion.startExplosion();
  // set the class run boolean to true
  explosionGo = true;
  // Set the gain on the explosion sample to be louder closer, quieter further away
  explodeSound.setGain(map(z, 0, -3000, 0, -15));
  // Play the sound
  explodeSound.trigger();
}

// This function checks the weapon fire and calculates the alignment of target sights 
// and the enemy objects in 3D space
void weaponFired() {
  // Use various strokes to create a laser with a 'hot' core and a plasma 'sheath'
  stroke(170, 0, 0);
  strokeWeight(6);
  line(originX, originY-5, shipZ-10, targetX, targetY, weaponSightPlane);
  stroke(255, 100, 0);
  strokeWeight(3);
  line(originX, originY-5, shipZ-10, targetX, targetY, weaponSightPlane);
  stroke(255, 200, 0);
  strokeWeight(1);
  line(originX, originY-5, shipZ-10, targetX, targetY, weaponSightPlane);
  // Play the sound sample for the laser fire
  laser.trigger();

  // The hard bit - Calculating the 3 dimensional trigonometry of every enemy object in order to match the
  // X and y angles for camera-target to the x & y angles for the camera-weapon sights.

  // Calculate mouse pointer angle from centre 
  // above center is negative. Left of centre is negative 
  float adjX = mouseX-width/2;
  float adjY = mouseY-height/2;
  // distance to cursor plane from camera eye
  float opp = abs(weaponSightPlane)+abs(cameraZ); //cameraEyeZ);
  float hyp = sqrt(opp*opp + adjX*adjX);
  float angleX = degrees(atan(opp/adjX));
  float angleY = degrees(atan(opp/adjY));

  if (debug) println();
  if (debug) println("Cursor Xangle: "+angleX+", Yangle:"+angleY+" opp:"+opp+" adjX:"+adjX);
  if (debug) println();

  // Make two arrays to hold building angles for X & Y (stored as degrees for readability)
  float [] buildingTrigAngleX = new float[numBuildings];
  float [] buildingTrigAngleY = new float[numBuildings];

  for (int i=0; i<numBuildings; i++) {
    // X angle from camera to building is atan(opposite/adjacent sides)
    //use Z and X as our triangle sides 
    stroke(200);
    // X distance from centre for adjacent angle
    float adjBuild = ((xArray[buildingX[i]]-width)-width/2);
    // distance to building in the z plane + distance to camera eye (use abs to make both positive - avoid weird results)
    float oppBuild = abs(cameraZ)+abs(zArray[buildingZ[i]]);
    // Calculate angle with atan
    buildingTrigAngleX[i] = degrees(atan(oppBuild/adjBuild));
    if (debug) print(", oppBuild:"+oppBuild+ ", adjBuild: "+adjBuild+" XArr:"+xArray[buildingX[i]]);
    if (debug) print("  #"+i+", BuildAngX: "+buildingTrigAngleX[i]);

    // This time use Y and Z as our triangle sides
    adjBuild = yArray[buildingX[i]][buildingZ[i]]-height/2-50;
    //we can reuse the oppBuild Value as we are still using the Z plane as our opposite side
    buildingTrigAngleY[i] = degrees(atan(oppBuild/adjBuild));

    if (debug) print(", BuildAngX: "+ buildingTrigAngleY[i]);
    if (debug) println();

    // if the building is 'alive' - i.e. not hit...
    if (buildingAlive[i]) {
      //compare it to the cursor angle - if they match - its a hit
      if (angleX - accuracy <= buildingTrigAngleX[i] && angleX + accuracy >= buildingTrigAngleX[i]) {
        if (debug)println("X HIT! "+ i);
        if (angleY - accuracy -3<= buildingTrigAngleY[i] && angleY + accuracy +3>= buildingTrigAngleY[i]) {
          if (debug)println("Y HIT! " +i);
          //remove the building from the alive array
          buildingAlive[i] = false;
          // make an explosion at the coordinates
          somethingExplodes(xArray[buildingX[i]]-width, yArray[buildingX[i]][buildingZ[i]], zArray[buildingZ[i]]);
          //decrement buildings remaining
          buildingsRemain -= 1;
          // Add score
          score +=10;
        }
      }
    }// if alive
  } // num buildings loop


  // Now do the same with the aliens...
  for (int i =1; i<aliensPerLevel; i++) {
    //set temp variable alienLocation to get the aliens location from the class
    alienLocation = alien[i].getLocation();
    // X distance from centre for adjacent angle
    float adjAlien = (alienLocation.x-width/2);
    // distance to alien in the z plane + distance to camera eye (use abs to make both positive - avoid weird results)
    float oppAlien = abs(cameraZ)+abs(alienLocation.z);
    // Calculate angle with atan
    float alienAngleX = degrees(atan(oppAlien/adjAlien));
    // This time use Y and Z as our triangle sides
    adjAlien = alienLocation.y-height/2;
    // Calculate angle with atan
    float alienAngleY = degrees(atan(oppAlien/adjAlien));

    // Compare the angle from camera of the aliens with that of the cursor
    if (angleX - 1 <=alienAngleX && angleX + 1 >= alienAngleX) {
      if (debug)println("X HIT! "+ i);
      if (angleY - 1 <= alienAngleY && angleY + 1 >= alienAngleY) {
        if (debug)println("Y HIT! " +i);
        // remove the alien from the field of play (class call)
        alien[i].hit();
        somethingExplodes(alienLocation.x, alienLocation.y, alienLocation.z );
        //decrement the number of aliens
        aliensRemaining--;
        //increment the score
        score +=20;
      }
    }
  } // for
  // reset the weapon fired boolean
  weaponFired=false;
}



void enemyBuildings() {
  for (int i=0; i<numBuildings; i++) {
    pushMatrix();
    // Go to the terrain coordinates of the buildings as generated in 'generateEnemyBuildings'
    //translate(xArray[buildingX[i]],yArray[buildingX[i]][buildingZ[i]],zArray[buildingZ[i]]);
    translate(xArray[buildingX[i]]-width, yArray[buildingX[i]][buildingZ[i]]-50, zArray[buildingZ[i]]);
    if (debug) {
      int textSz = 18;
      textSize(textSz);
      textAlign(LEFT, CENTER);
      fill(250);
      noStroke();
      fill(250, 250, 0);
      textSize(30);
      text("#"+ i, 35, -190, 0);
      fill(250);
      textSize(textSz);
      text("x:"+(xArray[buildingX[i]]-width), 0, -150, 0);
      text("y:"+(yArray[buildingX[i]][buildingZ[i]]), 0, -150+textSz+2, 0);
      text("z:"+zArray[buildingZ[i]], 0, -150+textSz*2+2, 0);
    }
    if (zArray[buildingZ[i]]<weaponSightPlane) {
      stroke(170, 120, 0);
    } else {
      stroke(0);
    }
    if (!buildingAlive[i]) {
      stroke(255, 0, 0);
    }
    fill(75);
    //straighten up the shapes
    rotateX(radians(-90));
    rotateZ(radians(45));
    // if the building exists, draw it!
    if (buildingAlive[i]) {
      draw3Dshape(5, 20, 100);
    }
    popMatrix();
  }
} // end void enemy buildings




void generateEnemyBuildings(int buildings) {
  // Police our input values to prevent array errors
  if (buildings<maxBuildings+1) {
    // lets make this global for other functions such as drawing, selecting and destruction
    numBuildings = buildings;
    buildingsRemain = buildings;
    for (int i=0; i<buildings; i++) {
      // randomly generate coordinates for the number of buildings
      buildingX[i] = int(random(0, groundArrayNum-1));
      buildingZ[i] = int(random(0, groundArrayNum-1));
      buildingAlive[i] = true;
    }
  } else {
    if (debug) println("Too many buildings for array!");
  }
  genBuildings = false;
}// void generate enemy buildings ---------------




void weaponSight(boolean onTarget) {
  // lose the default mouse cursor, make a cooler one.
  noCursor();
  // Push it
  pushMatrix();
  // centre on mouse cursor
  translate(mouseX, mouseY, weaponSightPlane);
  stroke(255);
  fill(0, 0);
  rectMode(CENTER);
  // draw a cross hairs
  line(-12, 0, -2, 0);
  line(2, 0, 12, 0);
  line(0, -12, 0, -2);
  line(0, 2, 0, 12);
  // draw a rectangle and then a diamond around it
  stroke(170, 0, 0);
  rect(0, 0, 10, 10);
  if (debug) {
    textSize(10);
    fill(200);
    noStroke();
    text("x:"+(mouseX), 35, 0, 0);
    text("y:"+(mouseY), 35, 12, 0);
  }
  rotateZ(radians(45));
  noFill();
  if (onTarget) {
    stroke(150, 0, 0);
    rect(0, 0, 28, 28);
  } else {
    stroke(100);
    rect(0, 0, 25, 25);
  }
  // pop the translate stack back
  popMatrix();
} // weapon sight -----------------------




void mousePressed() {
  // Fire the weapon! log the origin point and the target points
  targetX=mouseX;
  targetY=mouseY;
  originX=shipX;
  originY=shipY;
  // set the fired variable - let's us control the fire rate later
  weaponFired = true;
}




void keyPressed() {
  //process keypresses
  switch(key) {
    // Pew pew! Space bar Fire button as well as mouse click   
  case ' ': 
    // Fire the weapon! log the origin point and the target points
    targetX=mouseX;
    targetY=mouseY;
    originX=shipX;
    originY=shipY;
    // set the fired variable - let's us control the fire rate later
    weaponFired = true;
    break;
  }
} //keyPressed





void ship() {
  int moveSpeed = gameSpeed/5;
  // Scan for key presses in the ship routine to ensure the keys repeat
  // which doesn't happen on all platforms with keyPressed.
  if (keyPressed) {
    booster.setGain(boosterGain);
    switch(key) {
      // Up key
    case 's':              
    case 'S': 
      // check for screen limits
      if (!booster.isPlaying()) {
        booster.rewind();
        booster.play();
      }
      if (shipY<400) {
        shipY+=moveSpeed;
        // Do a nice angled move over time
        if (shipPitch<30) {
          shipPitch++;
        } else {
          shipPitch = 30;
        }
      }
      break;
      // down key
    case 'w':              
    case 'W': 
      // check for screen limits
      if (!booster.isPlaying()) {
        booster.rewind();
        booster.play();
      }
      if (shipY>190) {
        shipY-=moveSpeed;
        // Do a nice angled move over time
        if (shipPitch>-30) {
          shipPitch--;
        } else {
          shipPitch = -30;
        }
      }
      break;

      // Right key
    case 'd':              
    case 'D': 
      if (!booster.isPlaying()) {
        booster.rewind();
        booster.play();
      }
      // check for screen limits
      if (shipX<520) {
        shipX+=moveSpeed;
        // Do a nice angled move over time
        if (shipRoll<30) {
          shipRoll++;
        } else {
          shipRoll = 30;
        }
      }
      break;

      // Left Key
    case 'a':              
    case 'A': 
      if (!booster.isPlaying()) {
        booster.rewind();
        booster.play();
      }
      // check for screen limits
      if (shipX> 270) {
        shipX-=moveSpeed;
        // Do a nice angled move over time
        if (shipRoll>-30) {
          shipRoll--;
        } else {
          shipRoll = -30;
        }
      }
      break;
    } // end key switch
  } else {

    // Reset pitch when not being driven with a little rudimentary smoothing
    if (shipPitch>0) {
      shipPitch--;
      booster.setGain(booster.getGain()-1);
    } else if (shipPitch<0) {
      shipPitch++;
      booster.setGain(booster.getGain()-1);
    } else {
      shipPitch=0;
    }
    // Reset  Roll when not being driven with a little rudimentary smoothing
    if (shipRoll>0) {
      shipRoll--;
      booster.setGain(booster.getGain()-1);
    } else if (shipRoll<0) {
      shipRoll++;
      booster.setGain(booster.getGain()-1);
    } else {
      shipRoll=0;
    }
    if (shipRoll ==0 && shipPitch ==0) {
      booster.setGain(-100);
    }
  } // keyPressed else end

  lights();
  pushMatrix();
  translate(shipX, shipY, shipZ);
  // pitch (nose up/down)- do a little policing on the supplied value
  if (shipPitch>-90 && shipPitch <180) {
    rotateX(radians(90+shipPitch));
  }

  if (shipRoll>=0) {
    rotateY(radians(0+shipRoll));
  } else {
    rotateY(radians(360+shipRoll));
  }
  //yaw (rotate through y axis) - Don't use...
  rotateZ(radians(180));
  //Draw the ship
  shape(ship);

  //draw a force shield
  noStroke();

  ellipseMode(CENTER);
  rotateX(radians(90));
  // Set the force field colour based on the remaining lives
  fill(0, 0, 200, 50);
  if (lives==3) fill(0, 200, 0, 50);
  if (lives==2) fill(200, 200, 0, 65);
  if (lives==1) fill(200, 0, 0, 85);
  //draw the force field   
  ellipse(0, 0, 50, 20);
  //sphere(23); // or use a sphere
  popMatrix();
}  // ship ------------------------

void resetShip() {
  shipX = width/2;
  shipY = height/4*2.5;
  shipZ = 300;
  shipRoll = 0;
  shipPitch = 0;
} // reset ship ------------------------



void draw3Dshape(int sides, float shapeX, float shapeY) {
  // Code from this routine has been heavily based around an example found here:
  // http://vormplus.be/blog/article/drawing-a-cylinder-with-processing
  // Seems to be the most efficient way to build a 3D shape...
  float angle =360/sides;
  // create a shape part
  beginShape();
  // use a loop to generate the number of surfaces
  for (int i = 0; i < sides; i++) {
    // work out the x and y's...
    float x = cos(radians(i*angle))*shapeX;
    float y = sin(radians(i*angle))*shapeX;
    //draw the vertex ( no uv mapping as of yet :) )
    vertex(x, y, -shapeY/2);
  }
  endShape(CLOSE);
  // draw bottom shape
  beginShape();
  for (int i = 0; i < sides; i++) {
    float x = cos(radians(i*angle))*shapeX;
    float y = sin(radians(i*angle))*shapeX;
    vertex(x, y, shapeY/2);
  }
  endShape(CLOSE);
  // draw body
  beginShape(TRIANGLE_STRIP);
  for (int i = 0; i < sides + 1; i++) {
    float x = cos(radians(i*angle))*shapeX;
    float y = sin(radians(i*angle))*shapeX;
    vertex(x, y, shapeY/2);
    vertex(x, y, -shapeY/2);
  }
  endShape(CLOSE);
}// draw 3dshape -----------------------------

void initGroundSky() {

  // initialise SkyArray -----------
  for (int i=0; i< skyArrayNum; i++) {
    skyArray[i] = random(skyLimitMin, skyLimitMax);
    skyArrayHeight[i] = random(-height/3, height/4);
  }

  // initialise GroundArray -----------
  // x positions
  for (int x=0; x< groundArrayNum; x++) {
    //Populate two arrays with the X and Z coordinates for easy access later
    // width is multiplied by 3 to get additional terrain either side
    xArray[x] = (width*3)/groundArrayNum*x;
    // funky bit of maths to calculate division sizes from the horizon variables
    zArray[x]= skyLimitMin+x*(((skyLimitMin-skyLimitMax)*-1)/groundArrayNum);
    // and add height data for each position
    for (int z=0; z< groundArrayNum; z++) {
      //set the height
      yArray[x][z] = height/3*2+random(0, maxHeight);
    }
  } // end ground array init.
}

void ground() {
  for (int z=0; z< groundArrayNum; z++) {
    for (int x=0; x< groundArrayNum; x++) {
      stroke(255, 255, 255);
      point(xArray[x]-width, yArray[x][z]-5, zArray[z]);
      stroke(0, 100, 100);
      if (x<groundArrayNum-1) {
        //width is shifted over by 1 x width as we are using 3xwidth for the x terrain generation
        line(xArray[x]-width, yArray[x][z], zArray[z], xArray[x+1]-width, yArray[x+1][z], zArray[z]);
      }
      // test for position loop to prevent drawing from one end to other
      if (z<groundArrayNum-1 && zArray[z]<zArray[z+1]) {
        line(xArray[x]-width, yArray[x][z], zArray[z], xArray[x]-width, yArray[x][z+1], zArray[z+1]);
      }
    }//x
    // increment the position by the game speed variable
    zArray[z]+=gameSpeed;
    //test for limits and reset to start
    if (zArray[z]>skyLimitMax) {
      zArray[z] = skyLimitMin+(((skyLimitMin-skyLimitMax)*-1)/groundArrayNum);
    }
  }//z
}


void sky() { // ********************SKY*********************

  rectMode(CENTER);
  // Draw the sky elements one at a time
  for (int j=0; j<skyArrayNum; j++) {
    //ramp up the brightness based on distance from the camera to enhance depth perception.
    stroke(map(skyArray[j], skyLimitMin, skyLimitMax, 0, 200-map(skyArrayHeight[j], 0, height/3, 50, 0)));
    fill(map(skyArray[j], skyLimitMin, skyLimitMax, 10, 100-map(skyArrayHeight[j], 0, height/3, 50, 0)));
    pushMatrix();
    // Vary the x and z placement using the arrays, make it wide (3 widths)
    translate(-width+width*3/skyArrayNum*j, skyArrayHeight[j], skyArray[j]);
    //Rotate the rectangles parallel to the plane of play
    rotateX(radians(90));
    rect(0, 0, skyGridSize, skyGridSize);
    popMatrix();

    skyArray[j] += gameSpeed;
    if (skyArray[j] > skyLimitMax) {
      skyArray[j] = skyLimitMin;
    }
  }
}