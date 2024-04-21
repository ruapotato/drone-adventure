extends DirectionalLight3D

var drone


func _ready():
	drone = get_drone()


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))
	
func _process(delta):
	#print(drone.global_position.y)
	if drone.global_position.y < -70:
		light_energy = 1.0
		#visible = false
	else:
		light_energy = 1.0
		#visible = true
