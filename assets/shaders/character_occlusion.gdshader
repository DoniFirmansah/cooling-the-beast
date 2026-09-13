shader_type canvas_item;

uniform bool is_occluded = false;
uniform vec4 silhouette_color : source_color = vec4(0.35, 0.92, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.5;
uniform float pulse_speed : hint_range(0.0, 12.0) = 5.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	if (!is_occluded) {
		COLOR = col;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
		a = max(a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		
		if (col.a < 0.1 && a > 0.1) {
			// Sharp glowing outline around the character
			COLOR = silhouette_color;
		} else if (col.a >= 0.1) {
			// Holographic X-Ray pulse through occlusion
			float pulse = 0.45 + 0.25 * sin(TIME * pulse_speed);
			vec4 occluded_tint = mix(col, silhouette_color, pulse);
			COLOR = occluded_tint;
			COLOR.a = col.a;
		} else {
			COLOR = col;
		}
	}
}
