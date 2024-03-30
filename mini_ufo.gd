extends Node3D
@onready var body = $mini_ufo
var drone
var speed = 14


var life = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func _physics_process(delta):
	var wanted_speed = body.global_position.direction_to(drone.global_position) * speed
	body.linear_velocity = body.linear_velocity.lerp(wanted_speed,delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if life <= 0:
		print("mini down")
		queue_free()
	#var wanted_speed = body.global_position.direction_to(drone.global_position) * speed
	#body.linear_velocity = wanted_speed
	#body.apply_impulse()


func _on_audio_stream_player_3d_finished():
	$mini_ufo/AudioStreamPlayer3D.play()
