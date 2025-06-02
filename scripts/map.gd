extends Node2D

# Path to the 3D node in your SubViewport that represents the player/camera on the minimap
@onready var player_onmap_pos: Node3D = $SubViewportContainer/SubViewport/player_pos
# Path to the Camera3D node that views your minimap scene within the SubViewport
@onready var minimap_camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D

var map_scale = 0.15
var world: Node 
var player: Node3D # Reference to the main player node in the game world
var chicken: Node3D # Reference to a chicken node in the game world (example)

# Zoom limits for the minimap camera's Y position
var camera_max_zoom_out: float = 3309.0 # Camera further away (zoomed out)
var camera_min_zoom_in: float = 50.0    # Camera closer (zoomed in) - adjusted from 1 for practical use

# Icon scale properties
var min_icon_scale_at_min_zoom: float = 0.05 # Icon is smaller when camera is zoomed IN (min_zoom_in Y value)
var max_icon_scale_at_max_zoom: float = 1.5 # Icon is bigger when camera is zoomed OUT (max_zoom_out Y value)


func _ready() -> void:
	world = get_parent() # Assuming this Node2D (minimap controller) is a child of the main world root

	# Get references to nodes in the main game world.
	player = world.find_child("player") as Node3D
	chicken = world.find_child("chicken") as Node3D

	# Initialize camera position if needed, e.g., start zoomed out
	if is_instance_valid(minimap_camera):
		minimap_camera.position.y = camera_max_zoom_out 
		# This ensures it starts at a known zoom level, triggering correct initial icon scale.
	
	# Initial update to set correct scale based on starting camera zoom
	update_map_pos()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(minimap_camera):
		return

	var y_change = 0.0
	if event.is_action_pressed("zoom_out"):
		y_change = 33.0
	if event.is_action_pressed("zoom_in"):
		y_change = -33.0

	if y_change != 0.0:
		minimap_camera.position.y += y_change
		# Clamp the camera's Y position to the defined zoom limits
		minimap_camera.position.y = clampf(minimap_camera.position.y, camera_min_zoom_in, camera_max_zoom_out)
		# The scale will be updated in _process via update_map_pos


# Gets the main game world camera's current 2D position (on XZ plane) and Y-axis rotation.
func get_main_camera_transform_for_map() -> Dictionary:
	var main_game_camera: Camera3D = get_viewport().get_camera_3d()
	var main_camera_global_transform: Transform3D = main_game_camera.global_transform
	var pos_2d = Vector2(main_camera_global_transform.origin.x, main_camera_global_transform.origin.z)
	var forward_vector_3d = -main_camera_global_transform.basis.z
	var angle_2d = -atan2(forward_vector_3d.z, forward_vector_3d.x) - (PI/2)
	return {"position": pos_2d, "rotation": angle_2d}


# Updates the position, rotation, and scale of the 3D marker on the minimap.
func update_map_pos() -> void:
	if not is_instance_valid(player_onmap_pos):
		# print_debug("Minimap Error: player_onmap_pos is not valid.") # Optional debug
		return
	if not is_instance_valid(minimap_camera):
		# print_debug("Minimap Error: minimap_camera is not valid.") # Optional debug
		return

	var main_cam_map_transform: Dictionary = get_main_camera_transform_for_map()

	# --- Update player_onmap_pos position ---
	var target_map_x: float = main_cam_map_transform.position.x * map_scale
	var target_map_z: float = main_cam_map_transform.position.y * map_scale 
	var marker_y_in_minimap_scene: float = 0.0
	player_onmap_pos.position = Vector3(target_map_x, marker_y_in_minimap_scene, target_map_z)

	# --- Update player_onmap_pos rotation ---
	var target_map_yaw: float = main_cam_map_transform.rotation
	player_onmap_pos.rotation = Vector3(0.0, target_map_yaw, 0.0)
	
	# --- Update player_onmap_pos scale based on minimap_camera zoom ---
	var current_cam_y = minimap_camera.position.y 
	# current_cam_y is already clamped by _unhandled_input when zoom changes via input.

	var new_scale_factor: float
	var zoom_range = camera_max_zoom_out - camera_min_zoom_in
	
	if zoom_range <= 0.001: # Check for very small or non-positive range to avoid issues
		# If range is negligible, pick one of the scales, e.g., the one for min_zoom
		new_scale_factor = min_icon_scale_at_min_zoom 
	else:
		# Remap camera_y from [min_zoom_y, max_zoom_y] to [min_icon_scale, max_icon_scale]
		new_scale_factor = remap(current_cam_y,
								   camera_min_zoom_in, camera_max_zoom_out,
								   min_icon_scale_at_min_zoom, max_icon_scale_at_max_zoom)
	
	# Clamp the final scale factor to ensure it's within the desired bounds,
	# as remap can extrapolate if current_cam_y somehow goes out of its clamped range
	# (e.g. if set directly by other code).
	new_scale_factor = clampf(new_scale_factor, min_icon_scale_at_min_zoom, max_icon_scale_at_max_zoom)

	player_onmap_pos.scale = Vector3(new_scale_factor,1,new_scale_factor)


func _process(delta: float) -> void:
	update_map_pos()
