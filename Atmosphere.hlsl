// Written By Jacob Tang

// Properties
float _LightIntensity;
float3 _LightColor;
float3 _LightDirection;
float _PlanetRadius;
float3 _PlanetCenter;
float _AtmosphereRadius;
float _Steps;
float _LightSteps;
float4 _RayleighScattering;
float4 _MieScattering;
float _ClipThreshold;
float _RayleighExponent;
float _MieExponent;
float _AtmoAlpha;
float _AtmoAlphaCutoff;

// Debugging
float _TestParameter;

// Returns Vector Length
float sqrLength(float3 v)
{
    return (v.x * v.x + v.y * v.y + v.z * v.z);
}

// Returns Sphere intersection for ray direction, returns t0 = first intersection, t1= second intersection
bool SphereIntersect(float3 ro, float3 rd, out float t0, out float t1, out bool t0_ground, bool isPlanet )
{
    // https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
    // Dot of planet to camera vector , tangent.
    float t = dot(_PlanetCenter - ro, rd);
    float3 pM = ro + rd * t;
    
   
    // Ray height above planet origin
    float height = sqrLength(pM - _PlanetCenter);
    
    float atmoRadi_Sqr = _AtmosphereRadius * _AtmosphereRadius;
    
    // No Ray intersection 
    if (height > (atmoRadi_Sqr))
        return false;
   
    float x = sqrt(atmoRadi_Sqr - height);
    
    t0 = (t - x < 0) ? 0 : t - x;
    t0_ground = false;
    
    // Intersection
    if (isPlanet && height < _PlanetRadius * _PlanetRadius && t > 0)
    {
        float x = sqrt(_PlanetRadius * _PlanetRadius - height);
        t1 = t - x;
        t0_ground = true;

    }
    else
    {
        t1 = t + x;
    }
    
    
    return true;
}

// Light march steps based on intersection
bool LightMarch(float3 p1, float3 rd, float l, out float2 lightDepth)
{
    float ds = l / _LightSteps;
    float time = 0;
    lightDepth = float2(0, 0);
    for (int i = 0; i < _LightSteps; i++)
    {
        float3 p = p1 + rd * (time + ds * 0.5);
        float height = (length(p - _PlanetCenter) - _PlanetRadius);

        if (height < 0)
            return false;

        // Optical Depth (Density Exponent term)
        lightDepth.x += exp(-height / _RayleighExponent) * ds;
        lightDepth.y += exp(-height / _MieExponent) * ds;

        time += ds;
    }
    return true;
}












# if 0

//sampler2D _MainTex;
//sampler2D _CameraDepthTexture;
//float4 _Tint;
//const float MAX = 10000.0;
//float _ph_ray;
//float _ph_mie;
//float _alpha;

// Ray Scatter length OLD
//float _NUM_OUT_SCATTER;
//float _NUM_IN_SCATTER;
//const float stepSize = 0.1;

// Atmosphere Properties OLD
//float _atmoRadius;
//float _AtmoThickness;
//float3 _LightDIr;

float2 RaySphere(float3 rayOrigin, float3 rayDir, float3 sphereCentre, float sphereRadius)
{

    float3 offset = rayOrigin - sphereCentre;
    float a = 1; // a = 1 (Ray Dir is normalized unit vector)
    float b = 2 * dot(offset, rayDir);
    float c = dot(offset, offset) - sphereRadius * sphereRadius;
    float discriminant = b * b - 4 * a * c; // Quadratic formula discriminant
    
    if (discriminant > 0)
    {
        float s = sqrt(discriminant);
        float distNear = max(0, (-b - s) / (2 * a));
        float distFar = (-b + s) / (2 * a);
        
        // Ignore Intersections behind ray
        if (distFar >= 0)
        {
            return float2(distNear, distFar - distNear);
        }
    }
    
    // No Intersection
    return float2(0, 0);
 
}

float2 ray_vs_sphere(float3 p, float3 dir, float3 sphereCentre, float r)
{
    float b = dot(p, dir);
    float c = dot(p, p) - r * r;
	
    float d = b * b - c;
    if (d < 0.0)
    {
        return float2(MAX, -MAX);
    }
    d = sqrt(d);
	
    return float2(-b - d, -b + d);
}




// Rayleigh
float phase_ray(float cc)
{
    return (3.0 / 16.0 / PI) * (1.0 + cc);
}

// MIE Scarting
float phase_mie(float g, float c, float cc)
{
    float gg = g * g;
	
    float a = (1.0 - gg) * (1.0 + cc);

    float b = 1.0 + gg - 2.0 * g * c;
    b *= sqrt(b);
    b *= 2.0 + gg;
	
    return (3.0 / 8.0 / PI) * a / b;
}

