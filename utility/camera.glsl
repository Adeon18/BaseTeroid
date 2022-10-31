#ifndef CAMERA_GLSL
#define CAMERA_GLSL

#include "utility/render.glsl"

vec3 getRo(vec4 camera_props) {
    vec3 ro = vec3(-camera_props.x, camera_props.y, camera_props.z);
    ro.xz *= Rotate(PI);
    return ro;
}

// lookat - central point of the camera
// zoom - zoom  ==  distance from camera to the screen
// c - center point on the screen = ro + forward * zoom factor z
// ro = ray origin
// right - if we look straight from the camera on screen, it is x offset
// up - if we look straight from the camera on screen, it is y offset
// intersection - the point on the screen where ray passes through it
vec3 getRd(vec2 uv, vec3 ro, vec4 camera_props) {
    // variables to control camera if we need it
    vec3 lookat = vec3(camera_props.xy, 0.);
    float zoom = camera_props.w;

    vec3 forward = normalize(lookat - ro),
        right = normalize(cross(vec3(0, 1, 0), forward)),
        up = cross(forward, right),
        c = ro + forward * zoom,
        intersection = c + uv.x * right + uv.y * up,
        d = normalize(intersection - ro);
    return d;
}

#endif // CAMERA_GLSL