extends Node3D

var static_body
var collision_shapes = []
# Called when the node enters the scene tree for the first time.
func _ready():
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	set_static(get_children())

func set_static(what):
	for child in what:
		if child is Node3D:
			set_static(child.get_children())
		if child is MeshInstance3D:
			child.create_trimesh_collision()
			child.get_child(0).get_child(0).shape.margin = 0.0
			collision_shapes.append(child.get_child(0))
			#if collision_shapes[-1] not in static_body.get_children():
			static_body.add_child(collision_shapes[-1])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
