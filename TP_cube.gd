extends MeshInstance3D



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_surface_override_material(0).emission_texture.noise.offset.y += delta * 100
