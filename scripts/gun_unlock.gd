extends Area3D

var drone

# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body == drone:
		print("UNLOCK")
		drone.unlocked_gun = true
		queue_free()
