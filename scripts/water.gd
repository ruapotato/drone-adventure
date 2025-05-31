extends Node3D

var chicken
var world

func _ready():
	chicken = get_chicken()
	world = chicken.get_parent()
	
func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

func _process(delta: float) -> void:
	global_position.x = chicken.global_position.x
	global_position.z = chicken.global_position.z
