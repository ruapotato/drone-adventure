extends RigidBody3D

#==============================================================================
# --- OnReady Variables ---
#==============================================================================
@onready var old_body_mesh = $imported_mesh/imported_mesh_og/body
@onready var audio_player = $imported_mesh/imported_mesh_og/AudioStreamPlayer3D

@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var laser_scene = preload("res://scenes/laser.tscn")
@onready var animation_tree = $chicken_wings/AnimationTree
@onready var camera = $head_piv/Camera3D
@onready var head_mesh = $head_piv/chicken_head
@onready var head_piv = $head_piv
@onready var shoot_from = $shoot_from
@onready var speed_collision = $speedCollision
@onready var shield_mesh = $shield
@onready var shield_sound_player = $shield_sound
@onready var shield_cam = $shield/shield_camera
@onready var expload_effect = $expload_effect
@onready var expload_sound_player = $expload_sound
@onready var ingenuity_mesh = $ingenuity_mesh
@onready var main_mesh = $mesh
@onready var pause_screen = $"../pause_screen" # User's path
@onready var legs_node = $LegsNode


#==============================================================================
# --- Export Variables for Tuning ---
#==============================================================================
@export var mouse_sensitivity = 0.003
@export var active_flight_speed = 120.0 # Max speed when player is actively controlling
@export var acceleration_force = 60.0 # Old force-based system
@export var brake_strength = 5.0      # Old force-based system
@export var pitch_limit_up = deg_to_rad(85.0)
@export var pitch_limit_down = deg_to_rad(-85.0)
@export var shake_intensity = 0.1
@export var move_lerp_factor = 10.0 # Old force-based lerped_velocity
@export var ground_detection_ray_length : float = 5.0
@export var ground_threshold : float = 0.5
@export var hover_animation_speed : float = 0.2 # Used by wing animation
# The following were for the old force-based system and power mechanics.
# @export var low_power_fall_force : float = 10.0 # Removed
@export var ground_hover_strength : float = 100.0 # Old force-based system
@export var ground_hover_damping : float = 15.0    # Old force-based system
@export var ground_friction : float = 5.0          # Old force-based system

#==============================================================================
# --- Game State Variables ---
#==============================================================================
var active = false # True if player is actively controlling the chicken
var player # Reference to the main player character, set by player script
var world # Set in _ready to get_parent()
var dist_ctl # Control node for distance, expected to have 'dist' and 'range' properties

var inventory = {"crystals":0, "using":"gun"}
var shoot_speed = 34
var tutorial_mode = false
var unlocked_gun = true
var collision_size_at_rest = .075
var laser_obj = null
var save_index = null
var save_file_path = null
var camera_shake_amount = 0.0
var last_velocity_vector = Vector3.ZERO # Still used for damage logic
var _height_from_ground : float = -1.0
var is_near_ground : bool = false
var is_being_destroyed = false # Flag to prevent multiple destruction calls

var _look_input_vector = Vector2.ZERO

var circle_radius = 1.0
var circle_time = 0.0
var circle_bob_time = 0.0

var follow_max_speed = 5.0
var follow_catch_up_bonus_speed = 10.0
var follow_min_dist_for_boost = 6.0
var follow_max_dist_for_boost = 25.0

var follow_trail_distance = 1.5
var follow_last_player_pos = Vector3.ZERO
var follow_target_pos = Vector3.ZERO
var is_speaking_behavior = false

var simple_wing_time = 0.0
var simple_wing_flap_speed = 15.0
var simple_wing_flap_amplitude = 0.5
@onready var old_wing_left = $imported_mesh/imported_mesh_og/wing2
@onready var old_wing_right = $imported_mesh/imported_mesh_og/wing


