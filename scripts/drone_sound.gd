extends AudioStreamPlayer

@onready var chicken = $".."
# Called when the node enters the scene tree for the first time.
func _ready():
	pass#stream.loop_mode = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass#pitch_scale = abs(chicken.get_throttle()/8) + .5


func _on_finished():
	play()
