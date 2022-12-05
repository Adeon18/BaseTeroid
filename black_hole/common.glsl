#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define FOV 0.8
#define CAM_ANGLE 0.001
#define MAX_STEPS 90
#define MIN_DIST 1e-5
#define MAX_DIST 60.0

//(reused some of @ollj's code, made it more readible)

// basic parameters
float R = 2.1;								// planet radius
float H = 0.1;							// density scale-height of atmosphere (not pressure scale height)

vec3 light = normalize(vec3(0,1,0));
const float light_bright =1.0;
const float light_ang = 0.1;

//specific controller buffer Addresses
const float CamP = 0.,     //camera position 
            CamA = 1.,     //camera rotation quaternion    
            CamV = 2.,     //camera velocity
            CamAV = 3.,    //camera rotation velocity
            PrevCamP = 4., //previous frame camera position
            PrevCamA = 5., //previous frame camera rotation quaternion
            PrevMouse = 6.,//previous mouse pos
            NAddr = 7.;    //max address count
            
#define get(i) texelFetch(iChannel2,ivec2(i,0),0)



//ollj quaternionRotation math
//
//ANY rotations in 3d are non-commutative!
//
//matrix rotations are just bulky, memory wasting
//EulerRotations almost certainly fail to rotate over the SHORTEST path.
//EulerRotations almost certainly will gimbalLock and get stuck along one axis
//QuaternionRotations are superior here.
//-> we only use EulerRorations for simple input devices (keyboard input)
//-> we convert to quaternions, buffered as vec4.

//quaternion Identity
vec4 qid() 
{
    return vec4(0, 0, 0, 1);
}

//return quaternion from axis and angle
vec4 aa2q(vec3 axis, float ang) 
{
    vec2 g = vec2(sin(ang), cos(ang)) * 0.5;
    return normalize(vec4(axis * g.x, g.y));
}

//return AxisAngle of NORMALIZED quaternion input
vec4 q2aa(vec4 q) 
{
    return vec4(q.xyz / sqrt(1.0 - q.w * q.w), acos(q.w) * 2.);
}

//return q2, rotated by q1, order matters (is non commutative) : (aka quaternion multiplication == AxisAngleRotation)
vec4 qq2q(vec4 q1, vec4 q2) 
{
    return vec4(q1.xyz * q2.w + q2.xyz * q1.w + cross(q1.xyz, q2.xyz), (q1.w * q2.w) - dot(q1.xyz, q2.xyz));
}

//extension to qq2q(), scaled by sensitivity [f] (==quaternion ANGULAR equivalent to slerp() )
vec4 qq2qLerp(vec4 a, vec4 b, float f) 
{
    float d = dot(a, b), t = acos(abs(d)), o = (1. / sin(t));
    return normalize(a * sin(t * (1.0 - f)) * o * sign(d) + b * sin(t * f) * o);
}

//doing qq2q() multiple times, you need to normalize() the quaternion, to fix rounding errors.
//how often you do this is up to you.

//normalize q (assuming length(q) is already close to 1, we can skip whe sqrt()
vec4 qn(vec4 q) 
{
    return q / dot(q,q);
}

//return quaternion, that is the shortest rotation, between looking to [a before], and looking to [b after] the rotation.
//http://wiki.secondlife.com/wiki/LlRotBetween
vec4 qBetween(vec3 a, vec3 b) 
{
    float v = sqrt(dot(a,a) * dot(a,a));

    if(v == 0.) return qid();
    
    v = dot(a, b) / v;
    vec3 c = a.yzx * b.zxy - a.zxy * b.yzx / v;
    float d = dot(c,c);
    
    if(d != 0.) 
    {
        float s = (v > - 0.707107) ? 1. + v : d / (1. + sqrt(1. - d));
        return vec4(c, s) / sqrt(d + s * s);
    }
    
    if(v > 0.) return qid();
    
    float m = length(a.xy);
    
    return (m != 0.) ? vec4(a.y, - a.x, 0, 0) / m : vec4(1, 0, 0, 0);
}

//return inverse of quaternion
vec4 qinv(vec4 q) 
{
    return vec4(- q.xyz, q.w) / dot(q,q);
}

