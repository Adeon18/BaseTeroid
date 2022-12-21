#ifndef RAY_GLSL
#define RAY_GLSL

#include "utility/render.glsl"
#include "utility/player.glsl"
#include "utility/camera.glsl"
#include "utility/common.glsl"
#include "utility/asteroids.glsl"
#include "utility/black_hole.glsl"
#include "utility/precompute_fetch.glsl"
#include "utility/precompute1_fetch.glsl"

#iChannel2 "file://utility/precompute.glsl"
#iChannel3 "file://utility/precompute1.glsl"

/* Get minimal distance to each object, objects are generated here for now */
vec4 getColAndDist(vec3 point) {
    // vec3 bp = vec3(5., 0., 0.);
    // float distToBox = sdBox(point - bp, Box(1., 1., 1., bp));

    vec2 offset = texelFetch(iChannel0, ivec2(0, 1), 0).xy;
    float distPiramid = createPlayer(point, vec3(0.), vec3(offset, 0.));

    float distAsteroids = createAsteroids(point);

    /// Use respective colors for respective objects
    vec4 colDist = minSd(vec4(PLAYER_COLOR, distPiramid), vec4(ASTEROID_COLOR, distAsteroids));

    /// render event horizon
    colDist = minSd(vec4(vec3(0.), length(point - BH_pos) - BH_R), colDist);

    return colDist;
}

/* Function for getting a normal to the plane */
vec3 getNormal(vec3 point) {
    float dist = getColAndDist(point).w;
    vec2 offset = vec2(.01, 0);

    vec3 normal = dist - vec3(
        getColAndDist(point - offset.xyy).w,
        getColAndDist(point - offset.yxy).w,
        getColAndDist(point - offset.yyx).w
    );

    return normalize(normal);
}

/*
 * Handle lighting and shadows
 * Takes current light level, new light position and a point
 * Takes color
 */
vec3 getLighting(vec3 point, vec3 lightPos, vec3 color) {
    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = getNormal(point);
    float lightIntencity = clamp(dot(normal, lightDir)*.5+.5, 0., 1.);
    // Get shadows
    // Use a point a bit off so the loop does not immediately end
    // vec3 stopColor = vec3(0.);
    // vec3 lightStopPoint = blackHoleRender(point + normal * SURF_DIST * 2., lightDir, stopColor).xyz;
    // if (length(point - lightStopPoint) > SURF_DIST) { lightIntencity *= .3; }
    return color * lightIntencity;
}

/// current_position is the ray origin
/// color is the resulting color
const float ray_dt_divisor = 1.;
vec4 blackHoleRender(vec2 fragCoord, vec3 currentPosition, vec3 rayVelocity, inout vec3 color) {
    // 4th coord is whether we found a point or diverged
    // 0 for diverged
    // 1 for converged on a point
    vec4 currentLocationAndMode = vec4(0.);
    float ray_dt = dt / ray_dt_divisor;
    for (int i = 0; i < MAX_STEPS * int(ray_dt_divisor); ++i) {
        vec4 colAndDist = getColAndDist(currentPosition);

        rayVelocity += blackHoleNullParticleAccl(currentPosition) * ray_dt;

        vec3 positionDelta = rayVelocity * ray_dt;
        float dist_to_travel = length(positionDelta);
        if (dist_to_travel > colAndDist.w) {
            positionDelta *= colAndDist.w / dist_to_travel;
        }

        currentPosition += positionDelta;

        // check that we got past height of second precomputed region
        if (currentPosition.z >= 1.02) {
            float mode = fetchPrecomputed1(fragCoord, currentPosition, rayVelocity);
            if (mode == 0.) {  // reached below event horison
                color = vec3(0.);
                currentLocationAndMode = vec4(currentPosition, 1.);
                break;
            }
            if (mode == 2.) {  // diverged
                currentLocationAndMode = vec4(currentPosition, 2.);
                break;
            }
        }

        // check that we got below event horizon
        if (distance(BH_pos, currentPosition) < BH_R) {
            color = vec3(0.);
            currentLocationAndMode = vec4(currentPosition, 1.);
            break;
        }

        // check that we landed on a point
        if (abs(colAndDist.w) < SURF_DIST) {
            color = colAndDist.rgb;
            currentLocationAndMode = vec4(currentPosition, 1.);
            break;
        }
    }
    if (currentLocationAndMode.w != 1.) {
        color = 0.2 * normalize(rayVelocity);
    }
    return currentLocationAndMode;
}

/// color is the resulting color
vec4 blackHoleRenderPrecomputed(vec2 fragCoord, inout vec3 color) {
    vec3 position = vec3(0.);
    vec3 velocity = vec3(0.);
    float mode = fetchPrecomputed(fragCoord, position, velocity);
    if (mode == 0.) {  // reached event horison
        color = vec3(0.);
        return vec4(vec3(0.), 1.);
    }
    if (mode == 2.) {  // diverged
        color = 0.2 * normalize(velocity);
        return vec4(vec3(0.), 2.);
    }
    return blackHoleRender(fragCoord, position, velocity, color);
}

#endif  // RAY_GLSL