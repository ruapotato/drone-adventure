extends Node3D

@onready var camera = $cam_piv/Camera3D
@onready var cam_piv = $cam_piv
@onready var planet = $EyeLand

var spin = true

var rotate_speed = .05
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if planet.visible:
		cam_piv.rotate_y(delta * rotate_speed)
		camera.look_at(planet.global_position)
