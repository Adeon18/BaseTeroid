#include "render.glsl"

#iChannel0 "self"
/*
 * Save the rotation radians so that the ship reembers it's previous
 * rotation.
 * ! There are 3 more variables to use in case needed :)
*/
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float rotationRad = texelFetch(iChannel0, ivec2(0, 0), 0).x;
    vec2 controls = vec2(0.);
    rotationRad += controls.x * 0.1;

    fragColor = vec4(rotationRad, 0, 0, 0);
}