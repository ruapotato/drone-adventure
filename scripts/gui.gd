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
@onready var stats_node = $stats
@onready var fps_label = $stats/fps

var chicken # Node3D or specific chicken type
var world   # Node3D or specific world type (the one with sun.rotation.x)
var added_counter: float = 0.0
var system_messages_counter: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken_node()
	# Assuming get_chicken_node() successfully returns chicken and its parent is the world node
	if chicken:
		world = chicken.get_parent()
	else:
		printerr("GUI Error: Chicken node not found in _ready(). UI might not function correctly.")
		# world will remain null if chicken is null


func get_chicken_node():
	var root_i_hope = get_parent()
	# This loop will error if root_i_hope becomes null before finding "world" named node,
	# or if "world" named node is not an ancestor.
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return root_i_hope.find_child("chicken") # Assumes chicken is direct child of "world"


func format_hour(hour_float: float) -> String:
	var mins_float = hour_float - floor(hour_float)
	var hour_int = int(floor(hour_float))
	
	var mins_int = int(mins_float * 60)
	var mins_str: String
	if mins_int < 10:
		mins_str = "0" + str(mins_int)
	else:
		mins_str = str(mins_int)
	
	if hour_int == 0: # For 00:xx friendly time
		hour_int = 12
	# This was in your script, handles 13-24 hour values if friendly_time produced them.
	# Based on world.gd's friendly_time (0-12 range), this might not be hit often unless 
	# friendly_time calculation changes to produce >12 directly.
	elif hour_int > 12 and hour_int <= 24: 
		hour_int = hour_int - 12
		if hour_int == 0 : hour_int = 12 
		
	return str(hour_int) + ":" + mins_str


func update_target_label():
	target_label.rotation = chicken.global_rotation.z


func update_time_label():
	# world.sun.rotation.x: -PI/2 rad (-90 deg) = noon (overhead)
	#                        0   rad (  0 deg) = sunset (horizon)
	#                        PI/2 rad ( 90 deg) = nadir (antipode/deepest night)
	var world_sun_rot_rad = world.sun.rotation.x
	
	# Desired GUI Display: 90 deg = noon, 0 deg = sunset
	var text_to_display: String

	if world_sun_rot_rad <= 0: # Covers Noon (-PI/2) up to Sunset (0)
		# Map [-PI/2, 0] radians to [90, 0] degrees for display
		# When world_sun_rot_rad = -PI/2 -> display should be 90
		# When world_sun_rot_rad = 0     -> display should be 0
		# Formula: display_deg = -rad_to_deg(world_sun_rot_rad) + (if needed offset, but -x works)
		# simpler: display_deg = rad_to_deg(-world_sun_rot_rad)
		var display_angle_deg_dayside = rad_to_deg(-world_sun_rot_rad)
		text_to_display = "Sun Angle: %.0f°" % display_angle_deg_dayside
	else: # Night side: world_sun_rot_rad goes from 0 (sunset) towards PI/2 (antipode)
		# Sun is below horizon from the "noon point's" perspective
		text_to_display = "Night (Sun Set)"
		# Optionally, you could show a negative angle or "depth" into night:
		# var night_depth_deg = rad_to_deg(world_sun_rot_rad) # This goes 0 to 90 as it gets "deeper" into night
		# text_to_display = "Night Phase: %.0f°" % night_depth_deg

	time_label.text = text_to_display

	# --- Optional: Append friendly clock time ---
	# This uses 'world.friendly_time' and 'world.friendly_time_am'
	# which should be correctly calculated in your world.gd script based on the new sun angle.
	# var friendly_time_val = world.friendly_time
	# var am_pm_str = " PM"
	# if world.friendly_time_am:
	# 	am_pm_str = " AM"
	# time_label.text += " (%s%s)" % [format_hour(friendly_time_val), am_pm_str]


func update_speed_label():
	speed_label.text = "MPH " + str(int(chicken.linear_velocity.length() * 2.23693629))


func update_chihuahuas():
	chihuahuas.visible = world.dogs_pissed


func update_added_label(delta):
	if added_counter <= 0:
		if added_label.text != "":
			added_label.text = ""
	else:
		added_counter -= delta


func update_fps():
	if stats_node.visible:
		fps_label.text = str(Engine.get_frames_per_second()) + " " + str(chicken.global_position)


func update_boss_bar():
	if world.boss_max_life != null and world.boss_max_life > 0:
		boss_bar.visible = true
		# Ensure world.boss_life is also not null if world.boss_max_life is checked
		var current_boss_life = 0.0
		if world.boss_life != null: # Minimal check if boss_life might be temporarily null
			current_boss_life = world.boss_life
		boss_bar.value = (current_boss_life / world.boss_max_life) * 100.0
	else:
		boss_bar.visible = false


func update_system_msg(delta):
	if system_messages.visible:
		if system_messages_counter > 0:
			system_messages_counter -= delta
		else: 
			system_messages_counter = 0.0
			system_messages.hide()


func _process(delta):
	# Assuming chicken and world are valid after _ready.
	# If not, errors will occur here as per your preference.
	if not is_instance_valid(chicken) or not is_instance_valid(world):
		# Minimal guard for _process loop if critical refs are missing
		# This avoids spamming errors every frame if _ready failed to get them.
		# You might want a more robust way to handle this (e.g., disable UI updates).
		return

	var current_crystals_text = crystal_label.text
	var new_crystals_val = chicken.inventory["crystals"]

	if str(new_crystals_val) != current_crystals_text:
		var previous_crystals = 0
		if current_crystals_text.is_valid_int():
			previous_crystals = int(current_crystals_text)
		
		var diff = new_crystals_val - previous_crystals
		if diff > 0: 
			added_label.text = "+" + str(diff)
		else: 
			added_label.text = str(diff) if diff != 0 else ""

		added_counter = 3.0
		crystal_label.text = str(new_crystals_val)
	
	if "bank" in chicken.inventory:
		var new_bank_val = chicken.inventory["bank"]
		if str(new_bank_val) != bank_label.text:
			bank_label.text = str(new_bank_val)
		bank_label.visible = true
	else:
		bank_label.visible = false

	update_added_label(delta)
	update_speed_label()
	update_fps()
	update_system_msg(delta)
	
	if not chicken.tutorial_mode:
		update_boss_bar()
		update_time_label() # Updated to new angle display
		update_target_label()
		update_chihuahuas()
