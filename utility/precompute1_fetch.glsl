#ifndef PRECOMPUTE1_FETCH_GLSL
#define PRECOMPUTE1_FETCH_GLSL

/// returns 0 when fetch is at border of black hole reached
float fetchPrecomputed1(vec2 fragCoord, inout vec3 position, inout vec3 velocity) {
    /// interpolate position and velocity
    vec2 flooredfragCoord = floor(fragCoord);  // remove possible .5
    vec4 currentPositionAndMode = vec4(0.);
    vec4 rayVelocityAndMode = vec4(0.);
    float mode = 1.;
    if (
        flooredfragCoord.x <= 1. || flooredfragCoord.y <= 0. ||
        flooredfragCoord.x >= (iResolution.x-1.) || flooredfragCoord.y >= (iResolution.y-1.)
    ) {
        return 0.;  /// we are at border, so inteprpolation is not possible
    } else {
        bool is_velocity = (flooredfragCoord.x-2.*floor(flooredfragCoord.x/2.)) == 0.;
        if (is_velocity) {
            rayVelocityAndMode = texelFetch(iChannel3, ivec2(flooredfragCoord), 0);
            mode = rayVelocityAndMode.w;
            currentPositionAndMode = (
                texelFetch(iChannel3, ivec2(flooredfragCoord-vec2(1., 0.)), 0) * .5 +
                texelFetch(iChannel3, ivec2(flooredfragCoord+vec2(1., 0.)), 0) * .5
            );
        } else {
            currentPositionAndMode = texelFetch(iChannel3, ivec2(flooredfragCoord), 0);
            mode = currentPositionAndMode.w;
            rayVelocityAndMode = (
                texelFetch(iChannel3, ivec2(flooredfragCoord-vec2(1., 0.)), 0) * .5 +
                texelFetch(iChannel3, ivec2(flooredfragCoord+vec2(1., 0.)), 0) * .5
            );
        }
        /// if we reached black hole in any of them, return 0
        if ((rayVelocityAndMode.w + currentPositionAndMode.w) < 2.) {
            return 0.;
        }
    }
    position = currentPositionAndMode.xyz;
    velocity = rayVelocityAndMode.xyz;
    return mode;
}

#endif  // PRECOMPUTE1_FETCH_GLSL