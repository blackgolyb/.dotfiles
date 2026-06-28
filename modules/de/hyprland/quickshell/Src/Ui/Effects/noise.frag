#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float strength;
    float grainSize;
    vec2 resolution;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 cell = floor(px / grainSize);

    float n = hash(cell);

    // centered noise: less dirty than pure black/white noise
    float grain = (n - 0.5) * 2.0;

    float alpha = strength * qt_Opacity;
    vec3 color = vec3(0.5 + grain * 0.5);

    fragColor = vec4(color * alpha, alpha);
}
