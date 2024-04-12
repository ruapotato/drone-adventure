extends Node3D
@onready var gui = $gui

@onready var drone = $drone
@onready var unlock_sound = $unlock_sound

var todo = {"throttle": "Push the left joy stick stight up to incress throttle.",
"hover": "hover just off the ground for 7 seconds.",
"turn": "While still hovering, slowly push the same left joystick to the left or right. This will turn the drone.",
"forward": "While still hovering with the left stick, slowly push foward with the right stick. You'll need to incress throttle to keep hovering.",
"shoot": "Hold left trigger to hover aim. This will let you move much like an FPS. Right trigger to shoot.",
"end": "Those are the basics, have fun getting a hang of it before playing the main game."}

var stage = 0
var hover_counter = 0
var friendly_time = 11.0
var friendly_time_am = true
var message
var init_turn = 0

func _ready():
	message = gui.find_child("message")
	gui.find_child("message_box").visible = true

func do_stage(delta):
	var act = todo.keys()[stage]
	var act_info = todo[act]
	message.text = act_info
	if act == "throttle":
		if drone.linear_velocity.y > 1.5:
			print("throttle unlock")
			stage += 1
			unlock_sound.play()
	
	if act == "end":
		if (drone.linear_velocity * Vector3(1,0,1)).length() > 13:
			gui.find_child("message_box").visible = false
			act = null
	
	if act == "shoot":
		if Input.is_action_pressed("aim"):
			if Input.is_action_just_pressed("fire_right"):
				stage += 1
				unlock_sound.play()
	
	if act == "forward":
		if (drone.linear_velocity * Vector3(1,0,1)).length() > 7:
			stage += 1
			unlock_sound.play()
	if act != "turn":
		init_turn = drone.global_rotation.y
	if act == "turn":
		print(init_turn - drone.global_rotation.y)
		if init_turn - drone.global_rotation.y > PI/3:
			stage += 1
			unlock_sound.play()
	if act == "hover":
		hover_counter += delta
		var hover_height = drone.global_position.y
		if hover_height > 3:
			message.text += "\nYou're too high! Lower your throttle by moving the left stick closer to the center."
			hover_counter = 0
		elif hover_height < .3:
			message.text += "\nYou're too low! Increase your throttle by moving the left stick up a small amount."
			hover_counter = 0
		else:
			message.text += "\nNice hight! Keep this up for a bit longer!."
			if hover_counter > 7:
				print("hover unlock")
				stage += 1
				unlock_sound.play()
		print()
		#if drone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	drone.power_cell = 100
	do_stage(delta)
