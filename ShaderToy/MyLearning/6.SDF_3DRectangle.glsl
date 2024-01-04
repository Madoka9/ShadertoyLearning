#define TMIN 0.1
#define TMAX 20.0
#define RAYMARCHTIMEMAX 128
#define PRECISION 0.001
#define PI 3.1415926
#define RADIUS 1.

vec2 TransUVToCenter(in vec2 fragCoord)
{
    return  2.0 * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

float SDFSphere(in vec3 pos, in float r)
{
    return length(pos - vec3(0.0,0.0,2.0)) - r;
}

float SDFBox(in vec3 p, in vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float RayMarch(in vec3 rayOrg, in vec3 rayDir)
{
    float t = TMIN;
    for(int i = 0; i < RAYMARCHTIMEMAX && t < TMAX; i++)
    {
        vec3 pos = rayOrg + t * rayDir;
        float d = SDFBox(pos, vec3(1, 1, 1));
        if(d < PRECISION)
        {
            break;
        }  
        t += d;
    }
    return t;
}
vec3 calcNormal( in vec3 p )
{
    //https://iquilezles.org/articles/normalsSDF/
    //计算法线可以通过计算SDF梯度来完成 ： n = normlize(nablaf(p))
    //Tetrahedron technique 四面体技术
    // m = Σki * f(p + hki)
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);//k0 = {1,-1,-1}, k1 = {-1,-1,1}, k2 = {-1,1,-1}, k3 = {1,1,1} -- 
    return normalize( k.xyy*SDFBox( p + k.xyy*h ,vec3(1, 1, 1)) + 
                      k.yyx*SDFBox( p + k.yyx*h ,vec3(1, 1, 1)) + 
                      k.yxy*SDFBox( p + k.yxy*h ,vec3(1, 1, 1)) + 
                      k.xxx*SDFBox( p + k.xxx*h ,vec3(1, 1, 1)) );
}

mat3 setCamera(in vec3 targetPos, in vec3 startPos, in float theta )
{
    vec3 z = normalize(targetPos - startPos);
    vec3 cp = vec3(sin(theta), cos(theta), 0.0);
    vec3 x = normalize(cross(z, cp));
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 Render(in vec2 uv)
{
    vec2 mousePos = TransUVToCenter(iMouse.xy);
    vec2 mo = mousePos.xy == vec2(0) ? vec2(.125) : mousePos.xy / TransUVToCenter(iResolution.xy);
    vec3 color = vec3(0.0, 0.0, 0.0);
    vec3 camPos = vec3(.5+2.5*cos(1.5+6.*mo.x), 1.+2.*mo.y, -1. + 2.5*sin(1.5+6.*mo.x));
    // if(iMouse.z > 0.01)
    // {
    //     float theta = iMouse.x / iResolution.x * 2.0 * PI;
    //     float theta2 = iMouse.y / iResolution.y * 2.0 * PI;
    //     camPos = vec3(cos(theta),sin(theta2), sin(theta) );
    // }
    vec3 targetPos = vec3(0,0,0);
    mat3 matCam = setCamera(targetPos, camPos, 0.0);
    vec3 rayDir = normalize(matCam * vec3(uv, 1.0));
    float t = RayMarch(camPos, rayDir);
    if(t < TMAX)
    {
        vec3 vertPos = camPos + t * rayDir;
        vec3 n = calcNormal(vertPos);
        vec3 lightPos = vec3(2.0, 1.0, 2.0);
        // if(iMouse.z > 0.01)
        // {
        //     vec2 mousePos = TransUVToCenter(iMouse.xy);
        //     lightPos = vec3(mousePos, 1.);
        // }
        float diff = clamp(dot(normalize(lightPos - vertPos), n),0.0,1.0);
        float amb = dot(n, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5;
        color = vec3(diff * vec3(1, 1, 1) +  amb * vec3(0.2196, 0.2196, 0.2196));
    }
    return sqrt(color);//伽马矫正
}

#define AA 4
#define useAA 1
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = TransUVToCenter(fragCoord);
    vec3 Col = vec3(0.0, 0.0, 0.0);

#if useAA
    for(int i = 0; i < AA; i++){
        for(int j = 0; j < AA; j++){
            vec2 offset = ( (vec2(float(i), float(j)) - 0.5 * float(AA)) / float(AA) ) * 2.0; 
            vec2 offsetUV = TransUVToCenter(fragCoord + offset);
            Col += Render(offsetUV);
        }
    }
    Col = Col / float(AA * AA);
#else
    Col = Render(uv);
#endif
    // vec3 Col = vec3(0.0, 0.0, 0.0);
    // SubSampling(fragCoord, Col);
    // --- output --- 
    fragColor = vec4(Col, 1.0);
}