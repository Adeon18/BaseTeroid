#iChannel0 "file://black_hole/buf_b.glsl"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 acc = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = vec4(
        tanh(pow(acc.xyz / acc.w, vec3(0.55))), 1.0
    );
}