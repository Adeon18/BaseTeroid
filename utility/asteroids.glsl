#ifndef ASTEROIDS_GLSL
#define ASTEROIDS_GLSL

#include "render.glsl"
#iChannel1 "file://utility/pseudorandom_movement.glsl"

#define ASTEROID_DIST 5.
#define NUM_ASTEROIDS 16
#define SCALE 10.

float modulo(float a, float b) {
    return a - (b * floor(a/b));
}

void rnd_transform(inout float x) {
    x = (1. - x) * x * 3.99;
}

void rnd_transform(inout vec2 v) {
    rnd_transform(v.x);
    rnd_transform(v.y);
}

float genAsteroid(vec3 point, vec2 spCGen) {
    Sphere sph = Sphere(vec3((spCGen * 2. - 1.) * vec2(15., 25.), 0.), 1.);
    return sdSphere(point - sph.pos, sph);
}

float createAsteroids(vec3 point) {
    float distToSphere = 99999.;

    for (int i = 0; i < NUM_ASTEROIDS; ++i) {
        distToSphere = min(distToSphere, genAsteroid(point, texelFetch(iChannel1, ivec2(i, 0), 0).xy));
    }

    return distToSphere;
}

#endif // ASTEROIDS_GLSL