shader_type canvas_item;
// Chromatic aberration — RGB channel separation.
// Used during DiscoHallucination Phase 4 + 5.
uniform float aberration : hint_range(0.0, 0.016) = 0.005;

void fragment() {
	vec2 r_uv = UV + vec2( aberration, 0.0);
	vec2 b_uv = UV - vec2( aberration, 0.0);
	float r = texture(TEXTURE, r_uv).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, b_uv).b;
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(r, g, b, a);
}
