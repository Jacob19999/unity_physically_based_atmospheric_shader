# Physically based atmospheric shader in unity

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/7a617937-d231-4139-9545-adcb519d0e01)

Perhaps one of the best visual components is the implementation of a physically based atmosphere scattering effect which has the ability to be instanced for each planet. Unity’s default physically based atmosphere is only available as 1 instance in a skybox and only runs  in HDRP. 

In order to create this effect, a mathematical model of how light scatters in the atmosphere due to gasses and particles needs to be implemented in the GPU. Additionally the scattering is a non linear problem which depends on many conditions like optical depth, light source etc… which cannot be solved easily by approximation. Hence raymarching is required to iteratively solve scattering for each pixel, which can be computationally expensive, however this greatly depends on the GPU and the number of parallel processing cores (CUDA or Stream cores).

Based on : https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering

# Mathematical model of the atmosphere

Mathematical model has to be implemented not only in the shape of the atmosphere, but also various properties of light like scattering, phase , in and out scattering functions, all implemented in the fragment shader.

# The Shader

In unity like all other games, a shader is a piece of specialized code that gets compiled natively into machine code that runs exclusively on the GPU. Suppose if there's a ball in the game scene, and that it needs to be rendered, there must be a shader somewhere that tells the GPU to render the ball, where, and what color it has to render. 
 
If we look at the example of the atmosphere shader, it is basically a bunch of code where its end result is to tell the GPU for every pixel on screen, what is the float4 value to render. This float4 is a single precision 4 column matrix where the first 3 columns are Red , green blue values, and the last element the transparency value or alpha. 

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/485d9e57-0310-4853-905f-74c1ae6e9c35)

# The Vertex Shader

The vertex is essentially the first process in the rendering pipeline. When an object is placed in the editor, the Unity game engine stores the position of each point or vertices and its position in game space. The vertices position is passed into the vertex shader, where for each area that is enclosed by 3 adjacent vertices.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/8824d892-bf1c-42ca-b961-bdf89d13acbe)

On the left the barebones vertex shader function. This function is named interpolator because its main function is to transform or interpolate the position of each vertex from game space to clip space. 

Looking at the vertex function, we can see that mash data is passed in as variable v, this mesh data essentially contains position information for one vertices. Next we can see that we utilize unity’s built-in function “UnityObjectToClipPos” or the Model view projection (MVP) matrix that transforms the position v of 1 vertices from gamespace to clip space. 

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/39c93d02-b373-4828-944a-83c82ea1a69e)

Suppose we have a vertex point p represented by the red dot in the diagram above. The point is the same point  however it is clear that they exist in different positions in game space and in clip space. This change in position is the main function of the MVP matrix transformation. 

Other items are calculated for instance the uv, which is the vector direction pointing to the outside facing normal direction from the vertice. This direction is important because it tells the GPU which side to render and which side not to render. View direction is the vector direction from the camera to the specific vertice.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/14e2fe8c-4bd0-4130-ada6-09a6d1f01c86)

# Rasterization

This function is built in and in general is automated. For every vertex shader output, 3 adjacent outputs that encircle an area are put together as a vertex. As shown on the right, 3 points which represent the output of 3 vertex shaders are combined to form the blue area. The grid pattern represents pixels on the screen and the rasterizer computes which pixels the vertex encircles

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/36af74e0-b00d-46a3-bf8a-df4f49f66946)

# The Fragment Shader

The fragment shader is a function that once again runs in the GPU for each pixel on screen. If we zoom in on the pixels as shown on the right, we can see that some pixels are only enclosed partially by the vertex (black line). Hence a pixel can be fragmented, where one side is in the vertex and another is not.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/d7f1bc49-5efc-44ba-830d-bcc0efbeacef)


In shader code the fragment shader takes in data from the rasterized vertex. Data can be hence passed in from the vertices by the vertex shader into pixels or fragment shader. For instance if an object has 3 vertices, and the user assigned different color to each one, then the information on color of each vertices can be pass in through the vertex shader into input i in the fragment shader, then the fragment shader would average out the colors based on distance and calculates the color needed to be displayed by each pixel, resulting in a vertex to be displayed on screen with a smooth shade.

# Math of Atmospheric scattering

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/2cb74212-3dac-4f6a-810c-0541cc0f544f)

For the purpose of a transparent atmosphere, we do not need many of the features of the vertex shader like passing color values of the mesh or uv since there will be no textures or color assigned to the mesh. Only view direction and vertex position is utilized here. We utilize the  fragment shader to perform all the necessary mathematical computations required for every pixel. This can be improved in the future by mirating this code to the vertex shader, since for objects close to the camera, there will always certainly be fewer vertices than pixels, leading to better performance. However this can be difficult to implement. 

# Scattering Functions 

There are 2 main types of scattering effects that take place in real life and should be simulated. These are rayleigh scattering and Mie scattering. 

