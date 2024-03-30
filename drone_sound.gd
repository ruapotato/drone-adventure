extends AudioStreamPlayer3D

@onready var drone = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass#stream.loop_mode = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pitch_scale = abs(drone.throttle/5) + 1.2


func _on_finished():
	play()

