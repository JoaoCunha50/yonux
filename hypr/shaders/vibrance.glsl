#version 300 es
precision mediump float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

const int RES_SIDE = 1920;

const float GAMMA_SIDE   = 1.10;
const float VIB_SIDE     = 1.32;
const float VIB_MAIN     = 1.15;
const float BRIGHT_SIDE  = 1.20;
const vec3 EYE_SENSITIVITY = vec3(0.299, 0.587, 0.114);

void main() {
    vec4 pixel = texture(tex, v_texcoord);
    vec3 rgb = pixel.rgb;

    ivec2 screen = textureSize(tex, 0);

    if (screen.x == RES_SIDE) {
        rgb = pow(rgb, vec3(1.0 / GAMMA_SIDE));
        float luma = dot(rgb, EYE_SENSITIVITY);
        rgb = mix(vec3(luma), rgb, VIB_SIDE);
        // rgb *= BRIGHT_SIDE;
    } else {
        float luma = dot(rgb, EYE_SENSITIVITY);
        rgb = mix(vec3(luma), rgb, VIB_MAIN);
    }

    fragColor = vec4(rgb, pixel.a);
}
