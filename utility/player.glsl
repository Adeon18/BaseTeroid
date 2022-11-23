#include "render.glsl"
#include "common.glsl"
#include "camera.glsl"

#iChannel0 "file://data_channel.glsl"

/*
 * Create the player object(Piramid) and handle input transformation and rotation
*/
float createPlayer(vec3 point, vec3 originPos, vec3 offset) {

    /// Get Rotation radians and matrix
    float rotationRad = texelFetch(iChannel0, ivec2(P_ROTATION_COL, PLAYER_LAYER_ROW), 0).x;
    mat2 rotationMat = Rotate(rotationRad);

    /// Player body
    Piramid body = Piramid(originPos, PLAYER_HEIGHT);
    float playerHeight = body.height / 2.;

    /// Handle body rotation and body movement
    vec3 bodyPos = point - body.pos;
    bodyPos -= offset;

    /// To be removed
    float isCollided = texelFetch(iChannel0, ivec2(P_COLLISION_COL, PLAYER_LAYER_ROW), 0).x;
    if (int(isCollided) == 1) {
        playerHeight = body.height / 4.;
    }

    bodyPos.xy *= rotationMat;

    /// Flatten the piramid
    bodyPos *= vec3(1., 1., 2.);

    return sdPyramid(bodyPos, playerHeight, body.height / 10., body.height / 1.5) / 2.;
}


/*
 * Calculate offset for the ship including rotation
 * Calculate and apply acceleration and deceleration to the ship
*/
vec2 calcOffset(vec2 offset, vec2 controls, inout vec2 inertia, float rotationRad) {
    /// Control values
    float turnSpeed = 0.1 / 100.;
    float velocity = 20. / 100.;
    /// Inertia values
    float speed = 5.;
    float maxSpeed = .1;
    float acceleration = 0.005;

    bool isThrottle = controls.y > 0.;      /* Get if throttling */

    controls.x *= turnSpeed;
    controls.y *= velocity;

    mat2 rotationMat = Rotate(rotationRad);
    controls *= rotationMat;
    controls.x *= -1.;

    /// Acceleration/deceleration
    if (isThrottle && length(inertia) < maxSpeed) {
        inertia.x = mix(inertia.x, controls.x, acceleration);
        inertia.y = mix(inertia.y, controls.y, acceleration);
    } else {
        inertia.x = mix(inertia.x, 0., acceleration);
        inertia.y = mix(inertia.y, 0., acceleration);
    }

    offset += inertia * speed;

    return offset;
}

/*
 * Player movement wrapper for the data channel
 * Handles ofsset and inetria
 * outFrag ///< [in/out]
 * .xy - offset
 * .zw - inertia
*/
void handleMovement(inout vec4 outFrag, vec2 controls) {
    outFrag = texelFetch(iChannel0, ivec2(P_MOVEMENT_COL, PLAYER_LAYER_ROW), 0);
    float rotationTexel = texelFetch(iChannel0, ivec2(P_ROTATION_COL, PLAYER_LAYER_ROW), 0).x;

    /// Handle offset
    outFrag.xy = calcOffset(outFrag.xy, controls, outFrag.zw, rotationTexel);
}

/*
 * Player rotation wrapper for the data channel
 * outFrag ///< [in/out]
 * .x - rotation
*/
void handleRotation(inout vec4 outFrag, vec2 controls) {
    outFrag = texelFetch(iChannel0, ivec2(P_ROTATION_COL, PLAYER_LAYER_ROW), 0);

    outFrag.x += controls.x * .1;
}
