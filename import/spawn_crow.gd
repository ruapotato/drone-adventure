extends Node3D
@onready var crow = preload("res://entities/crow.tscn")
@onready var tmp_mesh = $tmp_mesh
var drone
var spawn_range = 80
var spawned = false


func _ready():
	tmp_mesh.hide()
	drone = get_drone()
	
func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(drone.global_position) < spawn_range:
		if not spawned:
			add_child(crow.instantiate())
			spawned = true
