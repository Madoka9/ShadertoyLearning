void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = ((fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y)) * 2.0 ;

    float uvLength = length(uv);
    float uvStepValue = 0.1;
    float stepCol = step(uvLength, uvStepValue);

    fragColor =vec4(vec3(stepCol) ,1.0 );
}