extends Node2D

@onready var crystal_label = $crystals_label
@onready var camera = $SubViewportContainer/SubViewport/Camera3D
@onready var time_label = $TimeLabel
@onready var target_label = $targetLabel
@onready var speed_label = $SpeedLabel
@onready var power_cell = $power_cell
@onready var extra_power_cell = $extra_power_cell
@onready var refuel_label = $refuel
@onready var message = $message_box/message
@onready var message_box = $message_box
@onready var bank_label = $bank_label
@onready var added_label = $added_label
var drone
var world
var added_counter


# Called when the node enters the scene tree for the first time.
func _ready():

	drone = get_drone()
	world = drone.get_parent()



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
	if "extra_power" in drone.inventory:
		extra_power_cell.visible = true
		var max_extra_power = drone.extra_power_per_upgrade * drone.inventory["extra_power"]
		extra_power_cell.value = (drone.extra_power_cell / max_extra_power) * 100
	else:
		extra_power_cell.visible = false
	
func update_speed_label():
	speed_label.text = "MPH " + str(int(drone.linear_velocity.length() * 2.23693629))

func update_refuel():
	if drone.power_cell < 30:
		refuel_label.visible = true
	else:
		refuel_label.visible = false

func update_added_label(delta):
	if added_counter <= 0:
		if added_label.text != "":
			added_label.text = ""
	else:
		added_counter -= delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if str(drone.inventory["crystals"]) != crystal_label.text:
		added_label.text = "+" + str(drone.inventory["crystals"] - int(crystal_label.text))
		added_counter = 3
		crystal_label.text = str(drone.inventory["crystals"])
	if "bank" in drone.inventory:
		if str(drone.inventory["bank"]) != bank_label.text:
			bank_label.text = str(drone.inventory["bank"])
			bank_label.visible = true
	else:
		if bank_label.visible:
			bank_label.visible = false
	camera.global_position = drone.back_cam_mount.global_position
	camera.look_at(drone.global_position)
	update_added_label(delta)
	update_speed_label()
	if not drone.tutorial_mode:
		update_time_label()
		update_target_label()
		update_power_cell_label()
		update_refuel()
