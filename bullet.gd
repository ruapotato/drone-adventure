extends RigidBody3D

@onready var shape = $CollisionShape3D

@onready var mesh = $MeshInstance3D
@onready var area = $Area3D

@onready var normal_trail = $normal_trail
@onready var add_trail =$add_trail

var ttk = .1
var dead = false
var going_to_kill = null
var add_mode = false

var boom_color
var drone
var world
var vt

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
	drone = get_drone()
	#for child in get_drone().get_children():
	#	add_collision_exception_with(child)
	world = drone.world
	if not drone.tutorial_mode:
		vt = world.find_child("VoxelLodTerrain").get_voxel_tool()
		if not add_mode:
			normal_trail.emitting = true
			vt.mode = VoxelTool.MODE_REMOVE
		else:
			add_trail.emitting = true

func get_player():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("player"))


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if going_to_kill:
		mass = 10000
		linear_velocity = Vector3(0,0,0)
		ttk -= delta
		if ttk > 0:
			mesh.set_surface_override_material(0, boom_color)
			shape.shape.radius += delta * 10
			mesh.mesh.radius += delta * 10
			mesh.mesh.height += delta * 20
		if ttk < 0 and not dead:
			var new_decal = Decal.new()
			if not drone.tutorial_mode:
				vt.do_sphere(global_position, 1.5)
			new_decal.texture_albedo = load("res://import/damage.png")
			new_decal.texture_normal = load("res://import/damage.png")
			new_decal.set_deferred("global_position",global_position)
			get_parent().add_child(new_decal)
			dead = true
			queue_free()
			#shape.queue_free()
			#mesh.queue_free()
		
		



func _on_area_3d_body_entered(body):

	if body.name != "drone" and body.name != "bullet" and body != self:
		print()
		print(body.name)
		print(body.get_parent().name)
		print(body.get_parent().get_parent().name)
		print(body.name)
		if body.name == "ufo":
			body.life -= 1
			body.fly_ttl = 6
		if body.name == "mini_ufo":
			body.get_parent().life -= 1
		going_to_kill = body
		$boom.play()
