#ifndef PSEUDORANDOM_GLSL
#define PSEUDORANDOM_GLSL

#define SPEED 0.01
#define NUM_ASTEROIDS 16.

#iChannel0 "self"

float modulo(float a, float b) {
    return a - (b * floor(a/b));
}

void rnd_transform(inout float x) {
    x = (1. - x) * x * 3.99;
}

/*
 * Pseudorandom generator for asteroid coordinate
*/
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 rnd = vec4(0., 0., 0., 0.);
    if (fragCoord.x < NUM_ASTEROIDS && fragCoord.y < 1.) {
        rnd = texelFetch(iChannel0, ivec2(fragCoord.x, 0), 0);
        if (rnd.x == 0. || rnd.y == 0.) {
            rnd.xyzw = vec4(0.01, 0.26, 0.76, 0.99) / NUM_ASTEROIDS * fragCoord.x;
        } else if (rnd.x > 1. || rnd.y > 1. || rnd.x < 0. || rnd.y < 0.) {
            rnd.x = modulo(rnd.x, 1.0);
            rnd_transform(rnd.x);
            rnd.y = modulo(rnd.y, 1.0);
            rnd_transform(rnd.y);
            if (rnd.x < rnd.y) {
                rnd.x = 0.01;
            } else {
                rnd.y = 0.01;
            }
            rnd_transform(rnd.z);
            rnd_transform(rnd.w);
        } else {
            rnd.xy += (rnd.zw * 2. - 1.) * SPEED;
        }
    }
    fragColor = rnd;
}

#endif // PSEUDORANDOM_GLSL