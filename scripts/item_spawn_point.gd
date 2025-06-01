extends Node3D

# Biome parameters
const OUTER_RIM_START: float = 9000.0
const OUTER_RIM_BLEND: float = 8900.0
const OCEAN_RING_START: float = 2450.0
const OCEAN_RING_BLEND: float = 2200.0
const DESERT_CENTER_RADIUS: float = 1800.0
const DESERT_BLEND: float = 100.0
const VOLCANO_RADIUS: float = 120.0
const VOLCANO_BLEND: float = 100.0
const JEEP_SPAWN_PROBABILITY: float = 0.025 # Using your defined probability

# Paths to placeholder scenes
const CACTUS_SCENE_PATH: String = "res://level_bits/cactus.tscn"
const JEEP_SCENE_PATH: String = "res://entities/vehicle.tscn" # This is the "truck"
const COCONUT_TREE_SCENE_PATH: String = "res://scenes/tree_2.tscn"

# Variables to cache loaded scenes
var _loaded_cactus_scene: PackedScene = null
var _loaded_jeep_scene: PackedScene = null
var _loaded_coconut_tree_scene: PackedScene = null
var world # Will hold the reference to your main world node

enum Biome {
	UNKNOWN,
	VOLCANO,
	DESERT,
	ISLAND,
	OCEAN,
	OUTER_RIM_NIGHT
}

func _ready() -> void:
	world = get_world_node() # Use the safer function
	if world == null:
		printerr(name, ": 'world' node not found! Jeeps will be parented to this spawner as a fallback.")

	var current_pos: Vector3 = global_transform.origin
	var current_biome: Biome = get_biome_at_position(current_pos)

	var biome_name: String = "Invalid Biome"
	if Biome.has(current_biome): # Godot 4 enum utility
		biome_name = Biome.keys()[current_biome]
	
	print("Spawner '", name, "' at ", current_pos, " is in Biome: ", biome_name, " (Enum value: ", int(current_biome), ")")

	spawn_objects_for_biome(current_biome, current_pos)


func get_world_node(): # Renamed for clarity and made safer
	var current_ancestor = get_parent()
	while current_ancestor != null:
		if current_ancestor.name == "world": # Adjust "world" if your main scene root/node is named differently
			return current_ancestor
		current_ancestor = current_ancestor.get_parent()
	
	# Fallback or further search logic if needed:
	# For example, if world could be a direct child of the scene root if this spawner is high up:
	# var scene_root = get_tree().root
	# if scene_root.has_node("world"):
	#    return scene_root.get_node("world")
	
	# If you use groups:
	# var nodes_in_world_group = get_tree().get_nodes_in_group("world_group_identifier")
	# if not nodes_in_world_group.is_empty():
	#    return nodes_in_world_group[0]

	printerr(name, ": 'world' node not found by get_world_node().")
	return null


func get_biome_at_position(world_pos: Vector3) -> Biome:
	var dist_xz: float = Vector2(world_pos.x, world_pos.z).length()

	# Priority 1: Volcano
	var volcano_influence: float = smoothstep(VOLCANO_RADIUS + VOLCANO_BLEND, VOLCANO_RADIUS, dist_xz)
	if volcano_influence > 0.5:
		return Biome.VOLCANO

	# Priority 2: Desert
	var desert_outer_boundary: float = DESERT_CENTER_RADIUS + DESERT_BLEND
	if dist_xz <= desert_outer_boundary:
		var desert_core_influence_check_radius: float = DESERT_CENTER_RADIUS + (DESERT_BLEND / 2.0)
		if dist_xz <= desert_core_influence_check_radius:
			return Biome.DESERT
		var desert_strength: float = 1.0 - smoothstep(DESERT_CENTER_RADIUS, desert_outer_boundary, dist_xz)
		if desert_strength > 0.3:
			return Biome.DESERT

	# Priority 3: Outer Rim Night (farthest out)
	var outer_rim_night_influence: float = smoothstep(OUTER_RIM_START, OUTER_RIM_START + OUTER_RIM_BLEND, dist_xz)
	if outer_rim_night_influence > 0.5:
		return Biome.OUTER_RIM_NIGHT
	if dist_xz >= OUTER_RIM_START + (OUTER_RIM_BLEND / 2.0) : # Well into the night blend
		return Biome.OUTER_RIM_NIGHT

	# Priority 4: Island or Ocean
	if dist_xz > desert_outer_boundary and dist_xz < OUTER_RIM_START:
		if world_pos.y < 0.0:
			return Biome.OCEAN
		else:
			return Biome.ISLAND
	
	if dist_xz < OUTER_RIM_START:
		if world_pos.y < 0.0:
			return Biome.OCEAN
		else:
			return Biome.ISLAND

	return Biome.UNKNOWN


