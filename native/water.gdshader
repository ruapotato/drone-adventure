// Simple Water Shader v3 (Godot 4.x) - No Vertex Displacement
shader_type spatial;
// Enable transparency blending
render_mode blend_mix;

// --- Uniforms (Control Panel) ---
uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.8); // RGBA Color

// Normal Distortion (Fragment Shimmer Effect)
uniform float normal_scale : hint_range(1.0, 50.0) = 15.0;    // Scale for normal shimmer pattern (Lower = larger pattern)
uniform float normal_speed : hint_range(0.1, 5.0) = 0.7;      // Speed for normal shimmer
uniform float normal_strength : hint_range(0.0, 0.5) = 0.1;  // Strength of normal shimmer (Controls visual intensity)

// PBR Surface Properties
uniform float roughness : hint_range(0.0, 1.0) = 0.08;      // Controls sharpness of reflections/highlights

// --- Varyings ---
// Pass world position to the fragment shader for wave calculation
varying vec3 world_pos;

// --- Vertex Shader ---
// Minimal: Only calculates world position needed by the fragment shader.
// NO vertex displacement is performed here.
void vertex() {
	// Calculate vertex position in world space for consistent wave patterns in fragment shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// --- Fragment Shader ---
// Calculates final color, applies normal distortion for shimmering surface using combined waves
void fragment() {
	// --- Calculate Normal Distortion ---
	// Use multiple combined waves based on world position and time for a more organic shimmer.
	float time_factor_norm = TIME * normal_speed;

	// Wave Layer 1 for Normals (using world_pos X & Z)
	float wave1_n_x = sin(world_pos.x * normal_scale * 1.1 + time_factor_norm * 1.2);
	float wave1_n_z = cos(world_pos.z * normal_scale * 0.9 + time_factor_norm * 0.8);

	// Wave Layer 2 for Normals (different inputs/speeds)
	float wave2_n_x = cos(world_pos.z * normal_scale * 1.4 + time_factor_norm * 0.7); // Use Z for X component
	float wave2_n_z = sin(world_pos.x * normal_scale * 0.6 + time_factor_norm * 1.1); // Use X for Z component

	// Combine normal wave components. Mixing components like this adds complexity vs simple averaging.
	float offset_x = (wave1_n_x + wave2_n_z) * 0.5; // Mix components from different waves/axes
	float offset_z = (wave1_n_z + wave2_n_x) * 0.5; // Mix components from different waves/axes

	// Create the final offset vector scaled by normal_strength.
	// This represents a small push to the normal vector in the X and Z directions (relative to world).
	vec3 normal_offset = vec3(offset_x * normal_strength, 0.0, offset_z * normal_strength);

	// --- Apply Distortion & Calculate Final Color ---
	// Add the small offset to the mesh's base normal and re-normalize it.
	// This modified normal affects how light reflects off the surface.
	vec3 perturbed_normal = normalize(NORMAL + normal_offset);

	// Assign the final calculated values to the shader outputs
	NORMAL = perturbed_normal; // Use the perturbed normal for lighting calculations
	ALBEDO = water_color.rgb;  // Set the base color (from uniform)
	ALPHA = water_color.a;     // Set the transparency (from uniform)
	ROUGHNESS = roughness;     // Set the surface roughness (from uniform)
	METALLIC = 0.0;            // Water is non-metallic
}