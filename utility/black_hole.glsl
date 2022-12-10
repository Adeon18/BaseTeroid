#ifndef BLACK_HOLE_GLSL
#define BLACK_HOLE_GLSL

#include "utility/common.glsl"

const vec3 BH_pos = vec3(-.5, 1.5, -14.);  // BH position
const float BH_R = 1.;                     // event horizon radius
/// how much acceleration a black hole exerts on a light particle
vec3 blackHoleNullParticleAccl(vec3 p) {
    vec3 r = (p - BH_pos);
    return -1.5 * BH_R * r / pow(length(r), 5.0);
}
const float dt = 0.15;

#endif  // BLACK_HOLE_GLSL