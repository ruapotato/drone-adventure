extends Node3D

@onready var simple_home = preload("res://scenes/portal_home.tscn")
@onready var area =  $Area3D
@onready var fog =  $FogVolume
@onready var dist_fog = $dist_fog

var chicken
var world
var vt
var init_done = false
var init_countdown = 2
var disabled = false
var within_range = 70

var fog_colors = ["#FF0000","#FF7F00","#FFFF00","#00FF00","#0000FF","#4B0082","#9400D3"]
var color_index = 0.0

func _ready():
	chicken = get_chicken()
	world = chicken.world
	vt = world.dirt_vt
	
	#vt.smooth_sphere(global_position - Vector3(0,1,0), 10,200)
	#vt.do_box(global_position - Vector3(10,10,10), global_position + Vector3(10,10,10))
	#vt.do_sphere(global_position, 10)


func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if disabled:
		dist_fog.visible = false
		fog.visible = false
		return
	area.global_position.y += delta
	
	for other_area in area.get_overlapping_areas():
		if other_area != self:
			if "disabled" in other_area.get_parent() and not other_area.get_parent().disabled:
				other_area.get_parent().disabled = true
				other_area.get_parent().init_done = true
				print("Bad one:")
				print(other_area)
	for body in area.get_overlapping_bodies():
		if "removeable" in body.name:
			body.hide()
			body.collision_mask = 0
			body.set_deferred("global_position", body.global_position + Vector3(0, -50, 0))
			#if body.name != "RigidBody3D" and body.global_position != Vector3(0,0,0):
			#print(body.name)
			#print(body.global_position)
	
	#Fog
	if not init_done:
		color_index += delta * 5
		var wanted_color = Color(fog_colors[int(color_index)%len(fog_colors)])
		var dist = global_position.distance_to(chicken.global_position) 
		# 3000 = volumetric fog length
		if dist > 3000:
			#fog.visible = false
			dist_fog.get_active_material(0).albedo_color = dist_fog.get_active_material(0).albedo_color.lerp(wanted_color, delta * 10)
			dist_fog.visible = true
		else:
			#fog.visible = true
			fog.material.albedo = fog.material.albedo.lerp(wanted_color, delta * 10)
			dist_fog.visible = false
		if dist < 50:
			var target_density = (global_position.distance_to(chicken.global_position)/50)/10
			fog.material.density = lerp(fog.material.density,target_density,delta * 10)
		else:
			fog.material.density = lerp(fog.material.density, 1.0, delta/10)
		
		
		
		
		if init_countdown > 0:
			init_countdown -= delta
		if init_countdown < 0 and global_position.distance_to(chicken.global_position) < within_range:
			init_done = true
			dist_fog.visible = false
			fog.visible = false
			#vt.smooth_sphere(global_position, 25,400)
			#vt.do_sphere(global_position, 10)
			vt.mode = VoxelTool.MODE_ADD
			vt.do_box(global_position - Vector3(15,5,15), global_position + Vector3(15,0,15))
			vt.mode = VoxelTool.MODE_REMOVE
			vt.do_box(global_position - Vector3(15,0,15), global_position + Vector3(15,15,15))
			

			var new_home = simple_home.instantiate()
			#new_home.set_deferred("global_position",Vector3(global_position.x,global_position.x + .2,global_position.y))
			add_child(new_home)
	pass
