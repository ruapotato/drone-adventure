extends Node3D
@onready var gui = $gui

@onready var drone = $drone
@onready var unlock_sound = $unlock_sound

var todo = {"throttle": "Push the left joy stick stight up to incress throttle.",
"hover": "hover just off the ground for 10 seconds.",
"turn": "While still hovering, slowly push the same left joystick to the left or right. This will turn the drone."}

var stage = 0
var hover_counter = 0

func do_stage(delta):
	var act = todo.keys()[stage]
	var act_info = todo[act]
	gui.message.text = act_info
	if act == "throttle":
		if drone.linear_velocity.y > 1.5:
			print("throttle unlock")
			stage += 1
			unlock_sound.play()
	if act == "hover":
		hover_counter += delta
		var hover_height = drone.global_position.y
		if hover_height > 3:
			gui.message.text += "\nYou're too high! Lower your throttle by moving the left stick closer to the center."
			hover_counter = 0
		elif hover_height < .3:
			gui.message.text += "\nYou're too low! Increase your throttle by moving the left stick up a small amount."
			hover_counter = 0
		else:
			gui.message.text += "\nNice hight! Keep this up for a bit longer!."
			if hover_counter > 10:
				print("hover unlock")
				stage += 1
		print()
		#if drone

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	drone.power_cell = 100
	do_stage(delta)
