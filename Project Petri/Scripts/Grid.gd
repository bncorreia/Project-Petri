extends Node2D
class_name Grid


signal agent_selected(agent)
signal simulation_closed()

enum State{
	PLAY,
	EDIT,
	INSPECT
}


var plEditAgentButton = preload("res://Scripts/EditAgentButton.tscn")
var plSharedSpaceButton = preload("res://Scripts/SharedSpaceButton.tscn")
var plAgentButton = preload("res://Scripts/AgentButton.tscn")
var plGameAgent = preload("res://Scripts/GameAgent.gd")
var plGridCell = preload("res://Scripts/GridCell.tscn")
const Util = preload("res://Scripts/util.gd")
var play_icon = preload("res://botao-play-ponta-de-seta.png")
var pause_icon = preload("res://botao-de-pausa.png")
var inspect_icon = preload("res://magnifying-glass.png")
var edit_icon = preload("res://Edit_icon.png")

onready var cell_container := $CellContainer
onready var play_button := $PlayButt
onready var inspect_button := $InspectButt
onready var edit_agent_list := $AgentScroll/EditAgentList
onready var edit_space_list := $SpaceScroll/EditSpaceList
onready var cell_popup := $CellPopup
onready var token_edit := $CellPopup/TokenEdit
onready var agent_list := $CellPopup/AgentScroller/AgentList
onready var right_limit_pos := $RightLimit
onready var edit_instrunctions := $EditInstrunctionsLabel

export(String, FILE) var grid_path = "res://grids/empty.tres"
var empty_grid_path = "res://grids/empty.tres"

var state: int = State.PLAY

var selected_cell: Vector2 = Vector2.ZERO

var grid_name: String

var agent_types_names = []
var agent_types = []

#grelha onde se encontram os agentes Petri
var agent_grid = []
#grelha de ints que representam o numero de tokens em cada posição publica a que os agentes Petri podem aceder
var position_grid = []
#dicionario de "shared places" - a chave é o nome do place e o valor sao os tokens
var shared_places = {}

var visual_grid = []
var visual_offset_x := 1
var visual_offset_y := 1

var width: int
var heigth: int

var agent_brush: Util.agent_info = null

func _ready():
	init(grid_path)
	visual_update()
	
func init(path):
	agent_grid = []
	position_grid = []
	shared_places = {}
	visual_grid = []
	for child in cell_container.get_children():
		child.queue_free()
	
	state = State.INSPECT
	update_visual_state()

	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file "+ path +", error code ", err)
	
	#the first line of the grid file contains the grid name ex:"NAME default"
	var line = f.get_line()
	grid_name = line.split(" ",false)[1]
	
	#the second line contains the number of agent types ex:"#A 2"
	line = f.get_line()
	var agent_number = int(line.split(" ",false)[1])
	
	#the next agent_number lines contain the name of each agent type ex:"A 1 name\n A 2 name2"
	for i in agent_number:
		line = f.get_line()
		agent_types_names.append(line.split(" ",false)[2])
		agent_types.append(Util.generate_agent_info_from_file(Util.AGENT_FILE_PATH + agent_types_names[i] + ".tres"))
	
	#next, the width and heigth
	line = f.get_line()
	var info = line.split(" ",false)
	self.width = int(info[0])
	self.heigth = int(info[1])
	
	var temp = claculate_cell_scale(width, heigth)
	var grid_offset = temp[0]
	var scale = temp[1]
	var x_pos = grid_offset.x
	var y_pos = grid_offset.y
	var cell_dim = Util.DEFAULT_CELL_DIM * scale
	
	#initiating the agent, position and visual grids
	for i in width:
		agent_grid.append([])
		position_grid.append([])
		visual_grid.append([])
		for j in heigth:
			agent_grid[i].append([])
			position_grid[i].append(0)
			var new_cell = plGridCell.instance()
			new_cell.parent = self
			new_cell.cords = Vector2(i,j)
			new_cell.scale = Vector2(scale, scale)
			#new_cell.set_global_position(Vector2(cell_dims.x + i * cell_dims.x * 2 + Util.CELL_OFFSET * i, cell_dims.y + j * cell_dims.y * 2 + Util.CELL_OFFSET* j))
			new_cell.set_global_position(Vector2(x_pos, y_pos))
			y_pos += cell_dim + Util.CELL_OFFSET
			cell_container.add_child(new_cell)
			visual_grid[i].append(new_cell)
		x_pos += cell_dim + Util.CELL_OFFSET
		y_pos = grid_offset.y
	
	
	#reading the discription of the agent grid from the file and recreating it
	#in the file positions with 0 dont contain agents and positons with a number > 0 correspond to the agent type
	for j in heigth:
		line = f.get_line()
		var row = line.split(" ",false)
		for i in width:
			var agent_n = int(row[i])
			if agent_n > 0 and agent_n <= agent_number and agent_types[agent_n-1] != null:
				var new_agent = plGameAgent.new(agent_types[agent_n-1], Vector2(i,j), self)
				agent_grid[i][j].append(new_agent)
	f.close()
	update_shared_places()
	update_agent_list()



