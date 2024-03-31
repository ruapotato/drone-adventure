extends Node2D

@onready var crystal_label = $crystals_label
@onready var camera = $SubViewportContainer/SubViewport/Camera3D
@onready var time_label = $TimeLabel
@onready var target_label = $targetLabel
@onready var speed_label = $SpeedLabel
@onready var power_cell = $power_cell
@onready var refuel_label = $refuel

var player
var drone
var world

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_player()
	drone = get_drone()
	world = player.get_parent()

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

func format_hour(hour):
	#Spit hours an mins
	var mins = hour - float(int(hour))
	hour = hour - mins
	
	#Conver to clock terms
	mins = int(mins * 60)
	if mins < 10:
		mins = "0" + str(mins)
	else:
		mins = str(mins)
	if hour == 0:
		hour = 12

	return(str(hour) + ":" + mins)


func update_target_label():
	target_label.rotation = drone.global_rotation.z

func update_time_label():
	if world.friendly_time_am:
		time_label.text = format_hour(world.friendly_time) + " AM"
	else:
		time_label.text = format_hour(world.friendly_time) + " PM"
func update_power_cell_label():
	power_cell.value = drone.power_cell
	
func update_speed_label():
	speed_label.text = "MPH " + str(int(drone.linear_velocity.length() * 2.23693629))

func update_refuel():
	if drone.power_cell < 30:
		refuel_label.visible = true
	else:
		refuel_label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if str(drone.crystals) != crystal_label.text:
		crystal_label.text = str(drone.crystals)
	camera.global_position = drone.back_cam_mount.global_position
	camera.look_at(drone.global_position)
	update_time_label()
	update_target_label()
	update_speed_label()
	update_power_cell_label()
	update_refuel()
