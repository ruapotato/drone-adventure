extends Node3D
@onready var body = $mini_ufo
var chicken
var speed = 25

var dead_counter = 3.0 
var dead = false
var life = 1.1

var mode = "swing"

# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken()


func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

func _physics_process(delta):
	if mode == "swing":
		var wanted_speed = body.global_position.direction_to(chicken.global_position) * speed
		body.linear_velocity = body.linear_velocity.lerp(wanted_speed,delta)
		if chicken.global_position.distance_to(body.global_position) < 1:
			mode = "run"
	if mode == "run":
		var wanted_speed = body.global_position.direction_to(chicken.global_position) * speed * -.5
		body.linear_velocity = body.linear_velocity.lerp(wanted_speed,delta)
		if chicken.global_position.distance_to(body.global_position) > 10:
			mode = "swing"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		if dead_counter > 0:
			dead_counter -= delta
		else:
			queue_free()
		return
	if life <= 0:
		print("mini down")
		chicken.world.add_crystal_to_world(randi_range(1,3),body.global_position)
		$mini_ufo/expload.play()
		$mini_ufo/ufo2.visible = false
		$mini_ufo/expload_effect.emitting = true
		dead = true
		#queue_free()
	#var wanted_speed = body.global_position.direction_to(chicken.global_position) * speed
	#body.linear_velocity = wanted_speed
	#body.apply_impulse()


func _on_audio_stream_player_3d_finished():
	$mini_ufo/AudioStreamPlayer3D.play()
