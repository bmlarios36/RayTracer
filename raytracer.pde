String input =  "data/tests/submission3tests/submission3/test15.json";
String output = "data/tests/submission3tests/submission3/test15.png";

RayTracer rt;

void setup() 
{
  size(640, 640);
  noLoop();
  rt = new RayTracer(loadScene(input));
}

void draw () 
{
    background(255);
    PImage out = null;
    if (!output.equals(""))
    {
      out = createImage(width, height, RGB);
      out.loadPixels();
    }
    for (int i=0; i < width; i++)
    {
      for (int j=0; j< height; ++j)
      {
        color c = rt.getColor(i, j);
        set(i, j, c);
        if (out != null)
          out.pixels[j*width + i] = c;
      }
    }
    if (out != null)
    {
      out.updatePixels();
      out.save(output);
    }
}
 

class Ray
{
  Ray(PVector origin, PVector direction)
  {
    this.origin = origin;
    this.direction = direction;
  }
  PVector origin;
  PVector direction;
}

class RayTracer
{
  Scene scene;

  RayTracer(Scene scene)
  {
    setScene(scene);
  }

  void setScene(Scene scene)
  {
    this.scene = scene;
  }

  color getColor(int x, int y)
  {
    //shoot initial ray
    PVector origin = scene.camera;
    float w = width;
    float h = height;
    float u = ((x*1.0)/w) - 0.5;
    float v = -(((y*1.0)/h) - 0.5);
    PVector projection = new PVector(u*w, w/2, v*h).normalize();
    PVector direction = PVector.sub(projection, origin);
    Ray ray = new Ray(origin, direction);
    ArrayList<RayHit> hits = scene.root.intersect(ray);

    //if it hits something, then get its color
    if (hits.size() > 0)
    {
      //get first reflection ray and initialize color to first object hit
      color result = scene.lighting.getColor(hits.get(0), scene, origin);
      PVector V = PVector.mult(direction,-1);
      PVector N = hits.get(0).normal;
      PVector product = PVector.mult(PVector.mult(N,2), PVector.dot(N, V));
      PVector R = PVector.sub(product, V);
      PVector neworg = PVector.add(hits.get(0).location, PVector.mult(R, EPS));
      Ray newRay = new Ray(neworg, R);
      
      //shoot the ray into the scene
      ArrayList<RayHit> reflectHits = scene.root.intersect(newRay);
      float prevShine = hits.get(0).material.properties.reflectiveness;
      int refCounter = 1;
      
      //if we hit nothing, lerp color with the background 
      if (reflectHits.size() == 0)
      {
        result = lerpColor(result, scene.background, prevShine);
      } 
      //if we did hit something, lerp our current color with it 
      else
      {
        result = lerpColor(result, scene.lighting.getColor(reflectHits.get(0), scene, newRay.origin), prevShine);
      }
      
      //start reflecting unless our first hit was empty, or it was a reflection index of 0
      //loop until we hit max reflections
      while (reflectHits.size() > 0 && prevShine > 0 && refCounter <= scene.reflections)
      {
        //reverse the direction of our reflection ray
        V = PVector.mult(newRay.direction, -1);
        N = reflectHits.get(0).normal;
        product = PVector.mult(PVector.mult(N,2), PVector.dot(N, V));
        R = PVector.sub(product, V);
        neworg = PVector.add(reflectHits.get(0).location, PVector.mult(R, EPS));
        newRay = new Ray(neworg, R);
        prevShine = reflectHits.get(0).material.properties.reflectiveness;
        reflectHits = scene.root.intersect(newRay);
        if (reflectHits.size() == 0)
        {
          result = lerpColor(result, scene.background, prevShine);
        } else
        {
          result = lerpColor(result, scene.lighting.getColor(reflectHits.get(0), scene, newRay.origin), prevShine);
        }
        refCounter++;
      }
      return result;
    }
    //if it hits nothing, just get the background
    return scene.background;
  }
}
