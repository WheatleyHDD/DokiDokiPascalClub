extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var goto_section: String = ""
signal pressed_with_node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	emit_signal("pressed_with_node", self)
