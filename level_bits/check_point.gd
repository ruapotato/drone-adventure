extends Area3D

var level_loader
var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")


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
	if player in get_overlapping_bodies():
		player.save_check_point(global_position)
