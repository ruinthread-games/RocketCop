shader_type spatial;
render_mode diffuse_toon, specular_toon;

varying vec3 vertex_out;

uniform vec4 primary_colour : hint_color;
uniform vec4 secondary_colour : hint_color;

uniform vec2 brick_dimensions = vec2(2.0,1.0);
uniform vec3 brick_offset;

void vertex()
{
	vertex_out = VERTEX;
}

void fragment()
{
	float ofs = 0.5*brick_dimensions.x * float(int(floor(vertex_out.y/brick_dimensions.y)) % 2);
	float grout_mask = (1.0-step(fract(vertex_out.y/brick_dimensions.y+brick_offset.y),0.1)) * (1.0-step(fract(vertex_out.x/brick_dimensions.x+brick_offset.x+ofs),0.1)) * (1.0-step(fract(vertex_out.z/brick_dimensions.x+brick_offset.z+ofs),0.1));
	ALBEDO = mix(primary_colour, secondary_colour, grout_mask).rgb;
}