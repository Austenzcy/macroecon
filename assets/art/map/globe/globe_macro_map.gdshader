shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D map_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
	vec3 albedo = texture(map_texture, vec2(UV.x, 1.0 - UV.y)).rgb;
	vec3 light_direction = normalize(vec3(-0.52, 0.70, 0.58));
	float diffuse = max(dot(normalize(NORMAL), light_direction), 0.0);
	ALBEDO = albedo * (0.84 + diffuse * 0.16);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
