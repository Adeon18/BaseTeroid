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
vec3 handleKeyboard() {
    vec3 direction = vec3(0.);

    if (isKeyDown(Key_W)) {
        direction.xy += vec2(0., 1.);
    }

    if (isKeyDown(Key_S)) {
        direction.xy += vec2(0., -1.);
    }

    if (isKeyDown(Key_A)) {
        direction.xy += vec2(-1., 0.);
    }

    if (isKeyDown(Key_D)) {
        direction.xy += vec2(1., 0.);
    }

    if (isKeyPressed(Key_E)) {
        direction.z = 1.;
    }

    return direction;
}

uint hash(uint x) {
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

    vec2 die = texelFetch(iChannel0, ivec2(P_COLLISION_COL, PLAYER_LAYER_ROW), 0).xy;

    /*
    * Pseudorandom generator for asteroid coordinate
    */
    if (int(fragCoord.y) == ASTEROID_LAYER_ROW && fragCoord.x < NUM_ASTEROIDS && int(die.x) != 1) {
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

        // Destroy asteroid if there is a collision with a projectile
        vec4 projectileCollision = texelFetch(iChannel0, ivec2(fragCoord.x, PROJECTILE_COLLISION_ROW), 0);
        if (projectileCollision.x > 0.) {
            outFrag = vec4(0.);
        }
    }
    /*
     * Player shenanigans
    */
    else if (int(fragCoord.y) == PLAYER_LAYER_ROW) {
        if (int(die.x) == 1) {
            if (int(fragCoord.y) == PLAYER_LAYER_ROW && int(fragCoord.x) == P_COLLISION_COL) {
                if (iTime - die.y > 2.) {
                    fragColor = vec4(0.);
                } else {
                    fragColor = vec4(die, 0., 0.);
                }
            } else {
                fragColor = vec4(0.);
            }
            return;
        }
        /// Handle Player movement
        if (int(fragCoord.x) == P_MOVEMENT_COL) {
            handleMovement(outFrag);
        }
        else if(int(fragCoord.x) == P_CONTROLS_COL){
            vec3 controls = handleKeyboard().xyz;
            outFrag.xyz = controls;
        }
        /// Handle player rotation
        else if (int(fragCoord.x) == P_ROTATION_COL) {
            handleRotation(outFrag);
        }
        else if (int(fragCoord.x) == P_COLLISION_COL) {
            
            vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;
            vec2 offset = texelFetch(iChannel0, ivec2(P_MOVEMENT_COL, PLAYER_LAYER_ROW), 0).xy;

            /// Collision detection with asteroids
            for (int i = 0; i < int(NUM_ASTEROIDS); ++i) {
                vec2 asteroidCoords = (texelFetch(iChannel0, ivec2(i, int(ASTEROID_LAYER_ROW)), 0).xy * 2. - 1.) * screenSize;
                if (distance(offset.xy, asteroidCoords) < PLAYER_HEIGHT / 2. + ASTEROID_RADIUS &&
                    (length(offset.xy) != 0. && length(asteroidCoords) != 0.)) {
                    outFrag.x = 1.;
                    outFrag.y = iTime;
                }
            }
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
     * Projectile creation
    */
    else if (int(fragCoord.y) == PROJECTILE_CREATION_ROW && fragCoord.x < NUM_PROJECTILES && int(die.x) != 1) {
        vec4 controls = texelFetch(iChannel0, ivec2(P_CONTROLS_COL, PLAYER_LAYER_ROW), 0);
        vec4 currentProjectile = texelFetch(iChannel0, ivec2(fragCoord.x, fragCoord.y), 0);
        float lastShootTime = texelFetch(iChannel0, ivec2(NUM_PROJECTILES, PROJECTILE_CREATION_ROW), 0).x;
        outFrag = currentProjectile;

        if (int(currentProjectile.x) == 1) {
            outFrag.x = 2.;
        }

        bool wasAlreadyCreated = false;
        for (int i = 0; i < int(NUM_PROJECTILES); ++i) {
            float projectileStatus = texelFetch(iChannel0, ivec2(i, PROJECTILE_CREATION_ROW), 0).x;
            if (projectileStatus > 0. && projectileStatus < 2.) {
                wasAlreadyCreated = true;
                break;
            }
        }

        if (!wasAlreadyCreated && controls.z > 0. && currentProjectile.x < 1.) {
            outFrag.x = 1.;
        }

        vec4 projectilePos = texelFetch(iChannel0, ivec2(fragCoord.x, PROJECTILE_LAYER_ROW), 0);    
        vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;
        if (projectilePos.x > 1. || projectilePos.x < 0. || projectilePos.y > 1. || projectilePos.y < 0.) {
            outFrag.x = 0.;
        }

        for (int i = 0; i < int(NUM_ASTEROIDS); ++i) {
            vec2 projectileCollision = texelFetch(iChannel0, ivec2(i, PROJECTILE_COLLISION_ROW), 0).xy;
            if (projectileCollision.x > 0.) {
                outFrag.x = 0.;
            }
        }
    }
    /*
     * Projectile position calculation
    */
    else if (int(fragCoord.y) == PROJECTILE_LAYER_ROW && fragCoord.x < NUM_PROJECTILES && int(die.x) != 1) {
        float creationValue = texelFetch(iChannel0, ivec2(fragCoord.x, PROJECTILE_CREATION_ROW), 0).x;
        bool isJustCreated = creationValue > 0. && creationValue < 2.;
        bool isCreated = creationValue > 1.;
        vec4 currentProjectile = texelFetch(iChannel0, ivec2(fragCoord.x, fragCoord.y), 0);
        if (isJustCreated) {
            vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;
            vec2 position = texelFetch(iChannel0, ivec2(P_MOVEMENT_COL, PLAYER_LAYER_ROW), 0).xy;
            float rotationRad = texelFetch(iChannel0, ivec2(P_ROTATION_COL, PLAYER_LAYER_ROW), 0).x;
            vec2 direction = vec2(sin(rotationRad), cos(rotationRad));

            currentProjectile.xy = (position / screenSize + 1.) / 2.;
            currentProjectile.zw = direction;
        } else if (!isCreated) {
            currentProjectile = vec4(0.);
        }

        if (isCreated) {
            currentProjectile.xy += currentProjectile.zw * PROJECTILE_SPEED;
        }

        outFrag = currentProjectile;
    }
    /*
     * Projectile collision with asteroids
    */
    else if (int(fragCoord.y) == PROJECTILE_COLLISION_ROW && fragCoord.x < NUM_ASTEROIDS) {
        outFrag = vec4(0.);
        vec2 screenSize = texelFetch(iChannel0, ivec2(C_SCREEN_SIZE_COL, CAMERA_LAYER_ROW), 0).xy;
        vec2 asteroidCoords = (texelFetch(iChannel0, ivec2(fragCoord.x, int(ASTEROID_LAYER_ROW)), 0).xy * 2. - 1.) * screenSize;
        for (int i = 0; i < int(NUM_PROJECTILES); ++i) {
            bool isCreated = texelFetch(iChannel0, ivec2(i, PROJECTILE_CREATION_ROW), 0).x > 0.;
            if (isCreated) {
                vec2 projectilePos = (texelFetch(iChannel0, ivec2(i, PROJECTILE_LAYER_ROW), 0).xy * 2. - 1.) * screenSize;

                if (distance(projectilePos.xy, asteroidCoords) < PROJECTILE_RADIUS / 2. + ASTEROID_RADIUS
                    && (length(projectilePos.xy) != 0. && length(asteroidCoords) != 0.)) {

                    outFrag.x = 1.;
                }
            }
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