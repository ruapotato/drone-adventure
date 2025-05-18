extends Node3D

@onready var left_leg = null
@onready var right_leg = null
@onready var sound_on_foot_hit = preload("res://audio/player_toe_tip.wav")

# Regular leg dimensions
const REGULAR_LEG_SPEED = 25.0
const REGULAR_MAX_ANGLE = PI/10
const REGULAR_LEG_LENGTH = 0.4
const REGULAR_LEG_RADIUS = 0.03
const REGULAR_FOOT_LENGTH = 0.15

# Chicken leg dimensions
const CHICKEN_LEG_SPEED = 35.0
const CHICKEN_MAX_ANGLE = PI/8
const CHICKEN_LEG_LENGTH = 0.1
const CHICKEN_LEG_RADIUS = 0.015
const CHICKEN_TOE_LENGTH = 0.06
const CHICKEN_TOE_RADIUS = 0.008

# Dynamic properties based on type
var LEG_SPEED: float
var MAX_ANGLE: float
var LEG_LENGTH: float
const RESET_SPEED = 5.0
const SOUND_THRESHOLD = 0.95
const SOUND_COOLDOWN_TIME: float = 0.1

var time: float = 0.0
var current_speed: float = 0.0
var gravity_inverted: bool = false
var target_rotation = Vector3.ZERO
var level_loader
var player
var cam_arm
var chicken
var is_chicken = false

# Track previous angles for sound triggering
var prev_left_angle: float = 0.0
var prev_right_angle: float = 0.0
var sound_cooldown: float = 0.0


func _ready():
	if name == "chicken_legs":
		is_chicken = true
		# Set chicken dimensions
		LEG_SPEED = CHICKEN_LEG_SPEED
		MAX_ANGLE = CHICKEN_MAX_ANGLE
		LEG_LENGTH = CHICKEN_LEG_LENGTH
	else:
		# Set regular dimensions
		LEG_SPEED = REGULAR_LEG_SPEED
		MAX_ANGLE = REGULAR_MAX_ANGLE
		LEG_LENGTH = REGULAR_LEG_LENGTH
	
	level_loader = find_root()
	chicken = level_loader.find_child("chicken_spirit")
	player = level_loader.find_child("player")
	cam_arm = player.find_child("SpringArm3D")
	
	if !left_leg:
		left_leg = create_leg_mesh("left_leg", -0.1 if !is_chicken else -0.05)
	if !right_leg:
		right_leg = create_leg_mesh("right_leg", 0.1 if !is_chicken else 0.05)
	
	cam_arm.add_excluded_object(self)

func create_chicken_foot(parent: Node3D):
	# Create the chicken foot root node
	var foot = Node3D.new()
	foot.name = "foot"
	
	# Create yellow-orange material for chicken feet
	var chicken_material = StandardMaterial3D.new()
	chicken_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	chicken_material.albedo_color = Color(0.95, 0.65, 0.0)  # Yellow-orange color
	
	# Create three toes
	# Back toe
	var back_toe = create_toe(Vector3(0, 0, -CHICKEN_TOE_LENGTH), PI, chicken_material)
	foot.add_child(back_toe)
	
	# Left toe (angled backward)
	var left_toe = create_toe(Vector3(-CHICKEN_TOE_LENGTH * 0.7, 0, -CHICKEN_TOE_LENGTH * 0.7), PI + PI/4, chicken_material)
	foot.add_child(left_toe)
	
	# Right toe (angled backward)
	var right_toe = create_toe(Vector3(CHICKEN_TOE_LENGTH * 0.7, 0, -CHICKEN_TOE_LENGTH * 0.7), PI - PI/4, chicken_material)
	foot.add_child(right_toe)
	
	# Position the foot at the bottom of the leg
	foot.position = Vector3(0, -LEG_LENGTH, 0)
	parent.add_child(foot)

func create_toe(offset: Vector3, angle: float, material: Material) -> MeshInstance3D:
	var toe = MeshInstance3D.new()
	
	# Create toe mesh
	var toe_mesh = CapsuleMesh.new()
	toe_mesh.radius = CHICKEN_TOE_RADIUS
	toe_mesh.height = CHICKEN_TOE_LENGTH
	
	toe.mesh = toe_mesh
	toe.material_override = material
	
	# Position and rotate the toe
	toe.rotation.y = angle
	toe.position = offset * 0.5  # Offset from center
	toe.rotation.x = PI/2  # Point forward
	
	return toe

