// #iChannel1 "self"
// #iChannel2 "file://rotate.glsl"

// #include "render.glsl"


// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//     vec2 offset = texelFetch(iChannel1, ivec2(0, 0), 0).xy;

//     offset = calcOffset(offset);

//     fragColor = vec4(offset, 0., 0.);
// }