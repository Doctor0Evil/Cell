shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center : hint_range(0.0,1.0) = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float smoothness : hint_range(0.01, 1.0) = 0.4;

void fragment() {
    vec2 uv = SCREEN_UV;
    float dist = distance(uv, center);
    float vign = smoothstep(radius, radius + smoothness, dist);
    COLOR = vec4(0.0, 0.0, 0.0, vign * intensity);
}
