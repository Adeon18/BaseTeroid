#ifndef PSEUDORANDOM_GLSL
#define PSEUDORANDOM_GLSL

#define SPEED 0.01
#define NUM_ASTEROIDS 16.

#iChannel0 "self"

#iKeyboard

#include "render.glsl"
#include "common.glsl"

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


// float lerpThrottle = 0.;
/*
 * Calculate offset for the ship including rotation
*/
vec2 calcOffset(vec2 offset, vec2 controls, inout vec2 inertia, float rotationRad) {
    float turnSpeed = 0.1 / 100.;
    float velocity = 20. / 100.;

    bool isThrottle = controls.y > 0.;

    controls.x *= turnSpeed;
    controls.y *= velocity;
    // if (isThrottle) {
    //     lerpThrottle = mix(lerpThrottle, 2., 0.3);
    // }

    mat2 rotationMat = Rotate(rotationRad);
    controls *= rotationMat;
    controls.x *= -1.;  
    if (isThrottle) {
        // inertia = vec2(0., lerpThrottle) * rotationMat;
        inertia = controls;
    } else {
        inertia.x = mix(inertia.x, 0., 0.01);
        inertia.y = mix(inertia.y, 0., 0.01);
    }

    offset += inertia;
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
    } else if (int(fragCoord.y) == PLAYER_LAYER) {
        if (int(fragCoord.x) == P_MOVEMENT_COL) {
            outFrag = texelFetch(iChannel0, ivec2(fragCoord.x, fragCoord.y), 0);
            float rotationTexel = texelFetch(iChannel0, ivec2(P_ROTATION_COL, fragCoord.y), 0).x;
            vec2 controls = handleKeyboard();

            /// Handle offset
            outFrag.xy = calcOffset(outFrag.xy, controls, outFrag.zw, rotationTexel);
        } else if (int(fragCoord.x) == P_ROTATION_COL) {
            outFrag = texelFetch(iChannel0, ivec2(fragCoord.x, fragCoord.y), 0);
            vec2 controls = handleKeyboard();

            outFrag.x += controls.x * .1;
        }
    } else {
        discard;
    }

    fragColor = outFrag;
}

#endif // PSEUDORANDOM_GLSL