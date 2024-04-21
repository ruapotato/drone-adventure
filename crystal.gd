extends Area3D

var value = null
var message_range = 3
var bob_speed = .7
var timer = 0
var drone
var world
var init_pos
var collected = false
var collected_animation = .5
var shatter_range = 1


func get_drone():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("drone"))

# Called when the node enters the scene tree for the first time.
func _ready():
	name += "_crystal"
	drone = get_drone()
	world = drone.get_parent()
	#value = int(name.split("_")[0])
	if not value:
		init_pos = global_position + Vector3(0,randi_range(0,3),0)
		value = randi_range(1,200)
		value = int(value/randi_range(1,100)) + 1
	else:
		$shatter_sound.play()
	#	init_pos = global_position + Vector3(0,.2,0)
	#print(value)
	var color
	if value >= 200:
		color = Color("#ffffff")
	elif value >= 150:
		color = Color("#ffffcc")
	elif value >= 100:
		color = Color("#ff9999")
	elif value >= 50:
		color = Color("#ff66ff")
	elif value >= 20:
		color = Color("#3366ff")
	elif value >= 10:
		color = Color("#006699")
	else:
		color = Color("#003300")
	
	var color_material = StandardMaterial3D.new()
	color_material.albedo_color = color
	color_material.metallic = .75
	color_material.roughness = .07
	color_material.emission_enabled = true
	color_material.emission = color
	color_material.emission_energy_multiplier = value /100
	color_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	color_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	color_material.cull_mode = BaseMaterial3D.CULL_FRONT
	#color_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	#color_material.no_depth_test = true
	
	var outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(0,0,0)
	outline_material.metallic = .75
	outline_material.roughness = .07
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	#outline_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_material.grow = true
	outline_material.grow_amount = .005
	
	color_material.next_pass = outline_material
	color_material.roughness = .2
	color_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	color_material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	find_child("Upright_crystal").set_surface_override_material(0, color_material)
	
	#print(color)
	#Hid unneded meshes
	#for mesh in $Armature/Skeleton3D.get_children():
	#	if mesh.name != name:
	#		mesh.visible = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += (delta * bob_speed)
	if not collected:
		var bob_pos
		if int(timer) % 2 == 0:
			bob_pos = (timer - int(timer)) - .5
		else:
			bob_pos = .5 - (timer - int(timer))
		#print(bob_pos)
		global_position.y = init_pos.y + (bob_pos/5)
		
	if collected:
		collected_animation -= delta
		global_position = drone.global_position
		rotate_y(-delta * 5)
		global_position.y += 1.3 + abs(collected_animation - 1)
		if collected_animation < 0:
			#queue_free()
			visible = false
	
	#if global_position.distance_to(player.global_position) < message_range:
	#	if message:
	#		player.message_ui = message

func shatter():
	if value == 1:
		collected = true
		return
	var number_to_spit_into = randi_range(2,value)
	if number_to_spit_into > 3:
		number_to_spit_into = 3
	for split in range(0,number_to_spit_into):
		var offset = Vector3(0,0,0)
		offset.x = randi_range(-shatter_range,shatter_range)
		offset.z = randi_range(-shatter_range,shatter_range)
		world.add_crystal_to_world(int(value/number_to_spit_into),global_position + offset)
	collected = true
func _on_body_entered(body):
	if body == drone:
		#print("I'm colleded")
		$collected_sound.play()
		drone.inventory["crystals"] += value
		drone.save_game()
		#print(player.inventory["crystals"])
		collected = true
	else:
		if body.name != "wall":
			shatter()

