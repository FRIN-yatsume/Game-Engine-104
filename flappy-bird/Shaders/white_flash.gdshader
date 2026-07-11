shader_type canvas_item;
render_mode unshaded;

uniform float mix_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 albedo = texture(TEXTURE, UV);
	vec3 white = vec3(1.0);
	COLOR = vec4(mix(albedo.rgb, white, mix_amount), albedo.a);
}
