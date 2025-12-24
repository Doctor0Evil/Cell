shader_type canvas_item;

uniform float distortion_amount : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float neurochip_bleed : hint_range(0.0, 1.0) = 0.0;

// Chromatic aberration strength (0 = off).
uniform float chromatic_strength : hint_range(0.0, 2.0) = 0.0;

// Vignette color and shape.
uniform vec4 vignette_color : source_color = vec4(0.0, 0.9, 0.7, 1.0);
uniform float vignette_inner = 0.25;
uniform float vignette_outer = 0.95;
uniform float time_scale = 1.25;

// World-driven wobble
uniform vec2 world_offset = vec2(0.0);
uniform float world_scale = 0.1;

// Low quality mode for mobile
uniform bool low_quality = false;

// Screen texture for CA.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_scale;

    // Incorporate world offset into noise phase for world-reactive wobble
    vec2 world_uv = world_offset * world_scale;
    float world_phase = sin(world_uv.x + world_uv.y + t * 0.3);

    float noise = rand(vec2(uv.y * 12.0 + t * 2.3 + world_phase, uv.x * 7.0 - t * 1.7 - world_phase));

    float jitter = (noise - 0.5) * 0.02 * distortion_amount;
    if (low_quality) {
        jitter *= 0.4;
    }
    uv.x += jitter;

    vec2 centered = (uv - vec2(0.5)) * 2.0;
    float dist = length(centered);
    float v = smoothstep(vignette_inner, vignette_outer, dist);

    // Modulate vignette using world_phase so it can feel like world-reactive
    float world_mod = world_phase * 0.5 + 0.5;
    float vignette_strength = v * world_mod;

    float scan = sin(uv.y * (low_quality ? 300.0 : 900.0)) * 0.5 + 0.5;
    float scan_mask = mix(0.0, scan, scanline_intensity);
    if (low_quality) {
        scan_mask = 0.0;
    }

    // Base screen color.
    vec2 suv = SCREEN_UV;
    vec4 base_col = texture(screen_texture, suv);

    // Chromatic aberration offset from center (edges stronger)
    float ca = chromatic_strength * vignette_strength;
    if (low_quality) {
        ca *= 0.3;
    }
    vec2 offset = normalize(centered + 0.0001) * ca * 0.002;

    float r = texture(screen_texture, suv + offset).r;
    float g = base_col.g;
    float b = texture(screen_texture, suv - offset).b;
    vec3 ca_color = vec3(r, g, b);

    float ca_mix = clamp(ca, 0.0, 1.0);
    vec3 final_rgb = mix(base_col.rgb, ca_color, ca_mix);

    vec3 tint = mix(vec3(0.0), vignette_color.rgb, neurochip_bleed);
    float alpha = vignette_strength;
    alpha += scan_mask * 0.15;
    alpha = clamp(alpha, 0.0, 1.0);

    vec3 tinted = mix(final_rgb, final_rgb * tint, alpha);

    COLOR = vec4(tinted, 1.0);
}
