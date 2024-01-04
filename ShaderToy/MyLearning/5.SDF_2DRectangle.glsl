#define uvTiling 1.0

vec2 TransUVToCenter(in vec2 fragCoord)
{
    return uvTiling * 2.0 * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}

float calSDFRec(in vec2 uv, in vec2 v)
{
    vec2 d = abs(uv) - v;
    return length(max(d, 0.)) + min(max(d.x, d.y), 0.0); //外面部分 + 里面部分 点在里面时，d为负
}

// closest point
vec2 CalClosestPoint( in vec2 mousPos, in float r)
{
    vec2 pos = mousPos /  sqrt(mousPos.x * mousPos.x + mousPos.y * mousPos.y) * r;
    return pos;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float r = 0.5 + 0.2 * sin(iTime);
    vec2 uv = TransUVToCenter(fragCoord);
    //SDF
    float SD = calSDFRec(uv, vec2(r));
    vec3 c1 = 1. - sign(SD) * vec3(0.1, 0.4, 0.7); //区分内外
    float c2 = 1. - exp(-3. * abs(SD));
    float DisLine = 0.8 + 0.2 * sin(100. * abs(SD));
    vec3 Col = saturate( c1 * c2 * DisLine ) * vec3(1.0, 1.0, 1.0);
    Col = mix(Col, vec3(1.0, 1.0, 1.0), smoothstep(0.01, 0.0, abs(SD)));

    //Mouse Click
    if(iMouse.z > 0.01)
    {
        vec2 mousePos = TransUVToCenter(iMouse.xy);
        float SDMouse = calSDFRec(mousePos,vec2(r));
        Col = mix(Col, vec3(0.0, 1.0, 1.0), smoothstep(0.01, 0.0, abs(length(uv - mousePos) - abs(SDMouse))));
        Col = mix(Col, vec3(0.0, 1.0, 1.0), smoothstep(0.05, 0.0, length(uv - mousePos)));
        
        //Draw Closest Point
        vec2 ClosePointPos = CalClosestPoint(mousePos, r);
        Col = mix(Col, vec3(1.0, 0.0, 0.0), smoothstep(0.05, 0.0, length(uv - ClosePointPos)));
    }
    //---output---
    fragColor = vec4(Col, 1.0);
}