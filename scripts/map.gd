extends Node2D

@onready var player_onmap_pos = $player_pos

var map_scale = .015
var world
var player
var chicken

func _ready() -> void:
	world = get_parent()
	# It's generally safer to check if find_child returned a valid node
	# but per your instructions, we'll assume they exist.
	player = world.find_child("player")
	chicken = world.find_child("chicken")


func get_camera_transform_2d() -> Dictionary:
	var camera_3d = get_viewport().get_camera_3d()
	var camera_3d_global_transform: Transform3D = camera_3d.global_transform

	# Position on the XZ plane
	var pos_2d = Vector2(camera_3d_global_transform.origin.x, camera_3d_global_transform.origin.z)

	# Get the forward vector of the camera in global space
	var forward_vector_3d = -camera_3d_global_transform.basis.z
	# Calculate the angle of this vector on the XZ plane
	# atan2 usually takes (y, x), so for XZ plane with Z as "forward" in 3D mapping to "up" or "forward" in 2D:
	# If you want 0 degrees to be +X and 90 degrees to be +Z:
	# var angle_2d = atan2(forward_vector_3d.z, forward_vector_3d.x)
	# If you want 0 degrees to be +Z (forward) and 90 degrees to be +X (right):
	var angle_2d = atan2(forward_vector_3d.x, forward_vector_3d.z)
	# Godot's 2D rotation is typically such that 0 is along the positive X-axis.
	# If -Z in 3D (forward) should map to +Y in 2D (up), you might need to adjust.
	# For now, let's stick to the angle of the projection on the XZ plane.

	return {"position": pos_2d, "rotation": angle_2d}

func update_map_pos():
	var cam_transform_2d = get_camera_transform_2d()
	player_onmap_pos.position = cam_transform_2d.position * map_scale
	player_onmap_pos.rotation = cam_transform_2d.rotation
	# If your map icon points "up" by default (along its local -Y axis in Godot 2D)
	# and you want it to align with the camera's forward direction which we calculated
	# relative to the global +Z axis (or +X depending on atan2 variant), you might need an offset.
	# For example, if the icon points upwards (negative Y) and 0 rotation is right (positive X):
	# player_onmap_pos.rotation = cam_transform_2d.rotation + PI/2


func _process(delta: float) -> void:
	update_map_pos()
