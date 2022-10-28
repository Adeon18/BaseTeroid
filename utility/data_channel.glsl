#ifndef DATA_CHANNEL_GLSL
#define DATA_CHANNEL_GLSL

#define SPEED 0.01
#define NUM_ASTEROIDS 16.

#iChannel0 "self"

#iKeyboard

#include "render.glsl"
#include "common.glsl"
#include "player.glsl"

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


float modulo(float a, float b) {
    return a - (b * floor(a/b));
}

void rnd_transform(inout float x) {
    x = (1. - x) * x * 3.99;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 outFrag = vec4(0., 0., 0., 0.);

    /*
    * Pseudorandom generator for asteroid coordinate
    */
    if (int(fragCoord.y) == ASTEROID_LAYER_ROW && fragCoord.x < NUM_ASTEROIDS) {
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
    }
    /*
     * Player shenanigans
    */
    else if (int(fragCoord.y) == PLAYER_LAYER_ROW) {
        /// Handle Player movement
        if (int(fragCoord.x) == P_MOVEMENT_COL) {
            vec2 controls = handleKeyboard();
            handleMovement(outFrag, controls);
        }
        /// Handle player rotation
        else if (int(fragCoord.x) == P_ROTATION_COL) {
            vec2 controls = handleKeyboard();
            handleRotation(outFrag, controls);
        }
    }
    /*
     * Discard all other pixels
    */
    else {
        discard;
    }

    fragColor = outFrag;
}

#endif // DATA_CHANNEL_GLSL