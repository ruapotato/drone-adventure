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
@onready var chihuahuas = $chihuahuas
@onready var boss_bar = $boss_bar
@onready var system_messages = $system_messages

var chicken
var world
var added_counter
var system_messages_counter = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():

	chicken = get_chicken()
	world = chicken.get_parent()



func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

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
	target_label.rotation = chicken.global_rotation.z

func update_time_label():
	if world.friendly_time_am:
		time_label.text = format_hour(world.friendly_time) + " AM"
	else:
		time_label.text = format_hour(world.friendly_time) + " PM"

	
func update_speed_label():
	speed_label.text = "MPH " + str(int(chicken.linear_velocity.length() * 2.23693629))


func update_chihuahuas():
	if world.dogs_pissed:
		chihuahuas.visible = true
	else:
		chihuahuas.visible = false


func update_added_label(delta):
	if added_counter <= 0:
		if added_label.text != "":
			added_label.text = ""
	else:
		added_counter -= delta
func update_fps():
	if $stats.visible:
		$stats/fps.text = str(Engine.get_frames_per_second())

func update_boss_bar():
	if world.boss_max_life != null:
		if not boss_bar.visible:
			boss_bar.visible = true
		boss_bar.value =  world.boss_life/world.boss_max_life * 100
	else:
		if boss_bar.visible:
			boss_bar.visible = false

func update_system_msg(delta):
	if system_messages.visible:
		if system_messages_counter > 0:
			system_messages_counter -= delta
		elif system_messages_counter < 0:
			system_messages_counter = 0
			system_messages.hide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if str(chicken.inventory["crystals"]) != crystal_label.text:
		added_label.text = "+" + str(chicken.inventory["crystals"] - int(crystal_label.text))
		added_counter = 3
		crystal_label.text = str(chicken.inventory["crystals"])
	if "bank" in chicken.inventory:
		if str(chicken.inventory["bank"]) != bank_label.text:
			bank_label.text = str(chicken.inventory["bank"])
			bank_label.visible = true
	else:
		if bank_label.visible:
			bank_label.visible = false
	#camera.global_position = chicken.back_cam_mount.global_position
	#camera.look_at(chicken.global_position)
	update_added_label(delta)
	update_speed_label()
	update_fps()
	update_system_msg(delta)
	if not chicken.tutorial_mode:
		update_boss_bar()
		update_time_label()
		update_target_label()
		update_chihuahuas()
