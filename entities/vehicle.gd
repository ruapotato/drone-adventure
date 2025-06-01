extends VehicleBody3D

# NodePaths for @onready vars - ensure these are correct for your scene!
@onready var vehicle_camera: Camera3D = get_node_or_null("play_as/Camera3D") as Camera3D
@onready var chicken_mount_point: Node3D = get_node_or_null("play_as/mount") as Node3D
@onready var play_as_node: Node = get_node_or_null("play_as") # The parent of camera and mount

@onready var expload_effect_node: CPUParticles3D = get_node_or_null("expload_effect") as CPUParticles3D # Adjust type if GPUParticles3D
@onready var eng_sounds_node: AudioStreamPlayer = get_node_or_null("eng_sounds") as AudioStreamPlayer # Adjust type if AudioStreamPlayer3D
@onready var mount_point = $play_as/mount
var crashed = false
var beeing_helped = false
var tp_cooldown = 0.0
var time_to_live_crashed = 60.0
var chicken # Reference to the chicken node
var world # Reference to the main world node

var play_as = false

# Player control
var stuck_timer = 0.0
var stuck_threshold = 2.0
var min_stuck_velocity = 0.5
var max_engine_force = 150.0
var max_steering = 0.6
var max_brake_force = 10.0

# AI control
var AI_ENGINE_FORCE: float = 70.0
var AI_MAX_STEERING: float = 0.5
var AI_STEERING_LERP_SPEED: float = 4.0
var ai_steering_timer: float = 0.0
const AI_STEERING_CHANGE_INTERVAL_MIN: float = 2.0
const AI_STEERING_CHANGE_INTERVAL_MAX: float = 4.0
var current_ai_target_steering: float = 0.0


func _ready():
	# Validate @onready vars essential for play_as logic
	if not play_as_node:
		printerr("Vehicle critical error: 'play_as' node not found as a child of this vehicle. Player control will fail.")
	if not vehicle_camera:
		printerr("Vehicle critical error: 'play_as/Camera3D' not found. Vehicle camera will not work.")
	if not chicken_mount_point:
		printerr("Vehicle critical error: 'play_as/mount' node not found. Chicken mounting will fail.")

	chicken = get_chicken_node() # Renamed for clarity
	if chicken:
		# Try to get world via chicken's parent, assuming chicken starts in the world
		world = chicken.get_parent() 
		if world == null : # If chicken was already parentless or parent is not 'world'
			world = find_world_node() # Fallback to search
		print("Vehicle _ready: Chicken found: ", chicken.name, ". World set to: ", world.name if world else "null")
	else:
		printerr("Vehicle _ready: Chicken node not found by get_chicken_node(). Player interaction will fail.")
		world = find_world_node() # Still try to find world for other purposes if any

	ai_steering_timer = randf_range(0.5, 1.5)


func find_world_node():
	# Common ways to find a 'world' node
	var current_node = get_parent()
	while current_node != null:
		if current_node.name == "world": # Adjust if your world node has a different name or is identified by group
			return current_node
		current_node = current_node.get_parent()
	
	# Fallback: Check if world is a direct child of scene root
	var scene_root = get_tree().root
	if scene_root.has_node("world"):
		return scene_root.get_node("world")
		
	printerr("Vehicle: 'world' node could not be reliably found.")
	return null

func get_chicken_node(): # Renamed for clarity
	# This function needs to reliably find your chicken node in the scene.
	# Adjust the search logic if "world" and "chicken" aren't named exactly like this
	# or if the structure is different.
	var w = find_world_node() # Use the helper
	if w:
		var c = w.find_child("chicken", true, false) # Recursive search, ignore owner
		if not c:
			printerr("Vehicle get_chicken_node: Found 'world' (", w.name, "), but 'chicken' child not found within it.")
		return c
	else:
		# If world isn't found, as a last resort, maybe chicken is a global singleton or accessible differently?
		# For now, this indicates a setup issue.
		printerr("Vehicle get_chicken_node: 'world' node not found, cannot search for chicken.")
		return null


