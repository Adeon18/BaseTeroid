#include "utility/camera.glsl"
#include "utility/black_hole.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "self"

#define MAX_STEPS_PRECOMPUTE 256
const float precompute_dt_divisor = 2.;
vec4 height1precompute(vec3 current_position, vec3 ray_velocity, bool put_velocity) {
    // 4th coord is whether we reached height 1 or got past event horison
    vec4 rayLocationOrVelocityAndMode = vec4(0.);
    float precompute_dt = dt / precompute_dt_divisor;
    for (int i = 0; i < MAX_STEPS_PRECOMPUTE * int(precompute_dt_divisor); ++i) {
        float dist = abs(current_position.z+1.);

        ray_velocity += blackHoleNullParticleAccl(current_position) * precompute_dt;

        float dist_to_travel = length(ray_velocity) * precompute_dt;
        if (dist_to_travel > dist) {
            ray_velocity *= dist / dist_to_travel;
        }

        current_position += ray_velocity * precompute_dt;

        // check that we got below event horizon
        if (distance(BH_pos, current_position) < BH_R) {
            break;
        }

        // check that we landed on a point
        if (abs(dist) < SURF_DIST) {
            if (put_velocity) {
                rayLocationOrVelocityAndMode = vec4(normalize(ray_velocity), 1.);
            } else {
                rayLocationOrVelocityAndMode = vec4(current_position, 1.);
            }
            break;
        }
    }
    return rayLocationOrVelocityAndMode;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (iFrame == 0) {
        vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;
        // TODO: I couldn't use the data channel for some reason.
        // texelFetch(iChannel0, ...) works if we #include <player.glsl>, but
        // then texelFetch(iChannel1, ...) doesn't work. Since camera position
        // is a constant currently, I just pasted it here for a temporary fix
        vec4 camera_props = vec4(0., 0., 20., 0.5);// texelFetch(iChannel0, ivec2(C_OPTIONS_COL, CAMERA_LAYER_ROW), 0);
        vec3 ro = getRo(camera_props);
        vec3 rd = getRd(uv, ro, camera_props);
        /// put velocity if fragCoord.x is divisible by 2
        float flooredfragCoordx = floor(fragCoord.x);  // remove possible .5
        bool put_velocity = (flooredfragCoordx-2.*floor(flooredfragCoordx/2.)) == 0.;
        fragColor = height1precompute(ro, rd, put_velocity);
    } else {
        fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    }
}