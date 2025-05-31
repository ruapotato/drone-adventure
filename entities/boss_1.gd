extends Area3D

@onready var bad_mesh = $bad_mesh
@onready var good_mesh = $good_mesh

# Core boss parameters
@export var max_health := 3
@export var energy_ball_speed := 8.0
@export var reflect_chance := 0.9  # 90% chance to reflect like Ganondorf
@export var speed_increase := 1.25  # 25% faster each volley
@export var reveal_distance := 0.05  # Distance to reveal good mesh
@export var max_speed := 25


# Movement parameters
@export var float_height := 0.4
@export var float_speed := 1.5
@export var rotation_speed := 6.0
@export var hover_distance := 10.0  # Distance boss tries to maintain from player
@export var strafe_speed := 3.0
@export var back_dash_speed := 15.0

# Battle timing
@export var shooting_cooldown := 1.8  # Time between volleys
@export var laugh_duration := 1.2  # How long boss taunts after player miss
@export var stun_duration := 1.5  # How long boss is stunned when hit

# State management
enum BossState {
	INTRO,      # Initial appearance
	FLOATING,   # Normal hovering state
	CHARGING,   # About to shoot
	VOLLEYING,  # In energy ball volley
	LAUGHING,   # Taunting after player fails
	STUNNED,    # Hit by energy ball
	DEFEATED    # Final state
}

var current_state: BossState = BossState.INTRO
var level_loader
var player
var current_health
var current_energy_ball = null
var current_ball_speed
var is_vulnerable := false
var initial_bad_mesh_position: Vector3
var initial_height: float
var time_in_state: float = 0.0
var strafe_direction := Vector3.RIGHT
var volley_count := 0  # Track volleys for difficulty scaling

const ENERGY_BALL_SCENE = preload("res://weapons/energy_ball.tscn")

func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	current_health = max_health
	good_mesh.show()  # Show good mesh behind bad mesh
	initial_bad_mesh_position = bad_mesh.position
	initial_height = position.y
	_play_intro_animation()

func _physics_process(delta: float) -> void:
	if player == null:
		return
		
	time_in_state += delta
	
	# Base floating movement regardless of state
	position.y = initial_height + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_height
	
	match current_state:
		BossState.INTRO:
			_handle_intro_state(delta)
		BossState.FLOATING:
			_handle_floating_state(delta)
		BossState.CHARGING:
			_handle_charging_state(delta)
		BossState.VOLLEYING:
			_handle_volleying_state(delta)
		BossState.LAUGHING:
			_handle_laughing_state(delta)
		BossState.STUNNED:
			_handle_stunned_state(delta)
		BossState.DEFEATED:
			_handle_defeated_state(delta)

func _handle_intro_state(delta: float) -> void:
	if time_in_state >= 2.0:  # Intro animation duration
		_change_state(BossState.FLOATING)

func _handle_floating_state(delta: float) -> void:
	_face_player(delta)
	_maintain_distance(delta)
	_strafe_movement(delta)
	
	if time_in_state >= 1.5:  # Time before first shot
		_change_state(BossState.CHARGING)

func _handle_charging_state(delta: float) -> void:
	_face_player(delta)
	
	# Charging animation - pulse scale
	var pulse = 1.0 + sin(time_in_state * 15.0) * 0.1
	bad_mesh.scale = Vector3.ONE * pulse
	
	if time_in_state >= 0.7:  # Charge duration
		shoot_energy_ball()
		_change_state(BossState.VOLLEYING)

func _handle_volleying_state(delta: float) -> void:
	_face_player(delta)
	# Movement is limited during volley

func _handle_laughing_state(delta: float) -> void:
	_face_player(delta)
	if time_in_state >= laugh_duration:
		_change_state(BossState.FLOATING)

func _handle_stunned_state(delta: float) -> void:
	# Stunned animation - wobble
	var wobble = sin(time_in_state * 20.0) * 0.2
	bad_mesh.rotation.z = wobble
	
	if time_in_state >= stun_duration:
		bad_mesh.rotation.z = 0
		_change_state(BossState.FLOATING)

