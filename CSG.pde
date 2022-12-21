import java.util.Comparator;

class HitCompare implements Comparator<RayHit>
{
  int compare(RayHit a, RayHit b)
  {
     if (a.t < b.t) return -1;
     if (a.t > b.t) return 1;
     if (a.entry) return -1;
     if (b.entry) return 1;
     return 0;
  }
}

class Union implements SceneObject
{
  SceneObject[] children;
  Union(SceneObject[] children)
  {
    this.children = children;
  }

  ArrayList<RayHit> intersect(Ray r)
  {
      ArrayList<RayHit> hits = new ArrayList<RayHit>();
      ArrayList<RayHit> trueHits = new ArrayList<RayHit>();
      int depth = 0;
      for (SceneObject sc : children)
      {
        //catches corner case of starting WITHIN an object
         ArrayList<RayHit> childHit = sc.intersect(r);
         if(childHit.size() > 0)
         {
             if(childHit.get(0).entry == false)
             {
               depth++;
             }
         }
         hits.addAll(childHit);
      }
      //sorts all hits based on t value
      hits.sort(new HitCompare());
      
      //iterates through all hits, tracking our depth. 
      for(int i = 0; i < hits.size(); i++)
      {
        //if we encounter an entry AND our depth is 0, its a true entry hit
        if(hits.get(i).entry == true)
        {
          if(depth == 0)
          {
            trueHits.add(hits.get(i));
            depth++;
          }
          else
          {
            depth++;
          }
        }
        //if we encounter an exit AND our depth is 1, then its a true exit hit
        else
        {
          if(depth == 1)
          {
            trueHits.add(hits.get(i));
            depth--;
          }
          else
          {
            depth--;
          }
        }
      }
      return trueHits;
  }
  
}

class Intersection implements SceneObject
{
  SceneObject[] children;
  Intersection(SceneObject[] children)
  {
    this.children = children;
  }
  ArrayList<RayHit> intersect(Ray r)
  {
      ArrayList<RayHit> hits = new ArrayList<RayHit>();
      ArrayList<RayHit> trueHits = new ArrayList<RayHit>();
      int depth = 0;
      for (SceneObject sc : children)
      {
         ArrayList<RayHit> childHit = sc.intersect(r);
         if(childHit.size() > 0)
         {
             if(childHit.get(0).entry == false)
             {
               depth++;
             }
         }
         hits.addAll(childHit);
      }
      hits.sort(new HitCompare());
      
      //iterate through all RayHit objects
      for(int i = 0; i < hits.size(); i++)
      {
        //if we encounter an entry AND our depth is how many children there is, its a true entry hit
        if(hits.get(i).entry == true)
        {
          if(depth == (children.length-1))
          {
            trueHits.add(hits.get(i));
            depth++;
          }
          else
          {
            depth++;
          }
        }
        //if we encounter an exit AND we added an entry, then its a true exit hit
        else
        {
          if(depth == children.length)
          {
            trueHits.add(hits.get(i));
            depth--;
          }
          else
          {
            depth--;
          }
        }
      }
      return trueHits;
  }
  
}

class Difference implements SceneObject
{
  SceneObject a;
  SceneObject b;
  Difference(SceneObject a, SceneObject b)
  {
    this.a = a;
    this.b = b;
  }
  
  ArrayList<RayHit> intersect(Ray r)
  {
     //we will return hits
     ArrayList<RayHit> hits = new ArrayList<RayHit>();
     
     //state booleans to determine which volumes we are in and keep track of our iterations
     boolean inA = false, inB = false, endofA = false, endofB = false;
     
     //boolean to track if a rayhit is from a or not
     boolean Ahit; 
     
     //holder for current processed ray
     RayHit curr;
     
     //iterators for A and B
     int iterA = 0, iterB = 0;
     
     //get A and B into an array list and determine if we start in one of the bodies or not.
     ArrayList<RayHit> aHit = a.intersect(r);
     ArrayList<RayHit> bHit = b.intersect(r);
     aHit.sort(new HitCompare());
     bHit.sort(new HitCompare());
     if(aHit.size() > 0)
     {
         if(aHit.get(0).entry == false)
         {
           inA = true;
         }
     }
     else
     {
       endofA = true;
     }
     if(bHit.size() > 0)
     {
         if(bHit.get(0).entry == false)
         {
           inB = true;
         }
     }
     else
     {
       endofB = true;
     }
     //while theres still values to iterate through the arrays
     while(!endofA || !endofB)
     {
       //if we iterated through all of A already, then the ray is just B
       if(endofA)
       {
         Ahit = false;
         curr = bHit.get(iterB++);
         if(iterB == bHit.size())
         {
           endofB = true;
         }
       }
       //if we iterated through all of B already, then the ray is just A
       else if(endofB)
       {
         Ahit = true;
         curr = aHit.get(iterA++);
         if(iterA == aHit.size())
         {
           endofA = true;
         }
       }
       else
       {
         //our next A hit is closer than B
         if(aHit.get(iterA).t <= bHit.get(iterB).t)
         {
           Ahit = true;
           curr = aHit.get(iterA++);
           if(iterA == aHit.size())
           {
             endofA = true;
           }
         }
         //our next B hit is closer than A
         else
         {
           Ahit = false;
           curr = bHit.get(iterB++);
           if(iterB == bHit.size())
           {
             endofB = true;
           }
         }
       }
       
       //we are exiting a volume
       if(curr.entry == false)
       {
         //we are in both A and B
         if(inA && inB)
         {
           //if we are leaving A
           if(Ahit)
           {
             inA = false;
           }
           //if we are leaving B
           else
           {
             curr.normal = PVector.mult(curr.normal, -1);
             curr.entry = true;
             hits.add(curr);
             inB = false;
           }
         }
         //if we are only in A and not B and leave A
         else if(inA && !inB)
         {
             hits.add(curr);
             inA = false;
         }
         //if we are only in B and not A and we leave B
         else
         {
           inB = false;
         }
       }
       //we are entering a volume
       else
       {
         //if we're in neither body
         if(!inA && !inB)
         {
           if(Ahit)
            {
              hits.add(curr);
              inA = true;
            }
            else
            {
              inB = true;
            }
         }
         //if we're inB and we enter A
         else if(inB && !inA)
         {
           inA = true;
         }
         //if we're inA and we enter B
         else
         {
           curr.normal = PVector.mult(curr.normal, -1);
           curr.entry = false;
           hits.add(curr);
           inB = true;
         }
       }
     }
     return hits;
  }
}
