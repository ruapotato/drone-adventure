extends Node3D

@onready var mini_ufo = preload("res://mini_ufo.tscn")
@onready var ufo = preload("res://ufo.tscn")
@onready var balloon = preload("res://balloon.tscn")
@onready var lava_blob = preload("res://lava_blob.tscn")
@onready var piv = $piv
@onready var spawn_point = $piv/spawn_point
@onready var world = get_parent()

var spawn_every = 10
var spawn_counter = spawn_every
var spawn_index = 0
var drone
#var running = true
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
		if drone.inventory["crystals"] > 10 and night_spawn:
			spawn_counter = spawn_every
			var new_mini_ufo = mini_ufo.instantiate()
			new_mini_ufo.name = "mini_ufo_" + str(spawn_index)
			spawn_index += 1
			new_mini_ufo.set_deferred("global_position", spawn_point.global_position)
			get_parent().add_child(new_mini_ufo)
			return
	# sky things
	if global_position.y > 750:
		spawn_counter = spawn_every * 4
		if len(world.ufos.get_children()) == 0:
			print("INIT UFO")
			var new_ufo = ufo.instantiate()
			world.ufos.add_child(new_ufo)
			return

	elif global_position.y > 200 and day_spawn:
		spawn_counter = spawn_every
		var new_thing = balloon.instantiate()
		#new_thing.name = "balloon_" + str(spawn_index)
		spawn_index += 1
		new_thing.set_deferred("global_position", spawn_point.global_position)
		get_parent().add_child(new_thing)
		return
	
	# Under ground
	if global_position.y < -99:
		spawn_counter = spawn_every/(abs(drone.global_position.y)/300)
		print(spawn_counter)
		print("make ufo")
		var new_thing = mini_ufo.instantiate()
		new_thing.name = "mini_ufo_" + str(spawn_index)
		spawn_index += 1
		new_thing.set_deferred("global_position", spawn_point.global_position)
		get_parent().add_child(new_thing)
		return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = drone.global_position
	if true:#running:
		spawn_counter -= delta
		if spawn_counter < 0:
			spawn_something()
		rotation.y = drone.rotation.y
		#piv.rotate_y(delta*10)
