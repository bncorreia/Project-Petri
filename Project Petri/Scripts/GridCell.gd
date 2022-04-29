extends Area2D


onready var sprite := $Sprite
onready var token_label := $"Number of Tokens"

var parent
var cords: Vector2

func change_color(new_color: Color):
	sprite.modulate = new_color
	
	
func change_number_of_tokens(token_number: int):
	if token_number == 0:
		token_label.text = ""
	else:
		token_label.text = str(token_number)
	
	
func get_dimensions():
	return $CollisionShape2D.shape.extents

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.pressed:
		self.on_click(event.button_index)

func on_click(mouse_button_index):
	parent.cell_clicked(cords, mouse_button_index)
