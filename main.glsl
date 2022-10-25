#include "utility/render.glsl"

/* Get minimal distance to each object, objects are generated here for now */
float getDist(vec3 point) {
    // vec4 sphere = vec4(0, 1, 6, 1); // w = radius

    Sphere sph = Sphere(vec3(0, 1, 6), 1.);


    float distToSphere = sdSphere(point - sph.pos, sph);

    float distToPlane = sdPlane(point, vec3(0., 0., 0.));

    float distPiramid = createShip(point, vec3(0.));

    float d = min(distToSphere, distPiramid);

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


// What the fuck
vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;

    vec2 mos = iMouse.xy/iResolution.xy;

    vec3 col = vec3(0);

    // Simple camera
    vec3 ro = vec3(0, 3, -5);
    ro.yz *= Rotate(-mos.y+.4);
    ro.xz *= Rotate(-mos.x*6.2831);
    vec3 rd = R(uv, ro, vec3(0,0,0), .7);

    float d = rayMarch(ro, rd);

    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;

        float diffusedLighting = 0.;
        diffusedLighting = addLight(diffusedLighting, vec3(3, 5, 4), p);
        diffusedLighting = addLight(diffusedLighting, vec3(-3, 5, -4), p);


        col = vec3(diffusedLighting);
    }

    // Color correction
    //col = pow(col, vec3(.95));

    // Output to screen
    fragColor = vec4(col,1.0);
}