By only enabling rayleigh scattering, we can see that this adds the effect of what we are all familiar with, blue skies. This is due to the scattering of blue light by particles like gas or water molecules, whereare’s other wavelengths are absorbed. The wavelength of light scattered can be defined in the shader inspector by a color picker.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/eb1cef29-7cb7-48cc-880c-a08945afe411)

By only enabling Mie scattering we can see that mostly white light is scattered, and the amount of light scattered depends on the direction of the incoming light from each particle. Mie scattering is primarily caused by larger particles like aerosols in the lower atmosphere. 

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/2a89098b-263c-4c04-93c4-98ff340449e6)

Rayleigh + Mie scattering
Blending of both rayleigh and Mie results in the upper atmosphere being blueish while the lower thicker atmosphere scattering more white / yellow or red light depending on the position of the camera and sun.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/f4b4f36d-149b-43a6-a449-34bb55b5ca7e)

# In Fragment shader

Step 1 : RaySphere Intersection

The first step is to determine the optical depth of each pixel. Optical depth is represented as the distance a ray travels within the atmosphere, in the case of an atmosphere the optical depth is point A to Point B from a view direction as mentioned in the vertex shader. To calculate the optical depth, this can be done with pre-built libraries that are available online that utilize trigonometry given center point C which is the center of the planet in clip space and clip space position.

Part of the sphere intersection function, which returns the position of first intersection t0 and second intersection t1

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/2365db9e-9eff-4805-b414-c05a77a9cef7)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/ad0e8724-4868-4314-9c07-70a9dd9ef1d3)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/dc56f016-87cf-4e31-9c4c-1fae8cf6fdae)

Step 2 : Define the Phase function

In the real world, when light hits a particle,  some of the light is absorbed while others are scattered out. However the amount of light scattered out is not consistent. On the right a Mie scattering phase function indicates that more light is scattered aft of the particle than is scattered forward.  Therefore the amount of light scattered with respect to the angle from the incoming light source (Sun) depends on the phase function. In the shader the phase function is used to calculate how much light is scattered for each light step point given the angle of the sun and the angle of the view direction or camera. E.g if the camera is directly opposite the sun, then the phase function indicates that the scattering intensity will be the brightest.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/97d5545f-e037-45be-a450-2bb1b8b865bd)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/a31e3fd7-5960-4bd3-a259-7ee04dfc61c2)

The phase function where:

f() is the result of the function f() is the intensity of light scattered.
theta is the angle of the view direction from the particle or light step point to the camera.
g is the scattering coefficient typically -0.75 to -0.999 for Mie. We use zero for g for rayleigh, so light just passes through the atmosphere and becomes blue as an approximation. 

Actual code modified with reference : https://ebruneton.github.io/precomputed_atmospheric_scattering/atmosphere/functions.glsl.html

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/f75d3a6e-07ee-4ed8-987d-75702049bed9)

Step 3: Light March

Given the user input of the number of light steps in the inspector, which determines the number of points, we can determine where each light march point will be located. This is later used to calculate the out scattering function. 

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/4e9d82b4-9fda-439d-b93d-bf2bb78b63dc)

Distance of each point is the same and is simply the optical depth divided by the number of steps. Each point , p1, p2, pn can be calculated as a result by adding a distance vector. For each step, the density is sampled by taking h height and a manual input density exponent or falloff. If the exponent is 0.25 then the average density is at an altitude of 25% from ground to space.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/d838a0a4-582b-45e7-9b9e-cbe953b02d39)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/c43c2382-6f38-46ca-bf76-0aed2517a494)

Step 4: in / out Scattering Function

The out scattering function determines how much light is scattered for each pixel. The integral term on the right is already calculated above in the light march step as light depth (optical depth).

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/5a3e9d4c-a862-47d3-8c43-87beed77fb04)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/d16482a5-f8b3-423f-b12f-ee9b0d1f093d)

In code, rayleigh (left Term) and Mie (Right Term) are combined to obtain tau.

In scattering or attenuation, calculates energy added due to light from the sun for instance. We can simplify the formula where the attenuation is simply the exponent of tau and integrated with respect to ds (light step size)

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/8f8841ac-476a-4317-9e6e-76ec5981bae1)

In code we just need to take the exponent of out scattering to obtain attenuation. 

Step 5: Output

Color of each pixel due to Rayleigh and Mie combined into RGB value and passed into the fragmentation shader. An alpha cutoff based on the atmospheric height blends the top of the atmosphere with the dark space.

Step 6: Atmosphere dynamic properties (atmosphere.cs)

In the sphere intersection process, we utilized the central position of the planet as a centerpoint of the sphere intersection. Additionally other properties like sun direction changes with respect to time. In order to keep these properties updated, we created a script that targets those properties and dates it.

In application play mode, the shared material reference is used while for build, material reference is used.

![image](https://github.com/Jacob19999/unity_physically_based_atmospheric_shader/assets/26366586/f9743257-b828-4ae5-bfd4-3e185dce5817)










