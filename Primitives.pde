class Sphere implements SceneObject
{
    PVector center;
    float radius;
    Material material;

    Sphere(PVector center, float radius, Material material)
    {
       this.center = center;
       this.radius = radius;
       this.material = material;
    }

    float[] calculateUV(PVector n)
    {
      float u = 0.5 + (atan2(n.y,n.x)/(2*PI));
      float v = 0.5 - (asin(n.z)/PI);
      float[] results = {u,v};
      return results;
    }

    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        PVector d = r.direction;
        PVector o = r.origin;
        float tp = PVector.dot(PVector.sub(this.center, r.origin),d); // (c-o) * d
        PVector p = PVector.add(o, PVector.mult(d,tp));
        float x = PVector.sub(this.center, p).mag();
        float[] coords;

        //if x is greater than radius, no hit
        if(x > this.radius)
        {
          return result;
        }
        //if x is equal to the radius, exactly one tangential hit
        if(x == this.radius)
        {
            //t1 = t2 = tp
            PVector entry = PVector.add(o,PVector.mult(d,tp));
            PVector entrynorm = PVector.sub(entry,this.center).normalize();
            coords = calculateUV(entrynorm);
            result.add(new RayHit(tp,entry,entrynorm,true,this.material,coords[0],coords[1]));
            return result;
        }

        //if x isn't greater than radius...
        float t1 = tp - sqrt(pow(this.radius,2) - pow(x,2));
        float t2 = tp + sqrt(pow(this.radius,2) - pow(x,2));

        //it hits, but its behind the camera, so we dont care
        if(t1 < 0 && t2 < 0)
        {
          return result;
        }
        //it hits, but we are within the sphere
        else if(t1 < 0 || t2 < 0)
        {
          if(t1 < 0)
          {
            PVector exit = PVector.add(o,PVector.mult(d,t2));
            PVector exitnorm = PVector.sub(exit,this.center).normalize();
            coords = calculateUV(exitnorm);
            result.add(new RayHit(t2,exit,exitnorm,false,this.material,coords[0],coords[1]));
            return result;
          }
          else
          {
            PVector exit = PVector.add(o,PVector.mult(d,t1));
            PVector exitnorm = PVector.sub(exit,this.center).normalize();
            coords = calculateUV(exitnorm);
            result.add(new RayHit(t1,exit,exitnorm,false,this.material,coords[0],coords[1]));
            return result;
          }
        }
        //it's a standard hit with entry and exit
        else
        {
            PVector entry = PVector.add(o,PVector.mult(d,t1));
            PVector exit = PVector.add(o,PVector.mult(d,t2));
            PVector entrynorm = PVector.sub(entry,this.center).normalize();
            PVector exitnorm = PVector.sub(exit,this.center).normalize();
            coords = calculateUV(entrynorm);
            result.add(new RayHit(t1,entry,entrynorm,true,this.material,coords[0],coords[1]));
            coords = calculateUV(exitnorm);
            result.add(new RayHit(t2,exit,exitnorm,false,this.material,coords[0],coords[1]));
            return result;
        }
    }
}

class Plane implements SceneObject
{
    PVector center;
    PVector normal;
    float scale;
    Material material;

    Plane(PVector center, PVector normal, Material material, float scale)
    {
       this.center = center;
       this.normal = normal.normalize();
       this.material = material;
       this.scale = scale;
    }

    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        PVector d = r.direction;
        PVector o = r.origin;
        float dir = PVector.dot(d,this.normal);
        float numerator = PVector.dot(PVector.sub(this.center, o),this.normal);

        //ray is orthogonal to the plane, no hit. RETURN FAKE HIT
        if(dir == 0)
        {
          if(PVector.dot(PVector.sub(o,this.center),this.normal) <= 0)
          {
            result.add(new RayHit(Float.POSITIVE_INFINITY, new PVector(0,0,0),this.normal, false, this.material, 0, 0));
          }
          return result;
        }

