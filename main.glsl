#include "utility/render.glsl"
#include "utility/player.glsl"
#include "utility/asteroids.glsl"

#iChannel0 "file://utility/data_channel.glsl"

// lookat - central point of the camera
// z - zoom  ==  distance from camera to the screen
// c - center point on the screen = ro + forward * zoom factor z
// ro = ray origin
// right - if we look straight from the camera on screen, it is x offset
// up - if we look straight from the camera on screen, it is y offset
// intersection - the point on the screen where ray passes through it
vec3 getRd(vec2 uv, vec3 ro, vec3 lookat, float z) {
    vec3 forward = normalize(lookat-ro),
        right = normalize(cross(vec3(0, 1, 0), forward)),
        up = cross(forward, right),
        c = ro+forward*z,
        intersection = c + uv.x*right + uv.y*up,
        d = normalize(intersection-ro);
    return d;
}

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

/* Handle lighting and shadows */
vec3 getLighting(vec3 point, vec3 lightPos, vec3 color) {

    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = getNormal(point);

    float lightIntencity = clamp(dot(normal, lightDir)*.5+.5, 0., 1.);

    // Get shadows
    float distToLight = rayMarch(point + normal * SURF_DIST * 2., lightDir, BASE_COLOR); // Get the point a bit off so the loop does not immediately end
    if (distToLight < length(lightPos - point)) { lightIntencity *= .3; }

    return color * lightIntencity;
}

/*
 * Add a new light point to the Scene
 * Takes current light level, new light position and a point
 * Takes max of current light and new light so that badly lit areas light up
 * Takes color
 */
void addLight(inout vec3 currentLight, vec3 newLightPos, vec3 point, vec3 color) {
	currentLight = max(getLighting(point, newLightPos, color), currentLight);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;

    vec2 mos = iMouse.xy/iResolution.xy;

    vec3 col = vec3(0);

    // Simple camera

    // use this variables to move camera
    float cam_x = 0.;
    float cam_y = 0.;

    vec3 ro = vec3(-cam_x, cam_y, 20.);
    ro.xz *= Rotate(PI);

    // variables to control camera if we need it
    vec3 lookat = vec3(cam_x, cam_y, 0.);
    float zoom = 0.5;
    // #########################################

    // get ray direction!!!
    vec3 rd = getRd(uv, ro, lookat, zoom);
    // ####################

    vec3 color = vec3(0.);
    float d = rayMarch(ro, rd, color);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        vec3 diffusedLighting = vec3(0.);
        addLight(diffusedLighting, vec3(10, 10, -5), p, color);
        addLight(diffusedLighting, vec3(-10, -10, -5), p, color);
        addLight(diffusedLighting, vec3(10, -10, -5), p, color);
        addLight(diffusedLighting, vec3(-10, 10, -5), p, color);

        col = diffusedLighting;
    }
    // Color correction
    col = pow(min(col, 1.0), vec3(.99));

    // Output to screen
    fragColor = vec4(col,1.0);
}
