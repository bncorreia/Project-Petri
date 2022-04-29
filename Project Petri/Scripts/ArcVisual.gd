extends Line2D

signal arc_saved(arc)
signal arc_deleted(arc)

onready var info := $Info
onready var weight_label := $Info/Weight
onready var edit_popup := $Info/EditPopup
onready var weight_text := $Info/EditPopup/WeightText
onready var popup_pos := $Info/PopupPos

var from
var to
var is_from_pos: bool
var weight
var offset
var color

func init(from, to, is_from_pos, weight, offset, color):
	global_position = Vector2(0,0)
	global_rotation = 0
	self.from = from
	self.to = to
	self.is_from_pos = is_from_pos
	self.weight = weight
	self.offset = offset
	self.color = color
	
	default_color = color
	
func _ready():
	weight_label.text = str(weight)

func _process(delta):
	clear_points()
	var f1 = from.position_out.global_position - offset
	var f2 = from.position_out2.global_position - offset
	var t1 = to.position_in.global_position - offset
	var t2 = to.position_in2.global_position - offset
	
	var t_mid = (t1.x + t2.x)/2
	var f
	var t 
	
	if abs(f1.x-t_mid) < abs(f2.x-t_mid):
		f = f1
	else:
		f = f2
		
	add_point(f)
	
	if abs(f.x-t1.x) < abs(f.x-t2.x):
		t = t1
		add_point(t1)
		if to.in2_arcs.find(self) != -1:
			to.in2_arcs.erase(self)
		if to.in1_arcs.find(self) == -1:
			to.in1_arcs.append(self)
	else:
		t = t2
		add_point(t2)
		if to.in1_arcs.find(self) != -1:
			to.in1_arcs.erase(self)
		if to.in2_arcs.find(self) == -1:
			to.in2_arcs.append(self)
			
	info.global_position = (f+t)/2 + offset
	 

func del():
	if to.in2_arcs.find(self) != -1:
		to.in2_arcs.erase(self)
	if to.in1_arcs.find(self) != -1:
		to.in1_arcs.erase(self)
	queue_free()

func _on_EditButton_pressed():
	weight_text.text = weight_label.text
	edit_popup.set_global_position(popup_pos.global_position)
	edit_popup.popup()


func _on_SaveChangesButt_pressed():
	if weight_text.text.is_valid_integer():
		weight_label.text = weight_text.text
		emit_signal("arc_saved", self)


func _on_DeleteButt_pressed():
	emit_signal("arc_deleted", self)
