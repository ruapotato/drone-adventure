extends Node2D

@onready var fullscreen_checkbox = $fullscreen
@onready var throttle_zero_checkbox = $throttle_zero_at_center
@onready var back_button = $Button
#@onready var settings_button = $settings

@onready var button_order = [fullscreen_checkbox, throttle_zero_checkbox, back_button]
var button_index = 0

var drone
var world
var startup_screen
var loaded = false


func _ready():
	drone = get_drone()
	world = drone.world
	startup_screen = world.get_parent()

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed("menu_select"):
			if button_order[button_index] is CheckBox:
				button_order[button_index].button_pressed = !button_order[button_index].button_pressed
			else:
				print("Button")
				#button_order[button_index].emit_signal("button_down")
				button_order[button_index].emit_signal("pressed")
			#button_order[button_index].emit_signal("toggled")
		
		if Input.is_action_just_pressed("menu_down"):
			button_index += 1
		if Input.is_action_just_pressed("menu_up"):
			button_index -= 1
		
		
		if button_index > len(button_order) - 1:
			button_index =  len(button_order) -1
		if button_index < 0:
			button_index = 0



func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))


func show_selected():
	var selected = button_order[button_index]
	selected.add_theme_color_override("font_color", Color(1,0,0))
	selected.add_theme_color_override("font_pressed_color", Color(1,0,0))
	
	for i in range(0, len(button_order)):
		if i != button_index:
			var not_selected = button_order[i]
			not_selected.add_theme_color_override("font_color", Color(1,1,1))
			not_selected.add_theme_color_override("font_pressed_color", Color(1,1,1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not get_parent().visible and visible:
		visible = false
	if not visible:
		loaded = false
	if visible:
		show_selected()
		if not loaded:
			loaded = true
			if "throttle_zero_centered" in drone.inventory:
				if drone.inventory["throttle_zero_centered"]:
					$throttle_zero_at_center.button_pressed = true
				else:
					$throttle_zero_at_center.button_pressed = false
			else:
				
				$throttle_zero_at_center.button_pressed = false



func _on_button_pressed():
	#print("Hmmm")
	visible = false
	world.pause()
	#get_parent().visible = false
	


func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_throttle_zero_at_center_toggled(toggled_on):
	#print(drone.inventory)
	if toggled_on:
		drone.inventory["throttle_zero_centered"] = true
	else:
		drone.inventory["throttle_zero_centered"] = false
	drone.save_game()
	loaded = false
	#print(drone.inventory)


func _on_control_sensitivity_changed():
	world.control_sensitivity_effector = $ControlSensitivity.value
