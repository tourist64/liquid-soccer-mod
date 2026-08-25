shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_blinn;
uniform vec4 albedo_color : hint_color;
uniform vec4 Skin : hint_color;
uniform vec4 Shirt : hint_color;
uniform vec4 Shirt2 : hint_color;
uniform vec4 Shorts : hint_color;
uniform vec4 Shoes : hint_color;
uniform vec4 Numbers : hint_color;
uniform vec4 Gloves : hint_color;

uniform int kit;
uniform sampler2D texture_albedo ;
uniform sampler2D texture_albedo2 ;
uniform sampler2D texture_numbers  ;
uniform sampler2D texture_numbers2 ;
//uniform sampler2D texture_names ;
uniform sampler2D texture_bibs ;

uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform vec3 numChannelMult;
uniform bool nameOff=false;
uniform float numUVOff=0.0;
//uniform float nameOffMult=0.1;
uniform bool isKeeper=false;
uniform bool isSimple=false;
uniform bool doBibs=false;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}




void fragment() {
	if (!isSimple) {
	vec2 base_uv = UV;
	vec4 albedo_tex;
	vec3 al=vec3(0.0);
	if  (kit==0)
		albedo_tex = texture(texture_albedo,base_uv);
	else
		albedo_tex = texture(texture_albedo2,base_uv);
	
	//albedo_tex *= COLOR;
	al=Skin.rgb;
	al=mix(Skin.rgb,Shoes.rgb,smoothstep(0.0,0.05,albedo_tex.r));
	al=mix(al,Shorts.rgb,smoothstep(0.0,1.00,albedo_tex.g));
	
	al=mix(al,Shirt.rgb,smoothstep(0.5,1.0,albedo_tex.r));
	al=mix(al,Shirt2.rgb,smoothstep(0.0,1.0,albedo_tex.b));
	
	if (isKeeper ){
		al = mix(al,Gloves.rgb,smoothstep(0.5,.70,albedo_tex.g)*(1.0-smoothstep(0.8,.9,albedo_tex.g)));
	}
	
	vec3 numt=texture(texture_numbers,base_uv+vec2(0.0,numUVOff),0).rgb;
	vec3 mask=texture(texture_numbers2,base_uv,0).rgb;
	numt*=numChannelMult;
	numt*=mask.r;
	
	ALBEDO=mix(al,Numbers.rgb,max(max(numt.r,numt.g),numt.b));
	//if (nameOff){
	//	vec3 sa=texture(texture_names,base_uv).rgb;
	//	ALBEDO = mix(ALBEDO,Numbers.rgb,sa.g);
	//}
	if (doBibs){
		vec3 bib=texture(texture_bibs,base_uv).rgb;
		ALBEDO=mix(ALBEDO,albedo_color.rgb,bib.r);
		ALBEDO=mix(ALBEDO,Shirt.rgb,bib.g);
		
	}

	}
	else {
		ALBEDO=albedo_color.rgb;
		
	}
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
	//SSS_STRENGTH=0.50;
}
