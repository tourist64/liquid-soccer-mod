// NOTE: Shader automatically converted from Godot Engine 3.4.beta's SpatialMaterial.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_lambert,specular_disabled,vertex_lighting,world_vertex_coords;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform float off=0.127;
uniform float id=0.0;

void vertex() {
	ROUGHNESS=roughness;
	float flip=COLOR.r;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	//if (flip<.9)
	//	UV.x=1.0-UV.x;
	UV.y += id*off + 0.005;
	
}




void fragment() {
	vec2 base_uv = UV;
	if (smoothstep(COLOR.r,0.95,0.97)>0.9)
		base_uv.x=1.0-base_uv.x;
		
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	//ALBEDO = mix(ALBEDO,albedo_tex.rgb,smoothstep(0.9,0.95,COLOR.r));
	ALBEDO=mix(albedo_tex.rgb,vec3(0.1,0.1,0.1),dot(NORMAL,vec3(0.0,1.0,0.0)));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
