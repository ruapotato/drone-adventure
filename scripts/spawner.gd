extends Node3D

## Exports - Configure Spawner Behavior
@export var max_spawns: int = 20         # Maximum number of active spawns allowed.
@export var default_max_life: float = 60.0 # Default lifetime in seconds for a spawn.
@export var spawn_every: float = 10.0      # Base time between spawn attempts.

## Preloads - Entity Scenes
@onready var mini_ufo = preload("res://entities/mini_ufo.tscn")
@onready var ufo = preload("res://entities/ufo.tscn")
@onready var balloon = preload("res://entities/balloon.tscn")
@onready var lava_blob = preload("res://entities/lava_blob.tscn")

## Node References
@onready var piv = $piv
@onready var spawn_point = $piv/spawn_point
@onready var world = _get_world() # More robust world finding

## State Variables
var spawn_counter: float = 0.0
var spawn_index: int = 0
var drone: Node3D
var active_spawns: Array = [] # Stores references to all active spawns.

## Toggles - Control Spawn Conditions (Consider making these export vars or dynamic)
var day_spawn: bool = true
var night_spawn: bool = false

# ==============================================================================
# Godot Built-in Methods
# ==============================================================================

func _ready():
	"""Called when the node enters the scene tree."""
	drone = _get_drone()
	if not is_instance_valid(drone):
		printerr("Spawner Error: Drone node not found! Spawner will not function.")
		set_process(false) # Disable processing if drone isn't found
		return
	spawn_counter = spawn_every # Start with an initial delay

func _process(delta: float):
	"""Called every frame. Handles positioning and spawn timing."""
	if not is_instance_valid(drone):
		return # Stop if drone becomes invalid during gameplay

	# Keep spawner aligned with the drone
	global_position = drone.global_position
	rotation.y = drone.rotation.y
	#piv.rotate_y(delta * 10) # Optional pivot rotation

	# Countdown to next spawn attempt
	spawn_counter -= delta
	if spawn_counter <= 0:
		_try_spawn_something()

# ==============================================================================
# Spawning Logic
# ==============================================================================

func _try_spawn_something():
	"""Checks conditions and initiates a spawn if possible."""
	# 1. Check Max Spawn Limit
	if active_spawns.size() >= max_spawns:
		spawn_counter = 2.0 # Wait 2 seconds before checking again if maxed out
		return

	# 2. Determine What to Spawn (and its properties)
	var spawn_info = _determine_spawn_type()

	# 3. If a valid spawn is determined, execute it
	if spawn_info:
		_execute_spawn(spawn_info.scene, spawn_info.life)
		spawn_counter = spawn_info.next_delay # Set delay for the next spawn
	else:
		# No suitable spawn found, reset counter to base delay
		spawn_counter = spawn_every

func _determine_spawn_type() -> Dictionary:
	"""
	Determines which entity (if any) should spawn based on current conditions.
	Returns a dictionary with 'scene', 'life', and 'next_delay', or null.
	"""
	var y_pos = global_position.y
	var drone_crystals = drone.get("inventory").get("crystals") # Safely get crystals

	# Underground Spawns (Mini UFOs)
	if y_pos < -99:
		var depth_mult = max(0.1, abs(y_pos) / 300.0)
		return {
			"scene": mini_ufo,
			"life": default_max_life * 0.8, # Shorter life underground?
			"next_delay": spawn_every / depth_mult
		}

	# Ground Spawns (Mini UFOs at night with crystals)
	if y_pos >= -99 and y_pos <= 200:
		if drone_crystals > 10 and night_spawn:
			return {
				"scene": mini_ufo,
				"life": default_max_life,
				"next_delay": spawn_every
			}

	# Mid-Sky Spawns (Balloons during the day)
	if y_pos > 200 and y_pos <= 750:
		if day_spawn:
			return {
				"scene": balloon,
				"life": default_max_life * 1.5, # Balloons last longer
				"next_delay": spawn_every
			}

	# High-Sky Spawns (UFO, only if none active)
	if y_pos > 750:
		var ufo_active = false
		for spawn in active_spawns:
			# Check if any active spawn's script is or inherits from UFO's script
			# Or add UFOs to a group "UFO" and check: spawn.is_in_group("UFO")
			if is_instance_valid(spawn) and spawn.get_script() == ufo.get_script():
				ufo_active = true
				break
		
		if not ufo_active:
			print("Spawner: Spawning a UFO.")
			return {
				"scene": ufo,
				"life": default_max_life * 4.0, # UFOs last a long time
				"next_delay": spawn_every * 4.0 # Wait longer after a UFO
			}

	return {} # No suitable spawn found

func _execute_spawn(scene_to_spawn: PackedScene, life_duration: float):
	"""Instantiates, configures, and adds the new spawn to the world."""
	if not scene_to_spawn:
		printerr("Spawner: Attempted to execute spawn with a null scene.")
		return

	var new_spawn = scene_to_spawn.instantiate()

	# 1. Naming and Indexing
	var base_name = scene_to_spawn.resource_path.get_file().split(".")[0]
	new_spawn.name = base_name + "_" + str(spawn_index)
	spawn_index += 1

	# 2. Setup Lifetime Timer
	var life_timer = Timer.new()
	life_timer.name = "LifeTimer" # Good for debugging
	life_timer.wait_time = life_duration
	life_timer.one_shot = true
	# Connect timer timeout to the spawn's queue_free method
	life_timer.timeout.connect(new_spawn.queue_free)
	# Add timer as a child, it will be freed along with its parent
	new_spawn.add_child(life_timer)
	life_timer.start()

	# 3. Connect to its `tree_exiting` signal. This is crucial!
	#    It calls `_on_spawn_freed` whenever the node is removed,
	#    regardless of whether it's by the timer or by itself.
	#    We use bind() to pass 'new_spawn' itself to the handler.
	new_spawn.tree_exiting.connect(_on_spawn_freed.bind(new_spawn))

	# 4. Add to our tracking list
	active_spawns.append(new_spawn)

	# 5. Set position and add to the scene tree
	#    Setting global_position *before* adding is often fine.
	#    Use call_deferred("add_child", new_spawn) if you encounter physics issues.
	new_spawn.global_position = spawn_point.global_position
	world.add_child(new_spawn)

	print("Spawned: " + new_spawn.name + " Active count: " + str(active_spawns.size()))

# ==============================================================================
# Signal Handlers & Helpers
# ==============================================================================

func _on_spawn_freed(spawn: Node):
	"""
	Called when any tracked spawn is about to be removed from the scene tree.
	It removes the spawn from the `active_spawns` list.
	"""
	var index = active_spawns.find(spawn)
	if index != -1:
		active_spawns.remove_at(index)
		# print(f"Removed: {spawn.name}. Active count: {active_spawns.size()}")
	# else:
		# This can happen if it was removed by means other than this list,
		# or if the signal fires multiple times (unlikely but possible).
		# print(f"Warning: Tried to remove {spawn.name}, but it wasn't in active_spawns.")

func _get_world() -> Node:
	"""Finds the 'world' node by searching up the tree."""
	var current = self
	while is_instance_valid(current.get_parent()):
		current = current.get_parent()
		# You can make this check more specific if needed (e.g., check class or group)
		if current.name == "world":
			return current
	printerr("Spawner: Could not find 'world' node in parents!")
	return get_parent() # Fallback to direct parent

func _get_drone() -> Node3D:
	"""Finds the 'drone' node within the 'world'."""
	var world_node = _get_world()
	if is_instance_valid(world_node):
		# Find child recursively, but don't include internal nodes
		return world_node.find_child("drone", true, false)
	return null
