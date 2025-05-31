extends Node3D

@onready var collision_shape = $RigidBody3D/CollisionShape3D

const SHIELD_CARRY = 66.6
const SHIELD_ACTIVE = 0.0
const SHIELD_BACK = 180.0

# Much faster rotation speed for more immediate response
const ROTATION_SPEED: float = 25.0

var current_angle: float = SHIELD_CARRY
var target_angle: float = SHIELD_CARRY

var level_loader
var player
var target

func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	target = player.find_child("left_arm").find_child("target")
	rotation.y = deg_to_rad(SHIELD_CARRY)

func _process(delta: float) -> void:
	# More immediate rotation with faster interpolation
	current_angle = move_toward(current_angle, target_angle, delta * ROTATION_SPEED * 45.0)
	rotation.y = deg_to_rad(current_angle)
	hold_me()


func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "world":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

func hold_me():
	target.global_position = collision_shape.global_position

func stow() -> void:
	target_angle = SHIELD_BACK
	print("Shield: Stowing ", current_angle, " -> ", target_angle)

func shield() -> void:
	target_angle = SHIELD_ACTIVE
	print("Shield: Blocking ", current_angle, " -> ", target_angle)

func equip() -> void:
	target_angle = SHIELD_CARRY
	print("Shield: Equipping ", current_angle, " -> ", target_angle)
