extends Node3D

var TP3
var TP4
var portal_point_to_city
var drone
var TP4_corridor

# Called when the node enters the scene tree for the first time.
func _ready():
	TP3 = get_parent().find_child("TP3_shape")
	TP4 = get_parent().find_child("TP4_shape")
	drone = get_drone()
	portal_point_to_city = drone.get_parent().find_child("portal_in_point")
	#TP4_corridor = get_parent().find_child("CorridorPortalA")

func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if name == "TP4":
		global_position = portal_point_to_city.global_position
		global_rotation = portal_point_to_city.global_rotation

		


func _on_body_entered(body):
	#if "velocity" in body:
	#	body.velocity.x = body.velocity.x * -1
	#	body.velocity.z = body.velocity.z * -1
	if "tp_cooldown" in body:
		if body.tp_cooldown <= 0:
			#if "linear_velocity" in body:
			#	body.linear_velocity = Vector3(0,0,0)
			#if "velocity" in body:
			#	body.velocity = Vector3(0,0,0)
			if name == "TP3":
				body.tp_cooldown = 1
				#var tmp_height = body.global_position.y
				#var tmp_left = body.global_position.z
				#body.global_position = TP4.global_position
				#body.global_position.y = tmp_height
				#body.global_position.z = tmp_left
				
				
				var offset = global_position - body.global_position
				body.global_position = TP4.global_position + offset
				
			if name == "TP4":
				body.tp_cooldown = 1
				#var tmp_height = body.global_position.y
				#var tmp_left = body.global_position.z
				#body.global_position = TP3.global_position
				#body.global_position.y = tmp_height
				#body.global_position.z = tmp_left
				var offset = global_position - body.global_position
				body.global_position = TP3.global_position + offset

				#body.rotate_y(PI/2)
				
				#body.set_deferred("global_position",  TP3.global_position)
				#body.set_deferred("linear_velocity", body.linear_velocity)
				#print("TP to 1")
		#else:
		#	print("Wainting on cooldown: " + str(body.tp_cooldown ))
