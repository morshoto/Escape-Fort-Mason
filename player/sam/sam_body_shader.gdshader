shader_type spatial;

uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform vec4 jacket_color : source_color = vec4(0.13, 0.19, 0.29, 1.0);
uniform vec4 top_color : source_color = vec4(0.29, 0.47, 0.61, 1.0);
uniform vec4 pants_color : source_color = vec4(0.10, 0.15, 0.22, 1.0);

varying vec3 body_position;

void vertex() {
	body_position = VERTEX;
}

void fragment() {
	vec3 color = texture(base_texture, UV).rgb;
	float jacket_mask = smoothstep(0.68, 0.78, body_position.y)
		* (1.0 - smoothstep(1.48, 1.6, body_position.y));
	float center_mask = 1.0 - smoothstep(0.28, 0.48, abs(body_position.x));
	float pants_mask = 1.0 - smoothstep(0.86, 1.02, body_position.y);

	color = mix(color, jacket_color.rgb, jacket_mask * 0.94);
	color = mix(color, top_color.rgb, jacket_mask * center_mask * 0.42);
	color = mix(color, pants_color.rgb, pants_mask * 0.92);

	ALBEDO = color;
	ROUGHNESS = 0.82;
}