func create_leg_mesh(name: String, offset: float) -> Node3D:
	var root = Node3D.new()
	root.name = name
	add_child(root)
	
	root.position = Vector3(offset, 0, 0)
	
	# Create the leg mesh
	var leg = MeshInstance3D.new()
	leg.name = "mesh"
	
	var capsule = CapsuleMesh.new()
	capsule.radius = CHICKEN_LEG_RADIUS if is_chicken else REGULAR_LEG_RADIUS
	capsule.height = LEG_LENGTH
	leg.mesh = capsule
	
	# Material for the leg
	var leg_material = StandardMaterial3D.new()
	leg_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	if is_chicken:
		leg_material.albedo_color = Color(0.8, 0.6, 0.0)  # Slightly darker yellow for legs
	else:
		leg_material.albedo_color = Color.BLACK
	
	leg.material_override = leg_material
	leg.position = Vector3(0, -LEG_LENGTH/2, 0)
	root.add_child(leg)
	
	# Create appropriate foot based on type
	if is_chicken:
		create_chicken_foot(root)
	else:
		# Original foot code for regular legs
		var foot = MeshInstance3D.new()
		foot.name = "foot"
		var foot_capsule = CapsuleMesh.new()
		foot_capsule.radius = REGULAR_LEG_RADIUS
		foot_capsule.height = REGULAR_FOOT_LENGTH
		foot.mesh = foot_capsule
		foot.material_override = leg_material
		foot.position = Vector3(0, -LEG_LENGTH, -0.05)
		foot.scale = Vector3(1, 1, 0.8)
		foot.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(foot)
	
	# Add audio player
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.name = name + "_audio"
	audio_player.stream = sound_on_foot_hit
	audio_player.unit_size = 2.0 if is_chicken else 3.0
	audio_player.max_distance = 8.0 if is_chicken else 10.0
	audio_player.max_db = -15 if is_chicken else -10
	audio_player.position = Vector3(0, -LEG_LENGTH, 0)
	root.add_child(audio_player)
	
	return root

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null


func play_foot_sound(leg_node: Node3D):
	if sound_cooldown <= 0:
		var audio_player = leg_node.get_node(leg_node.name + "_audio")
		if audio_player and !audio_player.playing:
			audio_player.play()
			sound_cooldown = SOUND_COOLDOWN_TIME

func check_leg_extremes(current_angle: float, prev_angle: float) -> bool:
	# Check if the leg has reached an extreme position (fully up or down)
	var max_threshold = MAX_ANGLE * SOUND_THRESHOLD
	var min_threshold = -MAX_ANGLE * SOUND_THRESHOLD
	
	# Check if we've crossed either the upper or lower threshold
	var crossed_upper = prev_angle < max_threshold and current_angle >= max_threshold
	var crossed_lower = prev_angle > min_threshold and current_angle <= min_threshold
	
	return crossed_upper or crossed_lower

func animate_legs(delta: float, speed: float):
	# Update sound cooldown
	sound_cooldown = max(0, sound_cooldown - delta)
	
	time += delta * LEG_SPEED * speed
	
	# Smoothly adjust animation speed based on movement speed
	current_speed = lerp(current_speed, speed, delta * 5.0)
	
	if current_speed > 0.02:
		# Walking animation
		# Left leg swing
		var left_phase = time
		# Right leg swing (offset by PI radians = 180 degrees)
		var right_phase = time + PI
		
		# Calculate angles with opposite phases
		var left_angle = sin(left_phase) * MAX_ANGLE
		var right_angle = sin(right_phase) * MAX_ANGLE
		
		# Rotate around X axis for forward/backward motion
		# When gravity is inverted, we need to invert the rotation angle
		var rotation_multiplier = -1.0 if gravity_inverted else 1.0
		left_leg.rotation = Vector3(left_angle * rotation_multiplier, 0, 0)
		right_leg.rotation = Vector3(right_angle * rotation_multiplier, 0, 0)
		
		# Check each leg separately for sound triggering
		if check_leg_extremes(left_angle, prev_left_angle):
			play_foot_sound(left_leg)
		if check_leg_extremes(right_angle, prev_right_angle):
			play_foot_sound(right_leg)
		
		# Update previous angles
		prev_left_angle = left_angle
		prev_right_angle = right_angle
		
	else:
		# Return legs to neutral position when not moving
		# Use exponential interpolation for smoother transition
		left_leg.rotation = left_leg.rotation.lerp(Vector3.ZERO, delta * RESET_SPEED)
		right_leg.rotation = right_leg.rotation.lerp(Vector3.ZERO, delta * RESET_SPEED)
		
		# Reset the time and previous angles when stopped
		time = 0.0
		prev_left_angle = 0.0
		prev_right_angle = 0.0

func flip_gravity():
	gravity_inverted = !gravity_inverted
	
	for leg in [left_leg, right_leg]:
		var mesh = leg.get_node("mesh")
		
		# When gravity is flipped, we want to:
		# 1. Keep the pivot at the top of the leg (where it connects to the body)
		# 2. Rotate the leg 180 degrees to point in the right direction
		if gravity_inverted:
			# Keep pivot at top, just rotate the mesh 180 degrees
			mesh.rotation = Vector3(PI, 0, 0)
			# Keep the mesh position relative to the pivot point
			mesh.position.y = -LEG_LENGTH/2
		else:
			# Return to normal orientation
			mesh.rotation = Vector3.ZERO
			mesh.position.y = -LEG_LENGTH/2
