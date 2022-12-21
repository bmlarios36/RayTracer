class RayHit
{
     float t;
     PVector location;
     PVector normal;
     boolean entry;
     Material material;
     float u, v;
     RayHit(float t, PVector l, PVector norm, boolean e, Material m, float u, float v)
     {
       this.t = t;
       this.location = l;
       this.normal = norm;
       this.entry = e;
       this.material = m;
       this.u = u;
       this.v = v;
     }
}

interface SceneObject
{
   ArrayList<RayHit> intersect(Ray r);
}

class Scene
{
   LightingModel lighting;
   SceneObject root;
   int reflections;
   color background;
   PVector camera;
   PVector view;
   float fov;
}
