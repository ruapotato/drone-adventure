extends Sprite2D

var chicken
# Called when the node enters the scene tree for the first time.
func _ready():
	chicken = get_chicken()

func get_chicken():
	var root_i_hope = get_parent()
	while root_i_hope.name != "world":
		root_i_hope = root_i_hope.get_parent()
	return(root_i_hope.find_child("chicken"))

func _process(delta):
	if not visible:
		return
	if chicken.unlocked_gun:
		if chicken.inventory["using"] == "gun":
			for kid in $Gun.get_children():
				kid.label_settings.font_color = Color(1,0,1)
		else:
			for kid in $Gun.get_children():
				kid.label_settings.font_color = Color(0,0,0)
		if not $Gun.visible:
			$Gun.visible = true
	else:
		if $Gun.visible:
			$Gun.visible = false
	if "land_making_gun" in chicken.inventory:
		if chicken.inventory["using"] == "land_making_gun":
			for kid in $Build.get_children():
				kid.label_settings.font_color = Color(1,0,1)
		else:
			for kid in $Build.get_children():
				kid.label_settings.font_color = Color(0,0,0)
		if not $Build.visible:
			$Build.visible = true
	else:
		if $Build.visible:
			$Build.visible = false
	if "laser_gun" in chicken.inventory:
		if chicken.inventory["using"] == "laser_gun":
			for kid in $Laser.get_children():
				kid.label_settings.font_color = Color(1,0,1)
		else:
			for kid in $Laser.get_children():
				kid.label_settings.font_color = Color(0,0,0)
		if not $Laser.visible:
			$Laser.visible = true
	else:
		if $Laser.visible:
			$Laser.visible = false
	if "weckingball" in chicken.inventory:
		if chicken.inventory["using"] == "weckingball":
			for kid in $Ball.get_children():
				kid.label_settings.font_color = Color(1,0,1)
		else:
			for kid in $Ball.get_children():
				kid.label_settings.font_color = Color(0,0,0)
		if not $Ball.visible:
			$Ball.visible = true
	else:
		if $Ball.visible:
			$Ball.visible = false
