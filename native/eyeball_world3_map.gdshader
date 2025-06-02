shader_type spatial;

// New uniform for world scale
uniform float u_world_scale : hint_range(0.01, 10.0) = 1.0; // Default to 1:1 scale

// Base noise textures
uniform sampler2D u_noise : source_color;
uniform sampler2D u_noise2 : source_color;
uniform sampler2D u_noise3 : source_color;

// Texture uniforms
uniform sampler2D u_grass_texture : source_color;

varying vec3 v_normal;
varying vec3 v_pos; // This will be the world position of the vertex, affected by MODEL_MATRIX
varying vec3 v_view_dir;

// Biome parameters (these remain defined for the 1:1 world scale)
const float outer_rim_start = 9000.0;
const float outer_rim_blend = 8900.0; // Note: This might be a typo and intended to be a width like other blends.
                                     // If so, it should be added to outer_rim_start for the second smoothstep edge.
                                     // Current code uses it as the blend region's start.
const float ocean_ring_start = 2450.0;
const float ocean_ring_blend = 2200.0;
const float desert_center_radius = 1800.0;
const float desert_blend = 100.0;
const float volcano_radius = 120.0;
const float volcano_blend = 100.0;
const float volcano_core_radius = 5.0;
const float volcano_height = 1.0; // This is a relative height within the volcano model

// Base colors with variations
const vec3 VOLCANO_DARK = vec3(0.05, 0.02, 0.01);
const vec3 VOLCANO_LIGHT = vec3(0.1, 0.15, 0.3);
const vec3 VOLCANO_GLOW = vec3(1.0, 0.3, 0.1);
const vec3 DESERT_COLOR_A = vec3(0.35, 0.28, 0.15);
const vec3 DESERT_COLOR_B = vec3(0.28, 0.22, 0.12);
const vec3 DESERT_SPARKLE = vec3(1.8, 1.7, 1.4);
const vec3 GREEN_COLOR_A = vec3(0.04, 0.012, 0.4);
const vec3 GREEN_COLOR_B = vec3(0.01, 0.1, 0.01);
const vec3 NIGHT_COLOR_A = vec3(0.02, 0.1, 0.02);
const vec3 NIGHT_COLOR_B = vec3(0.005, 0.03, 0.005);

// Material parameters (these define texture tiling density for the 1:1 world scale)
uniform float noise_scale = 20.0;
uniform float color_noise_scale = 50.0;
uniform float sand_detail_scale = 100.0;
uniform float grass_scale = 8.0;
uniform float texture_blend = 0.6;

// Sparkle parameters
const float SPARKLE_DENSITY = 25.0;
const float SPARKLE_SIZE = 0.985;
const float SPARKLE_INTENSITY = 3.0;
const int ANGLE_BINS = 8;

// Hash function for stable random values
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Cellular noise (not currently used in biome calculation, but kept if needed)
float cellular_noise(vec2 pos) {
    vec2 i_pos = floor(pos);
    vec2 f_pos = fract(pos);
    float min_dist = 1.0;

    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 cell_point = hash22(i_pos + neighbor);
            vec2 diff = neighbor + cell_point - f_pos;
            float dist = length(diff);
            min_dist = min(min_dist, dist);
        }
    }
    return min_dist;
}

float get_slope_factor(vec3 normal) {
    // normal is world_normal, already normalized
    float raw_slope = abs(dot(normal, vec3(0.0, 1.0, 0.0)));
    return 1.0 - raw_slope;
}

vec3 get_slope_color(vec3 base_color, float slope) {
    vec3 slope_color = mix(base_color, vec3(0.8) - base_color, 0.7);
    return mix(base_color, slope_color, slope);
}

