extends CharacterBody3D

@onready var cam_piv = $piv
@onready var camera_arm = $piv/SpringArm3D # Corrected path
@onready var camera = $piv/SpringArm3D/Camera3D      # Path to your player's camera
@onready var mesh = $mesh
@onready var leg_animator = $mesh/LegAnimator
@onready var sword = $mesh/sword
@onready var shield_node = $mesh/shield  # Renamed from 'shield' to avoid conflict with shield script if any
@onready var collision_shape = $CollisionShape3D
@onready var jump_sound = $mesh/player_sounds/jump
@onready var land_sound = $mesh/player_sounds/land
@onready var shield_sound = $mesh/player_sounds/shield
@onready var hurt_sound = $mesh/player_sounds/hurt
@onready var right_arm = $mesh/right_arm
@onready var left_arm = $mesh/left_arm

# Movement constants
const SPEED = 5.0
const ACCELERATION = 30.0 # Affects how quickly velocity changes, used in move_toward or lerp
const FRICTION = 60.0      # Affects how quickly player stops, used in move_toward
const ROTATION_SPEED = 20.0
const AERIAL_STRIKE_GRAVITY_MULT = 1.5
const AERIAL_STRIKE_INITIAL_VELOCITY_Y = -0.5 # Renamed from AERIAL_STRIKE_SPEED for clarity
const POSSESSION_TRANSITION_TIME = 0.5 # Not currently used, but kept from your script
const FLUTE_PLAY_TIME = 1.0
const MIN_POSSESSION_DISTANCE = 0.0
const MAX_POSSESSION_DISTANCE = 10.0 # Used to check if chicken is in range to *start* possession
# const POSSESSION_DURATION = 10.0 # REMOVED
const POSSESSION_COOLDOWN = 1.0

# Movement States
enum ActionState {IDLE, WALK, JUMP, ROLL, ATTACK, BLOCK, HURT, PLAYING_FLUTE, POSSESSING}

# Basic movement mechanics
const JUMP_VELOCITY = 6.0
const JUMP_BUFFER_TIME = 0.1
const COYOTE_TIME = 0.1

# Combat and movement abilities
const ROLL_SPEED = 8.0
const ROLL_DURATION = 0.4
const KNOCKBACK_FORCE = 8.0
const DAMAGE_INVULNERABILITY_TIME = 0.8
const TARGETING_DISTANCE = 10.0

# Get the gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# State handling
var active = true # Player character is active by default
var action_state = ActionState.IDLE
var jump_buffer_timer = 0.0
var coyote_timer = 0.0
var was_on_floor = false

# Variables for possession system
var is_playing_flute = false
var flute_timer = 0.0
# var possession_timer = 0.0 # REMOVED
var possession_cooldown_timer = 0.0
var is_possessing = false # Player's own state for whether it *intends* to possess
var chicken_spirit # Reference to the chicken node instance
var world # Reference to the parent node, assumed to be the game world/level
var mouse_sensitivity = 0.01 # You added this

# Movement and combat variables
var input_dir = Vector2.ZERO
var direction = Vector3.ZERO # Desired movement direction based on input and camera
var target_enemy = null
var is_targeting = false
var is_blocking = false
var is_attacking = false
var is_rolling = false
var roll_timer = 0.0
var is_invulnerable = false
var damage_invulnerability_timer = 0.0

# Unused vars from your script, kept for completeness if you plan to use them
var last_player_position = Vector3.ZERO
var last_player_rotation = Basis()
var last_safe_position = Vector3.ZERO


func _ready():
	world = get_parent()
	chicken_spirit = world.find_child("chicken") 
	if is_instance_valid(chicken_spirit) and chicken_spirit.has_method("set_player"):
		chicken_spirit.set_player(self)
	else:
		printerr("Player _ready: Chicken node or set_player method not found!")


	camera_arm.add_excluded_object(self)
	camera_arm.add_excluded_object(mesh)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_piv.top_level = true
	cam_piv.global_position = global_position 

	if camera:
		camera.current = true
	else:
		printerr("Player _ready: Camera node ($piv/SpringArm3D/Camera3D) not found!")

	active = true 
	last_player_position = global_position
	last_player_rotation = mesh.transform.basis


