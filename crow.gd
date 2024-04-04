extends RigidBody3D

@onready var animation_tree = get_node("mesh/AnimationTree")

var drone
#var run_range = 20
var run_range = 20
var mode = "sit"
var speed = 20
# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	
func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func _physics_process(delta):
	if mode == "run":
		look_at(drone.global_position)
		var wanted_speed = global_position.direction_to(drone.global_position) * speed
		wanted_speed *= -1
		wanted_speed.y = abs(wanted_speed.y)
		linear_velocity = linear_velocity.lerp(wanted_speed,delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(drone.global_position) < run_range:
		mode = "run"
	if mode == "run":
		animation_tree.set("parameters/fly/blend_position", 1.0)