float air_density(float3 p, float ph, float R_Inner)
{

    return exp(-max(length(p) - R_Inner, 0.0) / ph);
}


float optic(float3 p, float3 q, float ph, float R_INNER)
{
    float3 s = (q - p) / float(_NUM_OUT_SCATTER);
    float3 v = p + s * 0.5;
	
    float sum = 0.0;
    for (int i = 0; i < _NUM_OUT_SCATTER; i++)
    {
        sum += air_density(v, ph, R_INNER);
        v += s;
    }
    sum *= length(s);
	
    return sum;
}


float3 in_scatter(float3 rayOrigin, float3 rayDir, float2 e, float3 l, float R_Inner)
{
    const float3 k_ray = float3(3.8 / 255, 13.5 / 255, 33.1 / 255);
    const float3 k_mie = float3(21.0 / 255, 21.0 / 255, 21.0 / 255);
    const float k_mie_ex = 1.1;
    
    float3 sum_ray = float3(0,0,0);
    float3 sum_mie = float3(0,0,0);
    
    float n_ray0 = 0;
    float n_mie0 = 0;
    
    float len = e.y / _NUM_IN_SCATTER;
    float3 rayPos_V_Step = rayDir * len;
    
    float3 rayPos_V = rayOrigin + rayDir * (e.x + len);
    
    for (int i = 0; i < _NUM_IN_SCATTER; i++, rayPos_V += rayPos_V_Step)
    {
        
        float d_ray = air_density(rayPos_V, _ph_ray, R_Inner) * len;
        float d_mie = air_density(rayPos_V, _ph_mie, R_Inner) * len;
               
        n_ray0 += d_ray;
        n_mie0 += d_mie;

        float2 f = ray_vs_sphere(rayPos_V, _LightDIr, _PlanetCenter, _atmoRadius);
        float3 u = rayPos_V + l * f.y;
        
        float n_ray1 = optic(rayPos_V, u, _ph_ray, R_Inner);
        float n_mie1 = optic(rayPos_V, u, _ph_mie, R_Inner);
        
        float n_ray_0x1 = n_ray0 + n_ray1;
        float n_mie_0x1 = n_mie0 + n_mie1;
       

        float att_float_x = exp(-(n_ray_0x1) * k_ray.x - (n_mie_0x1) * k_mie.x * k_mie_ex);
        float att_float_y = exp(-(n_ray_0x1) * k_ray.y - (n_mie_0x1) * k_mie.y * k_mie_ex);
        float att_float_z = exp(-(n_ray_0x1) * k_ray.z - (n_mie_0x1) * k_mie.z * k_mie_ex);

        float3 att = float3(att_float_x, att_float_y, att_float_z);

        sum_ray += float3(d_ray * att.x, d_ray * att.y, d_ray * att.z);
        sum_mie += d_mie * att;
        
    }
    
    float c = dot(rayDir, -l);
    float cc = c * c;
    
    float3 scatter = sum_ray * k_ray * phase_ray(cc) + 
                     sum_mie * k_mie * phase_mie(-0.78, c, cc);

    return 10 * scatter;

}

# endif

// Base Functions
struct meshData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 uv : TEXCOORD0;
    
};

struct Interpolator
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 viewVector : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float3 normal : TEXCOORD3;
    float3 startPos : TEXCOORD4;
    float3 viewDir : TEXCOORD5;
};


Interpolator vert(meshData v)
{
    Interpolator output;
    
    output.pos = UnityObjectToClipPos(v.vertex);
    output.normal = v.normal;
    output.uv = v.uv;
    output.startPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    output.viewDir = normalize(output.startPos - _WorldSpaceCameraPos.xyz);
    output.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
    
    
    float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv.xy * 2 - 1, 0, -1));
    output.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));
    _PlanetCenter = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));


    return output;
}


