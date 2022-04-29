const AGENT_FILE_PATH = "res://agents/"
const GRID_FILE_PATH = "res://grids/"
const EMPTY_AGENT_FILE_PATH = "res://empty.tres"

const DEFAULT_POS_POSITION_X = 60
const DEFAULT_TRANS_POSITION_X = 260
const DEFAULT_POSITION_Y = 65
const DEFAULT_POSITION_Y_OFFSET = 100

const FROM_POS_TO_TRANS_ARC_COLOR = Color(0.4,0.5,1)
const FROM_TRANS_TO_POS_ARC_COLOR = Color(1,0.6,0.3)
const PRIVATE_POS_COLOR = Color(1, 0.9, 0.5)
const PUBLIC_POS_COLOR = Color(1, 0.7, 0.4)
const SHARED_POS_COLOR = Color(0.8, 0.9, 0.5)

const DEFAULT_CELL_DIM = 64
const CELL_OFFSET = 2
const GRID_OFFSET_X = 20
const GRID_OFFSET_Y = 20


static func stuff():
	print("stuff")
	

#https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
static func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(path+file)

	dir.list_dir_end()

	return files
	
static func load_file(file):
	var f = File.new()
	var err = f.open(file, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
	var index = 1
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		line += " "
		print(line + str(index))

		index += 1
	f.close()
	return

class agent_info:
	var agent_name: String
	var number_pos: int
	var number_trans: int
	var positions: Array
	var transitions: Array
	var pos_names: Array
	var trans_names: Array
	var pos_positions: Array
	var trans_positions: Array
	var color: Color = Color(0,0,0)

static func generate_agent_info_from_file(file):
	var new_agent:= agent_info.new()
	var positions: Array
	var transitions: Array
	var pos_names: Array
	var trans_names: Array
	var pos_positions: Array
	var trans_positions: Array
	var positions_initialized = false
	var transitions_initialized = false
	var numb_trans: int
	var numb_pos: int
	var f = File.new()
	var err = f.open(file, File.READ)
	if err != OK:
		printerr("Could not open file "+ file  +", error code ", err)
		return null
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line()
		var array = Array(line.split(" ",false))
		if array.size() <= 0: 
			continue
		#print(array)
		match array:
			["NAME", var agent_name]:
				new_agent.agent_name = agent_name
			["#P", var number_of_positions]:
				if not positions_initialized and number_of_positions.is_valid_integer():
					#print("np " + number_of_positions)
					var arrays = initialize_position_array(int(number_of_positions))
					positions = arrays[0]
					pos_names = arrays[1]
					pos_positions = arrays[2]
					positions_initialized = true
					numb_pos = int(number_of_positions)
					
			["#T", var number_of_transitions]:
				if not transitions_initialized and number_of_transitions.is_valid_integer():
					#print("nt " + number_of_transitions)
					var arrays = initialize_transition_array(int(number_of_transitions))
					transitions = arrays[0]
					trans_names = arrays[1]
					trans_positions = arrays[2]
					transitions_initialized = true
					numb_trans = int(number_of_transitions)
					
			["P", var position, var arg]:
				if positions_initialized and position.is_valid_integer() and int(position) <= numb_pos:
					#arg is indicating the number of tokens in a private position
					if arg.is_valid_integer():
						#print("position " + position + " token " + arg)
						positions[int(position)-1] = int(arg)
					#arg is indicating the name of the shared place this position represents
					else:
						positions[int(position)-1] = arg
					
			["P", var position, var pos_x, var pos_y]:
				if positions_initialized and position.is_valid_integer() and int(position) <= numb_pos and pos_x.is_valid_integer() and pos_x.is_valid_integer():
					#print("position " + position + " token " + number_of_tokens)
					positions[int(position)-1] = Vector2(int(pos_x), int(pos_y))
					
			["T", var transition, var action, var arg]:
				if transitions_initialized and transition.is_valid_integer() and int(transition) <= numb_trans:
					transitions[int(transition)-1][2] = action
					transitions[int(transition)-1][3] = arg
					
			["PN", var position, var name]:
				if positions_initialized and position.is_valid_integer() and int(position) <= numb_pos:
					#print("position " + position + " token " + number_of_tokens)
					pos_names[int(position)-1] = name
					
			["TN", var transition, var name]:
				if transitions_initialized and transition and int(transition) <= numb_trans:
					trans_names[int(transition)-1] = name
					
			["PP", var position, var x, var y]:
				if positions_initialized and position.is_valid_integer() and int(position) <= numb_pos:
					#print("position " + position + " token " + number_of_tokens)
					pos_positions[int(position)-1] = Vector2(x,y)
					
			["TP", var transition, var x, var y]:
				if transitions_initialized and transition.is_valid_integer() and int(transition) <= numb_trans:
					trans_positions[int(transition)-1] = Vector2(x,y)
					
			["ARC", "T", var transition, "P", var position, var weight]:
				if positions_initialized and transitions_initialized and transition.is_valid_integer() and int(transition) <= numb_trans and position.is_valid_integer() and int(position) <= numb_pos and weight.is_valid_integer():
					#print("from t " + transition + " to p " + position + " with weight " + weight)
					transitions[int(transition) -1][1].append([int(position) -1, int(weight)])
					
			["ARC", "P", var position, "T", var transition, var weight]:
				if positions_initialized and transitions_initialized and transition.is_valid_integer() and int(transition) <= numb_trans and position.is_valid_integer() and int(position) <= numb_pos and weight.is_valid_integer():
					#print("from p " + position + " to t " + transition + " with weight "+ weight)
					transitions[int(transition) -1][0].append([int(position) -1, int(weight)])
					
			["C", var r, var g, var b]:
				new_agent.color = Color(float(r),float(g),float(b))
			_:
				#print("none of the above")
				pass
	f.close()
	new_agent.number_pos = numb_pos
	new_agent.number_trans = numb_trans
	new_agent.positions = positions
	new_agent.pos_names = pos_names
	new_agent.pos_positions = pos_positions
	new_agent.transitions = transitions
	new_agent.trans_names = trans_names
	new_agent.trans_positions = trans_positions
	return new_agent
	
static func generate_agent_info_from_agent(agent):
	var new_agent:= agent_info.new()
	new_agent.agent_name = agent.type_name
	new_agent.color = agent.type_color
	new_agent.pos_names = []
	new_agent.trans_names = []
	new_agent.pos_positions = []
	new_agent.trans_positions = []
	var pos = agent.petri_brain.position_array
	var trans = agent.petri_brain.transition_array
	new_agent.number_pos = pos.size()
	new_agent.number_trans = trans.size()
	
	new_agent.positions = []
	for p in pos:
		if p.type == PetriNet.Position_type.PRIVATE:
			new_agent.positions.append(p.token_number)
		elif p.type == PetriNet.Position_type.SHARED:
			new_agent.positions.append(p.shared_place_name)
		else:
			new_agent.positions.append(p.public_pos)
		new_agent.pos_names.append(p.name)
		new_agent.pos_positions.append(p.visual_pos)
			
	new_agent.transitions = []
	for t in trans:
		var in_arcs = []
		var out_arcs = []
		for arc in t.input_arcs:
			in_arcs.append([pos.find(arc.position),arc.weight])
		for arc in t.output_arcs:
			out_arcs.append([pos.find(arc.position),arc.weight])
		new_agent.transitions.append([in_arcs, out_arcs, t.action, t.action_arg])
		new_agent.trans_names.append(t.name)
		new_agent.trans_positions.append(t.visual_pos)
	
	return new_agent
	
static func generate_file_from_agent_info(agent_info):
	var file = AGENT_FILE_PATH + agent_info.agent_name + ".tres"
	var f = File.new()
	f.open(file, File.WRITE)
	#name
	f.store_line("NAME "+agent_info.agent_name)
	#tamanhos dos arrays
	f.store_line("#P "+str(agent_info.number_pos))
	f.store_line("#T "+str(agent_info.number_trans))
	#pos info
	for i in agent_info.positions.size():
		if typeof(agent_info.positions[i]) == TYPE_INT:
			f.store_line("P "+str(i+1)+" "+str(agent_info.positions[i]))
		elif typeof(agent_info.positions[i]) == TYPE_STRING:
			f.store_line("P "+str(i+1)+" "+ agent_info.positions[i])
		else:
			f.store_line("P "+str(i+1)+" "+str(agent_info.positions[i][0])+ " "+str(agent_info.positions[i][1]))
	#trans action
	for i in agent_info.transitions.size():
		if agent_info.transitions[i][2] != -1:
				f.store_line("T "+ str(i+1)+" "+str(agent_info.transitions[i][2])+ " "+agent_info.transitions[i][3])
	#pos names
	for i in agent_info.pos_names.size():
		f.store_line("PN "+str(i+1)+" "+agent_info.pos_names[i])
	#trans names
	for i in agent_info.trans_names.size():
		f.store_line("TN "+str(i+1)+" "+agent_info.trans_names[i])
	#pos positions
	for i in agent_info.pos_positions.size():
		f.store_line("PP "+str(i+1)+" "+ str(agent_info.pos_positions[i].x) +" "+ str(agent_info.pos_positions[i].y))
	#trans positions
	for i in agent_info.trans_positions.size():
		f.store_line("TP "+str(i+1)+" "+ str(agent_info.trans_positions[i].x) +" "+ str(agent_info.trans_positions[i].y))
	#arcs
	for i in agent_info.transitions.size():
		var input_arcs = agent_info.transitions[i][0]
		var output_arcs = agent_info.transitions[i][1]
		for arc in input_arcs:
			f.store_line("ARC P "+ str(arc[0]+1)+" T "+ str(i+1) + " " + str(arc[1]))
		for arc in output_arcs:
			f.store_line("ARC T "+ str(i+1)+" P "+ str(arc[0]+1) + " " + str(arc[1]))
	
	#color
	f.store_line("C " + str(agent_info.color.r) + " " + str(agent_info.color.g) + " " + str(agent_info.color.b))
	f.close()
	
static func initialize_position_array(size: int) -> Array:
	var p = []
	var p_names = []
	var p_positions = []
	for i in range(size):
		p.append(0)
		p_names.append("P" + str(i))
		p_positions.append(Vector2(DEFAULT_POS_POSITION_X, DEFAULT_POSITION_Y + DEFAULT_POSITION_Y_OFFSET*i))
	return [p, p_names, p_positions]
	
static func initialize_transition_array(size: int) -> Array:
	var t = []
	var t_names = []
	var t_positions = []
	for i in size:
		#[input arcs, output arcs, action, arg]
		t.append([[],[],-1,""])
		t_names.append("T" + str(i))
		t_positions.append(Vector2(DEFAULT_TRANS_POSITION_X, DEFAULT_POSITION_Y + DEFAULT_POSITION_Y_OFFSET*i))
	return [t, t_names, t_positions]
