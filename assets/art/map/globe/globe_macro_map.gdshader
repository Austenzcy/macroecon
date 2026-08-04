shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D map_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grid_color : source_color = vec3(1.0);
uniform float grid_opacity : hint_range(0.0, 1.0) = 0.24;

float anti_aliased_grid_line(float coordinate) {
	float distance_to_line = abs(fract(coordinate - 0.5) - 0.5);
	float pixel_distance = distance_to_line / max(fwidth(coordinate), 0.0001);
	return 1.0 - smoothstep(0.28, 0.78, pixel_distance);
}

void fragment() {
	vec3 albedo = texture(map_texture, vec2(UV.x, 1.0 - UV.y)).rgb;
	vec3 light_direction = normalize(vec3(-0.52, 0.70, 0.58));
	float diffuse = max(dot(normalize(NORMAL), light_direction), 0.0);
	vec3 shaded_map = albedo * (0.84 + diffuse * 0.16);

	// A restrained 30-degree graticule. Longitude lines fade close to the
	// poles so their convergence does not create bright white caps.
	float longitude_line = anti_aliased_grid_line(UV.x * 12.0);
	float latitude_line = anti_aliased_grid_line(UV.y * 6.0);
	float pole_distance = min(UV.y, 1.0 - UV.y);
	longitude_line *= smoothstep(0.025, 0.11, pole_distance);
	float grid_line = max(longitude_line, latitude_line);

	ALBEDO = mix(shaded_map, grid_color, grid_line * grid_opacity);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
