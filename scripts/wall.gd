extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$MeshInstance3D.get_active_material(0).albedo_texture.noise.fractal_ping_pong_strength += delta/5
	#$MeshInstance3D.get_active_material(0).albedo_texture.noise.