func _handle_defeated_state(delta: float) -> void:
	# Phase 1: Initial defeat animation (0-2 seconds)
	if time_in_state < 2.0:
		# Make the boss float up and down more dramatically
		position.y = initial_height + sin(time_in_state * 8.0) * float_height * 2.0
		# Rotate erratically
		bad_mesh.rotation.z = sin(time_in_state * 15.0) * 0.2
		bad_mesh.rotation.y += delta * 2.0
		
	# Phase 2: Evil spirit being expelled (2-4 seconds)
	elif time_in_state < 4.0:
		# Violent shaking
		bad_mesh.position.x = initial_bad_mesh_position.x + (randf() - 0.5) * 0.2
		bad_mesh.position.y = initial_bad_mesh_position.y + (randf() - 0.5) * 0.2
		
		# Pulse scale
		var pulse = 1.0 + sin(time_in_state * 20.0) * 0.2
		bad_mesh.scale = Vector3.ONE * pulse
		
	# Phase 3: Final separation (4-5 seconds)
	elif time_in_state < 5.0:
		var separation_progress = (time_in_state - 4.0)
		# Move evil spirit away
		bad_mesh.position.x = initial_bad_mesh_position.x - (separation_progress * 10.0)
		# Scale down evil spirit
		var remaining_scale = 1.0 - separation_progress
		bad_mesh.scale = Vector3.ONE * remaining_scale
		# Make good mesh larger
		good_mesh.scale = Vector3.ONE * (1.0 + separation_progress * 0.2)
		
	# Phase 4: Cleanup
	elif time_in_state >= 5.0:
		bad_mesh.queue_free()  # Remove just the evil spirit mesh
		current_state = BossState.INTRO  # This prevents further state updates
		level_loader.load_level('end')

func _play_intro_animation() -> void:
	# Start with a small scale and grow
	bad_mesh.scale = Vector3.ZERO
	var scale_tween = create_tween()
	scale_tween.tween_property(bad_mesh, "scale", Vector3.ONE, 1.0)
	scale_tween.set_trans(Tween.TRANS_BACK)
	scale_tween.set_ease(Tween.EASE_OUT)
	
	# Rise up from ground
	position.y -= 3.0
	var rise_tween = create_tween()
	rise_tween.tween_property(self, "position:y", initial_height, 1.5)
	rise_tween.set_trans(Tween.TRANS_SINE)
	rise_tween.set_ease(Tween.EASE_OUT)

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

func _face_player(delta: float) -> void:
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0  # Keep boss upright
	
	if direction_to_player.length() > 0.1:
		var target_transform = transform.looking_at(player.global_position, Vector3.UP)
		transform = transform.interpolate_with(target_transform, rotation_speed * delta)

func _maintain_distance(delta: float) -> void:
	var direction_to_player = global_position.direction_to(player.global_position)
	var distance = global_position.distance_to(player.global_position)
	
	if distance < hover_distance - 1.0:
		# Too close, back away
		global_position += -direction_to_player * back_dash_speed * delta
	elif distance > hover_distance + 1.0:
		# Too far, move closer
		global_position += direction_to_player * strafe_speed * delta

func _strafe_movement(delta: float) -> void:
	# Calculate strafe direction perpendicular to player direction
	var to_player = (player.global_position - global_position).normalized()
	strafe_direction = to_player.cross(Vector3.UP)
	
	# Reverse direction periodically
	if sin(Time.get_ticks_msec() * 0.001) > 0:
		strafe_direction = -strafe_direction
	
	# Apply strafe movement
	global_position += strafe_direction * strafe_speed * delta

func _change_state(new_state: BossState) -> void:
	current_state = new_state
	time_in_state = 0.0
	match new_state:
		BossState.CHARGING:
			# Telegraph animation
			var charge_tween = create_tween()
			charge_tween.tween_property(bad_mesh, "scale", Vector3.ONE * 1.2, 0.2)
		BossState.LAUGHING:
			# Reset any animations
			bad_mesh.scale = Vector3.ONE
		BossState.STUNNED:
			is_vulnerable = true
			# Flash effect using scale instead of modulate
			var flash_tween = create_tween()
			flash_tween.tween_property(bad_mesh, "scale", Vector3.ONE * 1.2, 0.1)
			flash_tween.tween_property(bad_mesh, "scale", Vector3.ONE, 0.1)

