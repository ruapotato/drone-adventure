extends Node3D

@onready var boss_1 = preload("res://entities/boss_1.tscn")

var chicken
var range = 400
var boss_1_loaded = false
var running_boss_1
# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken()
	
func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

func load_boss_1():
	running_boss_1 = boss_1.instantiate()
	add_child(running_boss_1)

func unload_boss_1():
	running_boss_1.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(chicken.global_position) < range:
		if not boss_1_loaded:
			load_boss_1()
			boss_1_loaded = true
	else:
		if boss_1_loaded:
			unload_boss_1()
			boss_1_loaded = false
