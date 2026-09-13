shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform bool enabled = false;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (!enabled || outline_width <= 0.0) {
		COLOR = col;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
		a = max(a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		
		if (col.a < 0.1 && a > 0.1) {
			COLOR = outline_color;
		} else {
			COLOR = col;
		}
	}
}
