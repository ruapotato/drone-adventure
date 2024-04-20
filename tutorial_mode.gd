extends Node3D
@onready var gui = $gui
@onready var pause_screen = $pause_screen
@onready var drone = $drone
@onready var unlock_sound = $unlock_sound
@onready var contol_images = $contols

var font = "[font_size=40][outline_size=5][outline_color=black]"
var todo = {"throttle": font + "Push the [color=red]left joystick up[/color] to increase throttle.",
"hover": font + "[color=red]Hover[/color] near the ground for 7 seconds.",
"turn": font + "While hovering, push the [color=red]left joystick to the right or left[/color] to turn.",
"forward": font + "While hovering, push the [color=red]right joystick up[/color] to tilt and move forward. You'll need to increase throttle to keep hovering.",
"shoot": font + "[color=red]Right trigger[/color] to shoot. [color=red]Hold the left trigger[/color] to hover-aim, this will let you move like an FPS.",
"end": font + "Those are the basics. Have fun getting a hang of it before playing the main game!"}

var stage = 0
var hover_counter = 0
var friendly_time = 11.0
var friendly_time_am = true
var message
var init_turn = 0
var hover_index = 0
var control_sensitivity_effector

func _ready():
	message = gui.find_child("message")
	gui.find_child("message_box").visible = true
	pause_screen.find_child("resume").text = "Next"
	pause_screen.find_child("toggle_skin").visible = false
	drone.control_lock_tilt = true
	drone.control_lock_yaw = true

func hurt(whatev, man):
	pass

func pause():
	if pause_screen.visible:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 0.01
	pause_screen.visible = not pause_screen.visible

func show_image(image_name):
	for kid in contol_images.get_children():
		if kid.name != image_name:
			kid.visible = false
		else:
			kid.visible = true
	
func do_stage(delta):
	var act = todo.keys()[stage]
	var act_info = todo[act]
	message.text = act_info
	if act == "throttle":
		show_image("hover")
		if drone.linear_velocity.y > 1.5:
			print("throttle unlock")
			stage += 1
			unlock_sound.play()
			pause()
	
	if act == "end":
		if (drone.linear_velocity * Vector3(1,0,1)).length() > 13:
			gui.find_child("message_box").visible = false
			act = null
	
	if act == "shoot":
		show_image("shoot")
		if Input.is_action_pressed("aim"):
			if Input.is_action_just_pressed("fire"):
				stage += 1
				contol_images.visible = false
				unlock_sound.play()
				pause()
	
	if act == "forward":
		show_image("forward")
		if (drone.linear_velocity * Vector3(1,0,1)).length() > 7:
			stage += 1
			unlock_sound.play()
			pause()
	if act != "turn":
		init_turn = drone.global_rotation.y
	if act == "turn":
		show_image("turn")
		print(init_turn - drone.global_rotation.y)
		if init_turn - drone.global_rotation.y > PI/3:
			stage += 1
			drone.control_lock_tilt = false
			unlock_sound.play()
			pause()
	if act == "hover":
		hover_index += delta * 5
		if int(hover_index) % 2 == 0:
			show_image("hover")
		else:
			show_image("idle")
		hover_counter += delta
		var hover_height = drone.global_position.y
		if hover_height > 3:
			message.text += "\nYou're too high! Lower your throttle by moving the left joystick closer to the center."
			hover_counter = 0
		elif hover_height < .3:
			message.text += "\nYou're too low! Increase your throttle by moving the left joystick up a little."
			hover_counter = 0
		else:
			message.text += "\nNice height! Keep this up for a bit longer."
			if hover_counter > 7:
				print("hover unlock")
				drone.control_lock_yaw = false
				stage += 1
				unlock_sound.play()
				pause()
		print()
		#if drone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	drone.power_cell = 100
	do_stage(delta)
