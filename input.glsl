#iKeyboard

#iChannel0 "self"


vec2 handleKeyboard(vec2 offset) {
    float velocity = 4. / 100.;
    
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

    offset += direction * velocity;
    return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 offset = texelFetch(iChannel0, ivec2(0, 0), 0).xy;

    offset = handleKeyboard(offset);

    fragColor = vec4(offset, 0, 0);
}