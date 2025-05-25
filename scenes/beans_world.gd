extends Node3D

@onready var gee = $Gee
@onready var env = $WorldEnvironment
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

func get_ground_color():
	var height = (abs(gee.global_position.y)/1000) + 1
	return(Color("#007100")/height)


func get_sky_color():
	var height = (abs(gee.global_position.y)/2000) + 1
	return(Color("#508dff")/height)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(get_sky_color())
	env.environment.sky.sky_material.set("sky_top_color", get_sky_color())
	env.environment.sky.sky_material.set("ground_bottom_color", get_ground_color())
	#if gee.global_position.y < 2000:
	#	env.environment.sky.sky_material.set("sky_top_color", get_sky_color())
		#env.environment.sky.sky_material.sky_top_color = Color("#4955ff")
	#elif gee.global_position.y < 4000:
	#	env.environment.sky.sky_material.set("sky_top_color", Color("#000000"))
		#env.environment.sky.sky_material.sky_top_color = Color("#000000")
	
