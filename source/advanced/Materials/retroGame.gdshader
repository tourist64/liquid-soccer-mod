shader_type canvas_item;
render_mode unshaded;
uniform vec2 player_position;
uniform vec4 color : hint_color = vec4(0.305, 0.298, 0.341,1);
uniform sampler2D vpt;
uniform float MULTIPLIER = 0.56;
uniform float SCALE = 0.5;
uniform float SOFTNESS = 0.45;
uniform vec2 resolution = vec2(640.0, 480.0); // Set the number of rows and columns the texture will be divided in. Scanlines and grille will make a square based on these values
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;
uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float warp_amount :hint_range(0.0, 5.0) = 1.0; // Warp the texture edges simulating the curved glass of a CRT monitor or old TV.
uniform float color_depth=8.0;
uniform float brightness : hint_range(0.0,5.0)=1.0;
uniform float vignette_intensity = 0.4; // Size of the vignette, how far towards the middle it should go.
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

// Takes in the UV and warps the edges, creating the spherized effect
vec2 warp(vec2 uv){
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta.xy, delta.xy);
	float delta4 = delta2 * delta2;
	float delta_offset = delta4 * warp_amount;
	
	return uv + delta * delta_offset;
}
float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_opacity);
}
void fragment(){
	
	
	vec2 uv = warp(UV);
	float vig = vignette(uv);
	vec2 tex_uv = ceil(uv * resolution) / resolution;
	vec3 tex = texture(TEXTURE,tex_uv).rgb;
	
	float r = (floor (tex.r*color_depth)/color_depth) * brightness;
	float g=  (floor (tex.g*color_depth)/color_depth) * brightness;
	float b=  (floor (tex.b*color_depth)/color_depth) *brightness;

	
	uv = warp(UV);
	float g_r = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
	r = mix(r, r * g_r, grille_opacity);
		
	float g_g = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
	g = mix(g, g * g_g, grille_opacity);
		
	float b_b = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));
	b = mix(b, b * b_b, grille_opacity);
	tex=vec3(r,g,b);
	float scanlines = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
	tex = mix(tex, tex * vec3(scanlines), scanlines_opacity);
	
	COLOR =vec4(tex*vig,1.0);
	
	
}