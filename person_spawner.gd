extends Area3D


@onready var NPC = preload("res://npc.tscn")
var NPCs = []

var spawn_every = 10
var spawn_counter = spawn_every
var world
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_world()


func get_world():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope)

func spawn():
	var new_npc = NPC.instantiate()
	new_npc.npc_home_pos = global_position

	#var jobs =  find_child("jobs").get_children()
	#new_npc.npc_work_pos = jobs[randi() % jobs.size()].global_position
	
	new_npc.npc_type = "fighter"
	
	#new_npc.set_deferred("global_position", home_to_fill.global_position)
	world.add_child(new_npc)
	new_npc.global_position = global_position
	NPCs.append(new_npc)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	spawn_counter-= delta
	if spawn_counter < 0:
		spawn_counter = spawn_every
		spawn()
		
