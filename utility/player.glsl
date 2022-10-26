#include "render.glsl"

#iChannel2 "file://rotate.glsl"

float createPlayer(vec3 point, vec3 originPos, vec3 controls, vec3 offset) {

    float rotationRad = texelFetch(iChannel2, ivec2(0, 0), 0).x;
    mat2 rotationMat = Rotate(rotationRad);
    vec3 newOffset = vec3(0., offset.y, 0.);

    Piramid body = Piramid(vec3(0., 0., 0.) + originPos, 1.5);


    vec3 bodyPos = point - body.pos;

    bodyPos -= offset;
    bodyPos.xy *= rotationMat;


    bodyPos *= vec3(1., 1., 2.);

    return sdPyramid(bodyPos, body.height) / 2.5;
}
