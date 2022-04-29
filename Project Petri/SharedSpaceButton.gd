extends Control

signal shared_space_edited(name, value)
signal shared_space_to_delete(name)

onready var label := $Container/Label
onready var delete_pop := $DeletePop
onready var edit_pop := $EditPop
onready var token_edit := $EditPop/TokenEdit

var space_name
var value


func init(name, value):
	self.space_name = name
	self.value = value
	
	
func _ready():
	label.text = space_name + ": "+str(value)


func _on_DeleteButton_pressed():
	delete_pop.set_global_position(rect_global_position)
	delete_pop.popup()


func _on_EditButton_pressed():
	token_edit.text = str(value)
	edit_pop.set_global_position(rect_global_position)
	edit_pop.popup()


func _on_ConfirmDeleteButton_pressed():
	emit_signal("shared_space_to_delete", space_name)
	


func _on_ConfirmEditButton_pressed():
	if token_edit.text.is_valid_integer():
		value = token_edit.text
		label.text = space_name + ": "+str(value)
		emit_signal("shared_space_edited", space_name, value)
