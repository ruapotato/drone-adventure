extends Node3D

var TP1
var TP2

# Called when the node enters the scene tree for the first time.
func _ready():
	TP1 = get_parent().find_child("TP1_shape")
	TP2 = get_parent().find_child("TP2_shape")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	#if "velocity" in body:
	#	body.velocity.x = body.velocity.x * -1
	#	body.velocity.z = body.velocity.z * -1
	if "tp_cooldown" in body:
		if body.tp_cooldown <= 0:
			if name == "TP1":
				body.tp_cooldown = 1
				var tmp_height = body.global_position.y
				var tmp_left = body.global_position.z
				body.global_position = TP2.global_position
				body.global_position.y = tmp_height
				body.global_position.z = tmp_left
				#body.set_deferred("global_position",  TP2.global_position)
				#body.set_deferred("linear_velocity", body.linear_velocity)
				#print("TP to 2")
			if name == "TP2":
				body.tp_cooldown = 1
				var tmp_height = body.global_position.y
				var tmp_left = body.global_position.z
				body.global_position = TP1.global_position
				body.global_position.y = tmp_height
				body.global_position.z = tmp_left
				#body.set_deferred("global_position",  TP1.global_position)
				#body.set_deferred("linear_velocity", body.linear_velocity)
				#print("TP to 1")
		#else:
		#	print("Wainting on cooldown: " + str(body.tp_cooldown ))
