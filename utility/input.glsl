#iKeyboard

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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 controls = handleKeyboard();

    fragColor = vec4(controls, 0, 0);
}