#ifndef PSEUDORANDOM_GLSL
#define PSEUDORANDOM_GLSL

#define SPEED 0.01
#define NUM_ASTEROIDS 16.

#define ASTEROID_LAYER 0
#define PLAYER_LAYER 1

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
    vec4 outFrag = vec4(0., 0., 0., 0.);

    if (int(fragCoord.y) == ASTEROID_LAYER && fragCoord.x < NUM_ASTEROIDS) {
        outFrag = texelFetch(iChannel0, ivec2(fragCoord.x, 0), 0);
        if (outFrag.x == 0. || outFrag.y == 0.) {
            outFrag.xyzw = vec4(0.01, 0.26, 0.76, 0.99) / NUM_ASTEROIDS * fragCoord.x;
        } else if (outFrag.x > 1. || outFrag.y > 1. || outFrag.x < 0. || outFrag.y < 0.) {
            outFrag.x = modulo(outFrag.x, 1.0);
            rnd_transform(outFrag.x);
            outFrag.y = modulo(outFrag.y, 1.0);
            rnd_transform(outFrag.y);
            rnd_transform(outFrag.z);
            rnd_transform(outFrag.w);
        } else {
            outFrag.xy += (outFrag.zw * 2. - 1.) * SPEED;
        }
    } else if (int(fragCoord.y) == PLAYER_LAYER) {
        if (int(fragCoord.x) == 0) {
            //vec2 controls =
        }
    } else {
        discard;
    }

    fragColor = outFrag;
}

#endif // PSEUDORANDOM_GLSL