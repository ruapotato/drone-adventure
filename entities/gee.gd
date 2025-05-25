extends RigidBody3D

@onready var crap = preload("res://entities/crap.tscn")
@onready var fart_sound = $fart_sound
@onready var crap_hole = $crap_hole
@onready var camera = $piv/SpringArm3D/Camera3D
@onready var vox = $piv/SpringArm3D/Camera3D/VoxelViewer

# --- Control & Physics Parameters ---
var active = false
var fart_power = 3000.0 # High value for FORCE - TUNE THIS!
var gass = 100.0
var gass_use_rate = 5.0
var max_rot = PI / 2.0 # 90 degrees tilt
var yaw_speed = 3.0   # How fast it turns left/right - TUNE THIS!

# --- Crap Parameters ---
var crap_every = 0.05
var crap_timer = crap_every

# --- Input State (Variables to hold axis values) ---
var throttle = 0.0
var yaw = 0.0
var pitch = 0.0
var roll = 0.0
var deadzone = 0.15 # Ignore minor stick drift

# --- World Ref ---
var world

var beans_found = 0

# --- Applies a quadratic sensitivity curve ---
func apply_curve(value):
	# This makes the initial stick movement less sensitive
	# and the later movement more sensitive.
	return value * abs(value)

# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_parent()
	fart_sound.play()
	fart_sound.volume_db = -80.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Ready! Press 'ui_accept' (Enter/Gamepad A) to activate.")
	print("--- IMPORTANT ---")
	print("Using 'throttle', 'yaw', 'pitch', 'roll' actions.")
	print("Ensure they are MAPPED CORRECTLY in Project Settings -> Input Map.")
	print("Set RigidBody3D -> Angular -> Damp = 0 in the Inspector!")
	print("---------------")

# Capture Joystick/Controller Input (LIKE THE DRONE SCRIPT)
func _unhandled_input(event):
	if not active:
		return

	# Set axis values based on events
	if event.is_action("throttle"):
		throttle = -event.axis_value # Drone uses - (Up = -1 -> +1)
	if event.is_action("yaw"):
		yaw = -event.axis_value      # Drone uses - (Right = +1 -> -1)
	if event.is_action("pitch"):
		pitch = event.axis_value   # Drone uses + (Up = -1)
	if event.is_action("roll"):
		roll = -event.axis_value     # Drone uses - (Right = +1 -> -1)

	# Handle activation/deactivation
	if event.is_action_pressed("ui_accept"):
		active = !active
		print("Player Active: ", active)
		if active:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			throttle = 0.0; yaw = 0.0; pitch = 0.0; roll = 0.0

# Handle physics-based movement and rotation every physics frame.
func _physics_process(delta):
	if not active:
		linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 2.0)
		angular_velocity = Vector3.ZERO
		return

	# --- Calculate Throttle (0 to 1) ---
	var current_throttle = clampf(throttle, 0.0, 1.0)

	# --- Rotation Logic (Direct Set) ---
	var target_x = 0.0
	var target_z = 0.0

	# 1. Calculate Target Pitch/Roll from Right Stick (WITH CURVE)
	if abs(pitch) > deadzone:
		target_x = pitch * max_rot # Confirmed OK (Up=-1 -> -X_rot (Fwd))
	if abs(roll) > deadzone:
		target_z = apply_curve(roll) * max_rot # <-- FLIPPED (Right=+1 -> -1 -> roll=-1. -1 * max_rot = -Z_rot (Right))

	# 2. Calculate New Yaw from Left Stick (Incrementally) (FIXED)
	var new_y = rotation.y
	if abs(yaw) > deadzone:
		new_y += yaw * yaw_speed * delta # <-- FLIPPED BACK (Right=+1 -> -1 -> yaw=-1. -1 * speed = -Y_rot (Left). This should be Right?)
		# Let's rethink Yaw based on "current script (-yaw) is inverted".
		# If -yaw is inverted, then +yaw should be correct.
		# Yaw comes in as -1 for Right. If we want Right = +Y turn, we need -yaw.
		# If the user says -yaw is inverted, then +yaw MUST be right for their setup.
		# So we use `+yaw`.

	# 3. DIRECTLY SET ROTATION
	rotation = Vector3(target_x, new_y, target_z)
	angular_velocity = Vector3.ZERO

	# --- Fart / Thrust Logic (Using apply_central_FORCE) ---
	if current_throttle > 0.01 and gass > 0:
		gass -= delta * gass_use_rate
		crap_timer -= delta
		apply_central_force(global_transform.basis.y * current_throttle * fart_power)
	if gass <= 0:
		world.play_as_drone()

	# --- Crap Logic ---
	if crap_timer < 0:
		bend_over(delta)
		crap_timer = crap_every

# Handle non-physics updates like sound.
func _process(delta):
	if not active:
		fart_sound.volume_db = lerp(fart_sound.volume_db, -80.0, delta * 5)
		return
	var current_throttle = clampf(throttle, 0.0, 1.0)
	if current_throttle > 0.01 and gass > 0:
		fart_sound.volume_db = lerp(fart_sound.volume_db, 0.0 - (1.0 - current_throttle) * 10, delta * 20)
		fart_sound.pitch_scale = randf_range(0.8, 1.2)
		if not fart_sound.playing:
			fart_sound.play()
	else:
		fart_sound.volume_db = lerp(fart_sound.volume_db, -80.0, delta * 5)

# Spawns 'crap'.
func bend_over(delta):
	var big_fart = false
	if linear_velocity.y < 0: linear_velocity.y = 0; big_fart = true
	if global_transform.basis.y.x < 0 and linear_velocity.x > 0: linear_velocity.x = 0; big_fart = true
	if global_transform.basis.y.x > 0 and linear_velocity.x < 0: linear_velocity.x = 0; big_fart = true
	if global_transform.basis.y.z < 0 and linear_velocity.z > 0: linear_velocity.z = 0; big_fart = true
	if global_transform.basis.y.z > 0 and linear_velocity.z < 0: linear_velocity.z = 0; big_fart = true

	var shit = crap.instantiate()
	shit.add_collision_exception_with(self)
	get_parent().add_child(shit)
	if big_fart:
		shit.scale = 3.0 * Vector3(1,1,1)
	shit.apply_impulse(linear_velocity - global_transform.basis.y)
	shit.global_position = crap_hole.global_position

# Ensures the fart sound loops.
func _on_fart_sound_finished():
	fart_sound.play()
