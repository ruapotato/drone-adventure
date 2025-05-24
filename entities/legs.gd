extends Node3D

@onready var left_leg_node: Node3D = null
@onready var right_leg_node: Node3D = null

# sound_on_foot_hit path needs to be valid.
@onready var sound_on_foot_hit = preload("res://audio/player_toe_tip.wav") if FileAccess.file_exists("res://audio/player_toe_tip.wav") else null


# Regular leg dimensions
const REGULAR_LEG_SPEED = 25.0
const REGULAR_MAX_ANGLE = PI/10
const REGULAR_LEG_LENGTH = 0.4
const REGULAR_LEG_RADIUS = 0.03
const REGULAR_FOOT_LENGTH = 0.15

# Chicken leg dimensions
const CHICKEN_LEG_SPEED = 35.0
const CHICKEN_MAX_ANGLE = PI/8 # Slightly larger swing for chicken
const CHICKEN_LEG_LENGTH = 0.1 # Shorter legs for drone
const CHICKEN_LEG_RADIUS = 0.015
const CHICKEN_TOE_LENGTH = 0.06
const CHICKEN_TOE_RADIUS = 0.008

# Dynamic properties based on type
var LEG_SPEED: float = CHICKEN_LEG_SPEED # Default to chicken
var MAX_ANGLE: float = CHICKEN_MAX_ANGLE # Default to chicken
var CURRENT_LEG_LENGTH: float = CHICKEN_LEG_LENGTH # Default to chicken

const RESET_SPEED = 5.0
const SOUND_THRESHOLD = 0.95 # Play sound when leg reaches 95% of max swing
const SOUND_COOLDOWN_TIME: float = 0.1 # Min time between footstep sounds

var time: float = 0.0
var current_speed: float = 0.0 # For animation lerping, based on drone's actual speed
var gravity_inverted: bool = false # Assume not used unless explicitly set by drone
var is_chicken: bool = true # Assume chicken legs by default if attached to drone

# Track previous angles for sound triggering
var prev_left_angle: float = 0.0
var prev_right_angle: float = 0.0
var sound_cooldown: float = 0.0

var drone: RigidBody3D # Reference to the drone RigidBody3D

func _ready():
	drone = get_parent() as RigidBody3D
	if not drone:
		print("Legs.gd is not a child of a RigidBody3D (the drone) or type cast failed!")

	if name == "chicken_legs":
		is_chicken = true
	else: # Default or other names
		is_chicken = true # Or false, based on your preference for unnamed leg nodes

	if is_chicken:
		LEG_SPEED = CHICKEN_LEG_SPEED
		MAX_ANGLE = CHICKEN_MAX_ANGLE
		CURRENT_LEG_LENGTH = CHICKEN_LEG_LENGTH
	else: # Regular legs
		LEG_SPEED = REGULAR_LEG_SPEED
		MAX_ANGLE = REGULAR_MAX_ANGLE
		CURRENT_LEG_LENGTH = REGULAR_LEG_LENGTH
	
	if !left_leg_node:
		left_leg_node = create_leg_mesh("left_leg", -0.1 if !is_chicken else -0.05)
	if !right_leg_node:
		right_leg_node = create_leg_mesh("right_leg", 0.1 if !is_chicken else 0.05)

	if sound_on_foot_hit == null:
		print("Footstep sound not loaded. Check path: res://audio/player_toe_tip.wav")


func create_chicken_foot(parent_leg_root: Node3D):
	var foot_root = Node3D.new()
	foot_root.name = "foot"
	
	var chicken_material = StandardMaterial3D.new()
	chicken_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	chicken_material.albedo_color = Color(0.95, 0.65, 0.0) # Yellow-orange
	
	var toe_mesh_def = CapsuleMesh.new()
	toe_mesh_def.radius = CHICKEN_TOE_RADIUS
	toe_mesh_def.height = CHICKEN_TOE_LENGTH

	# Back Toe (points backward)
	var back_toe = MeshInstance3D.new()
	back_toe.mesh = toe_mesh_def
	back_toe.material_override = chicken_material
	# Capsule is Y-aligned. Rotate PI/2 around X to lay flat.
	# With 0 Y-rotation, it points backward (local +Z after X-rotation).
	back_toe.transform.basis = Basis.from_euler(Vector3(PI/2, 0, 0)) 
	back_toe.position = Vector3(0, 0, CHICKEN_TOE_LENGTH * 0.4) # Offset backward
	foot_root.add_child(back_toe)
	
	# Left Toe (points forward-left)
	var left_toe = MeshInstance3D.new()
	left_toe.mesh = toe_mesh_def
	left_toe.material_override = chicken_material
	# Rotate PI/2 around X to lay flat, then -3*PI/4 around Y to point forward-left.
	left_toe.transform.basis = Basis.from_euler(Vector3(PI/2, -3*PI/4, 0)) 
	left_toe.position = Vector3(-CHICKEN_TOE_LENGTH * 0.35, 0, -CHICKEN_TOE_LENGTH * 0.3) # Offset
	foot_root.add_child(left_toe)
	
	# Right Toe (points forward-right)
	var right_toe = MeshInstance3D.new()
	right_toe.mesh = toe_mesh_def
	right_toe.material_override = chicken_material
	# Rotate PI/2 around X to lay flat, then 3*PI/4 around Y to point forward-right.
	right_toe.transform.basis = Basis.from_euler(Vector3(PI/2, 3*PI/4, 0)) 
	right_toe.position = Vector3(CHICKEN_TOE_LENGTH * 0.35, 0, -CHICKEN_TOE_LENGTH * 0.3) # Offset
	foot_root.add_child(right_toe)
	
	foot_root.position = Vector3(0, -CURRENT_LEG_LENGTH, 0)
	parent_leg_root.add_child(foot_root)