#==============================================================================
# --- Initialization Functions ---
#==============================================================================
func _ready():
	world = get_parent()

	# Note: 'player' here is a local variable for initialization purposes.
	# The member 'self.player' is set by set_player() and used for ongoing logic.
	var player_node_for_init = world.find_child("player") 
	if is_instance_valid(player_node_for_init):
		dist_ctl = player_node_for_init.find_child("chicken_range")
		if not is_instance_valid(dist_ctl):
			print("Chicken WARNING: 'chicken_range' node not found as a child of 'player' node during init. Range limit might not function correctly.")
		
		global_position = player_node_for_init.global_position
		print("Chicken: Initial position set near 'player' node found by name.")
	else:
		var spawn_node = world.find_child("spawn")
		if is_instance_valid(spawn_node):
			global_position = spawn_node.global_position
		else:
			global_position = Vector3.ZERO
		print("Chicken: 'player' node not found for initial pos or dist_ctl. Using spawn/origin.")

	if not is_instance_valid(self.player): # Check the member variable 'self.player'
		print("Chicken WARNING: self.player not set in _ready(). Player script should call set_player().")
		
	if world.find_child("is_tutorial"):
		tutorial_mode = true
		inventory = {"crystals":0, "using":"gun"}
		print("Chicken: Tutorial Mode Enabled")
	else:
		if world.has_method("get_game_index"):
			save_index = world.get_game_index()
			save_file_path = "user://savegame_" + str(save_index) + "_chicken.json"
			var loaded_inventory = load_save_data(save_file_path)
			if loaded_inventory: inventory = loaded_inventory; print("Chicken: Save game loaded.")
			else: print("Chicken: No save game, starting fresh."); inventory = {"crystals":0, "using":"gun"}
		else:
			print("Chicken: Game index not available. Save/load for chicken limited.")
			inventory = {"crystals":0, "using":"gun"}

	gravity_scale = 0
	linear_damp = 2.0
	angular_damp = 10.0
	axis_lock_angular_z = true
	axis_lock_angular_x = true
	
	print("Chicken controller ready!")
	last_velocity_vector = linear_velocity

	if not legs_node: print("Chicken WARNING: LegsNode not found.")
	if not animation_tree: print("Chicken WARNING: AnimationTree for wings not found.")

	camera.current = false
	active = false

func set_player(p_ref):
	player = p_ref # Sets the member variable self.player
	print("Chicken: Player reference set.")
	if not active and is_instance_valid(player):
		var offset_behind = -player.global_transform.basis.z * 2.5
		var offset_above = Vector3.UP * 1.5
		global_position = player.global_position + offset_behind + offset_above

func save_game():
	print("TODO: save game for chicken") # Consider what needs saving for the chicken now
	pass

#==============================================================================
# --- Possession Control (Called by Player Script) ---
#==============================================================================
func start_possession():
	print("Chicken: Start Possession sequence.")
	active = true
	camera.current = true
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	is_being_destroyed = false 
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	if expload_effect: expload_effect.emitting = false

func end_possession():
	print("Chicken: End Possession sequence.")
	active = false
	camera.current = false
	
	if is_instance_valid(laser_obj): 
		laser_obj.queue_free()
		laser_obj = null
		
	if is_instance_valid(player):
		if player.has_method("set_active_true_and_camera_current"): 
			player.set_active_true_and_camera_current() 
		else: 
			player.active = true
			if is_instance_valid(player.camera): 
				player.camera.current = true
			else:
				printerr("Chicken: Player camera node is invalid during end_possession!")

		var offset_behind = -player.global_transform.basis.z * 2.5
		var offset_above = Vector3.UP * 1.5
		global_position = player.global_position + offset_behind + offset_above
		var look_target = player.global_position + Vector3.UP * 0.5
		if (look_target - global_position).length_squared() > 0.01:
			look_at(look_target, Vector3.UP)
	else:
		print("Chicken: Player instance invalid during end_possession.")

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	head_piv.rotation.x = 0

#==============================================================================
# --- Godot Core Loop Functions ---
#==============================================================================
func _input(event):
	if active and not is_game_paused() and not is_being_destroyed and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_look_input_vector = event.relative

