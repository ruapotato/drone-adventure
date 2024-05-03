extends Node3D

@onready var crystal = preload("res://crystal.tscn")
@onready var env = $WorldEnvironment
@onready var drone = $drone
@onready var sun = $sun
#@onready var city = $city
@onready var ufos = $ufos
@onready var spawner = $spawner

@onready var UFO = preload("res://ufo.tscn")
#@onready var point_of_view = $pov
@onready var dirt_voxels = $VoxelLodTerrain
@onready var crystal_voxels = $VoxelLodTerrain2

const day_len = 60*2
const day_speed = PI/day_len
const fog_density = 0.0526
const day_workflow =  {6.0: "clear_fog",
					7.0:"day_spawn",
					21.0:"night_spawn",
					23.0: "get_foggy",
					2.0:  "UFO"}


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

# Called when the node enters the scene tree for the first time.
func _ready():
	#terrain_chop = city.find_child("terrain_cutout").get_children()
	dirt_vt = dirt_voxels.get_voxel_tool()
	crystal_vt = crystal_voxels.get_voxel_tool()
	
	

func run_active_tasks(delta):
	if active_task == "clear_fog":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density ,0.002, delta / (day_len/15))
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
		if len(ufos.get_children()) == 0:
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
		body.fly_ttl = 6
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