func create_leg_mesh(new_leg_name: String, x_offset: float) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.name = new_leg_name
	add_child(leg_root)
	
	leg_root.position = Vector3(x_offset, 0, 0)
	
	var leg_mesh_node = MeshInstance3D.new()
	leg_mesh_node.name = "mesh"
	
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = CHICKEN_LEG_RADIUS if is_chicken else REGULAR_LEG_RADIUS
	capsule_mesh.height = CURRENT_LEG_LENGTH
	leg_mesh_node.mesh = capsule_mesh
	
	var leg_material = StandardMaterial3D.new()
	leg_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	if is_chicken:
		leg_material.albedo_color = Color(0.8, 0.6, 0.0)
	else:
		leg_material.albedo_color = Color.BLACK
	leg_mesh_node.material_override = leg_material
	
	leg_mesh_node.position = Vector3(0, -CURRENT_LEG_LENGTH / 2.0, 0)
	leg_root.add_child(leg_mesh_node)
	
	if is_chicken:
		create_chicken_foot(leg_root)
	else:
		var foot_node = MeshInstance3D.new()
		foot_node.name = "foot"
		var foot_capsule = CapsuleMesh.new()
		foot_capsule.radius = REGULAR_LEG_RADIUS
		foot_capsule.height = REGULAR_FOOT_LENGTH
		foot_node.mesh = foot_capsule
		foot_node.material_override = leg_material
		foot_node.position = Vector3(0, -CURRENT_LEG_LENGTH, -0.05)
		foot_node.rotation_degrees = Vector3(90, 0, 0)
		leg_root.add_child(foot_node)
	
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.name = new_leg_name + "_audio"
	audio_player.stream = sound_on_foot_hit
	if sound_on_foot_hit:
		audio_player.unit_size = 2.0 if is_chicken else 3.0
		audio_player.max_distance = 8.0 if is_chicken else 10.0
		# audio_player.bus = "SFX" 
	audio_player.position = Vector3(0, -CURRENT_LEG_LENGTH, 0)
	leg_root.add_child(audio_player)
	
	return leg_root


func play_foot_sound(leg_node_to_play: Node3D):
	if sound_cooldown <= 0 and sound_on_foot_hit:
		var audio_player_path = NodePath(leg_node_to_play.name + "_audio")
		var audio_player = leg_node_to_play.get_node_or_null(audio_player_path) as AudioStreamPlayer3D # Safer get
		if audio_player and not audio_player.playing:
			audio_player.play()
			sound_cooldown = SOUND_COOLDOWN_TIME

func check_leg_extremes(current_angle_rad: float, prev_angle_rad: float) -> bool:
	var max_thresh_rad = MAX_ANGLE * SOUND_THRESHOLD
	var min_thresh_rad = -MAX_ANGLE * SOUND_THRESHOLD
	
	var crossed_upper = prev_angle_rad < max_thresh_rad and current_angle_rad >= max_thresh_rad
	var crossed_lower = prev_angle_rad > min_thresh_rad and current_angle_rad <= min_thresh_rad
	
	return crossed_upper or crossed_lower

func animate_legs(delta: float, speed_from_drone: float):
	if not left_leg_node or not right_leg_node: return

	sound_cooldown = max(0, sound_cooldown - delta)
	
	time += delta * LEG_SPEED * clamp(speed_from_drone, 0.0, 2.0)
	
	current_speed = lerp(current_speed, speed_from_drone, delta * 5.0)
	
	if current_speed > 0.02:
		var left_phase = time
		var right_phase = time + PI
		
		var left_angle_rad = sin(left_phase) * MAX_ANGLE
		var right_angle_rad = sin(right_phase) * MAX_ANGLE
		
		var rotation_multiplier = -1.0 if gravity_inverted else 1.0
		
		left_leg_node.rotation.x = left_angle_rad * rotation_multiplier
		right_leg_node.rotation.x = right_angle_rad * rotation_multiplier
		
		if check_leg_extremes(left_angle_rad, prev_left_angle):
			play_foot_sound(left_leg_node)
		if check_leg_extremes(right_angle_rad, prev_right_angle):
			play_foot_sound(right_leg_node)
		
		prev_left_angle = left_angle_rad
		prev_right_angle = right_angle_rad
	else:
		left_leg_node.rotation.x = lerp(left_leg_node.rotation.x, 0.0, delta * RESET_SPEED)
		right_leg_node.rotation.x = lerp(right_leg_node.rotation.x, 0.0, delta * RESET_SPEED)
		if abs(left_leg_node.rotation.x) < 0.01 :
			time = 0.0
			prev_left_angle = 0.0
			prev_right_angle = 0.0


func flip_gravity():
	gravity_inverted = !gravity_inverted
	
	for leg_node_to_flip in [left_leg_node, right_leg_node]:
		if leg_node_to_flip:
			var mesh_node = leg_node_to_flip.get_node_or_null("mesh") as MeshInstance3D # Safer get
			if mesh_node:
				if gravity_inverted:
					mesh_node.rotation.x = PI
				else:
					mesh_node.rotation.x = 0.0