func spawn_objects_for_biome(biome: Biome, base_position: Vector3) -> void: # base_position is spawner's global_transform.origin
	match biome:
		Biome.DESERT:
			var random_roll: float = randf()

			if random_roll < JEEP_SPAWN_PROBABILITY:
				# Attempt to spawn a Jeep (truck)
				if _loaded_jeep_scene == null:
					_loaded_jeep_scene = load(JEEP_SCENE_PATH) as PackedScene
					if _loaded_jeep_scene == null:
						printerr("Failed to load Jeep (vehicle) scene from: ", JEEP_SCENE_PATH)
				
				if _loaded_jeep_scene and _loaded_jeep_scene.can_instantiate():
					var jeep = _loaded_jeep_scene.instantiate()
					
					# --- Add jeep to world node if world is found ---
					if world != null:
						world.add_child(jeep)
						# print("Jeep '", jeep.name, "' added as child of WORLD node: '", world.name, "'")
					else:
						add_child(jeep) # Fallback: add to self if world not found
						printerr("Jeep '", jeep.name, "' parented to spawner '", name, "' as fallback (world node not found).")
					
					if jeep is Node3D:
						jeep.global_transform.origin = base_position # Position at the spawner's location
						# print("Jeep spawned at: ", base_position)
			else:
				# Attempt to spawn a Cactus
				if _loaded_cactus_scene == null:
					_loaded_cactus_scene = load(CACTUS_SCENE_PATH) as PackedScene
					if _loaded_cactus_scene == null:
						printerr("Failed to load Cactus scene from: ", CACTUS_SCENE_PATH)
				
				if _loaded_cactus_scene and _loaded_cactus_scene.can_instantiate():
					var cactus = _loaded_cactus_scene.instantiate()
					add_child(cactus) # Cactus remains child of this spawner node
					if cactus is Node3D:
						cactus.global_transform.origin = base_position # Position at the spawner's location
						# print("Cactus spawned at: ", base_position)
		
		Biome.ISLAND:
			if _loaded_coconut_tree_scene == null:
				_loaded_coconut_tree_scene = load(COCONUT_TREE_SCENE_PATH) as PackedScene
				if _loaded_coconut_tree_scene == null:
					printerr("Failed to load Coconut Tree scene from: ", COCONUT_TREE_SCENE_PATH)

			if _loaded_coconut_tree_scene and _loaded_coconut_tree_scene.can_instantiate():
				var tree = _loaded_coconut_tree_scene.instantiate()
				add_child(tree) # Coconut tree remains child of this spawner node
				if tree is Node3D:
					tree.global_transform.origin = base_position
		
		Biome.OCEAN:
			print("In Ocean biome. (No specific spawns requested for Ocean yet). Spawner: ", name)

		Biome.VOLCANO:
			print("In Volcano biome. (No specific spawns requested for Volcano). Spawner: ", name)
			
		Biome.OUTER_RIM_NIGHT:
			print("In Outer Rim Night biome. (No specific spawns requested). Spawner: ", name)
			
		_: # Biome.UNKNOWN or any other
			print("Unknown biome or no spawns defined for this biome. Spawner: ", name)
