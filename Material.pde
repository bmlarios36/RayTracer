class MaterialProperties
{
    float ks;
    float ka;
    float kd;
    float alpha;
    float reflectiveness;
    float refractionIndex;
    float transparency;
    
    MaterialProperties(float ka, float ks, float kd, float alpha, float reflectiveness, float transparency, float refractionIndex)
    {
       this.ks = ks;
       this.ka = ka;
       this.kd = kd;
       this.alpha = alpha;
       this.reflectiveness = reflectiveness;
       this.transparency = transparency;
       this.refractionIndex = refractionIndex;
    }
}

class Material
{
    MaterialProperties properties;
    color col;
    color getColor(float u, float v)
    {
      return col;
    }
    Material(MaterialProperties props, color col)
    {
       this.properties = props;
       this.col = col;
    }
}