func _unhandled_input(event):
	if not active: 
		if is_possessing and event.is_action_pressed("play_flute") and possession_cooldown_timer <= 0:
			end_possession_sequence() 
		return 

	if event is InputEventMouseMotion and not is_targeting:
		cam_piv.rotate_y(-event.relative.x * mouse_sensitivity)
		var new_pitch = camera_arm.rotation.x - event.relative.y * mouse_sensitivity
		camera_arm.rotation.x = clamp(new_pitch, -PI/2.1, PI/2.1)

	if is_playing_flute:
		if event.is_action_released("play_flute"): 
			pass 
		return 

	if event.is_action_pressed("move_up"):
		if is_on_floor() or coyote_timer > 0:
			perform_jump()
		else:
			jump_buffer_timer = JUMP_BUFFER_TIME
	
	elif event.is_action_pressed("fire"):
		perform_attack()
	elif event.is_action_released("fire"):
		if sword.has_method("release_charge"): sword.release_charge()
	
	elif event.is_action_pressed("roll"):
		start_roll()
	
	elif event.is_action_pressed("block"):
		start_block()
	elif event.is_action_released("block"):
		end_block()
	
	elif event.is_action_pressed("target"):
		toggle_targeting()


func _physics_process(delta):
	if not active: 
		# No possession timer logic needed here anymore
		return 

	if possession_cooldown_timer > 0:
		possession_cooldown_timer -= delta
	
	if possession_cooldown_timer <= 0 and not is_possessing:
		handle_possession_input()

	if not is_playing_flute and not is_possessing: 
		handle_basic_physics(delta)
		handle_movement_controls(delta)
		handle_targeting(delta)
		handle_combat(delta)
		update_timers(delta)
	elif is_playing_flute and not is_possessing: 
		velocity = Vector3.ZERO 
		if leg_animator.has_method("animate_legs"):
			leg_animator.animate_legs(delta, 0.0)

	if not is_possessing: 
		move_and_slide()


func handle_basic_physics(delta):
	if not is_on_floor():
		if is_attacking and sword.has_method("get_current_attack_type") and sword.get_current_attack_type() == sword.AttackType.AERIAL:
			velocity.y -= gravity * AERIAL_STRIKE_GRAVITY_MULT * delta
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			velocity.y -= gravity * delta
		
		if was_on_floor and not is_attacking:
			coyote_timer = COYOTE_TIME
	else: 
		if not was_on_floor:
			if is_instance_valid(land_sound): land_sound.play()
			if is_attacking and sword.has_method("get_current_attack_type") and sword.get_current_attack_type() == sword.AttackType.AERIAL:
				is_attacking = false 
				action_state = ActionState.IDLE
		if jump_buffer_timer > 0.0:
			perform_jump()
			jump_buffer_timer = 0.0
	was_on_floor = is_on_floor()

func handle_movement_controls(delta):
	if is_rolling: return

	input_dir = Input.get_vector("strafe_left", "strafe_right", "move_backward", "move_forward")
	var cam_transform = cam_piv.global_transform
	var cam_forward = -cam_transform.basis.z
	var cam_right = cam_transform.basis.x
	cam_forward.y = 0; cam_right.y = 0
	cam_forward = cam_forward.normalized(); cam_right = cam_right.normalized()

	if is_targeting and is_instance_valid(target_enemy):
		var target_dir_xz = (target_enemy.global_position - global_position)
		target_dir_xz.y = 0; target_dir_xz = target_dir_xz.normalized()
		direction = target_dir_xz * input_dir.y + target_dir_xz.cross(Vector3.UP) * input_dir.x
		if direction.length_squared() > 0.01: direction = direction.normalized()
	else:
		direction = (cam_forward * input_dir.y + cam_right * input_dir.x)
		if input_dir.x != 0 and input_dir.y != 0 and direction.length_squared() > 0.01:
			direction = direction.normalized()

	var current_speed = SPEED
	if is_attacking and sword.has_method("get_is_charging") and not sword.get_is_charging(): current_speed = 0.0
	elif sword.has_method("get_is_charging") and sword.get_is_charging() and sword.has_method("get_charge_movement_speed_mult"):
		current_speed *= sword.get_charge_movement_speed_mult()
	elif is_blocking: current_speed *= 0.4

	if direction.length_squared() > 0.01:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if not is_targeting and not is_attacking:
			var look_dir_xz = Vector3(direction.x, 0, direction.z)
			if look_dir_xz.length_squared() > 0.01:
				mesh.transform.basis = mesh.transform.basis.slerp(Basis.looking_at(look_dir_xz.normalized(), Vector3.UP), ROTATION_SPEED * delta)
		if is_on_floor() and action_state != ActionState.ATTACK and action_state != ActionState.ROLL: action_state = ActionState.WALK
		if leg_animator.has_method("animate_legs"): leg_animator.animate_legs(delta, Vector2(velocity.x, velocity.z).length() / SPEED)
	else: 
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
		if is_on_floor() and action_state != ActionState.ATTACK and action_state != ActionState.ROLL: action_state = ActionState.IDLE
		if leg_animator.has_method("animate_legs"): leg_animator.animate_legs(delta, 0.0)

