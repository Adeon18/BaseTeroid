#ifndef PRECOMPUTE_BASE_GLSL
#define PRECOMPUTE_BASE_GLSL

#include "utility/camera.glsl"
#include "utility/black_hole.glsl"

#define MAX_STEPS_PRECOMPUTE 512
const float precompute_dt_divisor = 10.;
float heightprecompute(inout vec3 current_position, inout vec3 ray_velocity, float aim_height) {
    // mode is whether we reached height 1 (1.) or got below event horison (0.)
    // or did not converge (2.)
    float mode = 2.;
    float precompute_dt = dt / precompute_dt_divisor;
    for (int i = 0; i < MAX_STEPS_PRECOMPUTE * int(precompute_dt_divisor); ++i) {
        float dist = abs(current_position.z - aim_height);

        ray_velocity += blackHoleNullParticleAccl(current_position) * precompute_dt;

        vec3 position_delta = ray_velocity * precompute_dt;
        float dist_to_travel = length(position_delta);
        if (dist_to_travel > dist) {
            position_delta *= dist / dist_to_travel;
        }
        current_position += position_delta;

        // check that we got below event horizon
        if (distance(BH_pos, current_position) < BH_R) {
            mode = 0.;
            break;
        }

        // check that we landed on a plane
        if (abs(dist) < SURF_DIST) {
            ray_velocity = ray_velocity;
            mode = 1.;
            break;
        }
    }
    return mode;
}

#endif  // PRECOMPUTE_BASE_GLSL