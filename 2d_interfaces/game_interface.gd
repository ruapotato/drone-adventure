extends Node2D

@onready var key_lable = $keys
@onready var clover_lable = $clover

var level_loader
var player
var keys = 0
var clover = 0
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


func update_keys():
	if keys != level_loader.get_key_count():
		keys = level_loader.get_key_count()
		key_lable.text = str(keys)


func update_clover():
	if clover != level_loader.clover:
		clover = level_loader.clover
		clover_lable.text = str(clover)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_keys()
	update_clover()
