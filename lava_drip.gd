extends Node3D
@onready var lava = preload("res://lava_blob.tscn")
#@onready var tmp_mesh = $tmp_mesh
var drone
var spawn_range = 200
var spawn_every
var lava_drop

func _ready():
	#tmp_mesh.hide()
	spawn_every = 1#randi_range(4,10)
	drone = get_drone()
	lava_drop = lava.instantiate()
	add_child(lava_drop)
	var new_size = randf_range(.5,9)
	lava_drop.find_child("CollisionShape3D").shape.radius = new_size
	lava_drop.find_child("MeshInstance3D").mesh.radius = new_size
	lava_drop.find_child("MeshInstance3D").mesh.height = new_size * 2
	
	
func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	spawn_every -= delta
	if global_position.distance_to(drone.global_position) < spawn_range:
		if spawn_every < 0:
			spawn_every = randi_range(4,10)
			lava_drop.gravity_scale *= -1
			#lava_drop.global_position = global_position
