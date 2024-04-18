extends Node3D

@onready var mini_ufo = preload("res://mini_ufo.tscn")
@onready var balloon = preload("res://balloon.tscn")
@onready var lava_blob = preload("res://lava_blob.tscn")
@onready var piv = $piv
@onready var spawn_point = $piv/spawn_point
@onready var world = get_parent()

var spawn_every = 10
var spawn_counter = spawn_every
var spawn_index = 0
var drone
var running = true
var day_spawn = true
var night_spawn = false
# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func spawn_something():
	# On ground
	if global_position.y > -99:
		if drone.inventory["crystals"] > 5 and night_spawn:
			spawn_counter = spawn_every
			var new_mini_ufo = mini_ufo.instantiate()
			new_mini_ufo.name = "mini_ufo_" + str(spawn_index)
			spawn_index += 1
			new_mini_ufo.set_deferred("global_position", spawn_point.global_position)
			get_parent().add_child(new_mini_ufo)
	# sky things
	if global_position.y > 200 and day_spawn:
		spawn_counter = spawn_every
		var new_thing = balloon.instantiate()
		#new_thing.name = "balloon_" + str(spawn_index)
		spawn_index += 1
		new_thing.set_deferred("global_position", spawn_point.global_position)
		get_parent().add_child(new_thing)	
	
	# Under ground
	if global_position.y < -99 and false:
		spawn_counter = spawn_every
		var new_thing = lava_blob.instantiate()
		new_thing.name = "lava_blob_" + str(spawn_index)
		spawn_index += 1
		new_thing.set_deferred("global_position", spawn_point.global_position)
		get_parent().add_child(new_thing)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = drone.global_position
	if running:
		spawn_counter -= delta
		if spawn_counter < 0:
			spawn_something()
		piv.rotate_y(delta*10)
