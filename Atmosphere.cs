using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

# Written By Jacob Tang

[ExecuteInEditMode]
public class Atmosphere : MonoBehaviour
{
    // Access atmosphere shader and change properties of the shader
    Renderer atmosphereShader;
    GameObject atmosphere;
    public GameObject DirectionalLight;
    public Vector3 gameObjectTransform;

    void Awake()
    {
        atmosphereShader = GetComponent<Renderer>();

        // Use the Specular shader on the material
        atmosphereShader.sharedMaterial.shader = Shader.Find("Jacob_Shaders/Atmosphere");
    }

    void Update()
    {

        if (DirectionalLight != null)
        {
            // Set normalized vector of directional light .
            Vector3 normalDirection = DirectionalLight.transform.forward.normalized;

            if (Application.isPlaying)
            {
                atmosphereShader.material.SetVector("_LightDirection", normalDirection);
            } else
            {
                atmosphereShader.sharedMaterial.SetVector("_LightDirection", normalDirection);
            }
            

            //Debug.Log(normalDirection);
          

        } else
        {
            //Debug.Log("Assign Directional light to " + transform.name);
        }

        gameObjectTransform = transform.position;
        // Set center of sphere as atmosphere sphere position

        if (Application.isPlaying)
        {

            atmosphereShader.material.SetVector("_PlanetCenter", gameObjectTransform);
        } else
        {
            atmosphereShader.sharedMaterial.SetVector("_PlanetCenter", gameObjectTransform);
        }
            


    }
}
