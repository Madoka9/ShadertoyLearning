
#define useif 0
#define uvTiling 3.0
#define sStepMultiplier 0.9
#define PI 3.1415926
/****************************************************************************/
/*  -----------------------------
    -                           -
    -       Enum_FunType        -
    -                           -
    -----------------------------
*/
#define FuncType_Sinx 0
#define FuncType_Cosx 1


/****************************************************************************/
vec2 TransUVToCenter(in vec2 fragCoord)
{
    return uvTiling * 2.0 * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}
//Grid
vec3 DrawNumberGrid(in vec2 uv)
{
    vec3 Col = vec3(0.0, 0.0, 0.0);
    // float xAxisWidth = 0.001; 0.001 小于一个像素大小，不会显示
    // float yAxisWidth = 0.001;
    /*
        fwidth（v） = abs( ddx(v) )+ abs(ddy(v))
        fwidth(uv.x) = abs(δx) + abs(0)
        fwidth(uv.y) = abs(0) + abs(δy)
    */

    // trans |0-1|0-1| to |0-1|1-0|
    //vec2 uvCeil =fract(uv);
    vec2 uvCeil = 1.0 - 2.0 * abs(fract(uv) - 0.5);

    float xAxisWidth = fwidth(uv.y);
    float yAxisWidth = fwidth(uv.x); 
    float xGridWidth = fwidth(uv.y);
    float yGridWidth = fwidth(uv.x); 
#if useif
    //Grid
    if(uvCeil.x < 2.0 * xGridWidth || uvCeil.y < 2.0 * yGridWidth) {Col = vec3(1.0, 1.0, 1.0);}
    //Axis
    if(abs(uv.y) < 2.0 * xAxisWidth) {Col = vec3(1.0, 0.0, 0.0);}
    if(abs(uv.x) < 2.0 * yAxisWidth) {Col = vec3(0.0, 1.0, 0.0);}
#else
    vec3 GridCol =(vec3(1.0, 1.0, 1.0) * saturate(step(uvCeil.x, xGridWidth) + step(uvCeil.y, yGridWidth))) * (1.0 - step(abs(uv.y),xAxisWidth) -  step(abs(uv.x),yAxisWidth));
    vec3 AxisCol = step(abs(uv.y),xAxisWidth) * vec3(1.0, 0.0, 0.0) +  step(abs(uv.x),yAxisWidth) * vec3(0.0, 1.0, 0.0);
    //vec3 GridCol =(vec3(1.0, 1.0, 1.0) * saturate(smoothstep(xGridWidth, sStepMultiplier * xGridWidth, uvCeil.x) + smoothstep(yGridWidth, sStepMultiplier * yGridWidth, uvCeil.y))) * (1.0 - smoothstep(xAxisWidth, sStepMultiplier * xAxisWidth, abs(uv.y)) -  smoothstep(yAxisWidth, yAxisWidth * sStepMultiplier, abs(uv.x)));
    //vec3 AxisCol = smoothstep(xAxisWidth, sStepMultiplier*xAxisWidth, abs(uv.y)) * vec3(1.0, 0.0, 0.0) +  smoothstep(yAxisWidth, sStepMultiplier * yAxisWidth, abs(uv.x)) * vec3(0.0, 1.0, 0.0);
    Col = (GridCol + AxisCol);
#endif
    return Col;
}
//Grid2
vec3 DrawNumberGridTab(in vec2 uv)
{
    vec3 col = vec3(0.4118, 0.4118, 0.4118);
    //gridtab
    vec2 grid = floor(mod(uv, 2.0));
    if(grid.x == grid.y)
    {
        col = vec3(0.2549, 0.2549, 0.2549);
    }

    //Axis
    vec3 AxisCol = smoothstep(fwidth(uv.y), sStepMultiplier*fwidth(uv.y), abs(uv.y)) * vec3(1.0, 0.0, 0.0) +  smoothstep(fwidth(uv.x), sStepMultiplier * fwidth(uv.x), abs(uv.x)) * vec3(0.0, 1.0, 0.0);
    col = col + AxisCol;

    return col;
}


