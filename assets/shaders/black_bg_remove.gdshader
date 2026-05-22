shader_type canvas_item;
// Removes the solid-black background from Scenario.gg sprite exports.
// Threshold 0.04 preserves very-dark-brown wood and shadow areas in the
// illustration while discarding pure-black (0,0,0) background pixels.
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    if (c.r < 0.04 && c.g < 0.04 && c.b < 0.04)
        discard;
    COLOR = c;
}
