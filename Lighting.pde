class Light
{
   PVector position;
   color diffuse;
   color specular;
   Light(PVector position, color col)
   {
     this.position = position;
     this.diffuse = col;
     this.specular = col;
   }

   Light(PVector position, color diffuse, color specular)
   {
     this.position = position;
     this.diffuse = diffuse;
     this.specular = specular;
   }

   color shine(color col)
   {
       return scaleColor(col, this.diffuse);
   }

   color spec(color col)
   {
       return scaleColor(col, this.specular);
   }
}

class LightingModel
{
    ArrayList<Light> lights;
    LightingModel(ArrayList<Light> lights)
    {
      this.lights = lights;
    }
    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      color hitcolor = hit.material.getColor(hit.u, hit.v);
      color surfacecol = lights.get(0).shine(hitcolor);
      PVector tolight = PVector.sub(lights.get(0).position, hit.location).normalize();
      float intensity = PVector.dot(tolight, hit.normal);
      return lerpColor(color(0), surfacecol, intensity);
    }

}

class PhongLightingModel extends LightingModel
{
    color ambient;
    boolean withshadow;

    PhongLightingModel(ArrayList<Light> lights, boolean withshadow, color ambient)
    {
      super(lights);
      this.withshadow = withshadow;
      this.ambient = ambient;
    }

    color getColor(RayHit hit, Scene sc, PVector viewer)
    {
      //all vectors to be used in Phong Calculations
      PVector R;
      PVector L;
      PVector V = PVector.sub(viewer,hit.location).normalize();
      PVector N = hit.normal;

      //easier to access hits material properties
      MaterialProperties hitMatProp = hit.material.properties;
      Material hitMat = hit.material;
      color Color = hitMat.getColor(hit.u, hit.v);
      color Shine;
      color Spec;
      color sum = multColor(scaleColor(Color, ambient), hitMatProp.ka);
      for(Light l : lights)
      {
        //Vector Setup
        L = PVector.sub(l.position, hit.location).normalize();
        //2N(N*L)
        R = PVector.mult(N, (2*PVector.dot(N,L)));
        R = PVector.sub(R,L).normalize();


        //shoot ray from hit location to current light
        if(withshadow)
        {
          //check if the light source is behind the object
          if(PVector.dot(hit.normal,L) < 0)
          {
            //light is behind the object, so we don't care
            continue;
          }
          Ray r = new Ray(PVector.add(hit.location,PVector.mult(L,EPS)),L);
          ArrayList<RayHit> reflectHits = sc.root.intersect(r);
  
          //if it hits something
          if(reflectHits.size() != 0)
          {
            //take the first hit, if its closer than our light, don't include this light's shine and spec CONTINUE
            if(reflectHits.get(0).t <= PVector.sub(l.position,hit.location).mag())
            {
              continue;
            }
          }
        }

        //l.shine() is i_d, kd is kd of material, result is i_d*kd
        Shine = multColor(l.shine(Color), hitMatProp.kd);

        //This takes the dot product of the vector toward the light and the norm and multiplies it to i_d*k_d giving our final shine comp
        Shine = multColor(Shine,PVector.dot(L,N));

        //l.spec() is i_s, ks is ks of material, result is i_s*ks
        Spec = multColor(l.spec(Color),hitMatProp.ks);
        Spec = multColor(Spec,pow(PVector.dot(R,V),hitMatProp.alpha));
        sum = addColors(sum,addColors(Spec,Shine));
      }
      return sum;
    }

}
