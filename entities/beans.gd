extends Area3D

var collected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if not collected:
		if body.name == "drone":
			body.get_parent().play_as_gee()
		if body.name == "Gee":
			collected = true
			body.gass = 100
			body.beans_found += 1
			visible = false
