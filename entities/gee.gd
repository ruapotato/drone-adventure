extends RigidBody3D

@onready var crap = preload("res://entities/crap.tscn")
@onready var fart_sound = $fart_sound
@onready var crap_hole = $crap_hole
# Make sure this path is correct for your scene!
@onready var camera = $piv/SpringArm3D/Camera3D
@onready var mount = $play_as/mount
@onready var play_as_mesh = $play_as/play_as_mesh

# --- Control & Physics Parameters ---
@export var mouse_sensitivity = 0.004
@export var fart_power = 50.0
@export var yaw_speed = 3.0
@export var max_rot_pitch = PI / 2.0
@export var max_rot_roll = PI / 2.0

var active = false
var gass = 100.0
var gass_use_rate = 10.0

# --- Crap Parameters ---
var crap_every = 0.05
var crap_timer = crap_every

# --- Input State ---
var _look_input = Vector2.ZERO
var _current_pitch = 0.0
var _current_roll = 0.0
var _current_yaw = 0.0

# --- World Ref ---
var world
var drone
var beans_found = 0

func _ready():
	world = get_parent()
	drone = world.find_child("drone")
	fart_sound.play()
	fart_sound.volume_db = -80.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gravity_scale = 1.0
	print("Fart Copter M&K Ready!")
	print("Use Mouse for Pitch/Roll, A/D for Yaw, Space/W for Thrust.")
	print("Press Esc to release mouse.")

func _input(event):
	if active and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_look_input = event.relative


func _physics_process(delta):
	if not active:
		# Slow down and stop when inactive
		linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 2.0)
		angular_velocity = Vector3.ZERO
		fart_sound.volume_db = lerp(fart_sound.volume_db, -80.0, delta * 5)
		return
	
	if active:
		drone.global_position = mount.global_position

	# --- 1. Rotation Logic (M&K - Direct Set) ---
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_current_pitch += _look_input.y * mouse_sensitivity
		_current_roll += -_look_input.x * mouse_sensitivity
		_look_input = Vector2.ZERO

	_current_pitch = clamp(_current_pitch, -max_rot_pitch, max_rot_pitch)
	_current_roll = clamp(_current_roll, -max_rot_roll, max_rot_roll)
	var yaw_input = Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")
	_current_yaw -= yaw_input * yaw_speed * delta

	rotation = Vector3(_current_pitch, _current_yaw, _current_roll)
	angular_velocity = Vector3.ZERO

	# --- 2. Fart / Thrust Logic (M&K) ---
	var apply_thrust = Input.is_action_pressed("move_up")
	var is_farting = false

	if apply_thrust and gass > 0:
		gass -= delta * gass_use_rate
		crap_timer -= delta
		apply_central_force(global_transform.basis.y * fart_power)
		is_farting = true

	# --- 3. Crap Logic ---
	if is_farting and crap_timer <= 0:
		bend_over(delta)
		crap_timer = crap_every

	# --- 4. Out of Gass Check ---
	# <<< MODIFIED: Added back the call to world.play_as_drone() >>>
	if gass <= 0 and active: # Check 'active' to ensure it only runs once
		print("Out of gass! Switching to drone...")
		#play_as_mesh.visible = true
		drone.active = true
		active = false # Deactivate this controller
		
		#TODO move this to here.
		world.play_as_drone()

		return # Stop processing this frame after switching

	# --- 5. Sound Logic ---
	if is_farting and active:
		fart_sound.volume_db = lerp(fart_sound.volume_db, 0.0, delta * 20)
		fart_sound.pitch_scale = randf_range(0.8, 1.2)
		if not fart_sound.playing:
			fart_sound.play()
	else:
		fart_sound.volume_db = lerp(fart_sound.volume_db, -80.0, delta * 5)

# Spawns 'crap'.
func bend_over(delta):
	var shit = crap.instantiate()
	shit.add_collision_exception_with(self)
	get_parent().add_child(shit)
	shit.apply_impulse((linear_velocity * 0.5) - global_transform.basis.y * 2.0)
	shit.global_position = crap_hole.global_position

# Ensures the fart sound loops.
func _on_fart_sound_finished():
	fart_sound.play()


func _on_play_as_body_entered(body: Node3D) -> void:
	if body == drone and gass != 0:
		play_as_mesh.visible = false
		active = true
		drone.active = false
		camera.current = true
