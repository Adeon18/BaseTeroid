#include "render.glsl"

#iChannel0 "self"
#iChannel1 "file://input.glsl"


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float rotationRad = texelFetch(iChannel0, ivec2(0, 0), 0).x;
    vec2 controls = texelFetch(iChannel1, ivec2(0, 0), 0).xy;
    rotationRad += controls.x * 0.1;

    fragColor = vec4(rotationRad, 0, 0, 0);
}