func hurt() -> void:
	if not is_vulnerable or current_state == BossState.DEFEATED:
		return
		
	current_health -= 1
	
	# Move the evil spirit mesh to reveal more of the lover
	var reveal_tween = create_tween()
	var new_position = bad_mesh.position
	new_position.x -= reveal_distance
	reveal_tween.tween_property(bad_mesh, "position", new_position, 0.3)
	reveal_tween.set_trans(Tween.TRANS_BACK)
	reveal_tween.set_ease(Tween.EASE_OUT)
	
	# Knockback effect
	var knockback_tween = create_tween()
	var knockback_pos = global_position + -transform.basis.z * 3.0
	knockback_tween.tween_property(self, "global_position", knockback_pos, 0.15)
	knockback_tween.tween_property(self, "global_position", global_position, 0.25)
	
	if current_health <= 0:
		_change_state(BossState.DEFEATED)
		defeat()
	else:
		_change_state(BossState.STUNNED)
		_play_hurt_animation()

func defeat() -> void:
	# Just change to defeated state, all animation handled there
	_change_state(BossState.DEFEATED)

func shoot_energy_ball() -> void:
	if current_energy_ball != null:
		return
	
	volley_count = 0
	current_ball_speed = energy_ball_speed + (volley_count * 2.0)
	print("shoot: " + str(current_ball_speed))
	print("Volley: " + str(volley_count))
	current_energy_ball = ENERGY_BALL_SCENE.instantiate()
	level_loader.add_child(current_energy_ball)
	current_energy_ball.set_deferred("boss", self)
	
	# Spawn ball slightly in front of boss
	current_energy_ball.global_position = global_position + -transform.basis.z * 2.0
	
	# Launch with just speed - direction is handled by energy ball
	current_energy_ball.launch(current_ball_speed)
	
	# Shooting effect
	var shoot_tween = create_tween()
	shoot_tween.tween_property(bad_mesh, "scale", Vector3.ONE * 1.2, 0.1)
	shoot_tween.tween_property(bad_mesh, "scale", Vector3.ONE, 0.1)
	
func _on_energy_ball_reflected() -> bool:
	volley_count += 1
	
	# Decide if boss reflects
	if randf() < reflect_chance:
		# Boss succeeds reflection
		current_ball_speed *= speed_increase
		if current_ball_speed > max_speed:
			current_ball_speed = max_speed
		print(current_ball_speed)
		return true
	else:
		# Boss fails reflection
		is_vulnerable = true
		return false
		
func _on_energy_ball_hit_boss() -> void:
	if is_vulnerable:
		hurt()
	_cleanup_energy_ball()

func _on_energy_ball_missed() -> void:
	_cleanup_energy_ball()
	_change_state(BossState.LAUGHING)
	volley_count = 0  # Reset volley count

func _on_energy_ball_hit_player() -> void:
	# Reset volley count since sequence is over
	volley_count = 0
	
	# Cleanup current energy ball
	_cleanup_energy_ball()
	
	# Optional: Add a brief pause before next attack
	await get_tree().create_timer(1.0).timeout
	
	# Return to floating state to start new attack sequence
	_change_state(BossState.FLOATING)

func _cleanup_energy_ball() -> void:
	if current_energy_ball:
		current_energy_ball.queue_free()
		current_energy_ball = null
	is_vulnerable = false


func _play_hurt_animation() -> void:
	# Flash using scale instead of modulate
	var flash_tween = create_tween()
	flash_tween.tween_property(bad_mesh, "scale", Vector3.ONE * 1.2, 0.1)
	flash_tween.tween_property(bad_mesh, "scale", Vector3.ONE * 0.8, 0.1)
	flash_tween.tween_property(bad_mesh, "scale", Vector3.ONE, 0.1)

func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body == player and current_state != BossState.DEFEATED:
		# Could add player damage here if touching boss
		pass

func _on_area_entered(area: Area3D) -> void:
	if area == current_energy_ball:
		_on_energy_ball_hit_boss()
