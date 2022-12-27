#ifndef RAY_GLSL
#define RAY_GLSL

#include "utility/render.glsl"
#include "utility/player.glsl"
#include "utility/camera.glsl"
#include "utility/common.glsl"
#include "utility/asteroids.glsl"
#include "utility/black_hole.glsl"

#iChannel2 "file://utility/precompute.glsl"

/* Get minimal distance to each object, objects are generated here for now */
vec4 getColAndDist(vec3 point) {
    // vec3 bp = vec3(5., 0., 0.);
    // float distToBox = sdBox(point - bp, Box(1., 1., 1., bp));

    vec2 offset = texelFetch(iChannel0, ivec2(0, 1), 0).xy;
    float distPiramid = createPlayer(point, vec3(0.), vec3(offset, 0.));

    float distAsteroids = createAsteroids(point);
    float distProjectiles = createProjectiles(point);

    /// Use respective colors for respective objects
    float hp = 0.3 - texelFetch(iChannel0, ivec2(P_COLLISION_COL, PLAYER_LAYER_ROW), 0).x;
    vec3 color = vec3(0.);
    if(hp == 0.3) {color = PLAYER_COLOR_3;}
    if(abs(hp - 0.2) < 0.01) {color = PLAYER_COLOR_2;}
    if(abs(hp - 0.1) < 0.01) {color = PLAYER_COLOR_1;}

    vec4 colDist = minSd(vec4(color, distPiramid), vec4(ASTEROID_COLOR, distAsteroids));
    colDist = minSd(vec4(PROJECTILE_COLOR, distProjectiles), colDist);

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
/// ray_velocity should be normalized
/// color is the resulting color
vec4 blackHoleRender(vec3 currentPosition, vec3 rayVelocity, inout vec3 color) {
    // 4th coord is whether we found a point or diverged
    vec4 currentLocationAndMode = vec4(0.);
    for (int i = 0; i < MAX_STEPS; ++i) {
        vec4 colAndDist = getColAndDist(currentPosition);

        rayVelocity += blackHoleNullParticleAccl(currentPosition) * dt;

        float dist_to_travel = length(rayVelocity) * dt;
        if (dist_to_travel > colAndDist.w) {
            rayVelocity *= colAndDist.w / dist_to_travel;
        }

        currentPosition += rayVelocity * dt;

        // check that we got below event horizon
        if (distance(BH_pos, currentPosition) < BH_R) {
            color = vec3(0.);
            currentLocationAndMode.xyzw = vec4(currentPosition, 1.);
            break;
        }

        // check that we landed on a point
        if (abs(colAndDist.w) < SURF_DIST) {
            color = colAndDist.rgb;
            currentLocationAndMode = vec4(currentPosition, 1.);
            break;
        }
    }
    return currentLocationAndMode;
}

/// color is the resulting color
vec4 blackHoleRenderPrecomputed(vec2 fragCoord, inout vec3 color) {
    /// interpolate position and velocity
    vec2 flooredfragCoord = floor(fragCoord);  // remove possible .5
    vec4 currentPositionAndMode = vec4(0.);
    vec4 rayVelocityAndMode = vec4(0.);
    if (
        flooredfragCoord.x <= 1. || flooredfragCoord.y <= 0. ||
        flooredfragCoord.x >= (iResolution.x-1.) || flooredfragCoord.y >= (iResolution.y-1.)
    ) {
        color = vec3(0.);
        return vec4(vec3(0.), 1.);  /// we are at border, so inteprpolation is not possible
    } else {
        bool is_velocity = (flooredfragCoord.x-2.*floor(flooredfragCoord.x/2.)) == 0.;
        if (is_velocity) {
            rayVelocityAndMode = texelFetch(iChannel2, ivec2(flooredfragCoord), 0);
            currentPositionAndMode = (
                texelFetch(iChannel2, ivec2(flooredfragCoord-vec2(1., 0.)), 0) * .5 +
                texelFetch(iChannel2, ivec2(flooredfragCoord+vec2(1., 0.)), 0) * .5
            );
        } else {
            currentPositionAndMode = texelFetch(iChannel2, ivec2(flooredfragCoord), 0);
            rayVelocityAndMode = (
                texelFetch(iChannel2, ivec2(flooredfragCoord-vec2(1., 0.)), 0) * .5 +
                texelFetch(iChannel2, ivec2(flooredfragCoord+vec2(1., 0.)), 0) * .5
            );
        }
        /// if we reached black hole in any of them, return 0
        if ((rayVelocityAndMode.w + currentPositionAndMode.w) < 2.) {
            color = vec3(0.);
            return vec4(vec3(0.), 1.);
        }
    }
    return blackHoleRender(currentPositionAndMode.xyz, rayVelocityAndMode.xyz, color);
}

#endif  // RAY_GLSL