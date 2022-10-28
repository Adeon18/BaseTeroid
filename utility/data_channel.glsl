#ifndef PSEUDORANDOM_GLSL
#define PSEUDORANDOM_GLSL

#define SPEED 0.01
#define NUM_ASTEROIDS 16.

#define ASTEROID_LAYER 0
#define PLAYER_LAYER 1

#iChannel0 "self"

#iKeyboard

#include "render.glsl"

/*
 * Capture keyboard input
*/
vec2 handleKeyboard() {
    vec2 direction = vec2(0., 0.);

    if (isKeyDown(Key_W)) {
        direction += vec2(0., 1.);
    }

    if (isKeyDown(Key_S)) {
        direction += vec2(0., -1.);
    }

    if (isKeyDown(Key_A)) {
        direction += vec2(-1., 0.);
    }

    if (isKeyDown(Key_D)) {
        direction += vec2(1., 0.);
    }

    return direction;
}


/*
 * Calculate offset for the ship including rotation
*/
vec2 calcOffset(vec2 offset, vec2 controls, float rotationRad) {
    float turnSpeed = 0.1 / 100.;
    float velocity = 20. / 100.;

    controls.x *= turnSpeed;
    controls.y *= velocity;
    mat2 rotationMat = Rotate(rotationRad);
    controls *= rotationMat;
    controls.x *= -1.;

    offset += controls;
    return offset;
}



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
    } else if (int(fragCoord.y) == 1) {
        if (int(fragCoord.x) < 100) {
            outFrag = texelFetch(iChannel0, ivec2(fragCoord.x, fragCoord.y), 0);
            vec2 controls = handleKeyboard();

            /// Handle offset
            outFrag.xy = calcOffset(outFrag.xy, controls, outFrag.z);
            outFrag.z += controls.x * .1;
        }
    } else {
        discard;
    }

    fragColor = outFrag;
}

#endif // PSEUDORANDOM_GLSL