//return VECTOR p, rotated by quaterion q;
vec3 qv2v(vec4 q, vec3 p) 
{
    return qq2q(q, qq2q(vec4(p, .0), qinv(q))).xyz;
}

//qv2v()  with swapped inputs
//return quaterion P (as vector), as if it is rotated by VECTOR p (as if it is a quaternion)
vec3 vq2v(vec3 p, vec4 q) 
{
    return qq2q(qinv(q), qq2q(vec4(p, 0.0), q)).xyz;
}

vec3 vq2v(vec4 a, vec3 b) 
{
    return qv2v(a, b);
}

//in case of namespace confuction
vec3 qv2v(vec3 a, vec4 b) 
{
    return vq2v(a, b);
}

//return mat3 of quaternion (rotation matrix without translation)
//https://www.shadertoy.com/view/WsGfWm
mat3 q2m(vec4 q) 
{
    vec3 a = vec3(-1, 1, 1);
    vec3 u = q.zyz * a, v = q.xyx * a.xxy;
    mat3 m = mat3(0.5) + mat3(0, u.x,u.y,u.z, 0, v.x,v.y,v.z, 0) * q.w + matrixCompMult(outerProduct(q.xyz, q.xyz), 1. - mat3(1));
    q *= q; 
    m -= mat3(q.y + q.z, 0, 0, 0, q.x + q.z, 0, 0, 0, q.x + q.y);
    return m * 2.0;
}

//return quaternion of orthogonal matrix (with determinant==1., or else quaternionm will not be normalized)
vec4 m2q(mat3 m) 
{
#define m2f(a,b) m[a][b]-m[b][a]
    //http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
    float q = 2. * sqrt(abs(1. + m[0][0] + m[1][1] + m[2][2]));
    return vec4(vec3(m2f(2, 1), m2f(0, 1), m2f(1, 0)) / q / 4., q);
#undef m2f
}

float at2e(vec2 a) 
{
    a *= 2.;
    return atan(a.x, 1. - a.y);
}

//return quaternion of Euler[yaw,pitch,roll]     
vec4 eYPR2q(vec3 o) 
{
    o *= .5;
    vec3 s = sin(o);
    //https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles#Source_code
    o = cos(o);
    vec4 a = vec4(s.xz, o.xz);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(-1, 1, -1, 1);
}

vec4 eYPR2q(vec2 o) 
{
    o *= .5;
    vec2 s = sin(o);
    o = cos(o);
    vec4 a = vec4(s.x, 0., o.x, 0.);
    return a.yyww * a.zxxz * o.y + a.wwyy * a.xzzx * s.y * vec4(- 1, 1, - 1, 1);
}

mat3 getCam(vec4 q) 
{
    return q2m(q);
}

//internal RNG state 
uvec4 s0, s1; 
ivec2 pixel;

void rng_initialize(vec2 p, int frame)
{
    pixel = ivec2(p);

    //white noise seed
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
    
    //blue noise seed
    s1 = uvec4(frame, frame*15843, frame*31 + 4566, frame*2345 + 58585);
}

// https://www.pcg-random.org/
uvec4 pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    return v;
}

float rand(){ return float(pcg4d(s0).x)/float(0xffffffffu); }
vec2 rand2(){ return vec2(pcg4d(s0).xy)/float(0xffffffffu); }
vec3 rand3(){ return vec3(pcg4d(s0).xyz)/float(0xffffffffu); }
vec4 rand4(){ return vec4(pcg4d(s0))/float(0xffffffffu); }

vec2 nrand2(float sigma, vec2 mean)
{
	vec2 Z = rand2();
    return mean + sigma * sqrt(-2.0 * log(Z.x)) * 
           vec2(cos(TWO_PI * Z.y),sin(TWO_PI * Z.y));
}


//uniformly spherically distributed
vec3 udir(vec2 rng)
{
    vec2 r = vec2(2.*PI*rng.x, acos(2.*rng.y-1.));
    vec2 c = cos(r), s = sin(r);
    return vec3(c.x*s.y, s.x*s.y, c.y);
}