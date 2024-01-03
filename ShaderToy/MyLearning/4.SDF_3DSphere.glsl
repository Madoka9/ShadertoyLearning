vec2 TransUVToCenter(in vec2 fragCoord)
{
    return  2.0 * (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
}



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 Col = vec3(1, 1, 1);

    // --- output ---
    fragColor = vec4(Col, 1.0);
}