func _process(delta):
	if tp_cooldown > 0:
		tp_cooldown -= delta

	if crashed:
		process_crashed_state(delta)
		return

	if not play_as:
		if global_transform.basis.y.y < 0.1: 
			if not crashed: 
				crashed = true
				print("AI JEEP CRASH - OVERTURNED!!! Vehicle: ", name)
	
	if play_as:
		handle_player_input(delta)
		chicken.global_position = mount_point.global_position

		var forward_input = Input.get_action_strength("move_forward")
		if forward_input > 0.1 and linear_velocity.length() < min_stuck_velocity:
			stuck_timer += delta
			if stuck_timer > stuck_threshold:
				if not crashed:
					crashed = true
					print("PLAYER JEEP CRASH - STUCK!!! Vehicle: ", name)
		else:
			stuck_timer = 0.0
	else: 
		if not crashed: 
			var desired_ai_steering: float = 0.0
			ai_steering_timer -= delta
			if ai_steering_timer <= 0:
				var random_choice = randf()
				if random_choice < 0.6: 
					current_ai_target_steering = randf_range(-AI_MAX_STEERING, AI_MAX_STEERING)
				elif random_choice < 0.9: 
					current_ai_target_steering = 0.0
				else: # 10% chance keep previous
					pass # current_ai_target_steering remains
				
				ai_steering_timer = randf_range(AI_STEERING_CHANGE_INTERVAL_MIN, AI_STEERING_CHANGE_INTERVAL_MAX)
				#print("AI ROAMING (", name, "): New TargetSteerRad: %.2f, NextChangeIn: %.1fs" % [current_ai_target_steering, ai_steering_timer])
			
			desired_ai_steering = current_ai_target_steering
			engine_force = AI_ENGINE_FORCE
			steering = lerp(steering, desired_ai_steering, AI_STEERING_LERP_SPEED * delta)
			brake = 0.0
			#print("AI UPDATE (", name, "): FinalSteeringRad: %.2f, Engine: %.1f, Velocity: %.1f" % [steering, engine_force, linear_velocity.length()])


func handle_player_input(delta):
	var forward_input = Input.get_action_strength("move_forward")
	var backward_input = Input.get_action_strength("move_backward")
	var steer_left_input = Input.get_action_strength("strafe_left") 
	var steer_right_input = Input.get_action_strength("strafe_right")

	var target_steering_normalized =  steer_left_input - steer_right_input
	var target_steering_radians = target_steering_normalized * max_steering 
	steering = lerp(steering, target_steering_radians, 5.0 * delta)

	if forward_input > 0.1:
		engine_force = forward_input * max_engine_force
		brake = 0.0
	elif backward_input > 0.1:
		var vehicle_forward_direction = -global_transform.basis.z
		if linear_velocity.dot(vehicle_forward_direction) > 0.1: 
			brake = backward_input * max_brake_force * 2.0 
			engine_force = 0.0
		else: 
			engine_force = -backward_input * max_engine_force * 0.5 
			brake = 0.0
	else:
		engine_force = 0.0
		brake = max_brake_force * 0.1


