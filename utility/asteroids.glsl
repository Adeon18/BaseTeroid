#ifndef ASTEROIDS_GLSL
#define ASTEROIDS_GLSL

#include "render.glsl"
#include "common.glsl"
#include "camera.glsl"
#iChannel0 "file://utility/data_channel.glsl"

#define POTATO 1

float createAsteroids(vec3 point) {
    float distToSphere = 99999.;

    vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;

    int num_asteroids = int(NUM_ASTEROIDS);
    for (int i = 0; i < num_asteroids; ++i) {
        Sphere sph = Sphere(vec3((
            texelFetch(iChannel0, ivec2(i, 0), 0).xy * 2. - 1.
        ) * screenSize, 0.), 1.);
        if (POTATO == 1) {
            distToSphere = min(distToSphere, sdAsteroid(point - sph.pos, sph, i));    
        } else {
            distToSphere = min(distToSphere, sdSphere(point - sph.pos, sph));
        }
    }

    return distToSphere;
}

float createProjectiles(vec3 point) {
    float distToProjectiles = 99999.;

    vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;

    int num_projectiles = int(NUM_PROJECTILES);
    for (int i = 0; i < num_projectiles; ++i) {
        Sphere sph = Sphere(vec3((
            texelFetch(iChannel0, ivec2(i, PROJECTILE_LAYER_ROW), 0).xy * 2. - 1.
        ) * screenSize, 0.), PROJECTILE_RADIUS);
        distToProjectiles = min(distToProjectiles, sdSphere(point - sph.pos, sph));
    }

    return distToProjectiles;
}

#endif // ASTEROIDS_GLSL