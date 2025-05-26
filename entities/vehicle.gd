extends VehicleBody3D

@onready var camera = $play_as/Camera3D
@onready var mount = $play_as/mount

# Removed: var start_time = 1
var init_angle = null
var crashed = false
var beeing_helped = false
var tp_cooldown = 0.0 # Initialize to 0.0
var time_to_live_crashed = 60
var drone
var world
var play_as = false

# New variables for player control and stuck detection
var stuck_timer = 0.0
var stuck_threshold = 2.0 # Seconds before 'stuck' triggers a crash
var min_stuck_velocity = 0.5 # Velocity threshold for being stuck
var max_engine_force = 150.0 # Increased for better control feel (adjust as needed)
var max_steering = 0.6 # Max steering angle (adjust as needed)
var max_brake_force = 10.0 # Added brake force

# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	world = drone.get_parent()

func get_drone():
	var root_i_hope = get_parent()
	# Safer loop: Check if get_parent() returns null
	while root_i_hope and root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	if root_i_hope:
		return root_i_hope.find_child("drone")
	else:
		print("Error: Could not find 'world' node.")
		return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Handle cooldown
	if tp_cooldown > 0:
		tp_cooldown -= delta

	# --- Process if already crashed ---
	if crashed:
		process_crashed_state(delta)
		return # Stop further processing if crashed

	# --- Check for NEW crash conditions ---
	# Setup init angle if not set
	if not play_as:
		if not init_angle:
			init_angle = global_rotation
		# Rotation crash
		if (init_angle - global_rotation).length() > .5:
			crashed = true
			print("CRASH - ROTATION!!!")
			process_crashed_state(delta) # Process immediately
			return

	# --- Handle Movement & Control ---
	if play_as:
		handle_player_input(delta)
		drone.global_position = mount.global_position

		# Stuck crash detection (only if player is trying to move forward)
		var forward_input = Input.get_action_strength("move_forward")
		if forward_input > 0.1 and linear_velocity.length() < min_stuck_velocity:
			stuck_timer += delta
			if stuck_timer > stuck_threshold:
				crashed = true
				print("CRASH - STUCK!!!")
				process_crashed_state(delta) # Process immediately
				return
		else:
			stuck_timer = 0.0 # Reset timer
	else:
		# Default behavior (AI/Scripted) - If not crashed and not controlled
		engine_force = 100.0 # Original AI force
		steering = 0.0
		brake = 0.0

# Handles player input for vehicle control
func handle_player_input(delta):
	var forward = Input.get_action_strength("move_forward")
	var backward = Input.get_action_strength("move_backward")
	var left = Input.get_action_strength("strafe_right")
	var right = Input.get_action_strength("strafe_left")
	#var handbrake = Input.get_action_strength("handbrake") # Assuming a "handbrake" input

	# Steering: Smoothly interpolate steering for better feel
	var target_steering = (right - left) * max_steering
	steering = lerp(steering, target_steering, 5.0 * delta) # Adjust 15.0 for responsiveness

	# Engine & Brake
	if forward > 0.1:
		engine_force = forward * max_engine_force
		brake = 0.0
	elif backward > 0.1:
		# Apply brakes if moving forward, reverse if stopped/moving backward
		if linear_velocity.dot(global_transform.basis.z) > 0.1:
			brake = backward * max_brake_force * 2.0 # Stronger brake when reversing intent
			engine_force = 0.0
		else:
			engine_force = -backward * max_engine_force * 0.5 # Slower reverse speed
			brake = 0.0
	else:
		engine_force = 0.0
		brake = max_brake_force * 0.1 # Gentle brake when no input

	# Handbrake (overrides normal brake)
	#if handbrake > 0.1:
	#	brake = max_brake_force * 5.0 # Strong handbrake


# Handles logic when the vehicle is in a crashed state
func process_crashed_state(delta):
	engine_force = 0.0
	steering = 0.0
	brake = max_brake_force # Apply full brakes when crashed

	if play_as:
		# Eject player
		if drone:
			drone.active = true
			drone.camera.current = true
		camera.current = false # Deactivate car camera
		play_as = false

	time_to_live_crashed -= delta
	if time_to_live_crashed < 0:
		queue_free()

	if not $expload_effect.emitting:
		$eng_sounds.stream = load("res://import/Audio/spaceEngineLarge_000.ogg")
		$eng_sounds.play()
		$expload_effect.emitting = true


func _on_eng_sounds_finished():
	if crashed: # Only loop if still crashed
		$eng_sounds.play()


func _on_play_as_body_entered(body: Node3D) -> void:
	if body == drone and not crashed: # Only allow entry if not crashed
		drone.active = false
		camera.current = true
		play_as = true
		stuck_timer = 0.0 # Reset stuck timer on entry
		# Reset engine/steering when player takes over
		engine_force = 0.0
		steering = 0.0
		brake = 0.0
