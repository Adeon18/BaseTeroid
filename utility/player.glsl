#include "render.glsl"

#iChannel3 "file://rotate.glsl"


float createPlayer(vec3 point, vec3 originPos, vec3 controls, vec3 offset) {
    Piramid body = Piramid(vec3(0., 0., 0.) + originPos + offset, 1.5);

    vec3 bodyPos = point - body.pos;

    bodyPos.xy *= Rotate(controls.x);

    bodyPos *= vec3(1., 1., 2.);

    return sdPyramid(bodyPos, body.height) / 2.5;
}
