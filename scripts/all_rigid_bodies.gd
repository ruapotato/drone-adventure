extends Node3D

var node3d
var collision_shapes = []
# Called when the node enters the scene tree for the first time.
func _ready():
	node3d = Node3D.new()
	add_child(node3d)
	
	set_static(get_children())

func set_static(what):
	for child in what:
		if child is Node3D:
			set_static(child.get_children())
		if child is MeshInstance3D:
			child.create_convex_collision()
			var tmp_collision_shape = child.get_child(0).get_child(0).shape
			child.get_child(0).get_child(0).shape.margin = 0.0
			var new_body = RigidBody3D.new()
			new_body.shape = tmp_collision_shape
			child.add_child(new_body)

			new_body.add_child(child)

			collision_shapes.append(child.get_child(0))
			#collision_shapes[-1].add_child(new_body)
			#if collision_shapes[-1] not in node3d.get_children():
			#node3d.add_child(collision_shapes[-1])
			node3d.add_child(new_body)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
