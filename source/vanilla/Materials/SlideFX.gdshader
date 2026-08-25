shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_disabled,vertex_lighting;
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
varying float age;

void vertex() {
	ROUGHNESS=roughness;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	UV+=INSTANCE_CUSTOM.yz*0.1;
	age=INSTANCE_CUSTOM.y;
	
}




void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv*0.5);
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	float thresh=age*age;
	float alph=smoothstep(thresh,thresh+0.01,albedo_tex.r);
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = albedo.a * alph;
}
