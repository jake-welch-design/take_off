import processing.video.*;
import com.hamoid.*;
import gab.opencv.*;

Movie video;
VideoExport videoExport;
OpenCV opencv;

PGraphics pg, mask, grain, text;
PShape takeoff;

color bg = 255;
color primary = 0;

int vidLength = 15;
int frames = 60;
int delay = 5;
int grainAmt = 100;

void setup() {
  size(1080, 1920);
  frameRate(frames);
  background(bg);

  ( video = new Movie(this, "plane_vertical.mp4")).loop();
  while (video.height == 0 ) delay(2);

  pg = createGraphics(width, height);
  mask = createGraphics(width, height);
  grain = createGraphics(width, height);
  text = createGraphics(width, height);

  takeoff = loadShape("take-off.svg");

  opencv = new OpenCV(this, width, height);
  opencv.startBackgroundSubtraction(5, 3, 0.1);

  videoExport = new VideoExport(this, "export.mp4");
  videoExport.setFrameRate(frames);
  videoExport.startMovie();
  videoExport.setQuality(100, 0);
}

void movieEvent(Movie video) {
  video.read();
  video.speed(0.08);
}

void draw() {

  opencv.loadImage(video);
  opencv.updateBackground();
  opencv.dilate();
  opencv.erode();

  text.beginDraw();
  text.clear();
  text.shape(takeoff, 60, 100);
  text.endDraw();

  pg.beginDraw();
  pg.clear();
  pg.image(video, 0, 0);
  pg.endDraw();

  mask.beginDraw();
  mask.stroke(255);
  mask.noFill();
  // Draw the contours onto the mask
  for (Contour contour : opencv.findContours()) {
    mask.beginShape();
    for (PVector point : contour.getPoints()) {
      mask.vertex(point.x, point.y);
    }
    mask.endShape(CLOSE);
  }
  mask.endDraw();

  PImage videoMasked = pg.get();
  videoMasked.mask(mask.get());

  grain.beginDraw();
  grain.background(0);
  grain.image(videoMasked, 0, 0);
  //FILM GRAIN EFFECT
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      float noise = random(-grainAmt, grainAmt);
      color c = grain.get(i, j);
      color grainColor = color(red(c) + noise, green(c) + noise, blue(c) + noise);
      grain.set(i, j, grainColor);
    }
  }
  grain.endDraw();

  push();
  fill(0);
  rect(0, 0, width, height);
  pop();

  push();
  image(grain, 0, 0);
  pop();

  if (frameCount > (frames * 10) + delay) {
    if (frameCount % 60 < 30) {
      push();
      image(text, 0, 0);
      pop();
    }
  }

  if (frameCount > delay) {
    videoExport.saveFrame();
  }
  if (frameCount >= (frames * vidLength) + delay) {
    videoExport.endMovie();
    exit();
  }
}