func handle_possession_input():
	if Input.is_action_just_pressed("play_flute") and not is_rolling and not is_attacking and not is_blocking:
		start_playing_flute()
	elif Input.is_action_just_released("play_flute") and is_playing_flute:
		attempt_possession()

func start_playing_flute():
	if is_playing_flute or is_possessing: return
	print("Player: Playing flute...")
	is_playing_flute = true
	flute_timer = FLUTE_PLAY_TIME
	action_state = ActionState.PLAYING_FLUTE
	velocity = Vector3.ZERO

func attempt_possession():
	if not is_instance_valid(chicken_spirit) or not is_playing_flute:
		cancel_flute(); return
	var distance = global_position.distance_to(chicken_spirit.global_position)
	if distance >= MIN_POSSESSION_DISTANCE and distance <= MAX_POSSESSION_DISTANCE: # Range check to START possession
		start_possession_sequence()
	else:
		print("Player: Chicken out of range for possession."); cancel_flute()

func start_possession_sequence():
	if not is_instance_valid(chicken_spirit):
		printerr("Player: Cannot start possession, chicken_spirit is not valid."); cancel_flute(); return
	print("Player: Starting possession of chicken.")
	active = false 
	is_possessing = true 
	is_playing_flute = false
	# possession_timer = POSSESSION_DURATION # REMOVED
	action_state = ActionState.POSSESSING
	if camera: camera.current = false
	if chicken_spirit.has_method("start_possession"):
		chicken_spirit.start_possession()
	else:
		printerr("Player Error: chicken_spirit has no start_possession method!")
		active = true; is_possessing = false; action_state = ActionState.IDLE
		if camera: camera.current = true

func end_possession_sequence():
	if not is_possessing and action_state != ActionState.POSSESSING:
		if is_playing_flute: cancel_flute()
		return
	print("Player: Ending possession of chicken.")
	active = true 
	is_possessing = false 
	is_playing_flute = false
	action_state = ActionState.IDLE
	# possession_timer = 0.0 # REMOVED
	possession_cooldown_timer = POSSESSION_COOLDOWN
	if camera: camera.current = true 
	if is_instance_valid(chicken_spirit) and chicken_spirit.has_method("end_possession"):
		chicken_spirit.end_possession() 
	velocity = Vector3.ZERO

func cancel_flute():
	print("Player: Flute play cancelled.")
	is_playing_flute = false
	flute_timer = 0.0
	if action_state == ActionState.PLAYING_FLUTE: action_state = ActionState.IDLE
	if not is_possessing: active = true

func start_aerial_strike():
	if not active or is_possessing: return
	velocity.y = AERIAL_STRIKE_INITIAL_VELOCITY_Y

func handle_targeting(delta):
	if not active or is_possessing or is_playing_flute: return
	if is_targeting and is_instance_valid(target_enemy):
		var look_dir = (target_enemy.global_position - global_position)
		look_dir.y = 0
		if look_dir.length_squared() > 0.01 and not is_attacking and not is_rolling:
			mesh.transform.basis = mesh.transform.basis.slerp(Basis.looking_at(look_dir.normalized(), Vector3.UP), ROTATION_SPEED * delta)
		var target_cam_pos = global_position + Vector3(0, 0.44, 0) 
		cam_piv.global_position = cam_piv.global_position.lerp(target_cam_pos, delta * 10.0) 
	else:
		var target_cam_pos = global_position + Vector3(0, 0.44, 0)
		cam_piv.global_position = cam_piv.global_position.lerp(target_cam_pos, delta * 5.0)

func handle_combat(delta): 
	if not active or is_possessing or is_playing_flute: return
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			if action_state == ActionState.ROLL: action_state = ActionState.IDLE

func perform_jump():
	if not active or is_possessing or is_playing_flute: return
	if is_on_floor() or coyote_timer > 0.0:
		if is_instance_valid(jump_sound): jump_sound.play()
		velocity.y = JUMP_VELOCITY
		action_state = ActionState.JUMP
		coyote_timer = 0.0; was_on_floor = false

func perform_attack():
	if not active or is_possessing or is_playing_flute: return
	if is_attacking or is_rolling or is_blocking: return
	is_attacking = true; action_state = ActionState.ATTACK
	if is_on_floor():
		if sword.has_method("start_charge"): sword.start_charge()
		elif sword.has_method("perform_ground_attack"): sword.perform_ground_attack()
		else: printerr("Player: Sword lacks attack/charge methods!"); is_attacking = false; action_state = ActionState.IDLE
	else:
		if sword.has_method("start_aerial_strike"): sword.start_aerial_strike(); start_aerial_strike()
		else: printerr("Player: Sword lacks aerial strike method!"); is_attacking = false; action_state = ActionState.IDLE

