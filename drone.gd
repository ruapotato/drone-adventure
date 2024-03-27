extends RigidBody3D

@onready var bullet = preload("res://bullet.tscn")
@onready var camera = $Camera3D
@onready var target = $Label3D
@onready var shoot_from = $shoot_from
@onready var back_cam_mount = $back_cam_mount
@onready var speed_collision = $speedCollision

var collision_size_at_rest = .075

var unlocked_gun = true
var unlocked_landgun = true
var shoot_speed = 34

var throttle = 0.0
var max_throttle = 3.5

var yaw = 0.0
var yaw_speed = 3

var pitch = 0.0
var pitch_speed = 5

var roll = 0.0
var roll_speed = 5
var tp_cooldown = 0

var crystals = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func fire_landgun():
	if not unlocked_landgun:
		return
	var new_bullet = bullet.instantiate()
	new_bullet.set_deferred("global_position", shoot_from.global_position)
	new_bullet.add_mode = true
	#new_bullet.init_pos = shoot_from.global_position
	#new_bullet.init_vel = linear_velocity + (-global_transform.basis.z *  shoot_speed)
	#new_bullet.init_vel = (-global_transform.basis.z *  shoot_speed)
	
	
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-camera.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)

func fire_normal():
	if not unlocked_gun:
		return
	var new_bullet = bullet.instantiate()
	new_bullet.set_deferred("global_position", shoot_from.global_position)
	new_bullet.add_mode = false
	#new_bullet.init_pos = shoot_from.global_position
	#new_bullet.init_vel = linear_velocity + (-global_transform.basis.z *  shoot_speed)
	#new_bullet.init_vel = (-global_transform.basis.z *  shoot_speed)
	
	
	new_bullet.add_collision_exception_with(self)
	new_bullet.linear_velocity = linear_velocity
	new_bullet.apply_impulse(-camera.global_transform.basis.z *  shoot_speed)
	apply_impulse(global_transform.basis.z * .1)
	get_parent().add_child(new_bullet)
	
	
func _unhandled_input(event):
	if event.is_action("throttle"):
		throttle = -event.axis_value * max_throttle
	if event.is_action("yaw"):
		yaw = -event.axis_value
		
		#Odd bug fix Range is 1-0 but jumps to -1 at most right
		#not sure why it jumps to -1
		if yaw == -1:
			yaw = 0
		yaw = (yaw * 2) - 1
		
		#print(event.axis_value)
	if event.is_action("pitch"):
		pitch = event.axis_value
	if event.is_action("roll"):
		roll = -event.axis_value
		#print(event)

	if event.is_action_pressed("fire_right"):
		fire_normal()
	if event.is_action_pressed("fire_left"):
		fire_landgun()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if tp_cooldown > 0:
		tp_cooldown -= delta
	#print()
	if linear_velocity.length() > 5:
		speed_collision.shape.radius = collision_size_at_rest * ((linear_velocity.length()/5) + 1)
	else:
		speed_collision.shape.radius = collision_size_at_rest
	#rotate_y(yaw * delta)
	#linear_velocity.y += throttle * delta
	apply_impulse(global_transform.basis.y * delta * throttle)
	
	if abs(yaw) > .01:
		#print(yaw)
		rotate_y(yaw * yaw_speed * delta)
		
	if abs(pitch) > .01:
		#rotation.x = (pitch * PI)/2
		rotation.x = lerp(rotation.x,  (pitch * PI)/2, delta * 3)
	else:
		rotation.x = lerp(rotation.x,  0.0, delta * 4)

	if abs(roll) > .01:
		#rotation.z = (roll * PI)/2
		rotation.z = lerp(rotation.z,  (roll * PI)/2, delta * 3)
	else:
		rotation.z = lerp(rotation.z, 0.0, delta * 4)
	#print(throttle)

