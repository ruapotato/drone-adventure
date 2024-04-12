extends Node3D
@onready var NPC = preload("res://npc.tscn")
@onready var CAR = preload("res://vehicle.tscn")
@onready var TOW = preload("res://towtruck.tscn")
@onready var cars = $cars
@onready var towers = $towers
var NPCs = []

var cars_every = 4
var car_timer = cars_every
var city_running = false
var drone

func _ready():
	drone = get_drone()
	for home_to_fill in find_child("homes").get_children():
		var new_npc = NPC.instantiate()
		new_npc.npc_home_pos = home_to_fill.global_position

		var jobs =  find_child("jobs").get_children()
		new_npc.npc_work_pos = jobs[randi() % jobs.size()].global_position
		
		new_npc.npc_type = "worker"
		
		#new_npc.set_deferred("global_position", home_to_fill.global_position)
		add_child(new_npc)
		new_npc.global_position = home_to_fill.global_position
		NPCs.append(new_npc)
		#print(home_to_fill)


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func spawn_car(pos, angle):
	var new_car = CAR.instantiate()
	new_car.set_deferred("global_position", pos)
	new_car.set_deferred("global_rotation", angle)
	cars.add_child(new_car)

func update_cars(delta):
	if not city_running:
		return
	car_timer -= delta
	if car_timer < 0:
		var car_spawns =  find_child("car_spawns").get_children()
		var car_spawn = car_spawns[randi() % car_spawns.size()]
		spawn_car(car_spawn.global_position, car_spawn.global_rotation)
		car_timer = cars_every
	
	for car in cars.get_children():
		if car.crashed and not car.beeing_helped:
			car.beeing_helped = true
			var new_tow = TOW.instantiate()
			new_tow.tow_target = car
			new_tow.tow_dropoff = find_child("tow_port_drop")
			new_tow.set_deferred("global_position", find_child("tow_port").global_position)
			new_tow.set_deferred("global_rotation", find_child("tow_port").global_rotation)
			towers.add_child(new_tow)
			#print("Need tow...")



func update_city_running():
	city_running = drone.global_position.distance_to(global_position) < 150
	
	
	
func _process(delta):
	update_cars(delta)
	update_city_running()
	#print(city_running)
