
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform float scanline_strength = 0.08;
uniform float vignette_strength = 0.35;
uniform float distortion = 0.003;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float wave = sin(uv.y * 120.0) * distortion;
	uv.x += wave;
	
	vec4 color = texture(screen_texture, uv);
	
	float scanline = sin(uv.y * 800.0) * scanline_strength;color.rgb -= scanline;
	
	float dist = distance(uv, vec2(0.5));
	color.rgb *= smoothstep(0.8, vignette_strength, dist);
	
	COLOR = color;
	}