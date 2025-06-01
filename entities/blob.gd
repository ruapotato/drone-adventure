extends CharacterBody3D

@onready var vulnerable_zone = $KillArea3D
@onready var player_hurt_zone = $biteArea3D
@onready var mesh = $mesh
@onready var walk_sound = $walk_sound
@onready var die_sound = $die_sound
@onready var ground_check = $mesh/ground_check

const PATROL_SPEED = 1.5
const CHASE_SPEED = 2.5
const DETECTION_RADIUS = 6.0
const SQUISH_SPEED = 6.0
const SQUISH_AMOUNT = 0.6
const DEATH_SQUISH = 0.1
const DEATH_DURATION = 0.3
const DEATH_WAIT = 3.0

var level_loader
var player
var initial_y_scale = 1.0
var squish_time = 0.0
var is_dying = false
var death_timer = 0.0
var initial_death_scale = 1.0
var patrol_direction = Vector3.ZERO
var initial_mesh_rotation = 0.0
var is_moving_forward = true
var is_chasing = false

func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	if mesh:
		initial_y_scale = mesh.scale.y
		initial_death_scale = initial_y_scale
		setup_initial_direction()

func is_ground_ahead() -> bool:
	if not ground_check:
		return true
	return ground_check.is_colliding()

func setup_initial_direction():
	if not mesh:
		return
		
	# Store the initial rotation
	initial_mesh_rotation = rotation.y
	
	# Forward-facing (0°) should move forward/back (Z axis)
	# Left-facing (90°) should move left/right (X axis)
	# Convert initial rotation to patrol direction
	if is_approximately_zero(initial_mesh_rotation) or is_approximately_equal(initial_mesh_rotation, PI) or is_approximately_equal(initial_mesh_rotation, -PI):
		# Forward/backward facing - patrol along Z axis
		patrol_direction = Vector3(0, 0, 1)
	elif is_approximately_equal(abs(initial_mesh_rotation), PI/2):
		# Left/right facing - patrol along X axis
		patrol_direction = Vector3(1, 0, 0)
	else:
		# Default to Z axis for any other rotation
		patrol_direction = Vector3(0, 0, 1)
	
	# Keep the mesh's initial rotation, adding PI to correct the base orientation
	mesh.rotation.y = initial_mesh_rotation + PI
	
	# Reset node rotation after capturing direction
	rotation = Vector3.ZERO

func is_approximately_zero(value: float, epsilon: float = 0.01) -> bool:
	return abs(value) < epsilon

func is_approximately_equal(a: float, b: float, epsilon: float = 0.01) -> bool:
	return abs(a - b) < epsilon

func face_patrol_direction():
	if not mesh:
		return
	
	# Maintain initial mesh rotation when moving forward
	# Rotate 180° when moving backward
	mesh.rotation.y = initial_mesh_rotation + PI + (PI if not is_moving_forward else 0)

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "world":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

func start_death_sequence():
	die_sound.play()
	walk_sound.stop()
	is_dying = true
	death_timer = 0.0
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if player_hurt_zone:
		player_hurt_zone.monitoring = false
		player_hurt_zone.monitorable = false

func process_death_animation(delta: float) -> bool:
	death_timer += delta
	
	if death_timer <= DEATH_DURATION:
		var progress = death_timer / DEATH_DURATION
		var squish = lerp(initial_death_scale, DEATH_SQUISH, ease(progress, delta))
		mesh.scale.y = squish
		return false
	elif death_timer >= DEATH_WAIT:
		queue_free()
		return true
	return false

func die():
	start_death_sequence()

func am_i_dead():
	if not is_dying and player in vulnerable_zone.get_overlapping_bodies():
		start_death_sequence()

func can_i_bite():
	if not is_dying and player in player_hurt_zone.get_overlapping_bodies():
		var knockback_direction = (player.global_position - global_position).normalized()
		# Call take_damage with damage amount and knockback direction
		player.take_damage(1, knockback_direction)

func check_player_distance() -> bool:
	if not player:
		return false
	var distance = global_position.distance_to(player.global_position)
	return distance < DETECTION_RADIUS

func flip_patrol_direction():
	patrol_direction = -patrol_direction
	is_moving_forward = !is_moving_forward
	face_patrol_direction()

func patrol() -> Vector3:
	return patrol_direction * PATROL_SPEED

func chase_player() -> Vector3:
	var direction_to_player = (player.global_position - global_position).normalized()
	direction_to_player.y = 0  # Keep movement on horizontal plane
	
	if direction_to_player.length() > 0.1:
		if mesh:
			var target_angle = atan2(direction_to_player.x, direction_to_player.z)
			mesh.rotation.y = target_angle + PI
	
	# Only return movement vector if there's ground ahead
	if is_ground_ahead():
		print("Ground")
		return direction_to_player * CHASE_SPEED
	else:
		# Stop at cliff edge while chasing
		print("I'll wait here")
		return Vector3.ZERO

func update_squish_animation(delta: float) -> void:
	if not mesh or is_dying:
		return
	
	if velocity.length() > 0.1:
		squish_time += delta * SQUISH_SPEED
		var vertical_squish = 1.0 + (sin(squish_time) * SQUISH_AMOUNT)
		mesh.scale.y = initial_y_scale * vertical_squish
	else:
		mesh.scale.y = initial_y_scale

func _physics_process(delta: float) -> void:
	if is_dying:
		process_death_animation(delta)
		return
		
	am_i_dead()
	can_i_bite()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var was_chasing = is_chasing
	is_chasing = check_player_distance()
	
	if was_chasing and not is_chasing:
		face_patrol_direction()
	
	# Check for ground ahead and flip if no ground during patrol
	if not is_chasing and not is_ground_ahead():
		print("I'll go the other way")
		flip_patrol_direction()
	
	var movement = chase_player() if is_chasing else patrol()
	
	velocity.x = movement.x
	velocity.z = movement.z
	
	var collision = move_and_slide()
	if collision and not is_chasing:
		if get_slide_collision_count() > 0:
			var normal = get_slide_collision(0).get_normal()
			if abs(normal.x) > 0.5 or abs(normal.z) > 0.5:
				flip_patrol_direction()
	
	update_squish_animation(delta)

func _on_walk_sound_finished() -> void:
	walk_sound.play()
