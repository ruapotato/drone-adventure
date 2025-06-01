extends Node3D

@onready var door0_mesh = $Door0
@onready var door1_mesh = $Door1
@onready var door2_mesh = $Door2
@onready var door3_mesh = $Door3
@onready var door4_mesh = $Door4
@onready var door5_mesh = $Door5
@onready var door6_mesh = $Door6
@onready var door7_mesh = $Door7
var doors

var level_loader
var player
var level_to_load
var keys_needed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	keys_needed = int(name.split("_")[0])
	level_to_load = name.split("_")[-1]
	doors = [door0_mesh,door1_mesh,door2_mesh,door3_mesh,door4_mesh,door5_mesh,door6_mesh,door7_mesh]
	for door in doors:
		door.hide()
	
	doors[keys_needed].show()


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
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		if keys_needed <= level_loader.get_key_count():
			level_loader.load_level(level_to_load)
	
