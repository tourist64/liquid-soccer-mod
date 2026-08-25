shader_type spatial;
render_mode blend_mix,depth_draw_alpha_prepass,cull_disabled;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_verts : hint_albedo;

uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform int framemod;
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord, int tg_lod ) {
	vec2 tg_texel = 1.0 / vec2(256.0);
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos, float(tg_lod));
}
void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	int index=int(ceil(COLOR.g * 163.0));
	//vec3 pos = texelGet(texture_verts,ivec2(index,framemod),0).xyz;
	//VERTEX = pos;
	
}


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb  ;//* (1.0/max(albedo_tex.r,0.05));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = smoothstep(albedo_tex.r,0.0,0.01);
	//ALPHA_SCISSOR=alpha_scissor_threshold;
}
