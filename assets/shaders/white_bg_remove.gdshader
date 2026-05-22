shader_type canvas_item;
// Removes near-white backgrounds from FLUX/Scenario.gg silhouette exports
// where art was generated on a white canvas.
// threshold 0.86: preserves coloured artwork while discarding light-grey / pure-white bg.
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Perceptual luminance — weights green channel more (human eye is most sensitive)
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	if (lum > 0.86)
		discard;
	COLOR = c;
}
