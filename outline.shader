shader_type canvas_item;
render_mode unshaded;

uniform bool Smooth = true;
uniform float width : hint_range(0.0, 16) = 1.0;
uniform vec4 outline_color : hint_color = vec4(1.0);
uniform int pixel_size : hint_range(1, 10) = 4;
uniform bool add_margins;

void vertex() 
{
	if (add_margins)  VERTEX += (UV * 2.0 - 1.0) * width;
}

void fragment()
{
	// Modify sampling location for margin-added textures (non-animated, non-atlas using textures only)
	vec2 uv = UV;
	if (add_margins)
	{
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
		
		if (uv != clamp(uv, vec2(0.0), vec2(1.0)))
			COLOR.a = 0.0;
		else
			COLOR = texture(TEXTURE, uv);
	} else COLOR = texture(TEXTURE, uv);

	vec2 unit = (1.0/float(pixel_size) ) / vec2(textureSize(TEXTURE, 0));
	vec4 pixel_color = COLOR;

	if (pixel_color.a < 1.0) 
	{
		pixel_color = mix(outline_color, pixel_color, pixel_color.a);
		pixel_color.a = 0.0;  //We'll do an alpha test later in the outline func
		for (float x = -ceil(width); x <= ceil(width); x++) {
			for (float y = -ceil(width); y <= ceil(width); y++) {
				vec2 uv2 = uv + vec2(x*unit.x, y*unit.y);
				
				if (uv2 != clamp(uv2, vec2(0.0), vec2(1.0))  //Out of texture bounds
					|| texture(TEXTURE, uv2).a == 0.0 //Not in range of a texel
					|| (x==0.0 && y==0.0)  //Directly on top of a texel we already have the correct sample for
					) 
					continue;

				if (Smooth) {
					pixel_color.a += outline_color.a / (pow(x,2)+pow(y,2)) * (1.0-pow(2.0, -width));
						pixel_color.a = min(pixel_color.a, 1.0);

				} else {
					pixel_color.a = outline_color.a;
				}
			}
		}
	}
	COLOR = pixel_color;
}
