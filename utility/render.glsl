#include "object.glsl"

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01


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
//-----------------------------------------------------------------------------
/*
 * Distance functions -> give us the distane to said object type
 * NEGATIVE return on the inside and POSITIVE on the outside
 */

/* Get distance to the Box and put it in proper position */
float getDistBox(vec3 point, Box box) {
	point -= box.pos;
    point = abs(point) - vec3(box.wid, box.hig, box.dep);
    /// Account for inner position for there not to be distorted black dots
    return length(max(point, 0.)) + min(max(point.x, max(point.y, point.z)), 0.);
}

/* Get distance to the Torus and put it in proper position */
float getDistTorus(vec3 point, Torus tor) {
    point -= tor.pos;
    /// Projected distance to the outside layer of a torus
    float projDistToOut = length(point.xz) - tor.radBig;
    return length(vec2(projDistToOut, point.y)) - tor.radSmol;
}

/* Get distance to the Capsule */
float getDistCapsule(vec3 point, Capsule cap) {
    vec3 edge = cap.bot - cap.top;
    vec3 distToCapsule = point - cap.top;

    float distToHit = dot(edge, distToCapsule) / dot(edge, edge);
    distToHit = clamp(distToHit, 0., 1.);

    vec3 pointHit = cap.top + distToHit*edge;
    return length(point - pointHit) - cap.rad;
}

/* Get distance to the Cylinder */
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

float getDistSphere(vec3 point, Sphere sphere) {
    return length(point - sphere.pos) - sphere.rad;
}

float getDistPlane(vec3 point, vec3 plane) {
    return dot(point, normalize(plane));
}