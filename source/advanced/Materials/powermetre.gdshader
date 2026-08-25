
shader_type spatial;
render_mode async_visible,blend_mix,depth_draw_opaque,cull_back,diffuse_lambert,specular_disabled,unshaded;

uniform vec4 albedoFrom : hint_color;
uniform vec4 albedoTo : hint_color;
uniform vec4 albedoBG : hint_color;

uniform float progress;

void vertex() {
	UV=UV;
	// billboard the mesh
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
}

void fragment() {
	vec2 base_uv = UV;
	
	float pr=smoothstep(0.0+progress,0.0 +progress + 0.01,UV.x);
	ALBEDO = mix(mix(albedoFrom.rgb,albedoTo.rgb,progress),albedoBG.rgb,pr);
}