func update():
	var rand_list = put_agents_on_list()
	#print(rand_list.size())
	shuffle(rand_list)
	for i in range(rand_list.size()):
		rand_list[i].update()
	update_shared_places()
	visual_update()
		

func update_shared_places():
	var agent_list = put_agents_on_list()
	for agent in agent_list:
		for pos in agent.petri_brain.position_array:
			if pos.type == PetriNet.Position_type.SHARED and !shared_places.has(pos.shared_place_name):
				shared_places[pos.shared_place_name] = 0
	
	for child in edit_space_list.get_children():
		child.queue_free()
	
	for space in shared_places:
		var new_butt = plSharedSpaceButton.instance()
		new_butt.init(space, shared_places[space])
		new_butt.connect("shared_space_edited", self, "edit_shared_space")
		new_butt.connect("shared_space_to_delete", self, "delete_shared_space")
		#signals
		edit_space_list.add_child(new_butt)


func edit_shared_space(place_name, value):
	shared_places[place_name] = int(value) 
	update_shared_places()


func delete_shared_space(place_name):
	shared_places.erase(place_name)
	update_shared_places()


func update_agent_list():
	agent_brush = null
		
	var agent_types = []
	var files = Util.list_files_in_directory(Util.AGENT_FILE_PATH)
	for file in files:
		agent_types.append(plGameAgent.new(Util.generate_agent_info_from_file(file), Vector2.ZERO, null))
		
	for child in edit_agent_list.get_children():
		child.queue_free()
		
	for agent in agent_types:
		var new_butt = plEditAgentButton.instance()
		new_butt.init(agent, self)
		new_butt.connect("brush_agent_selected", self, "switch_agent_brush")
		new_butt.connect("brush_agent_to_edit", self, "agent_button_pressed")
		new_butt.connect("brush_agent_to_delete", self, "delete_agent_file")
		edit_agent_list.add_child(new_butt)


func visual_update():
	#print("update visual")
	for i in width:
		for j in heigth:
			var new_color:= Color(1,1,1)
			if !agent_grid[i][j].empty():
				new_color = agent_grid[i][j][0].type_color
			visual_grid[i][j].change_color(new_color)
			visual_grid[i][j].change_number_of_tokens(position_grid[i][j])


func update_visual_state():
	match state:
		State.PLAY:
			play_button.set_normal_texture(play_icon)
			inspect_button.set_normal_texture(inspect_icon)
			edit_instrunctions.visible = false
			
		State.EDIT:
			play_button.set_normal_texture(pause_icon)
			inspect_button.set_normal_texture(edit_icon)
			edit_instrunctions.visible = true

		State.INSPECT:
			play_button.set_normal_texture(pause_icon)
			inspect_button.set_normal_texture(inspect_icon)
			edit_instrunctions.visible = false


func delete_agent_file(agent):
	var dir = Directory.new()
	dir.remove(Util.AGENT_FILE_PATH + agent.type_name + ".tres")
	update_agent_list()
	

func switch_agent_brush(agent):
	state = State.EDIT
	update_visual_state()
	agent_brush = Util.generate_agent_info_from_agent(agent)
	

func switch_to_edit():
	state = State.EDIT
	update_visual_state()


func switch_to_play():
	state = State.PLAY
	update_visual_state()
	