func _unhandled_input(event):
	if not active or is_game_paused() or is_being_destroyed: return

	if event.is_action_pressed("select_gun"): inventory["using"] = "gun"; print("Chicken Selected: Gun")
	if "land_making_gun" in inventory and event.is_action_pressed("select_build"): inventory["using"] = "land_making_gun"; print("Chicken Selected: Build Gun")
	if "laser_gun" in inventory and event.is_action_pressed("select_laser"): inventory["using"] = "laser_gun"; print("Chicken Selected: Laser Gun")
	
	if event.is_action_pressed("fire"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		match inventory["using"]:
			"gun": fire_normal_weapon()
			"land_making_gun": fire_landgun_weapon()
			"laser_gun": fire_laser_weapon()
	if event.is_action_released("fire") and inventory["using"] == "laser_gun" and is_instance_valid(laser_obj):
		laser_obj.queue_free(); laser_obj = null

func _physics_process(delta):
	if not world:
		printerr("Chicken _physics_process: world is null!")
		return

	if active:
		if is_game_paused() or is_being_destroyed: 
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 10.0)
			angular_velocity = angular_velocity.lerp(Vector3.ZERO, delta * 10.0)
			return

		if rotation.z != 0: rotation.z = lerpf(rotation.z, 0, delta * 10.0)
		if rotation.x != 0: rotation.x = lerpf(rotation.x, 0, delta * 10.0)
		
		perform_ground_check(delta)

		if _look_input_vector != Vector2.ZERO:
			rotate_y(-_look_input_vector.x * mouse_sensitivity)
			head_piv.rotate_x(-_look_input_vector.y * mouse_sensitivity)
			head_piv.rotation.x = clamp(head_piv.rotation.x, pitch_limit_down, pitch_limit_up)
			_look_input_vector = Vector2.ZERO

		var input_movement_vector = Input.get_vector("strafe_left", "strafe_right", "move_backward", "move_forward")
		var lift_input_strength = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
		
		if is_near_ground: lift_input_strength = max(0, lift_input_strength) 

		var head_global_basis = head_piv.global_transform.basis
		var body_global_basis = global_transform.basis

		var fwd_dir = -head_global_basis.z * input_movement_vector.y
		var strafe_dir = body_global_basis.x * input_movement_vector.x
		var explicit_lift_dir = Vector3.UP * lift_input_strength

		var combined_movement_direction = (fwd_dir + strafe_dir + explicit_lift_dir)
		var target_active_vel = Vector3.ZERO
		var speed_for_active_mode = active_flight_speed

		if combined_movement_direction.length_squared() > 0.01:
			combined_movement_direction = combined_movement_direction.normalized()
			target_active_vel = combined_movement_direction * speed_for_active_mode
		
		# MODIFICATION: Range limit logic
		if is_instance_valid(player) and is_instance_valid(dist_ctl):
			# Ensure dist_ctl has 'dist' and 'range' properties.
			if ("dist" in dist_ctl) and ("range" in dist_ctl):
				if dist_ctl.dist > dist_ctl.range/2:
					# Chicken is too far from the player.
					# Prevent movement that would increase the distance further.
					var vector_from_player_to_chicken = global_position - player.global_position
					
					if vector_from_player_to_chicken.length_squared() > 0.0001: # Avoid division by zero if chicken is on player
						var direction_away_from_player = vector_from_player_to_chicken.normalized()
						
						# Calculate the component of the target velocity that is moving away from the player.
						var speed_component_away = target_active_vel.dot(direction_away_from_player)
						
						if speed_component_away > 0:
							# If the chicken is trying to move further away, subtract this component.
							target_active_vel -= direction_away_from_player * speed_component_away
							# This allows tangential movement or movement towards the player, but stops further outward movement.
			else:
				# Optional: Warn if properties are missing, but only once to avoid spamming console.
				if not has_meta("dist_ctl_prop_warning"): # Check if we've warned before
					printerr("Chicken: 'dist_ctl' node is missing 'dist' or 'range' properties. Range limit inactive.")
					set_meta("dist_ctl_prop_warning", true) # Mark that we've warned
		# END OF MODIFICATION

		if is_near_ground:
			if target_active_vel.y < 0 and _height_from_ground < (ground_threshold * 0.5) and _height_from_ground != -1.0:
				target_active_vel.y = 0
		
		var active_control_lerp_factor = 10.0
		linear_velocity = linear_velocity.lerp(target_active_vel, delta * active_control_lerp_factor)

		#process_damage_logic() 
		if not active: return 

		update_shield_visuals()
		apply_camera_shake(delta)
		update_dynamic_collision_size()
		update_chicken_leg_animations(delta)
		update_chicken_wing_animations()
		last_velocity_vector = linear_velocity

	else: # Chicken is NOT actively controlled
		if is_game_paused():
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 10.0)
			angular_velocity = angular_velocity.lerp(Vector3.ZERO, delta * 10.0)
			if legs_node and legs_node.has_method("animate_legs"):
				legs_node.animate_legs(delta, 0)
			return

		handle_following_player_movement(delta)
		update_simple_wing_flap(delta)
		update_chicken_leg_animations(delta)
		linear_damp = 5.0
		angular_damp = 5.0

