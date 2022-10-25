#ifndef RENDER_GLSL
#define RENDER_GLSL

#include "object.glsl"

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01

#define PI 3.14159


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
 * Distance functions -> give us the distanсe to said object type
 * NEGATIVE return on the inside and POSITIVE on the outside
 * * vec3 point: origin point - the position you want your object to be at
 * * Object: obj to find distance to
 */

/* Get distance to the Box and put it in proper position */
float sdBox(vec3 point, Box box) {
    /// By default the scale is inversed

    point = abs(point) - vec3(box.wid, box.hig, box.dep);
    /// Account for inner position for there not to be distorted black dots
    return (length(max(point, 0.)) + min(max(point.x, max(point.y, point.z)), 0.));
}

/* Get distance to the Torus and put it in proper position */
float getDistTorus(vec3 point, Torus tor) {
    /// Projected distance to the outside layer of a torus
    float projDistToOut = length(point.xz) - tor.radBig;
    return length(vec2(projDistToOut, point.y)) - tor.radSmol;
}

/* Get distance to the Capsule */
float sdCapsule(vec3 point, Capsule cap) {
    vec3 edge = cap.bot - cap.top;
    vec3 distToCapsule = point - cap.top;

    float distToHit = dot(edge, distToCapsule) / dot(edge, edge);
    distToHit = clamp(distToHit, 0., 1.);

    vec3 pointHit = cap.top + distToHit*edge;
    return length(point - pointHit) - cap.rad;
}

/* Get distance to the Cylinder */
float sdCylinder(vec3 point, Cylinder cap) {
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

/* Get distance to the Sphere - The fastest! */
float sdSphere(vec3 point, Sphere sphere) {
    return length(point) - sphere.rad;
}

/* Get distance to the Plane */
float sdPlane(vec3 point, vec3 plane) {
    return dot(point, normalize(plane));
}

/*
 * Get distance to the Piramid - for now used only in player creation
 */
float sdPyramid(vec3 p, float h) {
    float m2 = h*h + 0.25;

    p.xz = abs(p.xz);
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= 0.5;

    vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);

    float s = max(-q.x,0.0);
    float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );

    float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
    float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);

    float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);

    return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}

#endif // RENDER_GLSL