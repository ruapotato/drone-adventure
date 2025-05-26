shader_type spatial;

// Base noise textures
uniform sampler2D u_noise : source_color;
uniform sampler2D u_noise2 : source_color;
uniform sampler2D u_noise3 : source_color;

// Texture uniforms
uniform sampler2D u_grass_texture : source_color;

varying vec3 v_normal;
varying vec3 v_pos;
varying vec3 v_view_dir;

// Biome parameters
const float outer_rim_start = 9000.0;
const float outer_rim_blend = 8900.0;
const float ocean_ring_start = 2450.0;
const float ocean_ring_blend = 2200.0;
const float desert_center_radius = 1800.0;
const float desert_blend = 100.0;
const float volcano_radius = 120.0;
const float volcano_blend = 100.0;
const float volcano_core_radius = 5.0;
const float volcano_height = 1.0;

// Base colors with variations - Further darkened desert colors
const vec3 VOLCANO_DARK = vec3(0.05, 0.02, 0.01);
const vec3 VOLCANO_LIGHT = vec3(0.1, 0.15, 0.3);
const vec3 VOLCANO_GLOW = vec3(1.0, 0.3, 0.1);
const vec3 DESERT_COLOR_A = vec3(0.35, 0.28, 0.15);  // Significantly darker base
const vec3 DESERT_COLOR_B = vec3(0.28, 0.22, 0.12);  // Significantly darker base
const vec3 DESERT_SPARKLE = vec3(1.8, 1.7, 1.4);     // More controlled sparkle brightness
const vec3 GREEN_COLOR_A = vec3(0.04, 0.12, 0.04);
const vec3 GREEN_COLOR_B = vec3(0.02, 0.08, 0.02);
const vec3 NIGHT_COLOR_A = vec3(0.01, 0.05, 0.01);
const vec3 NIGHT_COLOR_B = vec3(0.005, 0.03, 0.005);

// Material parameters
uniform float noise_scale = 20.0;
uniform float color_noise_scale = 50.0;
uniform float sand_detail_scale = 100.0;
uniform float grass_scale = 8.0;
uniform float texture_blend = 0.6;

// Sparkle parameters
const float SPARKLE_DENSITY = 25.0;    // More sparkles spread out
const float SPARKLE_SIZE = 0.985;      // Very small, sharp points
const float SPARKLE_INTENSITY = 3.0;   // Moderate intensity for each sparkle
const int ANGLE_BINS = 8;              // More angle variations

// Hash function for stable random values
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float cellular_noise(vec2 pos) {
    vec2 i_pos = floor(pos);
    vec2 f_pos = fract(pos);
    float min_dist = 1.0;

    // Use hash function instead of texture for more stable results
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
    float raw_slope = abs(dot(normalize(normal), vec3(0.0, 1.0, 0.0)));
    return 1.0 - raw_slope;
}

vec3 get_slope_color(vec3 base_color, float slope) {
    vec3 slope_color = mix(base_color, vec3(0.8) - base_color, 0.7);
    return mix(base_color, slope_color, slope);
}

float get_sparkle(vec2 position, vec3 view_dir, vec3 normal) {
    // Get the main view angle in relation to the surface
    vec3 norm_normal = normalize(normal);
    vec3 norm_view = normalize(view_dir);

    // Calculate view angle components for binning
    float view_dot = dot(norm_normal, norm_view);
    vec2 view_plane = normalize(norm_view.xz);
    float angle = atan(view_plane.y, view_plane.x);

    // Create discrete angle bins for stable sparkle sets
    float angle_bin = floor((angle + PI) * float(ANGLE_BINS) / (2.0 * PI));

    // Create three layers of sparkles at different scales for more natural distribution
    vec2 base_pos = position * SPARKLE_DENSITY;
    vec2 hash_input = vec2(floor(base_pos.x), floor(base_pos.y));
    vec2 random_offset = hash22(hash_input + vec2(angle_bin * 1234.5678, angle_bin * 9876.5432));

    // Three layers of sparkles at different scales
    vec2 sparkle_pos1 = fract(base_pos + random_offset);
    vec2 sparkle_pos2 = fract((base_pos * 1.4 + vec2(0.5)) + random_offset * 1.7);
    vec2 sparkle_pos3 = fract((base_pos * 0.8 - vec2(0.7)) + random_offset * 0.9);

    float d1 = length(sparkle_pos1 - vec2(0.5));
    float d2 = length(sparkle_pos2 - vec2(0.5));
    float d3 = length(sparkle_pos3 - vec2(0.5));

    // Create very sharp sparkle points
    float s1 = 1.0 - step(SPARKLE_SIZE, d1);
    float s2 = 1.0 - step(SPARKLE_SIZE + 0.002, d2);
    float s3 = 1.0 - step(SPARKLE_SIZE - 0.002, d3);

    // Create view-dependent factor that changes smoothly between angle bins
    float view_factor = pow(1.0 - abs(view_dot), 2.0);

    // Combine sparkle layers with slight intensity variations
    float sparkle = max(max(s1, s2 * 0.8), s3 * 0.9);

    // Add subtle variation based on position but not time
    float variation = hash22(hash_input).x * 0.3 + 0.7;

    return sparkle * view_factor * SPARKLE_INTENSITY * variation;
}
vec3 get_volcano_texture(vec3 world_pos, vec3 normal) {
    float height = world_pos.y;
    float slope = get_slope_factor(normal);

    // Core glow effect
    float dist_to_center = length(world_pos.xz);
    float core_factor = smoothstep(volcano_core_radius + 50.0, volcano_core_radius, dist_to_center);

    // Height-based rock variation
    float height_factor = smoothstep(0.0, volcano_height, height);

    // Combine rock colors based on slope
    vec3 rock_color = mix(VOLCANO_DARK, VOLCANO_LIGHT, pow(slope, 0.5));

    // Add glow based on core proximity and vertical surfaces
    float glow_intensity = core_factor + (slope * (1.0 - core_factor) * 0.3);
    vec3 final_color = mix(rock_color, VOLCANO_GLOW, glow_intensity);

    return final_color;
}
vec3 get_grass_texture(vec2 world_pos) {
    vec2 uv1 = world_pos / grass_scale;
    vec2 uv2 = (world_pos + vec2(3.7, 1.9)) / (grass_scale * 0.7);

    vec3 grass1 = texture(u_grass_texture, uv1).rgb;
    vec3 grass2 = texture(u_grass_texture, uv2).rgb;

    return mix(grass1, grass2, 0.5) * 0.8;
}

