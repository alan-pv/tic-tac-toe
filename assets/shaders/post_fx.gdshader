shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

uniform float aberration : hint_range(0.0, 8.0) = 1.0;   // pixels of split at the edge
uniform float grain : hint_range(0.0, 0.12) = 0.030;
uniform float grain_time = 0.0;
uniform float vignette : hint_range(0.0, 1.5) = 0.45;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.35;
uniform float scanlines : hint_range(0.0, 0.4) = 0.0;
uniform float scan_density : hint_range(100.0, 2000.0) = 700.0;
uniform float aspect = 1.0;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0, 1.0, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	float d = length(c);

	// Radial, not uniform: none in the middle, most in the corners, so centred
	// text is never fringed with colour.
	vec3 col;
	if (aberration > 0.001) {
		vec2 dir = normalize(c + vec2(1e-6));
		vec2 off = dir * SCREEN_PIXEL_SIZE * aberration * smoothstep(0.15, 0.85, d);
		col.r = texture(screen_tex, uv + off).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - off).b;
	} else {
		col = texture(screen_tex, uv).rgb;
	}

	col *= tint;

	if (scanlines > 0.001) {
		float s = sin(FRAGCOORD.y * scan_density * 0.01);
		col *= 1.0 - scanlines * (0.5 + 0.5 * s);
	}

	col *= 1.0 - vignette * smoothstep(vignette_start, 1.05, d);

	// Grain, strongest in the dark areas, which is where banding shows.
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	float n = hash21(FRAGCOORD.xy + fract(grain_time) * 311.7);
	col += (n - 0.5) * grain * (1.0 + 1.8 * (1.0 - smoothstep(0.0, 0.30, luma)));

	col = mix(col, flash_color, flash);

	COLOR = vec4(col, 1.0);
}