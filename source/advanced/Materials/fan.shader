shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_albedo2 : hint_albedo;
uniform sampler2D texture_anim : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform vec4 Skin : hint_color;
uniform vec4 Skin2 : hint_color;
uniform vec4 Shirt : hint_color;
uniform vec4 Shirt2 : hint_color;
uniform vec4 Shirt3 : hint_color;
uniform vec4 Shirt4 : hint_color;
uniform vec4 Shorts : hint_color;
uniform vec4 Shoes : hint_color;
uniform int kit;
uniform float frame=1.0;
uniform int doAnim;
uniform float startframe=240.0;
uniform float framerange=120.0;
varying vec4 idata;
vec4 texelGet ( sampler2D tg_tex, ivec2 tg_coord ) {
	vec2 tg_texel = vec2(.00390625,.001953125);
	vec2 tg_getpos = (vec2(tg_coord) * tg_texel) + (tg_texel * 0.5);
	return texture(tg_tex, tg_getpos);
}

void vertex() {
	UV2.y = 1.0-UV2.y;
	idata=INSTANCE_CUSTOM;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	//float fframe = 4.0/256.0;
	//float fframe2= 4.0/256.0;
	float fframe=(idata.b*29.0*4.0);
	if (doAnim > 0) {
		//fframe = (mod (((TIME*0.8)+idata.g)*30.0,30.0)+1.0);
		//fframe = mix(fframe,fframe+30.0,smoothstep(0.5,0.55,idata.b))/512.0;
		fframe =( mod (fframe+(TIME*0.6)*30.0,framerange));
	}
	vec3 pos = texture(texture_anim,vec2((UV2.x*153.0)/256.0,(startframe+fframe)/512.0)).xyz;
	pos=(2.0*pos)-1.0;
	pos*=7.0;
	VERTEX = pos;
	
	
}




void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex=vec4(1.0);
	
	albedo_tex = mix(texture(texture_albedo,base_uv), texture(texture_albedo2,base_uv),smoothstep(0.5,.51,idata.g));
	vec3 skin = mix(Skin.rgb,Skin2.rgb,idata.r);
	vec3 alt=clamp(albedo_tex.rgb,0.0,1.0);
	ALBEDO=skin.rgb;
	//albedo_tex *= COLOR;
	ALBEDO=mix(skin,Shoes.rgb,smoothstep(0.1,0.2,alt.b));
	ALBEDO=mix(ALBEDO,Shorts.rgb,smoothstep(0.4,0.75,alt.b));
	vec3 shirt = mix(Shirt.rgb,Shirt2.rgb,idata.g);
	shirt=mix(shirt,Shirt4.rgb,smoothstep(.8,.96,idata.a));
	shirt=mix(shirt,Shirt3.rgb,smoothstep(0.6,1.0,idata.b));
	
	
	ALBEDO=mix(ALBEDO,shirt,smoothstep(0.8,0.85,alt.r));
	//ALBEDO=mix(ALBEDO,Shirt2.rgb,smoothstep(0.2,0.85,alt.r));
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
