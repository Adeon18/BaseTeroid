#iChannel0 "file://input.glsl"
#iChannel1 "self"
#iChannel2 "file://rotate.glsl"

#include "render.glsl"

vec2 calcOffset(vec2 offset) {
    float turnSpeed = 0.1 / 100.;
    float velocity = 20. / 100.;
    vec2 controls = texelFetch(iChannel0, ivec2(0, 0), 0).xy;


    controls.x *= turnSpeed;
    controls.y *= velocity;
    float rotationRad = texelFetch(iChannel2, ivec2(0, 0), 0).x;
    mat2 rotationMat = Rotate(rotationRad);
    controls *= rotationMat;
    controls.x *= -1.;

    offset += controls;
    return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 offset = texelFetch(iChannel1, ivec2(0, 0), 0).xy;
    
    offset = calcOffset(offset);

    fragColor = vec4(offset, 0., 0.);
}