//Create the alien class
class Alien {
  // setup the vectors, starting point and hit boolean
  PVector location;
  PVector velocity;
  float screenDepth = -4000;
  boolean exists = true;

  Alien() {
    //Set alien generation parameters
    location = new PVector(random(width), random(height-300), screenDepth); 
    velocity = new PVector(random(0.5, 0.3), random(0.4, 0.3), random(2, 24));
    exists = true;
  }

    // make it move by adding the velocity
  void update() {
    location.add(velocity);
  }


// if it hasn't been hit, show it
  void display() {
    //check they exist!
    if (exists) {
      // change the colour if too close for weapons
      if (location.z < 0) {
        stroke(255, 0, 0);
        fill(175);
      } else {
        stroke(0, 0, 0);
        fill(80,0,0);
      }
      
      pushMatrix();
      // move to the location and draw the alien
      translate(location.x, location.y, location.z);
      //ellipse(0, 0, 40, 40);
      rotateX(radians(90));
      // draw a UFO (created on tinkerCad)
      shape(ufo);
      popMatrix();
    }
  }

  void checkEdges() {
    //bounce from side to side if it goes too wide
    if (location.x >width || location.x<0) {
      velocity.x *= -1;
    } 
    if (location.y >height-200 || location.y<100) {
      velocity.y *= -1;
    } 
    // redraw it if it moves too far towards us.
    if (location.z >300) {
      location.z=screenDepth;
    }
  } //check edges

  // if it has been hit (i.e. doesn't exist), move waaaay into the Z axis
  PVector getLocation() {
    if (!exists) {
      location.x = 0;
      location.y=0;
      location.z=-8000;
    }
    return location;
  }

// if it gets hit, cease to exist
  void hit() {
    exists=false;
  }


// reset the alien to a new position
  void reset() {
    location = new PVector(random(width), random(height-300), screenDepth); 
    velocity = new PVector(random(0.4, 0.2), random(0.2, 0.3), random(2, 20));
    exists=true;
  }
} // end class Alien



// The explosion class and the particle class were based heavily on the processing tutorial
// https://processing.org/examples/simpleparticlesystem.html
// and modified to suit the program. This included making it 3dimensional and changing the generation methods.

class Explosion{
  // setup our class
  ArrayList<Particle> particles;
  PVector origin;
  
  // setup the initial starting point
 Explosion(PVector position) {
    origin = position.copy();
    // new class of particles
    particles = new ArrayList<Particle>();
  }
  
  // add a particle to the target point
  void addParticle() {
    particles.add(new Particle(origin));
  }
  
  // we want a limited and exciting explosion so just make twenty particles that fly off quickly
  void startExplosion(){
    for(int i=0;i<20;i++){
    particles.add(new Particle(origin));
    }
  }
  
  // keep them moving away from origin, i.e. run the individual particles
  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      // check the lifetime... and remove in necessary
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}//class explosion


// this is the class that is used in the class above - the individual particle
class Particle {
  // set it up
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  // make the velocity easy to change
  int velocityConst = 10; 

  // creation method (constructor)
  Particle(PVector l) {
    acceleration = new PVector(0, 0.01,0);
    velocity = new PVector(random(-velocityConst, velocityConst), random(-velocityConst, velocityConst),random(-velocityConst, velocityConst));
    position = l.copy();
    lifespan = 50.0;
  }

  void run() {
    update();
    display();
  }

  // Method to update position - add the acceleration and the velocity
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 1.0;
  }

  // Method to display
  void display() {
    // make a random red-yellow colour for the particles with an opacity based on longevity
    stroke(random(200,255),random(120,180),0, lifespan*5);
    fill(random(200,255),random(120,180),0, lifespan*5);
    pushMatrix();
    translate(position.x, position.y, position.z);
    ellipse(0,0, 8, 8);
    popMatrix();
  }

  // check to see if its alive.
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}