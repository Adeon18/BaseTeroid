#include "utility/camera.glsl"
#include "utility/precompute_base.glsl"
#include "utility/precompute_fetch.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "self"
#iChannel2 "file://utility/precompute.glsl"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (iFrame == 0) {
        vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;
        vec3 position = vec3(0.);
        vec3 velocity = vec3(0.);
        float mode = fetchPrecomputed(fragCoord, position, velocity);
        if (mode == 0.) {
            fragColor = vec4(0.);
        } else {
            mode = heightprecompute(position, velocity, 1.02);
            if (mode == 0.) {
                fragColor = vec4(0.);
            } else {
                mode = heightprecompute(position, velocity, 1.);
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
            }
        }
    } else {
        fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    }
}