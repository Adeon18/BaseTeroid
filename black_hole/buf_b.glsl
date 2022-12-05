#include "black_hole/common.glsl"
#iChannel0 "self"
#iChannel1 "file://img/game_over.png"
#iChannel2 "file://black_hole/buf_a.glsl"

// render improvement iterations
// #define SPP 1

// const float aperture_size = 0.0;

// this function procuces numbers in a unit sphere
// vec2 aperture() {
//     vec2 r = rand2();
//     return vec2(sin(TWO_PI*r.x), cos(TWO_PI*r.x))*sqrt(r.y);
// }

/// initialise ray_origin, ray_direction based on pixel value position
bool getRay(vec2 uv, out vec3 ray_origin, out vec3 ray_direction) {
    // mat3 cam = getCam(get(CamA));
    // vec2 apert_cent = -0.*uv;
    // vec2 ap = aperture();
    // if(!(distance(ap, apert_cent) < 1.0)) return false;
    // vec3 daperture = ap.x*cam[0] + ap.y*cam[1];

    // float focus = 2.5 + 0.8;  // * pow(length(ap), 5.0);
    // ray_direction = normalize(focus*(cam*vec3(FOV*uv, 1.0)));  // - aperture_size * daperture);

    ray_origin = get(CamP).xyz;  // + aperture_size * daperture;
    ray_direction = normalize(3.3 * (
        getCam(get(CamA)) * vec3(FOV * uv, 1.0)
    ));
    return true;
}

const vec3 BH_pos = vec3(0.0);  // BH position
const float BH_R = 0.5;         // event horizon radius
vec3 force(vec3 p) {
    vec3 r = (p - BH_pos);
    return -1.5 * BH_R * r / pow(length(r), 5.0);
}

// integration timestep
const float dt = 0.15;
vec4 render(vec2 fragCoord) {
    // fragCoord += rand2();  // add noise (for multipart calculation)
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    vec3 current_position, ray_velocity;
    if(!getRay(uv, current_position, ray_velocity)) return vec4(0,0,0,1);

    vec3 fcol = vec3(0.0);

    for (int i = 0; i < 128; i++) {
        // integrate velocity (simple integration)
        ray_velocity += force(current_position) * dt;
        current_position += ray_velocity * dt;
        if (distance(BH_pos, current_position) < BH_R) {  // 0.9 * 
            return vec4(fcol, 1.0); // got below event horizon
        }
    }

    // vec3 tx = texture(iChannel1, fragCoord/iResolution.xy).xyz;
    // vec3 tx = texture(iChannel1, ray_velocity.xy*4.).rgb;
    vec3 tx = texture(iChannel1, ray_velocity.xy).rgb;
    fcol = 15. * pow(tx, vec3(4.0));

    return vec4(fcol, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // rng_initialize(fragCoord, iFrame);

    // fragColor = vec4(0.0);
    // for (int i = 0; i < SPP; i++)
    //     fragColor += render(fragCoord);

    fragColor = render(fragCoord);
}