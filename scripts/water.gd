extends Node3D

var drone
var world

func _ready():
	drone = get_drone()
	world = drone.get_parent()
	
func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func _process(delta: float) -> void:
	global_position.x = drone.global_position.x
	global_position.z = drone.global_position.z
