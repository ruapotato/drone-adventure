extends RigidBody3D

var spawn_point
var spawn_rot
var speed
# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_point = global_position
	spawn_rot = rotation


func _physics_process(delta):
	if global_position.distance_to(spawn_point) > .05:
		gravity_scale = 1.0
		speed = 1 - (global_position.distance_to(spawn_point) * 2)
		speed *= 40
		if speed > 0:
			var wanted_speed = global_position.direction_to(spawn_point) * speed
			linear_velocity = linear_velocity.lerp(wanted_speed,delta)
			if rotation != spawn_rot:
				rotation = rotation.lerp(spawn_rot, delta)
	else:
		gravity_scale = 0.0
		global_position = spawn_point
		rotation = spawn_rot