#==============================================================================
# --- Systems & Helper Functions ---
#==============================================================================
func perform_ground_check(_delta):
	if not world: return
	var space_state = get_world_3d().direct_space_state
	if not space_state: print("Chicken ERROR: Could not get 3D physics space state."); return
	var ray_start = global_position + Vector3.UP * 0.1
	var ray_end = ray_start + Vector3.DOWN * (ground_detection_ray_length + 0.1)
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask, [self])
	
	var result = space_state.intersect_ray(query)
	if result:
		_height_from_ground = global_position.distance_to(result.position)
		is_near_ground = (_height_from_ground < ground_threshold)
	else:
		_height_from_ground = -1.0
		is_near_ground = false

func update_chicken_leg_animations(delta):
	if not legs_node or not legs_node.has_method("animate_legs"): return
	var current_speed = linear_velocity.length()
	if active:
		if is_near_ground and current_speed > 0.1:
			legs_node.animate_legs(delta, current_speed)
		else:
			legs_node.animate_legs(delta, 0)
	else: # Following
		legs_node.animate_legs(delta, current_speed / follow_max_speed if follow_max_speed > 0 else 0)


func update_chicken_wing_animations():
	if not animation_tree or not animation_tree.active: return
	var speed = linear_velocity.length()
	var anim_speed_scale = 0.0
	if is_near_ground:
		anim_speed_scale = 0.0
	elif speed < 0.5:
		anim_speed_scale = hover_animation_speed
	else:
		var reference_speed = active_flight_speed if active else follow_max_speed
		anim_speed_scale = speed / reference_speed if reference_speed > 0 else 0
	animation_tree.set("parameters/SPEED/scale", anim_speed_scale * 50)

func save_game_data():
	if not save_file_path: print("Chicken: Save file path not set."); return
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(inventory)) 
		file.close()
		print("Chicken: Game saved to " + save_file_path)
	else: print("Chicken: Error saving game.")

func load_save_data(path):
	if not FileAccess.file_exists(path): return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json_parser = JSON.new()
		var err = json_parser.parse(content)
		if err == OK:
			var data = json_parser.get_data()
			if data is Dictionary:
				data["using"] = "gun" 
				return data
			else:
				print("Chicken: Loaded data is not a dictionary."); return null
		else:
			print("Chicken: Error parsing save file. Error: ", err, " Line: ", json_parser.get_error_line(), " Message: ", json_parser.get_error_message()); return null
	else:
		print("Chicken: Error loading save file from " + path); return null

func fire_normal_weapon():
	if not unlocked_gun or not world: return
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = shoot_from.global_position
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_central_impulse(-head_piv.global_transform.basis.z.normalized() * shoot_speed)
	world.add_child(new_bullet)

func fire_landgun_weapon():
	if not "land_making_gun" in inventory or not world:
		print("Chicken: Land making gun not available or world missing.")
		return
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = shoot_from.global_position
	if new_bullet.has_method("set_as_landmaker_bullet"):
		new_bullet.set_as_landmaker_bullet(true)
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_central_impulse(-head_piv.global_transform.basis.z.normalized() * shoot_speed)
	world.add_child(new_bullet)

func fire_laser_weapon():
	if not "laser_gun" in inventory: return
	if not is_instance_valid(laser_obj):
		laser_obj = laser_scene.instantiate()
		laser_obj.name = "laser_beam"
		shoot_from.add_child(laser_obj)
		laser_obj.global_rotation = head_piv.global_rotation

func process_damage_logic():
	if is_being_destroyed: return 

	var impact_vector = last_velocity_vector - linear_velocity
	var impact_strength = impact_vector.length()

	if impact_strength > 15: 
		if last_velocity_vector.length() > 1.0 and impact_vector.normalized().dot(last_velocity_vector.normalized()) < -0.5:
			print("Chicken Smacked! Strength: " + str(impact_strength))
			camera_shake_amount = 0.3 
			if shield_sound_player: shield_sound_player.play() 
			
			hurt() 

func hurt():
	if is_being_destroyed or not active: 
		return

	print("Chicken: Hurt! Switching back to player.")
	is_being_destroyed = true 

	if expload_sound_player: 
		expload_sound_player.play()
	if expload_effect: 
		expload_effect.emitting = true

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	end_possession()


