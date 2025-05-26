extends RigidBody3D

#==============================================================================
# --- OnReady Variables ---
#==============================================================================
@onready var bullet = preload("res://scenes/bullet.tscn")
@onready var laser = preload("res://scenes/laser.tscn")
@onready var animation_tree = get_node("chicken_wings/AnimationTree")
@onready var camera = $head_piv/Camera3D
@onready var head_mesh = $head_piv/chicken_head
@onready var head_piv = $head_piv
@onready var shoot_from = $shoot_from
@onready var speed_collision = $speedCollision
@onready var shield = $shield
@onready var shield_sound = $shield_sound
@onready var shield_cam = $shield/shield_camera
@onready var expload_effect = $expload_effect
@onready var expload_sound = $expload_sound
@onready var ingenuity_mesh = $ingenuity_mesh
@onready var mesh = $mesh
@onready var pause_screen = $"../pause_screen"
@onready var vt = null
@onready var legs = $LegsNode

#==============================================================================
# --- Export Variables for Tuning ---
#==============================================================================
@export var mouse_sensitivity = 0.003
@export var move_speed = 20.0
@export var lift_speed = 15.0
@export var acceleration = 60.0
@export var brake_strength = 5.0
@export var pitch_limit_up = deg_to_rad(85.0)
@export var pitch_limit_down = deg_to_rad(-85.0)
@export var shake_intensity = 0.1
@export var move_lerp_factor = 10.0
@export var ground_detection_ray_length : float = 5.0
@export var ground_threshold : float = 0.5 # How close to be 'on ground'
@export var power_gain_on_ground : float = 25.0
@export var hover_power_cost : float = 0.8
@export var hover_animation_speed : float = 0.2
@export var low_power_threshold : float = 15.0
@export var low_power_fall_force : float = 10.0
@export var ground_hover_strength : float = 100.0 # <<< NEW: Force pushing up from ground
@export var ground_hover_damping : float = 15.0 # <<< NEW: Force stopping bounce on ground
@export var ground_friction : float = 5.0 # <<< NEW: How much 'grip' on the ground

#==============================================================================
# --- Game State Variables ---
#==============================================================================
var active = true
var dead = false
var dead_reset_counter = 0.0
var inventory = {"crystals":0, "using":"gun"}
var power_cell = 100.0
var fire_cost = 3.0
var power_cost = 0.5
var power_gain = 5.0
var shoot_speed = 34
var world = null
var tutorial_mode = false
var unlocked_gun = true
var collision_size_at_rest = .075
var laser_obj = null
var save_index = null
var save_file = null
var extra_power_cell = 0.0
var extra_power_per_upgrade = 10
var shake = 0.0
var last_velocity = Vector3.ZERO
var _height_from_ground : float = -1.0
var is_near_ground : bool = false

# --- Internal Variables ---
var _look_input = Vector2.ZERO
var _lerped_velocity = Vector3.ZERO

#==============================================================================
# --- Core Godot Functions ---
#==============================================================================
func _ready():
	# ... (Keep as before) ...
	world = get_parent()
	global_position = world.find_child("spawn").global_position if world.find_child("spawn") else Vector3.ZERO
	if get_parent().find_child("is_tutorial"):
		tutorial_mode = true; inventory = {"crystals":0, "using":"gun"}; print("Tutorial Mode Enabled")
	else:
		var voxel_terrain = world.find_child("VoxelLodTerrain")
		if voxel_terrain: vt = voxel_terrain.get_voxel_tool()
		else: print("Warning: VoxelLodTerrain not found!")
		save_index = get_parent().game_index; save_file = "user://savegame_" + str(save_index) + ".json"
		var loaded_inventory = load_save(save_file)
		if loaded_inventory: inventory = loaded_inventory; print("Save game loaded.")
		else: print("No save game found, starting fresh."); inventory = {"crystals":0, "using":"gun"}
	gravity_scale = 0; linear_damp = 2.0; angular_damp = 10.0
	axis_lock_angular_z = true; axis_lock_angular_x = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED); print("Chicken controller ready!")
	last_velocity = linear_velocity
	if not legs: print("WARNING: LegsNode not found at $LegsNode. Leg animations will not work.")

func _input(event):
	# ... (Keep as before) ...
	if active and not is_paused() and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_look_input = event.relative

