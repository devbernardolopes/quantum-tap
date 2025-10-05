shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.5;

uniform float ring_thickness : hint_range(0.01, 0.5) = 0.1;
uniform float ring_radius : hint_range(0.1, 0.9) = 0.4;

uniform vec4 progress_color : source_color  = vec4(1.0, 0.5, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 gradient_color : source_color = vec4(0.5, 0.2, 1.0, 1.0);

uniform float smoothness : hint_range(0.001, 0.1) = 0.01;

uniform float gradient_strength : hint_range(0.0, 1.0) = 0.5;
uniform bool use_gradient = true;

uniform float rotation_offset : hint_range(0.0, 6.28318) = 0.0;

vec2 rotate(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
}

void fragment() {
    vec2 uv = UV - 0.5;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x) + PI;

    angle = mod(angle + rotation_offset, 2.0 * PI);

    float start_angle = PI * 0.5;
    float progress_angle = progress * 2.0 * PI;

    float adjusted_angle = mod(angle + start_angle, 2.0 * PI);

    float outer_ring = 1.0 - smoothstep(ring_radius + ring_thickness - smoothness,
                                       ring_radius + ring_thickness + smoothness, dist);
    float inner_ring = smoothstep(ring_radius - smoothness, ring_radius + smoothness, dist);
    float ring_mask = outer_ring * inner_ring;

    float progress_mask = step(adjusted_angle, progress_angle);

    vec4 final_color;
    if (use_gradient) {
        float gradient_factor = adjusted_angle / (2.0 * PI);
        final_color = mix(progress_color, gradient_color, gradient_factor * gradient_strength);
    } else {
        final_color = progress_color;
    }

    vec4 ring_color = mix(background_color, final_color, progress_mask);

    COLOR = vec4(ring_color.rgb, ring_color.a * ring_mask);
}