#include "utility/render.glsl"

#iKeyboard

#iChannel0 "file://input.glsl"


vec2 controls = vec2(0.);

/* Get minimal distance to each object, objects are generated here for now */
float getDist(vec3 point) {
    // vec4 sphere = vec4(0, 1, 6, 1); // w = radius
    // vec2 offset = texelFetch(iChannel0, ivec2(0, 0), 0).xy;

    Sphere sph = Sphere(vec3(10., 1., 0.), 1.);


    float distToSphere = sdSphere(point - sph.pos, sph);
    vec3 bp = vec3(5., 1., 0.);
    float distToBox = sdBox(point - bp, Box(1., 1., 1., bp));

    float distPiramid = createShip(point, vec3(0.));

    float d = min(distToSphere, distPiramid);
    d = min(distToBox, d);

    return d;
}

/* Function fot getting a normal to the plane */
vec3 getNormal(vec3 point) {
    float dist = getDist(point);
    vec2 offset = vec2(.01, 0);

    vec3 normal = dist - vec3(
        getDist(point - offset.xyy),
        getDist(point - offset.yxy),
        getDist(point - offset.yyx)
    );

    return normalize(normal);
}

/* Main ray marching function */
float rayMarch(vec3 ro, vec3 rd) {
    float distToOrigin = 0.;

    for (int i = 0; i < MAX_STEPS; ++i) {
        vec3 currentLocation = ro + distToOrigin * rd;
        float distToScene = getDist(currentLocation);

        distToOrigin += distToScene;

        if (distToOrigin > MAX_DIST || abs(distToScene) < SURF_DIST) { break; }
    }

    return distToOrigin;
}

/* Handle lighting and shadows */
float getLighting(vec3 point, vec3 lightPos) {

    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = getNormal(point);

    float lightIntencity = clamp(dot(normal, lightDir)*.5+.5, 0., 1.);

    // Get shadows
    float distToLight = rayMarch(point + normal * SURF_DIST * 2., lightDir); // Get the point a bit off so the loop does not immediately end
    // if (distToLight < length(lightPos - point)) { lightIntencity *= .3; }

    return clamp(lightIntencity, 0., 1.);
}

/*
 * Add a new light point to the Scene
 * Takes current light level, new light position and a point
 * Takes max of current light and new light so that badly lit areas light up
 */
float addLight(float currentLight, vec3 newLightPos, vec3 point) {
	return max(currentLight, getLighting(point, newLightPos));
}


// lookat - central point of the camera
// z - zoom  ==  distance from camera to the screen
// c - center point on the screen = ro + forward * zoom factor z
// ro = ray origin
// right - if we look straight from the camera on screen, it is x offset
// up - if we look straight from the camera on screen, it is y offset
// intersection - the point on the screen where ray passes through it
vec3 getRd(vec2 uv, vec3 ro, vec3 lookat, float z) {
    vec3 forward = normalize(lookat-ro),
        right = normalize(cross(vec3(0,1,0), forward)),
        up = cross(forward,right),
        c = ro+forward*z,
        intersection = c + uv.x*right + uv.y*up,
        d = normalize(intersection-ro);
    return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    controls = texelFetch(iChannel0, ivec2(0, 0), 0).xy;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;

    vec2 mos = iMouse.xy/iResolution.xy;

    vec3 col = vec3(0);

    // Simple camera

    // use this variables to move camera
    float cam_x = 0.;
    float cam_y = 0.;

    vec3 ro = vec3(-cam_x, -cam_y, 20);
    ro.xz *= Rotate(PI);
    
    // variables to control camera if we need it
    vec3 lookat = vec3(cam_x, cam_y, 0.);
    float zoom = 0.5;
    // #########################################
    
    // get ray direction!!!
    vec3 rd = getRd(uv, ro, lookat, zoom);
    // ####################
    
    float d = rayMarch(ro, rd);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        float diffusedLighting = 0.;
        diffusedLighting = addLight(diffusedLighting, vec3(3, 5, 4), p);
        diffusedLighting = addLight(diffusedLighting, vec3(-3, 5, -4), p);


        col = vec3(diffusedLighting);
    }
    // Color correction
    col = pow(col, vec3(.95));

    // Output to screen
    fragColor = vec4(col,1.0);
}
