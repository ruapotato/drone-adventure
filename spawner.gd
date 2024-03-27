extends Node3D

@onready var zombie = preload("res://mini_ufo.tscn")
@onready var piv = $piv
@onready var spawn_point = $piv/spawn_point


var spawn_every = 10
var spawn_counter = spawn_every
var zombie_index = 0
var drone
# Called when the node enters the scene tree for the first time.
func _ready():
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = drone.global_position
	spawn_counter -= delta
	if spawn_counter < 0:
		spawn_counter = spawn_every
		var new_zombie = zombie.instantiate()
		new_zombie.name = "zombie_" + str(zombie_index)
		zombie_index += 1
		new_zombie.set_deferred("global_position", spawn_point.global_position)
		get_parent().add_child(new_zombie)
	piv.rotate_y(delta*10)
