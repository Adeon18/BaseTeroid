#ifndef DATA_CHANNEL_GLSL
#define DATA_CHANNEL_GLSL

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

uint hash( uint x ) {
    x += x << 10u;
    x ^= x >>  6u;
    x += x <<  3u;
    x ^= x >> 11u;
    x += x << 15u;
    return x;
}
// taken from https://stackoverflow.com/a/17479300/16471208
float random(vec3 v) {
    uvec3 uiv = floatBitsToUint(v);
    uint m = hash(uiv.x ^ hash(uiv.y) ^ hash(uiv.z));
    m &= 0x007FFFFFu; // keep mantissa
    m |= 0x3F800000u; // add 1.0
    return uintBitsToFloat(m) - 1.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 outFrag = vec4(0., 0., 0., 0.);

    /*
    * Pseudorandom generator for asteroid coordinate
    */
    if (int(fragCoord.y) == ASTEROID_LAYER_ROW && fragCoord.x < NUM_ASTEROIDS) {
        outFrag = texelFetch(iChannel0, ivec2(fragCoord.x, ASTEROID_LAYER_ROW), 0);
        if (outFrag.x > 1. || outFrag.y > 1. || outFrag.x <= 0. || outFrag.y <= 0.) {
            float d = random(vec3(fragCoord, iTime));
            outFrag.zw = vec2(
                random(vec3(fragCoord, iTime+1.)),
                random(vec3(fragCoord, iTime+2.))
            );
            outFrag.zw = outFrag.zw * 2. - 1.;
            if (d < 0.25) {
                outFrag.x = 0.001;
                outFrag.y = random(vec3(fragCoord, iTime+3.));
                if (outFrag.z < 0.) { outFrag.z = -outFrag.z; }
            } else if (d < 0.50) {
                outFrag.x = random(vec3(fragCoord, iTime+3.));
                outFrag.y = 0.001;
                if (outFrag.w < 0.) { outFrag.w = -outFrag.w; }
            } else if (d < 0.75) {
                outFrag.x = 0.999;
                outFrag.y = random(vec3(fragCoord, iTime+3.));
                if (outFrag.z > 0.) { outFrag.z = -outFrag.z; }
            } else {
                outFrag.x = random(vec3(fragCoord, iTime+3.));
                outFrag.y = 0.999;
                if (outFrag.w > 0.) { outFrag.w = -outFrag.w; }
            }
        } else {
            outFrag.xy += outFrag.zw * ASTEROID_SPEED;
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
        } else {
            discard;
        }
    }
    /*
     * Camera properties(constant)
    */
    else if (int(fragCoord.y) == CAMERA_LAYER_ROW) {
        if (int(fragCoord.x) == C_OPTIONS_COL) {
            // camera position is constant for now
            outFrag.xy = vec2(0., 0.);
            // height is constant for now
            outFrag.z = 20.;
            // zoom is constant for now
            outFrag.w = 0.5;
            // vec2 mos = iMouse.xy/iResolution.xy;
        } else if (int(fragCoord.x) == C_SCREEN_SIZE_COL) {
            /// Screen size calculation -> this is scary
            vec2 upRightUV = .5 * iResolution.xy / iResolution.y;
            vec4 camera_props = texelFetch(iChannel0, ivec2(0., CAMERA_LAYER_ROW), 0);
            vec3 ro = getRo(camera_props);
            vec3 upRightRD = getRd(upRightUV, ro, camera_props);
            float cosAngle = dot(-1. * ro, upRightRD) / length(ro);
            float dist = length(ro) / cosAngle;
            vec2 screenSize = (ro + upRightRD * dist).xy;
            screenSize += 1.;

            outFrag.xy = screenSize;
        } else {
            discard;
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