extends Area3D

@onready var mesh = $Mesh
@export var rotation_speed := 3.0
@export var reflection_distance := 2.0  # Distance at which boss attempts reflection

var speed := 0.0
var boss = null
var sword_edge = null
var reflected := false
var sword 

func _physics_process(delta: float) -> void:
	# Get direction to current target
	var direction
	if reflected:
		direction = (boss.global_position - global_position).normalized()
	else:
		direction = (boss.player.global_position - global_position).normalized()
	
	# Move towards target
	position += direction * speed * delta
	
	# Rotate mesh for visual effect
	mesh.rotate_y(rotation_speed * delta)
	mesh.rotate_x(rotation_speed * 0.5 * delta)
	
	# Check for boss reflection when close enough
	if reflected and not boss.is_vulnerable:
		var distance_to_boss = global_position.distance_to(boss.global_position)
		if distance_to_boss <= reflection_distance:
			_attempt_boss_reflection()

func launch(initial_speed: float) -> void:
	speed = initial_speed
	reflected = false
	
	# Launch effect
	var scale_tween = create_tween()
	mesh.scale = Vector3.ZERO
	scale_tween.tween_property(mesh, "scale", Vector3.ONE, 0.2)
	scale_tween.set_trans(Tween.TRANS_BACK)
	scale_tween.set_ease(Tween.EASE_OUT)

func reflect() -> void:
	if reflected:
		return
		
	reflected = true
	
	# Visual feedback
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh, "scale", Vector3.ONE * 1.5, 0.1)
	flash_tween.tween_property(mesh, "scale", Vector3.ONE, 0.1)

func _attempt_boss_reflection() -> void:
	var did_reflect = boss._on_energy_ball_reflected()
	
	if did_reflect:
		reflected = false
		speed *= boss.speed_increase
		# Add max speed check
		if speed > boss.max_speed:
			speed = boss.max_speed
			
		var flash_tween = create_tween()
		flash_tween.tween_property(mesh, "scale", Vector3.ONE * 1.8, 0.15)
		flash_tween.tween_property(mesh, "scale", Vector3.ONE, 0.15)
	else:
		boss._on_energy_ball_hit_boss()

func _on_area_entered(area: Area3D) -> void:
	sword = boss.player.find_child("sword")
	if sword.is_animating:
		sword_edge = sword.find_child("Cutting Edge")
		if area == sword_edge and not reflected:
			reflect()

func _on_body_entered(body: Node3D) -> void:
	if body == boss.player and not reflected:
		print("boss.player hit!")
		boss.player.flip_gravity()
		boss._on_energy_ball_hit_player()  # Notify boss about hit
		queue_free()
