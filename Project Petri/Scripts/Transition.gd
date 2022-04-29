extends Area2D

signal trans_saved(trans)
signal trans_deleted(trans)

onready var name_label := $"Label"
onready var position_in := $"Position In"
onready var position_out := $"Position Out"
onready var position_in2 := $"Position In2"
onready var position_out2 := $"Position Out2"
onready var edit_popup := $EditPopup
onready var name_text := $EditPopup/NameText
onready var popup_pos := $PopupPos
onready var action_scroll := $EditPopup/ActionScroll
onready var argument_text := $EditPopup/ArgumentText
onready var save_button := $EditPopup/SaveChangesButt
onready var delete_button := $EditPopup/DeleteButt
onready var t1 := $t1
onready var t2 := $t2

var trans_name
var trans_act: int
var trans_arg: String
var func_names
var func_tips
var index
var selected := false
var following := false
var edited := false
var deleted := false
var created : = false
var mouse_position_offset : Vector2

var in1_arcs := []
var in2_arcs := []

func init(trans_name, act, arg, func_names, func_tips, index, created):
	self.trans_name = trans_name
	self.trans_act = act
	self.trans_arg = arg
	self.func_names = func_names
	self.func_tips = func_tips
	self.index = index
	self.created = created
	if created:
		following = true


func _ready():
	name_label.text = trans_name
	action_scroll.add_item("No Action")
	for func_name in func_names:
		action_scroll.add_item(func_name)
	if trans_act == -1:
		action_scroll.select(0)
		argument_text.placeholder_text = "no action selected"
	else:
		action_scroll.select(trans_act + 1)
		argument_text.text = trans_arg
	

#quando uma nova transição é criada, ela segue a posição do rato do utilizador até ele clicar onde a deseja posicionar
#durante o resto do tempo, ela só segue o rato se o utilizador a estiver a arrastar
func _on_Transition_input_event(viewport, event, shape_idx):
	if Input.is_action_just_pressed("click"):
		if following:
			following = false
			#guardar nova posição
			emit_signal("trans_saved", self)
		else:	
			selected = true
			mouse_position_offset = global_position - get_global_mouse_position()
	elif Input.is_action_just_released("click"):
		selected = false
		#guardar posição inicial
		emit_signal("trans_saved", self)
		

func _physics_process(delta):
	if selected or following:
		global_position = get_global_mouse_position() + mouse_position_offset
		
		
func _process(delta):
	if in1_arcs.size() > 0:
		t1.visible = true
	else:
		t1.visible = false
		
	if in2_arcs.size() > 0:
		t2.visible = true
	else:
		t2.visible = false


func _on_EditButton_pressed():
	name_text.text = name_label.text
	edit_popup.set_global_position(popup_pos.global_position)
	edit_popup.popup()


func _on_SaveChangesButt_pressed():
	name_label.text = name_text.text
	trans_act = action_scroll.selected - 1
	if argument_text.text!= "":
		trans_arg = argument_text.text
	else:
		trans_arg = "_"
	emit_signal("trans_saved", self)


func _on_DeleteButt_pressed():
	emit_signal("trans_deleted", self)


#to solve a godot bug
func _on_OptionButton_toggled(button_pressed):
	save_button.visible = !save_button.visible
	delete_button.visible = !delete_button.visible
	argument_text.visible = !argument_text.visible


func _on_OptionButton_item_selected(index):
	argument_text.text = ""
	if index == 0:
		argument_text.placeholder_text = "no action selected"
	else:
		argument_text.placeholder_text = func_tips[index-1]
