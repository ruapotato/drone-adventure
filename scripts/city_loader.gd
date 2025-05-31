extends Node3D

@onready var city = preload("res://scenes/city.tscn")

var chicken
var range = 400
var city_loaded = false
var running_city
# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken()
	
func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

func load_city():
	running_city = city.instantiate()
	add_child(running_city)

func unload_city():
	running_city.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(chicken.global_position) < range:
		if not city_loaded:
			load_city()
			city_loaded = true
	else:
		if city_loaded:
			unload_city()
			city_loaded = false
