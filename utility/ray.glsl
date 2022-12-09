#ifndef RAY_GLSL
#define RAY_GLSL

#include "utility/render.glsl"
#include "utility/player.glsl"
#include "utility/camera.glsl"
#include "utility/common.glsl"
#include "utility/asteroids.glsl"

const vec3 BH_pos = vec3(0., 0., -10.);  // BH position
const float BH_R = 0.5;  // event horizon radius
/// how much acceleration a black hole exerts on a light particle
vec3 blackHoleNullParticleAccl(vec3 p) {
    vec3 r = (p - BH_pos);
    return -1.5 * BH_R * r / pow(length(r), 5.0);
}

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
    colDist = minSd(vec4(BH_pos, length(point) - BH_R), colDist);

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

/* Main ray marching function */
// float rayMarch(vec3 ro, vec3 rd, inout vec3 color) {
//     float distToOrigin = 0.;

//     for (int i = 0; i < MAX_STEPS; ++i) {
//         vec3 currentLocation = ro + distToOrigin * rd;
//         /// rgb + w as length
//         vec4 distToScene = getColAndDist(currentLocation);

//         distToOrigin += distToScene.w;

//         if (distToOrigin > MAX_DIST || abs(distToScene.w) < SURF_DIST) {
//             color = distToScene.rgb;
//             break;
//         }
//     }

//     return distToOrigin;
// }

/// current_position is the ray origin
/// ray_velocity should be normalized
/// color is the resulting color
const float dt = 0.15;
vec4 blackHoleRender(vec3 current_position, vec3 ray_velocity, inout vec3 color) {
    // 4th coord is whether we found a point or diverged
    vec4 currentLocationAndMode = vec4(0.);
    for (int i = 0; i < MAX_STEPS * 5; ++i) {
        vec4 colAndDist = getColAndDist(current_position);

        ray_velocity += blackHoleNullParticleAccl(current_position) * dt;

        float dist_to_travel = length(ray_velocity) * dt;
        if (dist_to_travel > colAndDist.w) {
            ray_velocity *= colAndDist.w / dist_to_travel;
        }

        current_position += ray_velocity * dt;

        // check that we got below event horizon
        if (distance(BH_pos, current_position) < BH_R) {
            color = vec3(0.);
            currentLocationAndMode.xyzw = vec4(current_position, 1.);
            break;
        }

        // check that we landed on a point
        if (abs(colAndDist.w) < SURF_DIST) {
            color = colAndDist.rgb;
            currentLocationAndMode = vec4(current_position, 1.);
            break;
        }
    }
    // if (currentLocationAndMode.w == 0.) {
    //     ray_velocity = normalize(ray_velocity);
    //     float distToOrigin = 0.;
    //     for (int i = 0; i < MAX_STEPS; ++i) {
    //         vec3 currentLocation = current_position + distToOrigin * ray_velocity;
    //         /// rgb + w as length
    //         vec4 colAndDist = getColAndDist(currentLocation);

    //         distToOrigin += colAndDist.w;

    //         // check that we got below event horizon
    //         if (distance(BH_pos, currentLocation) < BH_R) {
    //             color = vec3(0.);
    //             currentLocationAndMode.xyzw = vec4(current_position, 1.);
    //             break;
    //         }

    //         if (distToOrigin > MAX_DIST) break;
    //         if (abs(colAndDist.w) < SURF_DIST) {
    //             color = colAndDist.rgb;
    //             currentLocationAndMode = vec4(currentLocation, 1.);
    //             break;
    //         }
    //     }
    // }
    return currentLocationAndMode;
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

#endif  // RAY_GLSL