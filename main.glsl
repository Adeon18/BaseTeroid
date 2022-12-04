#include "utility/render.glsl"
#include "utility/player.glsl"
#include "utility/camera.glsl"
#include "utility/common.glsl"
#include "utility/asteroids.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "file://img/game_over.png"

/* Get minimal distance to each object, objects are generated here for now */
vec4 getDist(vec3 point) {
    // vec3 bp = vec3(5., 0., 0.);
    // float distToBox = sdBox(point - bp, Box(1., 1., 1., bp));

    vec2 offset = texelFetch(iChannel0, ivec2(0, 1), 0).xy;
    float distPiramid = createPlayer(point, vec3(0.), vec3(offset, 0.));

    float distAsteroids = createAsteroids(point);

    /// Use respective colors for respective objects
    vec4 colDist = minSd(vec4(PLAYER_COLOR, distPiramid), vec4(ASTEROID_COLOR, distAsteroids));

    return colDist;
}

/* Function for getting a normal to the plane */
vec3 getNormal(vec3 point) {
    float dist = getDist(point).w;
    vec2 offset = vec2(.01, 0);

    vec3 normal = dist - vec3(
        getDist(point - offset.xyy).w,
        getDist(point - offset.yxy).w,
        getDist(point - offset.yyx).w
    );

    return normalize(normal);
}

/* Main ray marching function */
float rayMarch(vec3 ro, vec3 rd, inout vec3 color) {
    float distToOrigin = 0.;

    for (int i = 0; i < MAX_STEPS; ++i) {
        vec3 currentLocation = ro + distToOrigin * rd;
        /// rgb + w as length
        vec4 distToScene = getDist(currentLocation);

        distToOrigin += distToScene.w;

        if (distToOrigin > MAX_DIST || abs(distToScene.w) < SURF_DIST) {
            color = distToScene.rgb;
            break;
        }
    }

    return distToOrigin;
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
    float distToLight = rayMarch(point + normal * SURF_DIST * 2., lightDir, BASE_COLOR); // Get the point a bit off so the loop does not immediately end
    if (distToLight < length(lightPos - point)) { lightIntencity *= .3; }

    return color * lightIntencity;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;

    // get ray origin & direction
    vec4 camera_props = texelFetch(iChannel0, ivec2(0., CAMERA_LAYER_ROW), 0);
    vec3 ro = getRo(camera_props);
    vec3 rd = getRd(uv, ro, camera_props);

    vec3 outCol = vec3(0.2666, 0.2784, 0.3529);
    vec3 lightColor = vec3(0.);

    float die = texelFetch(iChannel0, ivec2(P_COLLISION_COL, PLAYER_LAYER_ROW), 0).x;
    if (int(die) == 1) {
        fragColor = texture(iChannel1, fragCoord/iResolution.xy);
        return;
    }

    float d = rayMarch(ro, rd, lightColor);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        vec3 diffusedLighting = vec3(0.);
        diffusedLighting += 0.25 * getLighting(p, vec3(10, 10, -5), lightColor);
        diffusedLighting += 0.25 * getLighting(p, vec3(-10, -10, -5), lightColor);
        diffusedLighting += 0.25 * getLighting(p, vec3(10, -10, -5), lightColor);
        diffusedLighting += 0.25 * getLighting(p, vec3(-10, 10, -5), lightColor);
        diffusedLighting *= 1.354;

        outCol = diffusedLighting;
    }
    // Color correction
    outCol = pow(min(outCol, 1.0), vec3(.99));

    // Output to screen
    fragColor = vec4(outCol, 1.0);
}
