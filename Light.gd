extends Button

const ADJACENT_DISTANCE = 85

@onready var customizeButton = %CustomizeButton

# Called when the node enters the scene tree for the first time.
func _ready():
	text = str(name.to_int())

func _on_pressed():
	if customizeButton.is_pressed():
		return
	checkNearbyButtons()

func checkNearbyButtons():
	var transform = get_transform().origin
	for child: Button in get_parent().get_children():
		if child == self:
			continue
		var t = child.get_transform().origin
		var diff = transform - t
		if diff.length() < ADJACENT_DISTANCE:
			print("toggling: ", child.name)
			child.set_pressed(!child.is_pressed())
