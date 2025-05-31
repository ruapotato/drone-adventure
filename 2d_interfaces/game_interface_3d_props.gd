extends Node3D

@onready var key_mesh = $Key
@onready var clover_mesh = $clover4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	key_mesh.rotate_y(delta/2)
