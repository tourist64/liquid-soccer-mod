shader_type canvas_item;
uniform float siz=1.0;
uniform float ysiz=0.8;
uniform float linedepth=1.0;
uniform float thresh=0.7;
uniform float soften=1.0;
uniform vec4 linecolor: hint_color;
const float eps = 0.0000001;

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 rgb2hsv( in vec3 c)
{
    vec4 k = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.zy, k.wz), vec4(c.yz, k.xy), (c.z<c.y) ? 1.0 : 0.0);
    vec4 q = mix(vec4(p.xyw, c.x), vec4(c.x, p.yzx), (p.x<c.x) ? 1.0 : 0.0);
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0*d+eps)), d / (q.x+eps), q.x);
}
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}
vec3 rtexture(sampler2D t,vec2 uv) {
	vec3 c;
	vec3 f=texture(t,uv).xyz;
	vec3 hocol=rgb2hsv(f);
	//f.b=.5;
	//c=hsv2rgb(f);
	return f;
}
void fragment() {
	vec3 ocol=texture(TEXTURE,UV).xyz;
	// flatten using hsv
	vec3 hocol=rgb2hsv(ocol);
	hocol.b=floor(hocol.b*10.0)/10.0;
	ocol=hsv2rgb_smooth(hocol);
    vec3 col = texture(TEXTURE, UV).xyz;
	//hocol = rgb2hsv(col);
	//hocol.b=0.5;
	col=-8.0 * col;//hsv2rgb(hocol);
//	vec3 ycol = texture(TEXTURE, UV + vec2(0.0, SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
//	vec3 ymcol = texture(TEXTURE, UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
//	vec3 hy=rgb2hsv(ycol);
//	vec3 hym=rgb2hsv(ymcol);
//	float dy=abs(col.b-hym.b)+abs(col.b-hy.b);
//	vec3 xcol = texture(TEXTURE, UV + vec2( SCREEN_PIXEL_SIZE.x*siz),0.0).xyz;
//	vec3 xmcol = texture(TEXTURE, UV + vec2( -SCREEN_PIXEL_SIZE.x*siz),0.0).xyz;
//	vec3 hx=rgb2hsv(xcol);
//	vec3 hxm=rgb2hsv(xmcol);
//	float dx=abs(col.b-hxm.b)+abs(col.b-hx.b);
////    
    col += texture(TEXTURE, UV + vec2(0.0, SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
    col += texture(TEXTURE, UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
    col += texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x*siz, 0.0)).xyz;
    col += texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x*siz, 0.0)).xyz;
    col += texture(TEXTURE, UV + SCREEN_PIXEL_SIZE.xy*siz).xyz;
    col += texture(TEXTURE, UV - SCREEN_PIXEL_SIZE.xy*siz).xyz;
    col += texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x*siz, SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
    col += texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x*siz, -SCREEN_PIXEL_SIZE.y*ysiz)).xyz;
//	float tl=texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x*siz, SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float l=texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x*siz, 0.0)).z;
//	float bl=texture(TEXTURE, UV + vec2(-SCREEN_PIXEL_SIZE.x*siz, -SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float t=texture(TEXTURE, UV + vec2(0.0, SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float bt=texture(TEXTURE, UV + vec2(0.0, -SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float tr=texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x*siz, SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float r=texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x*siz, 0.0)).z;
//	float br=texture(TEXTURE, UV + vec2(SCREEN_PIXEL_SIZE.x*siz, -SCREEN_PIXEL_SIZE.y*ysiz)).z;
//	float x = 3.0*tl + 10.0*l + 3.0*bl - 3.0*tr - 10.0*r - 3.0*br;
//	float y = 3.0 * tl + 10.0*t + 3.0*tr - 3.0* bl- 10.0 * bt -3.0 * br;
//	float line  = (sqrt(x*x)+(y*y));
	float line=col.r;
	//float line=(dx+dy)*.25;
	line=1.0-smoothstep(thresh,soften,line);
	
	
	//vec3 tcol=rgb2hsv(ocol);
	//tcol.b=floor(tcol.b*5.0)/5.0;
	//ocol=hsv2rgb_smooth(tcol);
	line=mix(1.0,line,linedepth);
    COLOR.xyz = ocol * (line) + (1.0-line)*linecolor.rgb ;
	//COLOR.xyz=vec3(col.r);
}