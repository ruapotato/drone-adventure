extends Node3D

@onready var mesh = $mesh

var player
var world
var chicken
var material
var range = 75
var dist = 0
var sharpness: float = 15.0

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
	var max_radius = range / 2.0
	var dist = global_position.distance_to(chicken.global_position)
	# Normalize the distance from 0 to 1 within the radius
	var normalized_dist = clamp(dist / max_radius, 0.0, 1.0)
	var sold_amount = pow(normalized_dist, sharpness)
	material.albedo_color.a = sold_amount


func _process(delta: float) -> void:
	update_material()
