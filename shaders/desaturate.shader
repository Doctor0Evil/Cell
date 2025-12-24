shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(lum);
    vec3 outc = mix(col.rgb, gray, amount);
    COLOR = vec4(outc, col.a);
}
