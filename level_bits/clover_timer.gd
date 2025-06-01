extends Node3D
@onready var start_box = $Area3D
@onready var timer_sound = $timer_sound

var level_loader
var player
var count_down = 13
var counting = false
var started = false  # Track if we've started the sequence

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_loader = find_root()
	player = level_loader.find_child("player")
	# Initially hide child objects except mesh
	end()

func find_root(node=get_tree().root) -> Node:
	if node.name.to_lower() == "level_loader":
		return node
	for child in node.get_children():
		var found = find_root(child)
		if found:
			return found
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if counting:
		count_down -= delta
		
		if count_down < 0 and started:
			queue_free()
		elif count_down < 0:
			end()

func start() -> void:
	if not counting:
		print("Clover time!!!")
		timer_sound.play()
		counting = true
		started = true  # Mark that we've started the sequence
		count_down = 7  # Reset the countdown
		# Make all child objects visible
		for child in get_children():
			if child != start_box and child != timer_sound:
				child.visible = true

func end() -> void:
	print("Clover time end!")
	counting = false
	# Make all child objects invisible except mesh
	for child in get_children():
		if child != start_box and child != timer_sound:
			child.visible = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		start()
