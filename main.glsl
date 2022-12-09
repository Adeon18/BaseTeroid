#include "utility/ray.glsl"

#iChannel0 "file://utility/data_channel.glsl"
#iChannel1 "file://img/game_over.png"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy) / iResolution.y;

    // get ray origin & direction
    vec4 camera_props = texelFetch(iChannel0, ivec2(0., CAMERA_LAYER_ROW), 0);
    vec3 ro = getRo(camera_props);
    vec3 rd = getRd(uv, ro, camera_props);

    vec3 outCol = vec3(0.2666, 0.2784, 0.3529);

    float die = texelFetch(iChannel0, ivec2(P_COLLISION_COL, PLAYER_LAYER_ROW), 0).x;
    if (int(die) == 1) {
        fragColor = texture(iChannel1, fragCoord/iResolution.xy);
        return;
    }

    vec3 objColor = vec3(0.);
    vec4 renderEndPointAndMode = blackHoleRender(ro, rd, objColor);

    if (renderEndPointAndMode.w == 1.) {
        vec3 diffusedLighting = 1.354 * getLighting(renderEndPointAndMode.xyz, vec3(10, 10, -5), objColor);
        //diffusedLighting += 0.25 * getLighting(renderEndPointAndMode.xyz, vec3(-10, -10, -5), objColor);
        // diffusedLighting += 0.25 * getLighting(renderEndPointAndMode.xyz, vec3(10, -10, -5), objColor);
        //diffusedLighting += 0.25 * getLighting(renderEndPointAndMode.xyz, vec3(-10, 10, -5), objColor);

        outCol = diffusedLighting;
    }
    // Color correction
    outCol = pow(min(outCol, 1.0), vec3(.99));

    // Output to screen
    fragColor = vec4(outCol, 1.0);
}