        float t = numerator/dir;
        //ray will never hit the plane, facing the other way. RETURN FAKE HIT
        if (t <= 0)
        {
          if(dir <= 0)
          {
            result.add(new RayHit(Float.POSITIVE_INFINITY, new PVector(0,0,0), this.normal, false, this.material, 0, 0));
          }
          return result;
        }
        //it hits
        else
        {

          PVector location = PVector.add(o, PVector.mult(d, t));
          PVector D = PVector.sub(location,this.center);
          PVector axis = new PVector(0,0,1);
          if(dir <= 0)
          {
            //entry
            PVector N = this.normal;
            PVector R = axis.cross(N).normalize();
            if(R.mag() < EPS)
            {
              axis = new PVector(0,1,0);
              R = axis.cross(N).normalize();
            }
            PVector U = N.cross(R).normalize();
            float x = PVector.dot(D,R)/this.scale;
            float y = PVector.dot(D,U)/this.scale;
            float u = x - floor(x);
            float v = -y - floor(-y);
            result.add(new RayHit(t, location, N, true, this.material, u, v));
            return result;
          }
          else
          {
            //exit
            PVector N = PVector.mult(this.normal, -1);
            PVector R = axis.cross(N).normalize();
            if(R.mag() < EPS)
            {
              axis = new PVector(0,1,0);
              R = axis.cross(N).normalize();
            }
            PVector U = N.cross(R).normalize();
            float x = PVector.dot(D,R)/this.scale;
            float y = PVector.dot(D,U)/this.scale;
            float u = x - floor(x);
            float v = -y - floor(-y);
            result.add(new RayHit(t, location, N, false, this.material, u, v));
            return result;
          }
        }
    }
}

class Triangle implements SceneObject
{
    PVector v1;
    PVector v2;
    PVector v3;
    PVector normal;
    PVector tex1;
    PVector tex2;
    PVector tex3;
    Material material;

    Triangle(PVector v1, PVector v2, PVector v3, PVector tex1, PVector tex2, PVector tex3, Material material)
    {
       this.v1 = v1;
       this.v2 = v2;
       this.v3 = v3;
       this.tex1 = tex1;
       this.tex2 = tex2;
       this.tex3 = tex3;
       this.normal = PVector.sub(v2, v1).cross(PVector.sub(v3, v1)).normalize();
       this.material = material;
    }

    float[] ComputeUV(PVector a, PVector b, PVector c, PVector p)
    {
      float[] result = new float[2];
      PVector e = PVector.sub(b,a);
      PVector g = PVector.sub(c,a);
      PVector d = PVector.sub(p,a);
      float denom = (PVector.dot(e,e) * PVector.dot(g,g)) - (PVector.dot(e,g) * PVector.dot(g,e));
      result[0] = ((PVector.dot(g,g)*PVector.dot(d,e)) - (PVector.dot(e,g) * PVector.dot(d,g)))/denom;
      result[1] = ((PVector.dot(e,e) * PVector.dot(d,g)) - (PVector.dot(e,g) * PVector.dot(d,e)))/denom;
      return result;
    }

    PVector computeTexCoords(float theta, float phi)
    {
      PVector result;
      float psi = 1 - (theta + phi);
      result = PVector.mult(tex2,theta);
      result = PVector.add(result,PVector.mult(tex3,phi));
      result = PVector.add(result,PVector.mult(tex1,psi));
      return result;
    }

    ArrayList<RayHit> intersect(Ray r)
    {
        ArrayList<RayHit> result = new ArrayList<RayHit>();
        //compute if the ray intersects the plane...
        PVector d = r.direction;
        PVector o = r.origin;
        float dir = PVector.dot(d,this.normal);
        float numerator = PVector.dot(PVector.sub(this.v1, o),this.normal);

        //ray is orthogonal to the plane of the triangle
        if(dir == 0)
        {
            return result;
        }
        float t = numerator/dir;
        //ray will never hit the plane, it's facing the other way.
        if (t < 0)
        {
            return result;
        }

       //ray hits triangle plane
       else
       {
          PVector location = PVector.add(o, PVector.mult(d, t));
          RayHit ray;
          float[] vals = ComputeUV(this.v1, this.v2, this.v3, location);
          float u = vals[0], v = vals[1];
          if(dir >= 0)
          {
            //if we are "inside" the triangle, just exit
            return result;
          }
          //ray hits the triangle
          if(u >= 0 && v >= 0 && (u+v) <= 1)
          {
             PVector res = computeTexCoords(u,v);
             ray = new RayHit(t,location,this.normal,true,this.material,res.x,res.y);
             PVector newLoc = PVector.add(o, PVector.mult(d, t + EPS));
             RayHit thinray = new RayHit(t+EPS,newLoc, PVector.mult(this.normal,-1), false, this.material, res.x, res.y);
             result.add(ray);
             result.add(thinray);
             return result;
          }

          //ray does not hit the triangle
          return result;
      }
  }
}
