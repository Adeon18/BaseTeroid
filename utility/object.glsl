
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
 * A fucking sphere, idk
*/
struct Sphere {
    vec3 pos;
	float rad;
};