// get_sparkle now uses 'position' which will be derived from unscaled_world_pos
// view_dir and normal are from the actual rendered surface
float get_sparkle(vec2 position, vec3 view_dir, vec3 normal) {
    vec3 norm_normal = normalize(normal); // Ensure normalization, though world_normal should be.
    vec3 norm_view = normalize(view_dir);

    float view_dot = dot(norm_normal, norm_view);
    vec2 view_plane = normalize(norm_view.xz); // Be cautious if view_dir.xz is zero
		if (length(view_plane) < 0.0001) view_plane = vec2(1.0, 0.0); // Avoid division by zero
    float angle = atan(view_plane.y, view_plane.x);

    float angle_bin = floor((angle + PI) * float(ANGLE_BINS) / (2.0 * PI));

    vec2 base_pos = position * SPARKLE_DENSITY; // 'position' is unscaled here
    vec2 hash_input = vec2(floor(base_pos.x), floor(base_pos.y));
    vec2 random_offset = hash22(hash_input + vec2(angle_bin * 1234.5678, angle_bin * 9876.5432));

    vec2 sparkle_pos1 = fract(base_pos + random_offset);
    vec2 sparkle_pos2 = fract((base_pos * 1.4 + vec2(0.5)) + random_offset * 1.7);
    vec2 sparkle_pos3 = fract((base_pos * 0.8 - vec2(0.7)) + random_offset * 0.9);

    float d1 = length(sparkle_pos1 - vec2(0.5));
    float d2 = length(sparkle_pos2 - vec2(0.5));
    float d3 = length(sparkle_pos3 - vec2(0.5));

    float s1 = 1.0 - step(SPARKLE_SIZE, d1);
    float s2 = 1.0 - step(SPARKLE_SIZE + 0.002, d2);
    float s3 = 1.0 - step(SPARKLE_SIZE - 0.002, d3);

    float view_factor = pow(1.0 - abs(view_dot), 2.0);
    float sparkle = max(max(s1, s2 * 0.8), s3 * 0.9);
    float variation = hash22(hash_input).x * 0.3 + 0.7;

    return sparkle * view_factor * SPARKLE_INTENSITY * variation;
}

// This function now receives unscaled_world_pos
vec3 get_volcano_texture(vec3 unscaled_world_pos, vec3 normal) {
    float height = unscaled_world_pos.y; // Compares against unscaled height
    float slope = get_slope_factor(normal);

    float dist_to_center = length(unscaled_world_pos.xz); // Unscaled distance
    float core_factor = smoothstep(volcano_core_radius + 50.0, volcano_core_radius, dist_to_center);

    float height_factor = smoothstep(0.0, volcano_height, height); // volcano_height is relative

    vec3 rock_color = mix(VOLCANO_DARK, VOLCANO_LIGHT, pow(slope, 0.5));
    float glow_intensity = core_factor + (slope * (1.0 - core_factor) * 0.3);
    vec3 final_color = mix(rock_color, VOLCANO_GLOW, glow_intensity);

    return final_color;
}

// This function now receives unscaled_world_pos_xz
vec3 get_grass_texture(vec2 unscaled_world_pos_xz) {
    // grass_scale is for 1:1 world, unscaled_world_pos_xz makes texture appear denser on scaled-down map
    vec2 uv1 = unscaled_world_pos_xz / grass_scale;
    vec2 uv2 = (unscaled_world_pos_xz + vec2(3.7, 1.9)) / (grass_scale * 0.7);

    vec3 grass1 = texture(u_grass_texture, uv1).rgb;
    vec3 grass2 = texture(u_grass_texture, uv2).rgb;

    return mix(grass1, grass2, 0.5) * 0.8;
}

// This function now receives unscaled_world_pos_xz
vec3 get_sand_texture(vec2 unscaled_world_pos_xz, vec3 view_dir, vec3 normal) {
    // sand_detail_scale is for 1:1 world
    vec2 uv1 = unscaled_world_pos_xz / sand_detail_scale;
    vec2 uv2 = (unscaled_world_pos_xz * 1.5 + vec2(1.1, 2.3)) / sand_detail_scale;
    vec2 uv3 = (unscaled_world_pos_xz * 0.7 - vec2(2.5, 1.7)) / sand_detail_scale;

    float sand1 = texture(u_noise, uv1).r;
    float sand2 = texture(u_noise2, uv2).r;
    float sand3 = texture(u_noise3, uv3).r;

    float sand_detail = mix(mix(sand1, sand2, 0.5), sand3, 0.3);
    vec3 base_sand = vec3(sand_detail) * 0.7 + 0.1;

    // Sparkles are generated based on unscaled position for consistent patterns
    float sparkle_val = get_sparkle(unscaled_world_pos_xz, view_dir, normal);

    return base_sand + DESERT_SPARKLE * sparkle_val;
}

// This function now receives unscaled_world_pos_xz
vec3 get_varied_color(vec3 color_a, vec3 color_b, vec2 unscaled_world_pos_xz) {
    // color_noise_scale is for 1:1 world
    vec2 noise_uv = unscaled_world_pos_xz / color_noise_scale;
    float variation = texture(u_noise2, noise_uv).r;
    return mix(color_b, color_a, variation);
}

