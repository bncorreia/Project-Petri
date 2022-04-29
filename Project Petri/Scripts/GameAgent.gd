class_name GameAgent

var plPetriNet = preload("res://Scripts/PetriNet.gd")
const Util = preload("res://Scripts/util.gd")

var petri_brain: PetriNet
var position: Vector2
var type_name: String
var type_color: Color
var creator: GameAgent = null
var exists: bool
var func_refs: Array = []
var func_names: Array = []
var func_tips: Array = []
var grid
var original_agent_info

func _init(agent_info, pos, grid):	
	original_agent_info = agent_info
	position = pos
	self.grid = grid
	type_name = agent_info.agent_name
	type_color = agent_info.color
	func_refs = [
		funcref(self, "die"),
		funcref(self, "put_agent_on_grid"),
		funcref(self, "move_agent_up"),
		funcref(self, "move_agent_down"),
		funcref(self, "move_agent_left"),
		funcref(self, "move_agent_right")
	]
	func_names = [
		"Die",
		"Create Agent",
		"Move Up",
		"Move Down",
		"Move Left",
		"Move Right"
	]
	func_tips = [
		"no argument needed",
		"agent name",
		"distance",
		"distance",
		"distance",
		"distance"
	]
	petri_brain = plPetriNet.new(agent_info.positions, agent_info.transitions, agent_info.pos_names, agent_info.trans_names, agent_info.pos_positions, agent_info.trans_positions, func_refs, self, grid)
	
	
func update():

	petri_brain.update()
	#petri_brain.print_current_configuration()
	
	
func die(arg):
	var cords = get_pos()
	grid.agent_grid[cords.x][cords.y].erase(self)


func put_agent_on_grid(agent):
	var dir = Directory.new()
	if dir.file_exists(Util.AGENT_FILE_PATH + agent + ".tres"):
		var new_agent = get_script().new(Util.generate_agent_info_from_file(Util.AGENT_FILE_PATH + agent + ".tres"), get_pos(), grid)
		var cords = get_pos()
		grid.agent_grid[cords.x][cords.y].append(new_agent)

	
func move_agent(delta: Vector2):
	var new_pos = move_aux(grid.width, grid.heigth, position + delta)
	grid.agent_grid[position.x][position.y].erase(self)
	grid.agent_grid[new_pos.x][new_pos.y].append(self)
	position = new_pos
	
func move_agent_up(distance):
	if !distance.is_valid_integer():
		distance = 1
	move_agent(Vector2.UP * int(distance))
	
func move_agent_down(distance):
	if !distance.is_valid_integer():
		distance = 1
	move_agent(Vector2.DOWN * int(distance))
	
func move_agent_left(distance):
	if !distance.is_valid_integer():
		distance = 1
	move_agent(Vector2.LEFT * int(distance))
	
func move_agent_right(distance):
	if !distance.is_valid_integer():
		distance = 1
	move_agent(Vector2.RIGHT * int(distance))

func get_pos():
	return position

func move_aux(width, heigth, new_pos: Vector2):
	if new_pos.x >= width:
		new_pos.x = 0
	elif new_pos.x < 0:
		new_pos.x = width-1
		
	if new_pos.y >= heigth:
		new_pos.y = 0
	elif new_pos.y < 0:
		new_pos.y = heigth-1
		
	return new_pos