func _unhandled_input(event):
	# ... (Keep as before) ...
	if not active or is_paused() or dead: return
	if event.is_action_pressed("select_gun"): inventory["using"] = "gun"; print("Selected: Gun")
	if "land_making_gun" in inventory and event.is_action_pressed("select_build"): inventory["using"] = "land_making_gun"; print("Selected: Build Gun")
	if "laser_gun" in inventory and event.is_action_pressed("select_laser"): inventory["using"] = "laser_gun"; print("Selected: Laser Gun")
	if event.is_action_pressed("fire"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if power_cell > fire_cost + 1:
			match inventory["using"]:
				"gun": draw_power(fire_cost); fire_normal()
				"land_making_gun": draw_power(fire_cost); fire_landgun()
				"laser_gun": fire_laser()
		else: print("Not enough power to fire!")
	if event.is_action_released("fire") and inventory["using"] == "laser_gun" and laser_obj:
		laser_obj.queue_free(); laser_obj = null

func _physics_process(delta):
	if rotation.z != 0:
		rotation.z = 0
	if rotation.x != 0:
		rotation.x = 0
	if dead: dead_logic(delta); return
	#if not active:
		#var tmp_cam = get_viewport().get_camera_3d()
		#var mount = tmp_cam.get_parent().find_child("mount")
		
		#global_position = mount.global_position
		#linear_velocity = tmp_cam.get_parent().get_parent().get_parent().linear_velocity
	if is_paused() or not active: return

	ground_check(delta)
	var is_low_power = power_cell < low_power_threshold

	# --- 1. Handle Look / Rotation ---
	if _look_input != Vector2.ZERO:
		rotate_y(-_look_input.x * mouse_sensitivity)
		head_piv.rotate_x(-_look_input.y * mouse_sensitivity)
		head_piv.rotation.x = clamp(head_piv.rotation.x, pitch_limit_down, pitch_limit_up)
		_look_input = Vector2.ZERO

	# --- 2. Handle Movement Input ---
	var input_vector = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_backward")
	var lift_input = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	if is_low_power: lift_input = min(0, lift_input)
	# <<< NEW: Prevent pushing DOWN if near ground (allow UP for jumping) >>>
	if is_near_ground: lift_input = max(0, lift_input)

	# --- 3. Calculate Target Velocity ---
	var head_basis = head_piv.global_transform.basis
	var fwd = head_basis.z * input_vector.y
	var strafe = head_basis.x * input_vector.x
	var lift = Vector3.UP * lift_input
	var combined_dir = (fwd + strafe + lift).normalized()
	var target_speed = 0.0
	if input_vector.length_squared() > 0.01: target_speed = move_speed
	elif abs(lift_input) > 0.01: target_speed = lift_speed
	var target_velocity = combined_dir * target_speed
	_lerped_velocity = lerp(_lerped_velocity, target_velocity, delta * move_lerp_factor)

	# --- 4. Apply Forces ---
	var move_force = (_lerped_velocity - linear_velocity) * acceleration * mass
	if combined_dir.length_squared() < 0.01 and linear_velocity.length_squared() > 0.1:
		move_force = -linear_velocity * brake_strength * mass

	# <<< NEW: Ground Hover & Low Power Fall Logic >>>
	if is_near_ground:
		var target_height = ground_threshold * 0.8 # Aim slightly below threshold
		var height_error = target_height - _height_from_ground
		var hover_force_y = height_error * ground_hover_strength - linear_velocity.y * ground_hover_damping
		apply_central_force(Vector3.UP * hover_force_y * mass) # Apply hover force

		# Apply ground friction
		var horizontal_velocity = linear_velocity * Vector3(1, 0, 1)
		apply_central_force(-horizontal_velocity * ground_friction * mass)

		# Prevent input force from pushing down
		move_force.y = max(0, move_force.y)

	elif is_low_power: # Only apply fall if NOT near ground
		apply_central_force(Vector3.DOWN * low_power_fall_force * mass)
		move_force.y = min(0, move_force.y) # Prevent input force from pushing up

	apply_central_force(move_force) # Apply input force

	# --- 5. Power Management ---
	var is_moving = combined_dir.length_squared() > 0.01 or (abs(lift_input) > 0.01 and not is_near_ground)
	if is_near_ground: add_power(power_gain_on_ground * delta)
	else:
		var cost = hover_power_cost
		if is_moving: cost = max(cost, power_cost)
		draw_power(cost * delta)
	if laser_obj and not draw_power(fire_cost * delta):
		laser_obj.queue_free(); laser_obj = null

	# --- 6. Other Updates ---
	figure_damage()
	update_shield()
	do_shake(delta)
	update_collision_size()
	update_user_settings()
	update_leg_animations(delta)
	update_wing_animations()
	last_velocity = linear_velocity

#==============================================================================
# --- Ground Check / Walk ---
#==============================================================================
# ... (Keep as before) ...
func ground_check(delta):
	var space_state = get_world_3d().direct_space_state
	if not space_state: print("ERROR: Could not get 3D physics space state."); return
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * ground_detection_ray_length)
	query.exclude = [self]; query.collision_mask = self.collision_mask
	var result = space_state.intersect_ray(query)
	if result: _height_from_ground = global_position.distance_to(result.position); is_near_ground = (_height_from_ground > 0 and _height_from_ground < ground_threshold)
	else: _height_from_ground = -1.0; is_near_ground = false

func update_leg_animations(delta):
	# ... (Keep as before) ...
	if not legs: return
	if is_near_ground: legs.animate_legs(delta, linear_velocity.length())
	else: legs.animate_legs(delta, 0)

