// Upgrade NOTE: replaced 'glstate_matrix_projection' with 'UNITY_MATRIX_P'

// Written by Jacob Tang
// Based on : https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering

Shader "Jacob_Shaders/Atmosphere"
{    
    Properties
    {


        //_MainTex ("Texture", 2D) = "white" {}
        //_Tint ("Color Tint", color) = (1,1,1,1)
        //_atmoRadius ("Radius", float) = 10
        //_AtmoThickness("Atmosphere Thickness", float) = 0.5
        //_ph_ray("ph_ray", float)  = 0.002
        //_ph_mie("ph_mie", float) = 0.001
        //_alpha("alpha", float) = 1
        //_LightDIr("Light Direction", Vector) = (0,0,1)
        //_NUM_OUT_SCATTER("NUM_OUT_SCATTER", float) = 8
        //_NUM_IN_SCATTER("NUM_IN_SCATTER", float) = 80

        _PlanetRadius("Planet Radius", Float) = 470
        _AtmosphereRadius("Atmosphere Radius", Float) = 500
        _PlanetCenter("Planet Center", Vector) = (0,0,0)
        _LightDirection("Light Direction", Vector) = (0,0,1)
        _LightIntensity("Light Intensity", Float) = 30
        _LightColor("Light Color", Color) = (1,1,1)
        _Steps ("Steps", Int) = 20
        _LightSteps ("Light Steps", Int) = 12
        _RayleighScattering("Rayleigh Scattering", Color) = (0.08,0.2,0.51,0)
        _RayleighExponent("Rayleigh Exponent", Range(0.0,10.0)) = 0.6
        _MieScattering("Mie Scattering", Color) = (0.01, 0.9, 0, 0)
        _MieExponent("Mie Exponent", Range(0.0,10.0)) = 0.73
        _AtmoAlpha ("Overall Atmosphere Density", Range(0.0,1.0)) = 0.5
        _AtmoAlphaCutoff ("Atmosphere Edge Alpha Cutoff", Range(0.0,1.0)) = 0.1
        _TestParameter ("_TestParameter", Float) = 0
    }

    SubShader{

        Blend SrcAlpha OneMinusSrcAlpha
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100

        ZWrite Off
        Cull Off


        Pass {
            

            CGPROGRAM 

            #pragma vertex vert
            #pragma fragment frag
            #define PI 3.14159265
            #include "UnityCG.cginc"
           
            ////////////////////////// Program //////////////////////////
  



            #include "Atmosphere.hlsl"

            ////////////////////////// Program //////////////////////////

            ENDCG
        }
    }
}