func process_crashed_state(delta):
	engine_force = 0.0
	steering = 0.0
	brake = max_brake_force 

	if play_as: 
		print("Processing crashed state for player...")
		if chicken:
			print("Chicken found, attempting to eject.")
			var chicken_current_parent = chicken.get_parent()
			print("Chicken current parent: ", chicken_current_parent)
			if chicken_current_parent != world: 
				if chicken_current_parent: 
					print("Removing chicken from: ", chicken_current_parent.name)
					chicken_current_parent.remove_child(chicken)
				
				if world: 
					print("Adding chicken to world: ", world.name)
					world.add_child(chicken)
					chicken.global_transform = global_transform # Position chicken at crashed car's location
					chicken.rotation = Vector3.ZERO # Straighten chicken after eject
					chicken.reset_velocity()
				else:
					printerr("Vehicle crash: 'world' node is null, cannot reparent chicken to world.")

			chicken.active = true
			print("Chicken set to active.")
			var chicken_cam_activated = false
			if chicken.has_method("activate_camera"):
				chicken.activate_camera()
				chicken_cam_activated = true
			elif chicken.has_node("Camera3D"): 
				var chicken_cam_node = chicken.get_node_or_null("Camera3D") as Camera3D
				if chicken_cam_node:
					chicken_cam_node.current = true
					chicken_cam_activated = true
			print("Chicken camera activated: ", chicken_cam_activated)
		else:
			print("Process crashed state: Chicken reference is null.")
		
		if vehicle_camera: 
			vehicle_camera.current = false 
			print("Vehicle camera deactivated.")
		else:
			print("Process crashed state: Vehicle camera reference is null.")

		play_as = false 
		print("play_as set to false.")

	time_to_live_crashed -= delta
	if time_to_live_crashed < 0:
		pass

	if expload_effect_node and not expload_effect_node.is_emitting():
		if eng_sounds_node:
			var explosion_sound = load("res://import/Audio/spaceEngineLarge_000.ogg")
			if eng_sounds_node.stream != explosion_sound:
				eng_sounds_node.stream = explosion_sound
			if not eng_sounds_node.playing:
				eng_sounds_node.play()
		expload_effect_node.emitting = true


func _on_eng_sounds_finished():
	if eng_sounds_node and crashed: 
		eng_sounds_node.play()


func _on_play_as_body_entered(body: Node3D) -> void:
	print("Vehicle: _on_play_as_body_entered triggered by body: ", body.name if body else "null")
	if body == chicken and not crashed:
		if chicken != null and chicken.active: 
			print("Vehicle: Chicken (", chicken.name, ") is active, attempting to mount.")

			
			if chicken_mount_point: # chicken_mount_point is @onready var
				print("Vehicle: Mounting chicken to mount_point: ", chicken_mount_point.name)
				chicken_mount_point.add_child(chicken)
				# Set local transform to ensure chicken is perfectly at mount point's origin and orientation
				chicken.transform = Transform3D.IDENTITY 
			elif play_as_node: # Fallback to play_as_node if mount_point is missing
				print_rich("[color=yellow]Vehicle Warning: chicken_mount_point not found! Attaching chicken to 'play_as' node (", play_as_node.name, ") instead.[/color]")
				play_as_node.add_child(chicken) 
				chicken.transform = Transform3D.IDENTITY

				
			chicken.active = false
			var chicken_cam_deactivated = false
			if chicken.has_method("deactivate_camera"):
				chicken.deactivate_camera()
				chicken_cam_deactivated = true
			elif chicken.has_node("Camera3D"): 
				var chicken_cam_node = chicken.get_node_or_null("Camera3D") as Camera3D
				if chicken_cam_node:
					chicken_cam_node.current = false
					chicken_cam_deactivated = true
			print("Vehicle: Chicken camera deactivated: ", chicken_cam_deactivated)

			if vehicle_camera: 
				vehicle_camera.current = true 
				print("Vehicle: Vehicle camera activated.")
			else:
				printerr("Vehicle Warning: vehicle_camera node is null. Cannot activate car camera.")

			play_as = true
			stuck_timer = 0.0 
			engine_force = 0.0
			steering = 0.0
			brake = max_brake_force * 0.1 
			print("Vehicle: Player has entered vehicle. play_as = true")
		elif chicken == null:
			printerr("Vehicle: Cannot enter, chicken reference is null.")
		elif not chicken.active:
			print("Vehicle: Chicken (", chicken.name, ") is not active, not entering.")
	elif body != chicken:
		# print("Vehicle: Body entered sensor but it was not the chicken. Body: ", body.name if body else "null")
		pass
	elif crashed:
		print("Vehicle: Cannot enter, vehicle is crashed.")