// This function now takes unscaled_world_pos
vec3 calculate_biome(vec3 unscaled_world_pos, vec3 normal, vec3 view_dir) {
    // dist is now an unscaled distance, compared against unscaled biome constants
    float dist = length(unscaled_world_pos.xz);
    float slope = get_slope_factor(normal);

    float volcano_mix = smoothstep(volcano_radius + volcano_blend, volcano_radius, dist);

		// Adjusted outer_rim_blend logic: smoothstep from start to start + blend_width
    float outer_rim_blend_width = outer_rim_blend; // Assuming outer_rim_blend was intended as a width.
                                                // If outer_rim_blend was a second absolute position, the original logic was:
                                                // float outer = smoothstep(outer_rim_start, outer_rim_blend, dist); 
                                                // This is often confusing, so clarifying:
    float outer = smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend_width, dist);


    float ocean = smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend * 0.5, dist) * (1.0 - outer);
    float desert = 1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist);

    vec3 volcano_terrain = get_volcano_texture(unscaled_world_pos, normal); // Pass unscaled
    vec3 desert_base = get_varied_color(DESERT_COLOR_A, DESERT_COLOR_B, unscaled_world_pos.xz); // Pass unscaled
    vec3 green_base = get_varied_color(GREEN_COLOR_A, GREEN_COLOR_B, unscaled_world_pos.xz); // Pass unscaled
    vec3 night_base = get_varied_color(NIGHT_COLOR_A, NIGHT_COLOR_B, unscaled_world_pos.xz); // Pass unscaled

    vec3 sand_tex = get_sand_texture(unscaled_world_pos.xz, view_dir, normal); // Pass unscaled
    vec3 grass_tex = get_grass_texture(unscaled_world_pos.xz); // Pass unscaled

    vec3 desert_terrain = mix(desert_base, desert_base * sand_tex, texture_blend);
    vec3 ocean_terrain = mix(green_base, green_base * grass_tex, texture_blend);
    vec3 night_terrain = mix(night_base, night_base * grass_tex, texture_blend);

    desert_terrain = get_slope_color(desert_terrain, slope);
    ocean_terrain = get_slope_color(ocean_terrain, slope);
    night_terrain = get_slope_color(night_terrain, slope);

    vec3 outer_terrain = mix(ocean_terrain, night_terrain, outer);
    // Ensure desert is correctly blended before volcano
    float desert_influence = desert * (1.0 - volcano_mix) * (1.0 - outer) * (1.0 - ocean);
		float ocean_influence = ocean * (1.0 - volcano_mix) * (1.0 - outer);


		vec3 base_terrain;
		// Simplified blending order: start with largest scale (night/outer)
		// then mix in ocean, then desert, then volcano on top.
		base_terrain = mix(night_terrain, ocean_terrain, 1.0 - outer); // Base is night, or ocean if not in outer rim
		base_terrain = mix(base_terrain, desert_terrain, desert * (1.0-outer) * (1.0-ocean)); // Mix desert into non-ocean, non-outer areas
		base_terrain = mix(base_terrain, volcano_terrain, volcano_mix); // Finally, mix volcano on top

    return base_terrain;
}

void vertex() {
    v_normal = NORMAL; // Object-space normal
    // v_pos is the world position of the vertex, after MODEL_MATRIX transformation
    v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    // v_view_dir is calculated from the (potentially scaled) world_pos to the camera
    v_view_dir = normalize(v_pos - CAMERA_POSITION_WORLD);
}

void fragment() {
    // World normal of the (potentially scaled) surface
    vec3 world_normal = normalize(inverse(transpose(mat3(MODEL_MATRIX))) * v_normal);
    // Alternative for world_normal if no non-uniform scaling:
    // vec3 world_normal = normalize((MODEL_MATRIX * vec4(v_normal, 0.0)).xyz);


    // Convert v_pos (actual world position of fragment) to an "unscaled" reference
    // This allows biome constants and texture scales to be defined for a 1:1 world.
    vec3 unscaled_v_pos = v_pos / u_world_scale;

    vec3 biome_color = calculate_biome(unscaled_v_pos, world_normal, v_view_dir);

    ALBEDO = biome_color;
    ROUGHNESS = 0.8;
    SPECULAR = 0.15;
}