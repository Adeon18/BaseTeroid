#iChannel0 "file://input.glsl"
#iChannel1 "self"

vec2 calcOffset(vec2 offset) {
    float velocity = 20. / 100.;
    vec2 controls = texelFetch(iChannel0, ivec2(0, 0), 0).xy;

    offset += controls * velocity;
    return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 offset = texelFetch(iChannel1, ivec2(0, 0), 0).xy;
    
    offset = calcOffset(offset);

    fragColor = vec4(offset, 0., 0.);
}