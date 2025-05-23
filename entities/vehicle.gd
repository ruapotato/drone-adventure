extends VehicleBody3D

var start_time = 1
var init_angle = null
var crashed = false
var beeing_helped = false
var tp_cooldown = 0
var time_to_live_crashed = 60
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if crashed:
		time_to_live_crashed -= delta
		if time_to_live_crashed < 0:
			queue_free()
	if crashed and not $expload_effect.emitting:
		$eng_sounds.stream = load("res://import/Audio/spaceEngineLarge_000.ogg")
		$eng_sounds.play()
		$expload_effect.emitting = true
	
	if tp_cooldown < 0:
		tp_cooldown -= delta
	# Remove is falls off map
	#if global_position.y < 30:
	#	crashed = true
	
	#Remove is stops unexpectedly 
	start_time -= delta
	if start_time < 0 and linear_velocity.length() < .1:
		crashed = true
	# Setup init anlge, can't be done in _ready as it's set with deffered
	if not init_angle:
		init_angle = global_rotation
	#steering = 1.0
	if not crashed:
		engine_force = 100.0
	if crashed:
		engine_force = 0
	if (init_angle - global_rotation).length() > .5 and not crashed:
		crashed = true

		#print("CRASH!!!")
	#print((init_angle - global_rotation).length())


func _on_eng_sounds_finished():
	$eng_sounds.play()