func apply_camera_shake(delta):
	if camera_shake_amount > 0:
		camera.h_offset = randf_range(-1, 1) * camera_shake_amount * shake_intensity
		camera.v_offset = randf_range(-1, 1) * camera_shake_amount * shake_intensity
		camera_shake_amount -= delta
	elif camera_shake_amount <= 0 :
		camera_shake_amount = 0; camera.h_offset = 0; camera.v_offset = 0

func update_shield_visuals():
	if shield_mesh and shield_sound_player:
		var is_shield_active = shield_sound_player.playing 
		shield_mesh.visible = is_shield_active
		if shield_cam: shield_cam.visible = is_shield_active

func update_dynamic_collision_size():
	if not speed_collision or not speed_collision.shape: return
	var speed = linear_velocity.length()
	var new_radius = collision_size_at_rest * ((speed / 5.0) + 1.0) if speed > 5 else collision_size_at_rest
	if speed_collision.shape is SphereShape3D:
		speed_collision.shape.radius = new_radius

func is_game_paused():
	return is_instance_valid(pause_screen) and pause_screen.visible

#==============================================================================
# --- Following Player Logic ---
#==============================================================================
func handle_following_player_movement(delta):
	if not is_instance_valid(player):
		linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 5.0)
		return

	var player_pos = player.global_position
	var player_moving = (player_pos - follow_last_player_pos).length_squared() > 0.001
	follow_last_player_pos = player_pos
	circle_bob_time += delta * 3.0

	if is_speaking_behavior:
		var player_forward_vector = -player.global_transform.basis.z
		follow_target_pos = player_pos + player_forward_vector * 1.0
		follow_target_pos.y = player_pos.y + 1.0
	else:
		if player_moving:
			var player_forward_vector = -player.global_transform.basis.z
			follow_target_pos = player_pos + player_forward_vector * (follow_trail_distance * 0.5)
			follow_target_pos.y = player_pos.y + 1.2
		else:
			circle_time += delta * (1.0 + sin(circle_bob_time) * 0.2)
			var circle_offset = Vector3(
				cos(circle_time) * (circle_radius * 0.7),
				0.8 + sin(circle_bob_time) * 0.1,
				sin(circle_time) * (circle_radius * 0.7)
			)
			follow_target_pos = player_pos + circle_offset
	
	var direction_to_target = follow_target_pos - global_position
	var dist_sq_to_follow_target = direction_to_target.length_squared()
	
	var actual_distance_to_player = global_position.distance_to(player_pos)
	var effective_max_speed = follow_max_speed

	if actual_distance_to_player > follow_min_dist_for_boost:
		var range_val = follow_max_dist_for_boost - follow_min_dist_for_boost 
		var speed_increase_ratio = 0.0
		if range_val > 0.001:
			speed_increase_ratio = (actual_distance_to_player - follow_min_dist_for_boost) / range_val
		
		speed_increase_ratio = clamp(speed_increase_ratio, 0.0, 1.0)
		effective_max_speed = follow_max_speed + speed_increase_ratio * follow_catch_up_bonus_speed
	
	var current_follow_speed = effective_max_speed
	var close_proximity_threshold_sq = 0.2 * 0.2 
	if dist_sq_to_follow_target < close_proximity_threshold_sq and close_proximity_threshold_sq > 0.00001:
		current_follow_speed = effective_max_speed * (dist_sq_to_follow_target / close_proximity_threshold_sq)
		current_follow_speed = clamp(current_follow_speed, 0.0, effective_max_speed)

	var target_vel = Vector3.ZERO
	if dist_sq_to_follow_target > 0.0001:
		target_vel = direction_to_target.normalized() * current_follow_speed
	
	var follow_lerp_speed = 10.0
	linear_velocity = linear_velocity.lerp(target_vel, delta * follow_lerp_speed)

	var look_at_player_target = player_pos + Vector3.UP * 0.5
	if (look_at_player_target - global_position).length_squared() > 0.01:
		var desired_basis = global_transform.looking_at(look_at_player_target, Vector3.UP).basis
		global_transform.basis = global_transform.basis.slerp(desired_basis, delta * 5.0)


func update_simple_wing_flap(delta):
	if not old_wing_left or not old_wing_right: return
	simple_wing_time += delta * simple_wing_flap_speed
	var wing_rotation_angle = sin(simple_wing_time) * simple_wing_flap_amplitude
	old_wing_left.rotation.z = wing_rotation_angle
	old_wing_right.rotation.z = -wing_rotation_angle
