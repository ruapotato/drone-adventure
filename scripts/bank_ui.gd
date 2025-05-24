extends Node3D

#var message_range = 15
var message_range = 5
var selected_item_index = 1
var in_menu = false
var menu_in_use = false
var message = ["This is a good place to keep your crystal in case you die."]
var message_options = []

var exta_power_max = 10
var exta_power_cost = 300

var drone


var message_index = -1
var message_option_index = 1
var message_ui = null
var gui

# Called when the node enters the scene tree for the first time.
func _ready():
	drone = get_drone()
	gui = drone.get_parent().find_child("gui")
	for obj in $items.get_children():
		var mull_msg = obj.name
		message.append(mull_msg)

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))
	
func has_crystals(needed):
	var total_crystals = 0
	if "bank" in drone.inventory:
		total_crystals += drone.inventory["bank"]
	total_crystals += drone.inventory["crystals"]
	if total_crystals >= needed:
		return true
	return false

func charge_crystals(needed):
	if needed <= drone.inventory["crystals"]:
		drone.inventory["crystals"] -= needed
		return
	else:
		needed -= drone.inventory["crystals"]
		drone.inventory["crystals"] = 0
	#charge bank leftovers
	drone.inventory["bank"] -= needed

func _unhandled_input(event):
	if not menu_in_use:
		return
	if event.is_action_pressed("menu_next") or event.is_action_pressed("menu_back"):
		#print("MSG!")
		# Update message box page
		if message_ui:
			#print("MSG!2")
			if Input.is_action_just_pressed("menu_next"):
				message_index += 1
			if Input.is_action_just_pressed("menu_back"):
				message_index = -1
			#print(message_index)
			#print(message_ui)
			if len(message_ui) > message_index:
				gui.message.text = message_ui[message_index]
				gui.message.visible = true
				#print("Set text")
				#message_bg.visible = true
			else:
				#print("Out of msgs")
				gui.message.visible = false
				#message_bg.visible = false
				message_index = -1

func _process(delta):
	#print(message_options)
	#Menu options
	if menu_in_use:
		if message_options:
			if Input.is_action_just_pressed("menu_down"):
				message_option_index -= 1
			if Input.is_action_just_pressed("menu_up"):
				message_option_index += 1
			if message_option_index > len(message_options):
				message_option_index = 1
			if message_option_index < 1:
				message_option_index = len(message_options)
			
			#Draw
			var tmp_draw_index = 1
			for message_to_add in message_options:
				var option_name = "option_" + str(tmp_draw_index)
				#gui.find_child("MESSAGE_BG").find_child(option_name).text = message_to_add
				var option_lable = gui.find_child(option_name)
				option_lable.text = message_to_add
				if message_option_index == tmp_draw_index:
					option_lable.label_settings.font_color = Color(1,0,0)
				else:
					option_lable.label_settings.font_color = Color(1,1,1)
				tmp_draw_index += 1
			for not_used_draw_index in range(tmp_draw_index, 4):
				var option_name = "option_" + str(tmp_draw_index)
				var option_lable = gui.find_child(option_name)
				option_lable.text = ""
		
		if not message_options and message_ui:
			for menu_child in gui.find_child("message_box").get_children():
				#print("HI" + str(menu_child))
				if "option" in menu_child.name:
					if menu_child.text != "":
						menu_child.text = ""
	
	#print(global_position.distance_to(drone.global_position))
	#print(in_menu)
	if global_position.distance_to(drone.global_position) < message_range:
		menu_in_use = true
		gui.message_box.visible = true
		if message:
			message_ui = message
		if message_index == -1:
			gui.message.text = "Give me yo crystals, for save keeping."
		if message_index >= 0:
			in_menu = true
			#drone.look_at_override = $items.get_children()[message_index -1]
			var this_msg = message[message_index]
			var buy_text = "Deposit all"
			message_options = ["Deposit", "Quit"]

			
			if message_options:
				if Input.is_action_just_pressed("menu_select"):
					var action = message_options[message_option_index -1]
					if action == "Deposit":
						#TODO
						$sell.play()
						if "bank" not in drone.inventory:
							drone.inventory["bank"] = 0
						drone.inventory["bank"] += drone.inventory["crystals"]
						drone.inventory["crystals"] = 0
						drone.save_game()
						message_index = -1
					if action == "Quit":
						message_index = -1
						message_option_index = 1
						gui.message.visible = false

		else:
			in_menu = false
			#message_index = -1
			#drone.look_at_override = null
			message_options = null
	else:
		if menu_in_use:
			menu_in_use = false
			gui.message_box.visible = false
			message_index = -1
			gui.message.text = ""
			#message = []
			#drone.look_at_override = null
			message_options = null
	#NPC messages
	#if not message_ui:
		#message_warning.visible = false
	#	gui.message_box.visible = false
	
