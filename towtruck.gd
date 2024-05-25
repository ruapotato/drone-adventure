extends VehicleBody3D

@onready var nav = $NavigationAgent3D
@onready var target = $target
@onready var towing_mesh = $towing_mesh

var tow_target
var tow_dropoff

var todo = "pickup"

# Called when the node enters the scene tree for the first time.
func _ready():
	for fellow_truck in get_parent().get_children():
		add_collision_exception_with(fellow_truck)

func set_target_pickup():
	if tow_target.global_position.y < -5:
		tow_target.queue_free()
		queue_free()
	#if not tow_target.global_position:
	#	queue_free()
	nav.target_position = tow_target.global_position
	target.look_at(nav.get_next_path_position())
	target.rotate_y(PI)
	

func set_target_dropoff():
	if global_position.y < -5:
		queue_free()
	nav.target_position = tow_dropoff.global_position
	target.look_at(nav.get_next_path_position())
	target.rotate_y(PI)

func _physics_process(delta):
	if todo == "pickup":
		set_target_pickup()
		if global_position.distance_to(nav.target_position) < 10:
			#print("Drop off")
			tow_target.queue_free()
			towing_mesh.visible = true
			todo = "dropoff"
	if todo == "dropoff":
		set_target_dropoff()
		if global_position.distance_to(nav.target_position) < 10:
			#print("tow done!")
			queue_free()
	#steering = 1.0
	engine_force = 100.0
	
	rotation.y = lerp(rotation.y, target.global_rotation.y, delta * 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	


func _on_eng_sounds_finished():
	$eng_sounds.play()
