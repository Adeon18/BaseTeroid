#ifndef ASTEROIDS_GLSL
#define ASTEROIDS_GLSL

#include "render.glsl"
#include "common.glsl"
#include "camera.glsl"
#iChannel0 "file://utility/data_channel.glsl"

float createAsteroids(vec3 point) {
    float distToSphere = 99999.;

    vec2 upRightUV = .5 * iResolution.xy / iResolution.y;
    vec4 camera_props = texelFetch(iChannel0, ivec2(0., CAMERA_LAYER_ROW), 0);
    vec3 ro = getRo(camera_props);
    vec3 upRightRD = getRd(upRightUV, ro, camera_props);
    float cosAngle = dot(-1. * ro, upRightRD) / length(ro);
    float dist = length(ro) / cosAngle;
    vec2 screenSize = (ro + upRightRD * dist).xy;
    screenSize += 1.;

    for (int i = 0; i < int(NUM_ASTEROIDS); ++i) {
        Sphere sph = Sphere(vec3((
            texelFetch(iChannel0, ivec2(i, 0), 0).xy * 2. - 1.
        ) * screenSize, 0.), 1.);
        distToSphere = min(distToSphere, sdSphere(point - sph.pos, sph));
    }

    return distToSphere;
}

#endif // ASTEROIDS_GLSL