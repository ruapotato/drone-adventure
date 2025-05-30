extends RigidBody3D

@onready var crystal = preload("res://scenes/crystal.tscn")
@onready var shape = $CollisionShape3D

@onready var area = $Area3D

@onready var normal_trail = $normal_trail
@onready var add_trail =$add_trail

var mesh
var ttk = .1
var dead = false
var going_to_kill = null
var add_mode = false

var boom_color
var chicken
var world
var vt
var damage = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	boom_color = StandardMaterial3D.new()
	boom_color.albedo_color = Color(1,0,0)
	boom_color.metallic = .75
	boom_color.roughness = .07
	boom_color.emission_enabled = true
	boom_color.emission = Color(1,0,0)
	boom_color.emission_energy_multiplier = 50
	#add_collision_exception_with(area)
	chicken = get_chicken()
	#for child in get_chicken().get_children():
	#	add_collision_exception_with(child)
	world = chicken.world
	#if not chicken.tutorial_mode:
		#vt = world.dirt_vt
	if not add_mode:
		normal_trail.emitting = true
		#vt.mode = VoxelTool.MODE_REMOVE
		visible
		$add_trail/MeshInstance3D.visible = false
		mesh = $normal_trail/MeshInstance3D
	else:
		add_trail.emitting = true
		$normal_trail/MeshInstance3D.visible = false
		mesh = $add_trail/MeshInstance3D

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if going_to_kill:
		mass = 1000
		linear_velocity = Vector3(0,0,0)
		ttk -= delta
		if ttk > 0:
			mesh.set_surface_override_material(0, boom_color)
			shape.shape.radius += delta * 10
			mesh.mesh.radius += delta * 10
			mesh.mesh.height += delta * 20
		if ttk < 0 and not dead:
			#var new_decal = Decal.new()
			if not chicken.tutorial_mode:
				if not add_mode:
					world.dirt_vt.mode = VoxelTool.MODE_REMOVE
					world.dirt_vt.do_sphere(global_position, 1.5 * 2)
					world.crystal_vt.mode = VoxelTool.MODE_REMOVE
					world.crystal_vt.do_sphere(global_position, 1.5 * 2)
				else:
					world.crystal_vt.mode = VoxelTool.MODE_ADD
					world.crystal_vt.do_sphere(global_position, 1.5)
			#new_decal.texture_albedo = load("res://import/damage.png")
			#new_decal.texture_normal = load("res://import/damage.png")
			#new_decal.set_deferred("global_position",global_position)
			#get_parent().add_child(new_decal)
			dead = true
			queue_free()
			#shape.queue_free()
			#mesh.queue_free()
		
		



func _on_area_3d_body_entered(body):
	if "crow" in body.name:
		body.visible = false
		world.add_crystal_to_world(randi_range(20,100),body.global_position)
		$boom.play()
		return
	
	if global_position.distance_to(chicken.global_position) < 1.7:
		return
	if "ufo" in body.name:
		world.hurt(body, damage)
		if not "mini_ufo" in body.name:
			damage = 0
		going_to_kill = body
		$boom.play()
		
	if global_position.distance_to(chicken.global_position) < 1.7:
		return
	
	if body.name != "chicken" and body.name != "bullet" and body != self:
		world.hurt(body, damage)
		damage = 0
		going_to_kill = body
		$boom.play()
