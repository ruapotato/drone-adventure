extends Area3D

@onready var coin_sound = $coin_sound
var level_loader
var player
var is_collecting = false
var initial_scale
var initial_position
var target_position
const FLOAT_DISTANCE = 2.0  # How far the coin floats away
const SHRINK_SPEED = 2.0    # How fast the coin shrinks

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	initial_scale = scale
	
func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_collecting:
		# Shrink the coin
		var target_scale = initial_scale * 0.5  # 50% of original size
		scale = scale.lerp(target_scale, delta * SHRINK_SPEED)
		
		# Move away from player
		var direction = (global_position - player.global_position).normalized()
		var target_pos = initial_position + direction * FLOAT_DISTANCE
		global_position = global_position.lerp(target_pos, delta * SHRINK_SPEED)
		
		# Keep rotating while collecting
		rotate_y(delta)
	elif visible:
		rotate_y(delta)
		if player in get_overlapping_bodies():
			start_collection()

func start_collection() -> void:
	is_collecting = true
	initial_position = global_position
	coin_sound.play()
	level_loader.add_clover(5)
	
	# Connect to the finished signal if not already connected
	if not coin_sound.finished.is_connected(self._on_sound_finished):
		coin_sound.finished.connect(self._on_sound_finished)

func _on_sound_finished() -> void:
	queue_free()
