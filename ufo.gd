extends RigidBody3D

var SPEED = 300

var spawn_point = Vector3(0,1000,0)
var hover_point = Vector3(0,470,0)

var active_task = "drop"
var fly_ttl = 10
var life = 15
var drone
# Called when the node enters the scene tree for the first time.
func _ready():
	gravity_scale = 0
	drone = get_drone()
	global_position = spawn_point
	var parent_pos = get_parent().global_position
	spawn_point.x = parent_pos.x
	spawn_point.z = parent_pos.z
	hover_point.x = parent_pos.x
	hover_point.z = parent_pos.z

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if life <= 0:
		drone.world.add_crystal_to_world(randi_range(100,300),global_position)
		queue_free()

	if global_position.distance_to(hover_point) < 2:
		print("UFO flying")
		active_task = "fly"
		linear_velocity = Vector3(randf_range(-20,20),0,randf_range(-20,20))
	
	if active_task == "fly":
		fly_ttl -= delta
		if fly_ttl < 0:
			active_task = "run"
	if active_task == "run":
		global_position = global_position.move_toward(spawn_point, delta * SPEED)
	if active_task == "drop":
		global_position = global_position.move_toward(hover_point, delta * SPEED)
	if active_task == "run" and global_position.distance_to(spawn_point) < 2:
		print("UFO done")
		queue_free()
