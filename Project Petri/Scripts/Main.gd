extends Node


enum State{
	MAIN_MENU,
	AGENT_MENU,
	PETRI_VISUAL,
	SIMULATION,
	PETRI_IN_SIM
}


onready var grid_menu := $Grid
onready var petri_menu := $PetriVisual
onready var agent_menu := $AgentMenu
onready var main_menu := $MainMenu
onready var agent_list := $AgentMenu/AgentScroll/AgentList

var plGameAgent = preload("res://Scripts/GameAgent.gd")
var plAgentButton = load("res://Scripts/AgentButton.tscn")
const Util = preload("res://Scripts/util.gd")

export(String, FILE) var grid_path = "res://grids/default.tres"

var current_state: int = State.SIMULATION

# Called when the node enters the scene tree for the first time.
func _ready():
	grid_menu.connect("agent_selected",self,"handle_agent_selected")
	grid_menu.connect("simulation_closed", self, "handle_simulation_closed")
	petri_menu.connect("petri_visual_closed", self, "handle_petri_visual_closed")
	randomize()
	grid_menu.init(grid_path)
	grid_menu.visual_update()
	grid_menu.visible = true
	petri_menu.visible = false
	agent_menu.visible = false
	main_menu.visible = false
	
#	print("\nPETRI 1")
#	agent1.petri_brain.print_current_configuration(Grid, agent1)
#	print(str(agent1.petri_brain.get_position_array()))
#	print(str(agent1.petri_brain.get_transition_array()))
#	print("\nPETRI 2")
#	agent2.petri_brain.print_current_configuration(Grid, agent2)
#	print(str(agent2.petri_brain.get_position_array()))
#	print(str(agent2.petri_brain.get_transition_array()))
	#update 10 times
#	for i in 10:
#
#		print("\nUpdate #" + str(i))
##		print("PETRI 1")
##		Grid.agent_1.petri_brain.update(Grid)
##		Grid.agent_1.petri_brain.print_current_configuration(Grid)
##		print("PETRI 2")
##		Grid.agent_2.petri_brain.update(Grid)
##		Grid.agent_2.petri_brain.print_current_configuration(Grid)
#		Grid.update()
	

#func _input(event):
#	if event.is_action_pressed("ui_select"):
#		print("\nUpdate #" + str(update_index))
#		Grid.update()
#		update_index += 1
#		Grid.visual_update()



func handle_petri_visual_closed():
	if current_state == State.PETRI_VISUAL:
		petri_menu.visible = false
		main_menu.visible = true
		current_state == State.MAIN_MENU
	elif current_state == State.PETRI_IN_SIM:
		petri_menu.visible = false
		grid_menu.visible = true
		current_state == State.SIMULATION
		grid_menu.visual_update()
		grid_menu.update_agent_list()


func handle_simulation_closed():
	grid_menu.visible = false
	main_menu.visible = true
	current_state = State.MAIN_MENU
	

func handle_agent_selected(agent):
	grid_menu.visible = false
	petri_menu.destroy_petri()
	petri_menu.create_petri(agent)
	petri_menu.visible = true
	current_state = State.PETRI_IN_SIM


func _on_AgentButton_pressed():
	main_menu.visible = false
	for child in agent_list.get_children():
		agent_list.remove_child(child)
		child.queue_free()
		
	var agent_types = []
	var files = Util.list_files_in_directory(Util.AGENT_FILE_PATH)
	for file in files:
		agent_types.append(plGameAgent.new(Util.generate_agent_info_from_file(file), Vector2.ZERO, null))
		
	for agent in agent_types:
		var new_butt = plAgentButton.instance()
		new_butt.init(agent, self)
		agent_list.add_child(new_butt)
		
	agent_menu.visible = true
	current_state = State.AGENT_MENU


func agent_button_pressed(agent):
	agent_menu.visible = false
	petri_menu.destroy_petri()
	petri_menu.create_petri(agent)
	petri_menu.visible = true
	current_state = State.PETRI_VISUAL
	

func _on_GridButton_pressed():
	main_menu.visible = false
	grid_menu.visible = true
	current_state = State.SIMULATION


func _on_CreateAgentButton_pressed():
	agent_menu.visible = false
	petri_menu.destroy_petri()
	var agent = plGameAgent.new(Util.generate_agent_info_from_file(Util.EMPTY_AGENT_FILE_PATH), Vector2.ZERO, null)
	petri_menu.create_petri(agent)
	petri_menu.visible = true
	current_state = State.PETRI_VISUAL


func _on_GoBackButton_pressed():
	agent_menu.visible = false
	main_menu.visible = true
	current_state = State.MAIN_MENU
