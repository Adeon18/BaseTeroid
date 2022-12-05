//controller

#include "black_hole/common.glsl"
#iChannel2 "self"
#iKeyboard

const float force = 8.0;
const float mouse_sens = 100.0;
const float roll_speed = 0.5;

void mainImage(out vec4 o, in vec2 p) {
    p = floor(p);
    if(p.x > NAddr && p.y > 0.) discard;
    
    //get camera data
    vec3 cp = get(CamP).xyz;
    vec4 ca = get(CamA);
    
    float mode = 0.0;
    if (isKeyDown(Key_R)) mode = 1.0;
    
    //initialization
    if (iFrame == 0) {
        cp = normalize(vec3(1))*5.1;
        ca = aa2q( normalize(vec3(0,1,-0.3)), 1.17);
    }
    vec4 oldca = ca;
    if(p.x == PrevCamP) o = vec4(cp, 0);
    if(p.x == PrevCamA) o = ca;
    
    mat3 cam = getCam(ca);
    
    //get velocities
    vec3 cv = get(CamV).xyz;
    vec4 cav = get(CamAV);
    
    float dt = 1./60.0;
    //update position
    if(isKeyDown(Key_W)) cv += force*dt*cam*vec3(0,0,1);
    if(isKeyDown(Key_S)) cv += force*dt*cam*vec3(0,0,-1);
    if(isKeyDown(Key_A)) cv += force*dt*cam*vec3(-1,0,0);
    if(isKeyDown(Key_D)) cv += force*dt*cam*vec3(1,0,0);
    
    cp += dt*cv;
    cv += -cv*tanh(10.0*dt);
    
    //update camera orientation
    vec2 dmouse = dt*mouse_sens*(iMouse.xy - get(PrevMouse).xy)/iResolution.x;
    
    if(length(dmouse) < 0.1)
    {
        //rotate around y ax
        ca = qq2q(ca, aa2q(cam*vec3(0,1,0), -dmouse.x)); 
        //rotate around x ax
        ca = qq2q(ca, aa2q(cam*vec3(1,0,0), dmouse.y));
    }
    
    //roll camera
    if(isKeyDown(Key_Q)) ca = qq2q(ca, aa2q(cam*vec3(0,0,1), -roll_speed*dt)); 
    if(isKeyDown(Key_E)) ca = qq2q(ca, aa2q(cam*vec3(0,0,1), roll_speed*dt)); 
    
    if(distance(oldca, ca) > 0.001 || length(cv) > 0.01) mode = 1.0;
    
    if(p.x == CamP) o = vec4(cp, mode);
    if(p.x == CamA) o = ca;
    if(p.x == CamV) o = vec4(cv, 0.0);
    if(p.x == CamAV) o = vec4(0.0);
    if(p.x == PrevMouse) o = vec4(iMouse.xy, 0, 0);
}