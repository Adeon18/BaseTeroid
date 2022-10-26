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
 * Code "borrowed" from https://www.shadertoy.com/view/Ntd3DX
 */
float sdPyramid(vec3 position, float halfWidth, float halfDepth, float halfHeight) {
    position.xz = abs(position.xz);

    // bottom
    float s1 = abs(position.y) - halfHeight;
    vec3 base = vec3(max(position.x - halfWidth, 0.0), abs(position.y + halfHeight), max(position.z - halfDepth, 0.0));
    float d1 = dot(base, base);

    vec3 q = position - vec3(halfWidth, -halfHeight, halfDepth);
    vec3 end = vec3(-halfWidth, 2.0 * halfHeight, -halfDepth);
    vec3 segment = q - end * clamp(dot(q, end) / dot(end, end), 0.0, 1.0);
    float d = dot(segment, segment);

    // side
    vec3 normal1 = vec3(end.y, -end.x, 0.0);
    float s2 = dot(q.xy, normal1.xy);
    float d2 = d;
    if (dot(q.xy, -end.xy) < 0.0 && dot(q, cross(normal1, end)) < 0.0) {
        d2 = s2 * s2 / dot(normal1.xy, normal1.xy);
    }
    // front/back
    vec3 normal2 = vec3(0.0, -end.z, end.y);
    float s3 = dot(q.yz, normal2.yz);
    float d3 = d;
    if (dot(q.yz, -end.yz) < 0.0 && dot(q, cross(normal2, -end)) < 0.0) {
        d3 = s3 * s3 / dot(normal2.yz, normal2.yz);
    }
    return sqrt(min(min(d1, d2), d3)) * sign(max(max(s1, s2), s3));
}

#endif // RENDER_GLSL