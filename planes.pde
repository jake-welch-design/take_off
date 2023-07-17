/*
Code by jakewelch.design
https://www.instagram.com/jakewelch.design/
Text & video files can be downloaded here ->
https://drive.google.com/drive/folders/1mqtWtVxpZFgODPhzK0Yxs-ZVHhVHE1FW?usp=drive_link
*/ 

//import libraries
import processing.video.*;
import com.hamoid.*;
import gab.opencv.*;

Movie video;
VideoExport videoExport;
OpenCV opencv;

//PGraphics layers 
PGraphics pg, mask, grain, text;

//Text shape
PShape takeoff;

//Background & primary colors
color bg = 255;
color primary = 0;

//video export settings
int vidLength = 15;
int frames = 60;
int delay = 5;
int grainAmt = 100;

void setup() {
  size(1080, 1920);
  frameRate(frames);

//put background in setup instead of draw to create trailing effect
  background(bg);

//initialize video
  ( video = new Movie(this, "plane_vertical.mp4")).loop();
  while (video.height == 0 ) delay(2);

//initialize layers
  pg = createGraphics(width, height);
  mask = createGraphics(width, height);
  grain = createGraphics(width, height);
  text = createGraphics(width, height);

//initialize text shape
  takeoff = loadShape("take-off.svg");

//initialize computer vision library
  opencv = new OpenCV(this, width, height);
  opencv.startBackgroundSubtraction(5, 3, 0.1);

//initialize video export
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
//open cv settings for finding contours (see opencv examples for find contours)
  opencv.loadImage(video);
  opencv.updateBackground();
  opencv.dilate();
  opencv.erode();

//draw text layer
  text.beginDraw();
  text.clear();
  text.shape(takeoff, 60, 100);
  text.endDraw();

//display video
  pg.beginDraw();
  pg.clear();
  pg.image(video, 0, 0);
  pg.endDraw();

//mask layer
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

//Create PImage of video mask
  PImage videoMasked = pg.get();
  videoMasked.mask(mask.get());

//draw grain layer
  grain.beginDraw();
  grain.background(0);
  grain.image(videoMasked, 0, 0);

//film grain effect
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      float noise = random(-grainAmt, grainAmt);
      color c = grain.get(i, j);
      color grainColor = color(red(c) + noise, green(c) + noise, blue(c) + noise);
      grain.set(i, j, grainColor);
    }
  }
  grain.endDraw();

//rectangle shape that's being carved out by mask
  push();
  fill(0);
  rect(0, 0, width, height);
  pop();

//display full composition with grain
  push();
  image(grain, 0, 0);
  pop();

//display & flash text 
  if (frameCount > (frames * 10) + delay) {
    if (frameCount % 60 < 30) {
      push();
      image(text, 0, 0);
      pop();
    }
  }

//video export stuff -- start after specified amount of frames & exit after certain amount of time
  if (frameCount > delay) {
    videoExport.saveFrame();
  }
  if (frameCount >= (frames * vidLength) + delay) {
    videoExport.endMovie();
    exit();
  }
}
