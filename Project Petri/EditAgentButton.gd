extends Control

signal brush_agent_selected(agent)
signal brush_agent_to_edit(agent)
signal brush_agent_to_delete(agent)

onready var agent_butt := $Container/AgentButton
onready var edit_butt := $Container/EditButton
onready var agent_color := $Container/EditButton/AgentColor
onready var delete_pop := $DeletePop
var parent
var agent

func init(agent, parent):
	self.agent = agent
	self.parent = parent
	
func _ready():
	agent_butt.init(agent, self)
	agent_color.color = agent.type_color

func agent_button_pressed(agent):
	emit_signal("brush_agent_selected", agent)


func _on_EditButton_pressed():
	emit_signal("brush_agent_to_edit", agent)


func _on_EditButton2_pressed():
	delete_pop.set_global_position(rect_global_position)
	delete_pop.popup()


func _on_DeleteButton_pressed():
	emit_signal("brush_agent_to_delete", agent)