func start_roll():
	if not active or is_possessing or is_playing_flute: return
	if is_rolling or is_attacking or is_blocking or not is_on_floor(): return
	is_rolling = true; is_invulnerable = true
	damage_invulnerability_timer = ROLL_DURATION; roll_timer = ROLL_DURATION
	action_state = ActionState.ROLL
	var roll_dir_2d: Vector2
	var current_xz_vel = Vector2(velocity.x, velocity.z)
	if input_dir.length_squared() > 0.01 : roll_dir_2d = input_dir.normalized()
	elif current_xz_vel.length_squared() > 0.01: roll_dir_2d = current_xz_vel.normalized()
	else:
		var mesh_fwd_xz = Vector2(-mesh.global_transform.basis.z.x, -mesh.global_transform.basis.z.z)
		roll_dir_2d = mesh_fwd_xz.normalized() if mesh_fwd_xz.length_squared() > 0.001 else Vector2(0, -1)
	velocity.x = roll_dir_2d.x * ROLL_SPEED; velocity.z = roll_dir_2d.y * ROLL_SPEED
	velocity.y = 0.5 
	if is_instance_valid(shield_node) and shield_node.has_method("stow"): shield_node.stow()

func start_block():
	if not active or is_possessing or is_playing_flute: return
	if is_blocking or is_rolling or is_attacking: return
	is_blocking = true; action_state = ActionState.BLOCK
	if is_instance_valid(shield_sound): shield_sound.play()
	if is_instance_valid(shield_node) and shield_node.has_method("shield"): shield_node.shield()

func end_block():
	if not active or is_possessing or is_playing_flute: return
	if not is_blocking: return
	is_blocking = false;
	if action_state == ActionState.BLOCK: action_state = ActionState.IDLE
	if is_instance_valid(shield_node) and shield_node.has_method("equip"): shield_node.equip()

func toggle_targeting():
	if not active or is_possessing or is_playing_flute: return
	is_targeting = not is_targeting
	if is_targeting:
		target_enemy = null; var closest_dist_sq = TARGETING_DISTANCE * TARGETING_DISTANCE
		var potential_target = null
		for enemy_node in get_tree().get_nodes_in_group("targetable"):
			if not is_instance_valid(enemy_node): continue
			var dist_sq = global_position.distance_squared_to(enemy_node.global_position)
			if dist_sq < closest_dist_sq:
				var dir_to_enemy_flat = (enemy_node.global_position - global_position); dir_to_enemy_flat.y = 0
				var cam_fwd_flat = -cam_piv.global_transform.basis.z; cam_fwd_flat.y = 0
				if dir_to_enemy_flat.length_squared() > 0 and cam_fwd_flat.length_squared() > 0:
					if dir_to_enemy_flat.normalized().dot(cam_fwd_flat.normalized()) > 0.3:
						closest_dist_sq = dist_sq; potential_target = enemy_node
		if is_instance_valid(potential_target): target_enemy = potential_target; print("Player: Targeted ", target_enemy.name)
		else: is_targeting = false; print("Player: No target found.")
	else: target_enemy = null; print("Player: Targeting disabled.")

func take_damage(amount: int, knockback_direction: Vector3):
	if not active or is_possessing or is_invulnerable or is_rolling: return
	if is_blocking:
		if knockback_direction.normalized().dot(-mesh.global_transform.basis.z) > 0.5:
			print("Player: Blocked attack!"); velocity += knockback_direction.normalized() * KNOCKBACK_FORCE * 0.3
			if is_instance_valid(shield_sound): shield_sound.play()
			return
	print("Player: Took damage: ", amount); is_invulnerable = true
	if is_instance_valid(hurt_sound): hurt_sound.play()
	damage_invulnerability_timer = DAMAGE_INVULNERABILITY_TIME; action_state = ActionState.HURT
	velocity = knockback_direction.normalized() * KNOCKBACK_FORCE; velocity.y = JUMP_VELOCITY * 0.5
	# health -= amount ...

func update_timers(delta):
	if not active or is_possessing: return
	if jump_buffer_timer > 0: jump_buffer_timer -= delta
	if coyote_timer > 0: coyote_timer -= delta
	if damage_invulnerability_timer > 0:
		damage_invulnerability_timer -= delta
		if damage_invulnerability_timer <= 0:
			is_invulnerable = false
			if action_state == ActionState.HURT: action_state = ActionState.IDLE