func switch_to_inspect():
	state = State.INSPECT
	update_visual_state()


func _input(event):
	if visible and event.is_action_pressed("ui_select") and state != State.PLAY:
		update()
		


func claculate_cell_scale(width:int, heigth: int):
	var vp_rect = get_viewport_rect().size
	var x_space_to_fill = right_limit_pos.global_position.x - Util.GRID_OFFSET_Y * 2 - Util.CELL_OFFSET * (width-1)
	var y_space_to_fill = vp_rect.y - Util.GRID_OFFSET_Y * 2 - Util.CELL_OFFSET * (heigth-1)
	var x_cell_space = x_space_to_fill / width
	var y_cell_space = y_space_to_fill / heigth
	var scale = min(x_cell_space, y_cell_space) / Util.DEFAULT_CELL_DIM
	var x_grid_space = Util.DEFAULT_CELL_DIM * scale * width + Util.CELL_OFFSET * (width-1)
	var y_grid_space = Util.DEFAULT_CELL_DIM * scale * heigth + Util.CELL_OFFSET * (heigth-1)
	var x_offset = right_limit_pos.global_position.x / 2 - x_grid_space / 2
	var y_offset = vp_rect.y / 2 - y_grid_space / 2
	var offset := Vector2(max(x_offset, Util.GRID_OFFSET_X), max(y_offset, Util.GRID_OFFSET_Y))
	return [offset, scale]
	
	
func put_agents_on_list() -> Array:
	var list = []
	for i in width:
		for j in heigth:
			for agent in agent_grid[i][j]:
				list.append(agent)
	return list

#Implementation of the Fisher–Yates shuffle for List<T>
#https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_modern_algorithm
func shuffle(list: Array):
	for i in range(list.size()-1, 0, -1):
		var j = randi() % (i+1)
		var temp = list[i]
		list[i] = list[j];
		list[j] = temp;
		
		
func cell_clicked(cords: Vector2, mouse_index):
	if state == State.EDIT:
		if  mouse_index == BUTTON_LEFT and agent_brush != null:
			var new_agent = plGameAgent.new(agent_brush, cords, self)
			agent_grid[cords.x][cords.y].append(new_agent)
			visual_update()
			
		elif  mouse_index == BUTTON_RIGHT:
			agent_grid[cords.x][cords.y].clear()
			visual_update()
		update_shared_places()
	
	else:
		state = State.INSPECT
		update_visual_state()
		#setup popup
		selected_cell = cords
		var contents = get_cell_contents(cords)
		cell_popup.window_title = "Contents of Cell " + str(cords.y)+" "+str(cords.x)
		token_edit.text = str(contents[0])
		for child in agent_list.get_children():
			agent_list.remove_child(child)
			child.queue_free()
		for agent in contents[1]:
			var new_butt = plAgentButton.instance()
			new_butt.init(agent, self)
			agent_list.add_child(new_butt)
			
		cell_popup.popup()
		
	
	
func get_cell_contents(cords: Vector2):
	return [position_grid[cords.x][cords.y],agent_grid[cords.x][cords.y]]
	

func agent_button_pressed(agent):
	emit_signal("agent_selected", agent)
	selected_cell = Vector2.ZERO
	cell_popup.hide()


func _on_TokenButton_pressed():
	position_grid[selected_cell.x][selected_cell.y] = int(token_edit.text)
	visual_update()
	selected_cell = Vector2.ZERO
	cell_popup.hide()


func _on_GoBackButton_pressed():
	emit_signal("simulation_closed")


func _on_Timer_timeout():
	if state == State.PLAY:
		update()


func _on_NewAgentButt_pressed():
	state = State.EDIT
	update_visual_state()
	var agent = plGameAgent.new(Util.generate_agent_info_from_file(Util.EMPTY_AGENT_FILE_PATH), Vector2.ZERO, null)
	emit_signal("agent_selected", agent)


func _on_PlayButt_pressed():
	if state == State.PLAY:
		state = State.INSPECT
	else:
		state = State.PLAY
	update_visual_state()


func _on_InspectButt_pressed():
	state = State.INSPECT
	update_visual_state()


func _on_ClearButt_pressed():
	init(empty_grid_path)
	visual_update()
