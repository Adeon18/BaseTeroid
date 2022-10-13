#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST .01

/* A Capsule has position of the top and bottom spheres and their radius */
struct Capsule {
    vec3 top;
    vec3 bot;
    float rad;
};

/* A Cylinder is the same as Capsule but the algorithms are different */
struct Cylinder {
    vec3 top;
    vec3 bot;
    float rad;
};

/* A Torus has a main radius and the thickness of the tube and position */
struct Torus {
    float radBig;
    float radSmol;
    vec3 pos;
};

/*
* A box has width height and depth(all calculated from center to sides)
* and position
*/
struct Box {
    // width, height, depth can be put in a vec3
    float wid;
    float hig;
    float dep;
    vec3 pos;
};

/* 
* Rotate object in one plane:
* use obj.xy = Rotate(val);
* to rotate the object by some value on the xy plane
*/
mat2 Rotate(float val) {
    float s = sin(val);
    float c = cos(val );
    return mat2(c, -s, s, c);
}


float getDistBox(vec3 point, Box box) {
    point -= box.pos;
    /// max(vec3, float) clamps vec field to 0 if they < 0;
    return length(max(abs(point) - vec3(box.wid, box.hig, box.dep), 0.));
}

float getDistTorus(vec3 point, Torus tor) {
    point -= tor.pos;
    /// Projected distance to the outside layer of a torus
    float projDistToOut = length(point.xz) - tor.radBig;
    return length(vec2(projDistToOut, point.y)) - tor.radSmol;
}

float getDistCapsule(vec3 point, Capsule cap) {
    vec3 edge = cap.bot - cap.top;
    vec3 distToCapsule = point - cap.top;
    
    float distToHit = dot(edge, distToCapsule) / dot(edge, edge);
    distToHit = clamp(distToHit, 0., 1.);
    
    vec3 pointHit = cap.top + distToHit*edge;
    return length(point - pointHit) - cap.rad;
}

float getDistCylinder(vec3 point, Cylinder cap) {
    vec3 edge = cap.bot - cap.top;
    vec3 distToSide = point - cap.top;
    
    float distToHit = dot(edge, distToSide) / dot(edge, edge);
    // distToHit = clamp(distToHit, 0., 1.);
    
    vec3 pointHit = cap.top + distToHit*edge;
    // X-axis dist to cylinder
    float xDist = length(point - pointHit) - cap.rad;
    float yDist = (abs(distToHit - .5) - .5) * length(edge);
    
    float exteriorDist = length(max(vec2(xDist, yDist), 0.));
    float interiorDist = min(max(xDist, yDist), 0.);
    return exteriorDist + interiorDist;
}

float getDist(vec3 point) {
    vec4 sphere = vec4(0, 1, 6, 1); // w = radius
    
    float distToSphere = length(point - sphere.xyz) - sphere.w;
    float distToPlane = point.y;
    
    float capsuleDistance = getDistCapsule(point, Capsule(vec3(0, 0, 0), vec3(0, 0.5, 0), .9)); 
    float torusDistance = getDistTorus(point, Torus(1.5, .5, vec3(0, 0.5, 6))); 
    float distBox = getDistBox(point, Box(.5, .5, .5, vec3(-4, 0.5, 6)));
    float cylinderDistance = getDistCylinder (point, Cylinder(vec3(3, 1, 7), vec3(3, 3, 6), .6)); 
    
    
    float d = min(capsuleDistance, distToPlane);
    d = min(d, torusDistance);
    d = min(d, distBox);
    d = min(d, cylinderDistance);
    
    return d;
}

// Get distance to final point
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

float rayMarch(vec3 ro, vec3 rd) {
    float distToOrigin = 0.;
    
    for (int i = 0; i < MAX_STEPS; ++i) {
        vec3 currentLocation = ro + distToOrigin * rd;
        float distToScene = getDist(currentLocation);
        
        distToOrigin += distToScene;
        
        if (distToOrigin > MAX_DIST || distToScene < SURF_DIST) { break; }
    }
    
    return distToOrigin;
}

float getLighting(vec3 point) {
    // Global just for test
    vec3 lightPos = vec3(0, 7, 0);
    lightPos.xz += vec2(sin(iTime) * 2., cos(iTime) * 2.);
    
    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = getNormal(point);
    
    float lightIntencity = dot(lightDir, normal);
    
    // Get shadows
    float distToLight = rayMarch(point + normal * SURF_DIST * 2., lightDir); // Get the point a bit off so the loop does not immediately end
    if (distToLight < length(lightPos - point)) { lightIntencity *= .1; }
    
    return clamp(lightIntencity, 0., 1.);
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

        float diffusedLighting = getLighting(p);


        col = vec3(diffusedLighting);
    }

    // Output to screen
    fragColor = vec4(col,1.0);
}
