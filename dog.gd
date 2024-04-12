extends RigidBody3D

@onready var animation_tree = get_node("mesh/AnimationTree")
@onready var bark_sound = $bark_sound
@onready var mesh = $mesh
var drone
#var bark_range = 20
var bark_range = 10
var bark_range_start = 20
var mode = "sit"
var speed = 20

var max_range = 200
var init_pos
# Called when the node enters the scene tree for the first time.
func _ready():
	init_pos = global_position
	drone = get_drone()
	bark_sound.pitch_scale = randf_range(.7,1.4)
	mesh.scale = Vector3(1,1,1) * (((1-(bark_sound.pitch_scale-.7)+1)*5)-4)
	speed *= mesh.scale.x
	
func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func _physics_process(delta):
	if mode == "bark":
		look_at(drone.global_position)
		var dist = global_position.distance_to(drone.global_position)
		if dist - 2 < bark_range and dist + 2 > bark_range:
			animation_tree.set("parameters/walk_run/blend_position", 0.5)
			if not bark_sound.playing:
				bark_sound.play()
		else:
			animation_tree.set("parameters/walk_run/blend_position", 1.0)
			if dist < bark_range:
				if not bark_sound.playing:
					bark_sound.play()
				rotate_y(PI)
			else:
				if bark_sound.playing:
					bark_sound.stop()
		rotate_y(PI)
		if dist < bark_range:
			#print("Backup")
			#back up
			var wanted_speed = global_position.direction_to(drone.global_position) * speed
			wanted_speed *= -1
			wanted_speed.y = 0
			linear_velocity = linear_velocity.lerp(wanted_speed,delta)
			
		else:
			#run at:
			#print("run at")
			var wanted_speed = global_position.direction_to(drone.global_position) * speed
			wanted_speed.y = 0
			linear_velocity = linear_velocity.lerp(wanted_speed,delta)
			
	if mode == "run":
		look_at(drone.global_position)
		var wanted_speed = global_position.direction_to(drone.global_position) * speed
		wanted_speed *= -1
		wanted_speed.y = 0
		linear_velocity = linear_velocity.lerp(wanted_speed,delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.distance_to(drone.global_position) > max_range:
		if mode == "run" or mode == "bark":
			mode = "sit"
			animation_tree.set("parameters/walk_run/blend_position", 0.0)
			global_position = init_pos
			#print("Bird reset")
	if global_position.distance_to(drone.global_position) < bark_range_start:
		mode = "bark"
	if mode == "run":
		animation_tree.set("parameters/walk_run/blend_position", 1.0)
