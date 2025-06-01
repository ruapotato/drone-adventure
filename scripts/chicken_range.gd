extends Node3D

@onready var mesh = $mesh

var player
var world
var chicken
var material
var range = 75
var dist = 0

func _ready() -> void:
	player = get_parent()
	world = player.get_parent()
	chicken = world.find_child("chicken")
	material = mesh.get_active_material(0)
	update_size(range)
	
func update_size(size):
	mesh.mesh.radius = size / 2
	mesh.mesh.height = size
	range = size


func update_material():
	dist = global_position.distance_to(chicken.global_position)
	var sold_amount = ((dist + .001)/((range/2) - 5)) - .1
	if sold_amount < 0:
		sold_amount = 0

	material.albedo_color.a = sold_amount
	
func _process(delta: float) -> void:
	update_material()
