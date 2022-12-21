#include "utility/camera.glsl"
#include "utility/precompute_base.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "self"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (iFrame == 0) {
        vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;
        // TODO: I couldn't use the data channel for some reason.
        // texelFetch(iChannel0, ...) works if we #include <player.glsl>, but
        // then texelFetch(iChannel1, ...) doesn't work. Since camera position
        // is a constant currently, I just pasted it here for a temporary fix
        vec4 camera_props = vec4(0., 0., 20., 0.5);// texelFetch(iChannel0, ivec2(C_OPTIONS_COL, CAMERA_LAYER_ROW), 0);
        vec3 position = getRo(camera_props);
        vec3 velocity = getRd(uv, position, camera_props);
        float mode = heightprecompute(position, velocity, -1.);
        if (mode == 0.) {
            fragColor = vec4(0.);
        } else {
            /// put velocity if fragCoord.x is divisible by 2
            float flooredfragCoordx = floor(fragCoord.x);  // remove possible .5
            if ((flooredfragCoordx-2.*floor(flooredfragCoordx/2.)) == 0.) {
                fragColor = vec4(velocity, mode);
            } else {
                fragColor = vec4(position, mode);
            }
        }
    } else {
        fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    }
}