#if 1
float4 frag(Interpolator i) : SV_TARGET
{
    // Framgment shader by Jacob Tang
    // Manage user input error
    if (_PlanetRadius > _AtmosphereRadius)
        _PlanetRadius = _AtmosphereRadius - 2;
    if (_AtmosphereRadius < 0)
        _AtmosphereRadius = 1;

    //  Rayleigh Scattering wavelength
    float3 rsRGB = float3(_RayleighScattering.xyz);
    //  Mie Scattering intensity
    float msRGB = _MieScattering.x;
    //  Rayleigh Scattering density exponent 
    float rSH = _RayleighExponent;
    //  Mie Scattering density exponent 
    float mSH = _MieExponent;

    // Ray origin and ray direction
    i.viewDir = normalize(i.startPos - _WorldSpaceCameraPos.xyz);
    i.startPos = _WorldSpaceCameraPos;

    // Check for intersection
    float t0, t1, t0ground;
    if (!SphereIntersect(i.startPos, i.viewDir, t0, t1, t0ground, true ))
        discard;

    // Calculate light 
    float mu = dot(i.viewDir, normalize(-_LightDirection));
    float g = _MieScattering.y;
    
    // Helper functions for calculating phase value for Rayleigh and mie, however this can be assigned to a 
    // parameter to be defined manually.
    float phaseR = 3.0 / (16.0 * PI) * (1 + mu * mu);
    //phaseR = _TestParameter;
    float phaseM = 3.0 / (8.0 * PI) * ((1.f - g * g) * (1.f + mu * mu)) / ((2.f + g * g) * pow(1.f + g * g - 2.f * g * mu, 1.5f));

    float3 sumR, sumM;
    float2 opticalDepth;

    float3 p1 = i.startPos + i.viewDir * t0;
    float l = t1 - t0;
    float ds = l / _Steps;
    float time = 0;
    

    // Step through each segment
    for (int e = 0; e < _Steps; e++)
    {
        // Propogate each segment with respect to interval and time 
        float3 p = p1 + i.viewDir * (time + ds * 0.5);
        float3 lrd = normalize(-_LightDirection);

        float lt0, lt1, t0ground;
        SphereIntersect(p, lrd, lt0, lt1, t0ground, false);
        float2 opticallightDepth;
        float3 lp1 = p + lrd * lt0;
        
        // Advance segment, calculate density at sample point
        if (LightMarch(lp1, lrd, lt1 - lt0, opticallightDepth))
        {
            float height = length(p - _PlanetCenter) - _PlanetRadius;
            
            float hr = exp(-height / rSH) * ds;
            float hm = exp(-height / mSH) * ds;

            opticalDepth.x += hr;
            opticalDepth.y += hm;

            float3 tau = rsRGB * (opticalDepth.x + opticallightDepth.x) + msRGB * 1.1 * (opticalDepth.y + opticallightDepth.y);
            float3 attenuation = float3(exp(-tau.x), exp(-tau.y), exp(-tau.z));

            sumR += attenuation * hr;
            sumM += attenuation * hm;
        }

        time += ds;
    }

    // Combine Rayleigh and Mie
    float3 color = (sumR * rsRGB * phaseR + sumM * msRGB * phaseM) * _LightIntensity * _LightColor;

    // Calculate alpha dropoff based on ray optical depth, ignoring ground
    float colorBrightness = (color.r + color.g + color.b)/3;
    

    return float4(color.xyz, _AtmoAlpha * (colorBrightness + _AtmoAlphaCutoff));

}

#endif

#if 0
float4 frag(Interpolator i) : SV_TARGET
{
    
    
    float R_INNER = _atmoRadius;
    float R = R_INNER + _AtmoThickness;
    
    // Get camera Ray origin and ray direction.
    float3 rayOrigin = _WorldSpaceCameraPos;
    float3 rayDir = normalize(i.startPos - _WorldSpaceCameraPos);

    float4 colorOutput;
    float t0, t1;
    if (SphereIntersect(i.startPos, i.viewDir, t0, t1, true))
    {
        // Atmosphere hit
        colorOutput = float4(1, 1, 1, 1.0);
        
    }
    else
    { 
        // Atmosphere no hit
        colorOutput = float4(0, 0, 0, 1.0);
    }

    
    
    
    
    //float2 e = RaySphere(rayOrigin, rayDir, _PlanetCenter, _atmoRadius);
    
    //if (t0 - t1)
    
    //if (e.x = 0)
    //{
    //    colorOutput = float4(1, 0, 0, 1.0);
    //}
    //else
    //{
        
        //R_INNER = _atmoRadius;
        
        //float2 f = ray_vs_sphere(rayOrigin, rayDir, _PlanetCenter, R_INNER);

        //e.y = min(e.y, f.x);
        
        //float3 inScatter = in_scatter(rayOrigin, rayDir, e, _LightDIr, R_INNER);
        
        //float3 scatterOutput = float3(pow(inScatter.x, 1.0 / 2.2), pow(inScatter.y, 1.0 / 2.2), pow(inScatter.z, 1.0 / 2.2));

       // colorOutput = float4(1,1,0, 1);
        
   //}

    return colorOutput;
  
}
#endif
    