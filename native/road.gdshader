shader_type spatial;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform float metallic : hint_range(0.0,1.0) = 0;
uniform float roughness : hint_range(0.0,1.0) = 0.02;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform sampler2D wave;
uniform vec2 wave_dir = vec2(2.0,0.0);
uniform vec2 wave_dir2 = vec2(0.0,1.0);
uniform float time_scale : hint_range(0.0, 0.5) = 0.025;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color;

// Varying vars
varying float height;
varying vec3 world_pos;


float edge(float depth)
{
	depth = 2.0 * depth - 1.0;
	//return depth;
	return near * far / (far + depth * (near - far));
}

float forsnail(float amount, vec3 normal, vec3 view)
{
	vec3 norm_norm = normalize(normal);
	vec3 norm_view = normalize(view);
	return pow((1.0 - clamp(dot(norm_norm, norm_view), 0.0, 1.0)), amount);
	//return pow((1.0 - clamp(dot(normalized(normal), normalized(view)), 0.0, 1.0)), amount);
}
/*
void vertex()
{
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz /noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}
*/
void fragment() 
{
	// Depth stuff
	
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color3 = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	
	//float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	//float z_pos = edge(FRAGCOORD.z);
	//float z_diff = z_depth - z_pos;
	
	
	
	vec2 time = (TIME * wave_dir) * time_scale;
	vec2 time2 = (TIME * wave_dir2) * time_scale;
	
	vec3 normal_1 = texture(texture_normal, world_pos.xz + time).rgb;
	vec3 normal_2 = texture(texture_normal2, world_pos.xz + time2).rgb;
	vec3 normal_blend = mix(normal_1, normal_2, 0.5);
	
	//float forsnail = forsnail(6.0, NORMAL, VIEW);
	vec3 surface_color = mix(color, color2, color);
	//vec3 normal_blend = mix(texture(texture_normal,UV).rgb, texture(texture_normal2,UV).rgb);
	//vec3 normal = texture(texture_normal, UV).rgb;

	ALBEDO = mix(surface_color, color3, 0.75);
	//vec3 depth_color_adj = mix(edge_color, color3, step(edge_scale, z_diff));
	//ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0) );
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	// Place fragment code here.
}