vec3 get_sand_texture(vec2 world_pos, vec3 view_dir, vec3 normal) {
    vec2 uv1 = world_pos / sand_detail_scale;
    vec2 uv2 = (world_pos * 1.5 + vec2(1.1, 2.3)) / sand_detail_scale;
    vec2 uv3 = (world_pos * 0.7 - vec2(2.5, 1.7)) / sand_detail_scale;

    float sand1 = texture(u_noise, uv1).r;
    float sand2 = texture(u_noise2, uv2).r;
    float sand3 = texture(u_noise3, uv3).r;

    float sand_detail = mix(mix(sand1, sand2, 0.5), sand3, 0.3);
    vec3 base_sand = vec3(sand_detail) * 0.7 + 0.1;

    float sparkle = get_sparkle(world_pos.xy, view_dir, normal);

    return base_sand + DESERT_SPARKLE * sparkle;
}

vec3 get_varied_color(vec3 color_a, vec3 color_b, vec2 world_pos) {
    vec2 noise_uv = world_pos / color_noise_scale;
    float variation = texture(u_noise2, noise_uv).r;
    return mix(color_b, color_a, variation);
}

vec3 calculate_biome(vec3 world_pos, vec3 normal, vec3 view_dir) {
    float dist = length(world_pos.xz);
    float slope = get_slope_factor(normal);

    // Add volcano blend
    float volcano = smoothstep(volcano_radius + volcano_blend, volcano_radius, dist);

    // Previous biome calculations
    float outer = smoothstep(outer_rim_start, outer_rim_start + outer_rim_blend, dist);
    float ocean = smoothstep(ocean_ring_start, ocean_ring_start + ocean_ring_blend * 0.5, dist) * (1.0 - outer);
    float desert = 1.0 - smoothstep(desert_center_radius, desert_center_radius + desert_blend, dist);

    // Calculate all terrain types
    vec3 volcano_terrain = get_volcano_texture(world_pos, normal);
    vec3 desert_base = get_varied_color(DESERT_COLOR_A, DESERT_COLOR_B, world_pos.xz);
    vec3 green_base = get_varied_color(GREEN_COLOR_A, GREEN_COLOR_B, world_pos.xz);
    vec3 night_base = get_varied_color(NIGHT_COLOR_A, NIGHT_COLOR_B, world_pos.xz);

    vec3 sand_tex = get_sand_texture(world_pos.xz, view_dir, normal);
    vec3 grass_tex = get_grass_texture(world_pos.xz);

    vec3 desert_terrain = mix(desert_base, desert_base * sand_tex, texture_blend);
    vec3 ocean_terrain = mix(green_base, green_base * grass_tex, texture_blend);
    vec3 night_terrain = mix(night_base, night_base * grass_tex, texture_blend);

    desert_terrain = get_slope_color(desert_terrain, slope);
    ocean_terrain = get_slope_color(ocean_terrain, slope);
    night_terrain = get_slope_color(night_terrain, slope);

    vec3 outer_terrain = mix(ocean_terrain, night_terrain, outer);
    vec3 base_terrain = mix(desert_terrain, outer_terrain, smoothstep(0.0, 1.0, ocean + outer));

    // Blend volcano with base terrain
    return mix(base_terrain, volcano_terrain, volcano);
}

void vertex() {
    v_normal = NORMAL;
    v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_view_dir = normalize(world_pos - CAMERA_POSITION_WORLD);
}

void fragment() {
    vec3 world_normal = normalize((MODEL_MATRIX * vec4(v_normal, 0.0)).xyz);
    vec3 biome = calculate_biome(v_pos, world_normal, v_view_dir);

    ALBEDO = biome;
    ROUGHNESS = 0.8;
    SPECULAR = 0.15;
}