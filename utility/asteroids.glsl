#ifndef ASTEROIDS_GLSL
#define ASTEROIDS_GLSL

#include "render.glsl"
#include "common.glsl"
#iChannel1 "file://utility/data_channel.glsl"

float genAsteroid(vec3 point, vec2 spCGen) {
    Sphere sph = Sphere(vec3((spCGen * 2. - 1.) * vec2(10., 10.), 0.), 1.);
    return sdSphere(point - sph.pos, sph);
}

float createAsteroids(vec3 point) {
    float distToSphere = 99999.;

    for (int i = 0; i < int(NUM_ASTEROIDS); ++i) {
        distToSphere = min(distToSphere, genAsteroid(point, texelFetch(iChannel1, ivec2(i, 0), 0).xy));
    }

    return distToSphere;
}

#endif // ASTEROIDS_GLSL