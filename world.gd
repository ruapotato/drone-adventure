extends Node3D

@onready var env = $WorldEnvironment
@onready var drone = $drone
@onready var sun = $sun
@onready var city = $city
@onready var cars = $cars
@onready var towers = $towers
@onready var ufos = $ufos
@onready var spawner = $spawner
@onready var NPC = preload("res://npc.tscn")
@onready var CAR = preload("res://vehicle.tscn")
@onready var TOW = preload("res://towtruck.tscn")
@onready var UFO = preload("res://ufo.tscn")
#@onready var point_of_view = $pov
@onready var voxels = $VoxelLodTerrain

const day_len = 60*.5
const day_speed = PI/day_len
const fog_density = 0.0526
const day_workflow =  {5.9: "stop_spawn",
					6.0: "clear_fog",
					16.0:"start_spawn",
					23.0: "get_foggy",
					2.0:  "UFO"}


var hour_index
var vt
var time_to_init = 10
var init_done = false

var time
var friendly_time
var friendly_time_am = false
var NPCs = []

var cars_every = 4
var car_timer = cars_every


var active_task
var tasks_today = day_workflow.duplicate()
var terrain_chop

var plants
var city_running = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#terrain_chop = city.find_child("terrain_cutout").get_children()
	vt = find_child("VoxelLodTerrain").get_voxel_tool()
	for home_to_fill in city.find_child("homes").get_children():
		var new_npc = NPC.instantiate()
		new_npc.npc_home_pos = home_to_fill.global_position

		var jobs =  city.find_child("jobs").get_children()
		new_npc.npc_work_pos = jobs[randi() % jobs.size()].global_position
		
		new_npc.npc_type = "worker"
		
		#new_npc.set_deferred("global_position", home_to_fill.global_position)
		new_npc.global_position = home_to_fill.global_position
		
		add_child(new_npc)
		NPCs.append(new_npc)
		print(home_to_fill)
	

func run_active_tasks(delta):
	if active_task == "clear_fog":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density ,0.002, delta / (day_len/15))
	if active_task == "get_foggy":
		env.environment.volumetric_fog_density = lerp(env.environment.volumetric_fog_density, fog_density, delta / (day_len/4))
	if active_task == "start_spawn":
		spawner.running = true
	if active_task == "stop_spawn":
		spawner.running = false
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

func spawn_car(pos, angle):
	var new_car = CAR.instantiate()
	new_car.set_deferred("global_position", pos)
	new_car.set_deferred("global_rotation", angle)
	cars.add_child(new_car)

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

func update_cars(delta):
	if not city_running:
		return
	car_timer -= delta
	if car_timer < 0:
		var car_spawns =  city.find_child("car_spawns").get_children()
		var car_spawn = car_spawns[randi() % car_spawns.size()]
		spawn_car(car_spawn.global_position, car_spawn.global_rotation)
		car_timer = cars_every
	
	for car in cars.get_children():
		if car.crashed and not car.beeing_helped:
			car.beeing_helped = true
			var new_tow = TOW.instantiate()
			new_tow.tow_target = car
			new_tow.tow_dropoff = city.find_child("tow_port_drop")
			new_tow.set_deferred("global_position", city.find_child("tow_port").global_position)
			new_tow.set_deferred("global_rotation", city.find_child("tow_port").global_rotation)
			towers.add_child(new_tow)
			#print("Need tow...")

func update_city_running():
	city_running = drone.global_position.distance_to(city.global_position) < 150
	#print(city_running)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#setup_terrain(delta)
	sun.rotate_x(delta * day_speed)
	update_abs_time()
	update_friendly_time()
	update_sky_energy(delta)
	update_cars(delta)
	update_workflow()
	run_active_tasks(delta)
	update_city_running()

