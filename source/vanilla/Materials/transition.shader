shader_type canvas_item;

render_mode unshaded;
uniform float cutoff : hint_range(0.0,1.0);
uniform float ssize : hint_range(0.0,1.0);
uniform sampler2D mask: hint_albedo;
uniform sampler2D tex: hint_albedo;
uniform bool showTex;
void fragment()
{
	float v=texture(mask,UV).r;
	float a = smoothstep(cutoff,cutoff+ssize,v*(1.0-ssize)+ssize);
	//if (showTex){
	//	COLOR=vec4(texture(tex,UV).rgb,a);	
	//}
	//else{
	COLOR=vec4(COLOR.rgb,a);
	//}
}