#define TMIN 0.1
#define TMAX 100.0
#define RAYMARCHTIMEMAX 256
#define PRECISION 0.001
#define PI 3.1415926
#define RADIUS 1.

vec2 TransUVToCenter(in vec2 fragCoord)
{
    return  2.0 * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

float SDFSphere(in vec3 pos, in float r)
{
    return length(pos) - r;
}

float SDFPlane(in vec3 p)
{
    return p.y;
}

float map(in vec3 p)
{
    float d = SDFSphere(p,RADIUS);
    d = min(d, SDFPlane(p + vec3(0, 1, 0)));
    return d;
}

float RayMarch(in vec3 rayOrg, in vec3 rayDir)
{
    float t = TMIN;
    for(int i = 0; i < RAYMARCHTIMEMAX && t < TMAX; i++)
    {
        vec3 pos = rayOrg + t * rayDir;
        float d = map(pos);
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
    return normalize( k.xyy*map( p + k.xyy*h) + 
                      k.yyx*map( p + k.yyx*h) + 
                      k.yxy*map( p + k.yxy*h) + 
                      k.xxx*map( p + k.xxx*h) );
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
    vec3 targetPos = vec3(0,0,0);
    mat3 matCam = setCamera(targetPos, camPos, 0.0);
    vec3 rayDir = normalize(matCam * vec3(uv, 1.0));
    float t = RayMarch(camPos, rayDir);
    if(t < TMAX)
    {
        vec3 vertPos = camPos + t * rayDir;
        vec3 n = calcNormal(vertPos);
        vec3 lightPos = vec3(2.0, 2.0, 0.0);
        float diff = clamp(dot(normalize(lightPos - vertPos), n),0.0,1.0);
        //shadow -- https://iquilezles.org/articles/rmshadows/
        //从物体向光源反向Raymarch，
        float st = RayMarch(vertPos,normalize(lightPos - vertPos));
        if(st < TMAX)
        {
            diff *= 0.1;
        }

        float amb = dot(n, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5;
        color = vec3(diff * vec3(0.4314, 0.4078, 0.4078) +  amb * vec3(0.4196, 0.4196, 0.4196));
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