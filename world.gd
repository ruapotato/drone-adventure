extends Node3D

@onready var crystal = preload("res://crystal.tscn")
@onready var env = $WorldEnvironment
@onready var music = $music
@onready var drone = $drone
@onready var sun = $sun
#@onready var city = $city
@onready var ufos = $ufos
@onready var spawner = $spawner

@onready var UFO = preload("res://ufo.tscn")
#@onready var point_of_view = $pov
@onready var dirt_voxels = $VoxelLodTerrain
@onready var crystal_voxels = $VoxelLodTerrain2
@onready var gui = $gui
@onready var spawn = $spawn
@onready var pause_screen = $pause_screen

const day_len = 60*2
const day_speed = PI/day_len
const fog_density = 0.0526
const day_workflow =  {5.0:"day_spawn",
					7.5: "clear_fog",
					21.0:"night_spawn",
					23.0: "get_foggy",
					2.0:  "UFO"}

@onready var music_list = {"underground":preload("res://import/CC0_by_mrpoly_awesomeness.wav"),
							"ufo":preload("res://import/CC0_ruskerdax_-_the_creep.mp3"),
							"shop":preload("res://import/CC_BY_3.0_Varon_Kein_The Three Princesses of Lilac Meadow.ogg"),
							"meadow":preload("res://import/CC_by_4_migfus20_asdf_2.mp3"),
							"city":preload("res://import/CC-BY_Spring_Spring_Title_field 2_Master.ogg"),
							"heighup":preload("res://import/CC_by_3.0_Matthew Pablo_Desolate Collection/Desolate.mp3"),
							"dogs":preload("res://import/CC0_by_celestialghost8_Inevitable Doom.wav")}
var hour_index
var dirt_vt
var crystal_vt
var time_to_init = 10
var init_done = false
var hardness
var game_index
var control_sensitivity_effector = 0.0
var time
var friendly_time
var friendly_time_am = false



var active_task
var tasks_today = day_workflow.duplicate()
var terrain_chop

var plants
var dogs_pissed = false
var boss_life = null
var boss_max_life = null

var last_mouse_move = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#terrain_chop = city.find_child("terrain_cutout").get_children()
	dirt_vt = dirt_voxels.get_voxel_tool()
	crystal_vt = crystal_voxels.get_voxel_tool()
	
	

func run_active_tasks(delta):
	if active_task == "clear_fog":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density ,0.002, delta / (day_len/8))
	if active_task == "get_foggy":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density, fog_density, delta / (day_len/4))
	if active_task == "day_spawn":
		spawner.day_spawn = true
		spawner.night_spawn = false
	if active_task == "night_spawn":
		spawner.day_spawn = false
		spawner.night_spawn = true
	if active_task == "UFO":
		#print(len(ufos.get_children()))
		
		if len(ufos.get_children()) == 0 and drone.global_position.y > -50:
			print("INIT UFO")
			var new_ufo = UFO.instantiate()
			ufos.add_child(new_ufo)
			active_task = ""

func update_workflow():
	var hour_index = friendly_time
	if not friendly_time_am:
		hour_index += 12
	
	if hour_index < .2:
		print("day reset")
		tasks_today = day_workflow.duplicate()
	
	for todo_item_time in tasks_today:
		if abs(todo_item_time - hour_index) < .2:
			#print("new task")
			active_task = tasks_today[todo_item_time]
			tasks_today.erase(todo_item_time)


func message(this_message):
	gui.system_messages.text = this_message
	gui.system_messages.show()
	gui.system_messages_counter = 10

func update_friendly_time():
	var AM_PM = "PM"
	var hour
	
	if sun.rotation_degrees.x < 0:
		hour = 180 + sun.rotation_degrees.x
		hour = (hour/180) * 12
		hour -= 6
		if hour < 0:
			hour = 12 + hour
			AM_PM = "AM"
	if sun.rotation_degrees.x > 0:
		hour = 180 + sun.rotation_degrees.x
		hour = (hour/180) * 12
		hour -= 6
		if hour > 12:
			hour = abs(12 - hour)
			AM_PM = "AM"

	friendly_time = hour
	if AM_PM == "AM":
		friendly_time_am = true
	else:
		friendly_time_am = false

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		#print("mouse")
		last_mouse_move = 0.0


func pause():
	if pause_screen.visible:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 0.01
	pause_screen.visible = not pause_screen.visible

func add_crystal_to_world(value,pos):
	#randi_range(20,100)
	var new_crystal = crystal.instantiate()
	new_crystal.value = value
	new_crystal.init_pos = pos
	#new_crystal.global_position = body.global_position
	new_crystal.set_deferred("global_position", pos)
	drone.get_parent().add_child(new_crystal)

func hurt(body, how_much):
	print(body.name)
	if "weak_point" in body.name:
		body = body.get_parent()
		how_much *= 3
	
	
	if "crow" in body.name:
		if body.visible:
			body.visible = false
			add_crystal_to_world(randi_range(20,100),body.global_position)
	if "crystal" in body.name:
		body.shatter()
	elif body.name == "top_balloon":
		body.mass = .1
		body.find_child("balloon_shape").shape.radius = .1
		body.find_child("balloon_mesh").visible = false
	elif body.name == "dog":
		dogs_pissed = true
		print("Pissed on the dogs")
	elif body.name == "ufo":
		body.life -= how_much
		body.fly_ttl = 20
	elif body.name == "mini_ufo":
		body.get_parent().life -= how_much
	elif "life" in body:
		body.life -= how_much

func update_abs_time():
	if sun.rotation.x > 0:
		time = day_len + (-sun.rotation.x/PI) * day_len
		time = time * -1
	else:
		time =  abs((sun.rotation.x/PI) * day_len)

func update_sky_energy(delta):
	if sun.rotation.x > 0:
		env.environment.sky.sky_material.sky_energy_multiplier = lerp(env.environment.sky.sky_material.sky_energy_multiplier, 0.0, delta)
	else:
		env.environment.sky.sky_material.sky_energy_multiplier = lerp(env.environment.sky.sky_material.sky_energy_multiplier, 1.0, delta)

func update_env(delta):
	#print(drone.global_position.y)
	if drone.global_position.y > 200:
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density ,0.0, delta / (day_len/15))
	if drone.global_position.y < -50:
		env.environment.volumetric_fog_albedo = Color("#9e0174")
	else:
		env.environment.volumetric_fog_albedo = Color(1,1,1)

func update_music():
	#print( drone.global_position.y)
	var music_pick = ""
	if drone.global_position.y > 750:
		music_pick = "heighup"
		music.volume_db = 0
	elif drone.global_position.y > 430:
		music_pick = "city"
		music.volume_db = -5
	elif drone.global_position.y > -50:
		music_pick = "meadow"
		music.volume_db = 0
	else:
		music_pick = "underground"
		music.volume_db = -10
	if gui.message_box.visible:
		music_pick = "shop"
		music.volume_db = -15
	
	if len(ufos.get_children()) > 0:
		music_pick = "ufo"
		music.volume_db = -10
	
	if dogs_pissed:
		music_pick = "dogs"
	
	if music_list[music_pick] != music.stream:
		music.stream = music_list[music_pick]
		music.play()

func update_mouse(delta):
	last_mouse_move += delta
	if last_mouse_move > 3:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#setup_terrain(delta)
	sun.rotate_x(delta * day_speed)
	update_abs_time()
	update_friendly_time()
	update_sky_energy(delta)
	update_workflow()
	run_active_tasks(delta)
	update_env(delta)
	update_music()
	update_mouse(delta)




func _on_music_finished():
	music.play()
