#ifndef ASTEROIDS_GLSL
#define ASTEROIDS_GLSL

#include "render.glsl"

#define ASTEROID_DIST 5.

float modulo(float a, float b) {
    return a - (b * floor(a/b));
}

float createAsteroids(vec3 point, vec3 originPos, vec3 offset) {
    // vec2 pointShifted = point.xy; // - vec2(modulo(iTime, ASTEROID_DIST), modulo(iTime, ASTEROID_DIST));

    vec3 pointShifted = point - vec3(iTime, iTime, 0.);
    vec2 sphPos = floor(pointShifted.xy / ASTEROID_DIST + 0.5) * ASTEROID_DIST;
    Sphere sph = Sphere(vec3(sphPos, 0.), 1.);
    float distToSphere = sdSphere(pointShifted - sph.pos, sph);
    return distToSphere;
}

#endif // ASTEROIDS_GLSL