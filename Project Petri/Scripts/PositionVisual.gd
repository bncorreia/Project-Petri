extends Area2D


signal pos_saved(pos)
signal pos_deleted(pos)

enum Position_type{
	PRIVATE,
	PUBLIC,
	SHARED
	}
	

const Util = preload("res://Scripts/util.gd")

onready var sprite := $Sprite
onready var name_label := $"Name Label"
onready var arg_label := $ArgLabel
onready var position_in := $"Position In"
onready var position_out := $"Position Out"
onready var position_in2 := $"Position In2"
onready var position_out2 := $"Position Out2"
onready var edit_popup := $EditPopup
onready var name_text := $EditPopup/NameText
onready var scroll := $EditPopup/TypeScroll
onready var private_menu := $EditPopup/Private
onready var public_menu := $EditPopup/Public
onready var shared_menu := $EditPopup/Shared
onready var token_text := $EditPopup/Private/TokenText
onready var shared_text := $EditPopup/Shared/SharedText
onready var x_text := $EditPopup/Public/XText
onready var y_text := $EditPopup/Public/YText
onready var popup_pos := $PopupPos
onready var t1 := $t1
onready var t2 := $t2

var type: int = Position_type.PRIVATE
var pos_name: String
var tokens: int
var cord_x: int
var cord_y: int
var shared_name: String
var index 
var selected := false
var following := false
var edited := false
var deleted := false
var created : = false
var mouse_position_offset : Vector2

var in1_arcs := []
var in2_arcs := []

func init(pos_name, type, tokens, cord_x, cord_y, shared_name, index, created):
	self.pos_name = pos_name
	self.type = type
	self.tokens = tokens
	self.cord_x = cord_x
	self.cord_y = cord_y
	self.shared_name = shared_name
	self.index = index
	self.created = created
	if created:
		following = true
	
	
func _ready():
	name_label.text = pos_name
	token_text.text = str(tokens)
	shared_text.text = shared_name
	x_text.text = str(cord_x)
	y_text.text = str(cord_y)
	scroll.add_item("Private Position")
	scroll.add_item("Public Position")
	scroll.add_item("Shared Place")
	scroll.select(type)
	update_type()
	match type:
		Position_type.PRIVATE:
			sprite.modulate = Util.PRIVATE_POS_COLOR
			arg_label.text = str(tokens)
		Position_type.PUBLIC:
			sprite.modulate = Util.PUBLIC_POS_COLOR
			arg_label.text = str(cord_x)+", "+str(cord_y)
		Position_type.SHARED:
			sprite.modulate = Util.SHARED_POS_COLOR
			arg_label.text = shared_name


func update_type():
	match type:
		Position_type.PRIVATE:
			private_menu.visible = true
			public_menu.visible = false
			shared_menu.visible = false
		Position_type.PUBLIC:
			private_menu.visible = false
			public_menu.visible = true
			shared_menu.visible = false
		Position_type.SHARED:
			private_menu.visible = false
			public_menu.visible = false
			shared_menu.visible = true


#quando uma nova posição é criada, ela segue a posição do rato do utilizador até ele clicar onde a deseja posicionar
#durante o resto do tempo, ela só segue o rato se o utilizador a estiver a arrastar
func _on_Position_input_event(viewport, event, shape_idx):
	if Input.is_action_just_pressed("click"):
		if following:
			following = false
			#guardar nova posiçao
			emit_signal("pos_saved", self)
		else:	
			selected = true
			mouse_position_offset = global_position - get_global_mouse_position()
	elif Input.is_action_just_released("click"):
		selected = false
		#guardar posição inicial
		emit_signal("pos_saved", self)


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
	match type:
		Position_type.PRIVATE:
			sprite.modulate = Util.PRIVATE_POS_COLOR
			arg_label.text = token_text.text
		Position_type.PUBLIC:
			sprite.modulate = Util.PUBLIC_POS_COLOR
			arg_label.text = x_text.text+", "+y_text.text
		Position_type.SHARED:
			sprite.modulate = Util.SHARED_POS_COLOR
			arg_label.text = shared_text.text

	name_label.text = name_text.text
	emit_signal("pos_saved", self)
	edit_popup.hide()


func _on_DeleteButt_pressed():
	emit_signal("pos_deleted", self)
	edit_popup.hide()


func _on_TypeScroll_item_selected(index):
	type = index
	update_type()


#to solve a godot bug
func _on_TypeScroll_toggled(button_pressed):
	token_text.visible = !token_text.visible
	shared_text.visible = !shared_text.visible 
	x_text.visible = !x_text.visible
	y_text.visible = !y_text.visible
