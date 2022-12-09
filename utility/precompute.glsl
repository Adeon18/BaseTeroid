#include "utility/ray.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "self"

vec4 height1precompute(vec3 current_position, vec3 ray_velocity) {
    // 4th coord is whether we found a point or diverged
    vec4 rayLocation = vec4(0.);
    for (int i = 0; i < MAX_STEPS * 5; ++i) {
        float dist = abs(current_position.z-1.);

        ray_velocity += blackHoleNullParticleAccl(current_position) * dt;

        float dist_to_travel = length(ray_velocity) * dt;
        if (dist_to_travel > dist) {
            ray_velocity *= dist / dist_to_travel;
        }

        current_position += ray_velocity * dt;

        // check that we got below event horizon
        if (distance(BH_pos, current_position) < BH_R) {
            rayLocation.xy = current_position.xy;
            break;
        }

        // check that we landed on a point
        if (abs(dist) < SURF_DIST) {
            rayLocation.xy = current_position.xy;
            break;
        }
    }
    return rayLocation;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (iFrame == 0) {
        vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;
        vec4 camera_props = texelFetch(iChannel0, ivec2(0., CAMERA_LAYER_ROW), 0);
        vec3 ro = getRo(camera_props);
        vec3 rd = getRd(uv, ro, camera_props);
        fragColor = height1precompute(ro, rd);
    } else {
        discard;
        // fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    }
}