extends Node3D

var drone
var player

func _ready():
	#$MeshInstance3D.get_active_material(0).albedo_texture.noise.offset.x = 300
	#$MeshInstance3D.get_active_material(0).albedo_texture.noise.offset.z = 300
	player = get_player()
	drone = get_drone()

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))


func _process(delta):
	if global_position.distance_to(drone.global_position) > 100:
		global_position.x = drone.global_position.x
		global_position.z = drone.global_position.z
		
		#$MeshInstance3D.get_active_material(0).albedo_texture.noise.offset.x = 300 + (drone.global_position.x * 3)
		#$MeshInstance3D.get_active_material(0).albedo_texture.noise.offset.y = 300 +(drone.global_position.z *3 )