//MathFunclib
float MathFuncLib(in float x, in int FuncType)
{
    float a = 0.0;
    float T = 4.0 + 2.0 * sin(iTime);
    switch(FuncType)
    {
        //todo
        case 0:
            a = sin(2.0 * PI / T * x);
            break;
        case 1:
            a = cos(2.0 * PI / T * x);
            break;
        case 2:
            a = mod(x, 2.0);
            break;
        case 3:
            a = floor(mod(x, 2.0));
            break;
    }
    return a;
}

//绘制线段
vec3 DrawSegment(in vec2 pC, in vec2 pA, in vec2 pB, in float lineWidth, in vec3 lineCol)
{
    vec2 ab = pB - pA;
    vec2 ac = pC - pA;
    float d = length(ab * clamp(dot(ab, ac) / dot(ab, ab), 0.0 ,1.0) - ac);
    //return step(d, lineWidth) * lineCol;
    return smoothstep(lineWidth, lineWidth * 0.99, d) * lineCol;
}


//微分法 - 绘制函数图像 - 每一段都需要计算，消耗较大
vec3 DrawFunc(in vec2 uv, in int funcType, in vec3 LineCol)
{
    vec3 Col = vec3(0.0, 0.0, 0.0);
    for(float  i = 0.0; i < iResolution.x ; i++)
    {   
        float x1 = TransUVToCenter(vec2(i,0.0)).x;
        float x2 = TransUVToCenter(vec2(i+ 1.0, 0.0)).x;
        Col += DrawSegment(uv,vec2(x1, MathFuncLib(x1,funcType)), vec2(x2, MathFuncLib(x2,funcType)), fwidth(uv.x),LineCol);
    }
    return Col;
}

//subsampling - 绘制函数图像 性能消耗和采样次数有关，不过总体上来说比微分法消耗小
#define AA 4 // 4x4 = 16次采样
void SubSampling(in vec2 uv, in int funcType , out vec3 Col)
{
    float count = 0.0;
    for(int i = 0; i < AA; i++){
        for(int j = 0; j < AA; j++){
            vec2 offset = ( (vec2(float(i), float(j)) - 0.5 * float(AA)) / float(AA) ) * 2.0; 
            //vec2 offsetUV = TransUVToCenter(uv + offset);
            vec2 offsetUV = uv + offset;
            float f = MathFuncLib(offsetUV.x,funcType);
            count += smoothstep(f - 0.01, f + 0.01, offsetUV.y);
        }
    }
    
    if(count > float(AA * AA) / 2.0 )
    {
        count = float(AA * AA) - count;
    }
    count = count * 2.0 / float(AA * AA);
    //Col = mix(Col, vec3(0.0, 1.0, 0.4157), count);
    Col = vec3(count);
}


//Main.
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{

    vec2 uv = TransUVToCenter(fragCoord);
    //---------Draw Grid----------
    vec3 GridCol = DrawNumberGrid(uv);

    vec3 GridTab = DrawNumberGridTab(uv);

    //---------Draw Line-----------
    vec3 LineImage = DrawSegment(uv, vec2(-3.0,-3.0), vec2(3.0, 3.0),fwidth(uv.x), vec3(0.8941, 0.0314, 0.7804));
    vec3 SinImage = DrawFunc(uv, FuncType_Sinx, vec3(0.9333, 1.0, 0.0));
    vec3 CosImage = DrawFunc(uv, FuncType_Cosx, vec3(0.0, 0.6824, 1.0));
    vec3 testImage = DrawFunc(uv, 2, vec3(0.298, 0.0, 1.0));
    vec3 testImage2 = DrawFunc(uv, 3, vec3(0.3686, 0.3725, 0.0));

    //---------Batch Col----------
    //vec3 Col = GridTab + testImage + testImage2;
    //vec3 Col = mix(GridTab,SinImage,SinImage.r);
    //vec3 Col = GridTab + mix(SinImage,GridCol,0.5);
    vec3 Col = GridTab;
    SubSampling(uv, 0 , Col);

    //---------output------------
    fragColor = vec4(vec3(step(Col.r, 0.01)), 1.0);
}