func update_wing_animations():
	# ... (Keep as before, ensure param name matches your tree) ...
	if not animation_tree or not animation_tree.active: return
	var speed = linear_velocity.length(); var anim_speed_scale = 0.0
	if is_near_ground: anim_speed_scale = 0.0
	elif speed < 0.5: anim_speed_scale = hover_animation_speed
	else: anim_speed_scale = speed / move_speed
	animation_tree.set("parameters/SPEED/scale", anim_speed_scale * 50)

#==============================================================================
# --- Save / Load Functions ---
#==============================================================================
# ... (Keep as before) ...
func save_game():
	if not save_file: print("Save file path not set."); return
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file: file.store_line(JSON.stringify(inventory)); print("Game saved.")
	else: print("Error saving game.")

func load_save(path):
	if not FileAccess.file_exists(path): return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new(); var err = json.parse(file.get_line())
		if err == OK: var data = json.get_data(); data["using"] = "gun"; return data
		else: print("Error parsing save file."); return null
	else: print("Error loading save file."); return null

#==============================================================================
# --- Weapon / Fire Functions ---
#==============================================================================
# ... (Keep as before) ...
func fire_normal():
	if not unlocked_gun: return
	var new_bullet = bullet.instantiate()
	new_bullet.global_position = shoot_from.global_position
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-head_piv.global_transform.basis.z * shoot_speed)
	apply_impulse(head_piv.global_transform.basis.z * 0.1)
	world.add_child(new_bullet)

func fire_landgun():
	if not "land_making_gun" in inventory or not vt: return
	var new_bullet = bullet.instantiate()
	new_bullet.global_position = shoot_from.global_position
	new_bullet.add_mode = true
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-head_piv.global_transform.basis.z * shoot_speed)
	apply_impulse(head_piv.global_transform.basis.z * 0.1)
	world.add_child(new_bullet)

func fire_laser():
	if not "laser_gun" in inventory: return
	if laser_obj == null and power_cell > fire_cost + 1:
		laser_obj = laser.instantiate(); laser_obj.name = "laser"
		shoot_from.add_child(laser_obj)
		laser_obj.global_rotation = head_piv.global_rotation

#==============================================================================
# --- Power / Damage / Shield / Effects ---
#==============================================================================
# ... (Keep as before) ...
func figure_damage():
	var impact_vector = last_velocity - linear_velocity
	var impact_strength = impact_vector.length()
	if impact_strength > 15:
		if last_velocity.length() > 1.0 and impact_vector.normalized().dot(last_velocity.normalized()) < -0.5:
			print("Smacked! Strength: " + str(impact_strength))
			shake = 0.3
			if not draw_power(impact_strength * 0.5):
				print("Impact caused critical power failure!")
			if power_cell > 0: shield_sound.play()
	if power_cell < 0 and not dead:
		print("You are dead!")
		expload_sound.play(); expload_effect.emitting = true
		dead = true; dead_reset_counter = 3.0

func do_shake(delta):
	if shake > 0:
		camera.h_offset = randf_range(-1, 1) * shake * shake_intensity
		camera.v_offset = randf_range(-1, 1) * shake * shake_intensity
		shake -= delta
	elif shake <= 0:
		shake = 0; camera.h_offset = 0; camera.v_offset = 0

func update_shield():
	shield.visible = shield_sound.playing; shield_cam.visible = shield_sound.playing

func update_collision_size():
	var speed = linear_velocity.length()
	speed_collision.shape.radius = collision_size_at_rest * ((speed / 5.0) + 1.0) if speed > 5 else collision_size_at_rest

func add_power(power_to_add):
	var max_power = 100.0
	if power_cell < max_power:
		power_cell = min(power_cell + power_to_add, max_power)
		power_to_add = max(0, power_cell - max_power)
	if "extra_power" in inventory and power_to_add > 0:
		var max_extra = extra_power_per_upgrade * inventory["extra_power"]
		extra_power_cell = min(extra_power_cell + power_to_add, max_extra)

func draw_power(power_to_draw):
	var needed = power_to_draw
	if extra_power_cell >= needed: extra_power_cell -= needed; return true
	needed -= extra_power_cell; extra_power_cell = 0
	if power_cell >= needed: power_cell -= needed; return true
	power_cell = -1; return false

func dead_logic(delta):
	linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO
	dead_reset_counter -= delta
	if dead_reset_counter <= 0:
		print("Respawning...")
		global_position = world.find_child("spawn").global_position if world.find_child("spawn") else Vector3.ZERO
		rotation = Vector3.ZERO; head_piv.rotation = Vector3.ZERO
		inventory["crystals"] = 0; power_cell = 100.0; extra_power_cell = 0.0
		dead = false; expload_effect.emitting = false
		last_velocity = Vector3.ZERO; _lerped_velocity = Vector3.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		save_game()

#==============================================================================
# --- Visuals / Misc ---
#==============================================================================
func update_user_settings():
	pass
	#var use_lander = "lander_skin" in inventory and inventory["lander_skin"]
	#ingenuity_mesh.visible = use_lander; mesh.visible = not use_lander

func is_paused():
	return pause_screen != null and pause_screen.visible
