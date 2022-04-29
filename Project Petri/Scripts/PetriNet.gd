class_name PetriNet

enum Position_type{
	PRIVATE,
	PUBLIC,
	SHARED
}


#três classes internas

#uma para posições
class Position:
	#o type tem como valor um dos Position_type
	#o type ditará como acedemos ao valor dos tokens nesta posição:
	#private: o valor está na propriedade token_number embaixo
	#public: o valor está na matriz position_grid da grid 
	#shared: o valor está no dicionario shared_places da grid 
	var type: int 
	var public_pos: Vector2
	var shared_place_name: String
	var token_number: int
	
	#nome com qu eé apresentado na representação visual e posição global relativa
	var name: String
	var visual_pos: Vector2
	
	
#outra para arcos
class Arc:
	#bool que indica se o arco está a entrar ou a sair de uma transição
	var input: bool
	#posição associada a este arco dentro do position_array
	var position: Position
	#transição associada a este arco dentro do position_array
	var trans: Transition
	#peso do arco
	var weight: int
	
	
#outra para transições
class Transition:
	#tem dois arrays, cada um com arcos que conectam posições a esta transição 
	var input_arcs: Array = []
	var output_arcs: Array = []
	
	#nome com qu eé apresentado na representação visual e posição global relativa
	var name: String
	var visual_pos: Vector2
	
	#para alem de acionar os seus arcos de output, a transição tambem poderá estar responsável por executar uma dada função
	#var action: FuncRef
	var action: int = -1
	var action_arg: String 


#NOVO:
#-array de posições
var position_array: Array = []
#-array de transições (com ref aos indices dos seus arcos de input no array de arcos de input E uma referencia direta aos seus arcos de output)
var transition_array: Array = []
#-array de arcos de input
#var input_arc_array: Array = []
#Talvez ter duas classes separadas para arcos de input e output?

var func_refs: Array = []

var grid = null
var agent = null

#para iniciar, é recebido:
#um array com o tamanho do numero de posições da petri net em que cada valor corresponde aos tokens iniciais/ coordenadas da posição publica na grelha
#um array com o tamanho do numero de posições publicas a que a petri tentará ter acesso, cada valor corresponde à coordenada da posição na grelha
#um array a descrever as transições - cada elemento tem dois arrays de 2 ints, representando os arcos de input e de output. 

func _init(positions: Array, transitions: Array, pos_names: Array, trans_names: Array, pos_positions: Array, trans_positions: Array, func_refs, agent, grid):
	for i in positions.size():
		var new_pos = Position.new()
		#se for inteiro, é uma posição privada e pos indica o numero inicial de tokens
		#se for Vector2, é uma posição publica e pos indica a sua posição na grelha
		if typeof(positions[i]) == TYPE_INT:
			new_pos.type = Position_type.PRIVATE
			new_pos.token_number = positions[i]
		elif typeof(positions[i]) == TYPE_STRING:
			new_pos.type = Position_type.SHARED
			new_pos.shared_place_name = positions[i]
		else:
			new_pos.type = Position_type.PUBLIC
			new_pos.public_pos = positions[i]
		new_pos.name = pos_names[i]
		new_pos.visual_pos = pos_positions[i]
		position_array.append(new_pos)
		
	for i in transitions.size():
		var trans = transitions[i]
		var new_trans = Transition.new()
		var input_arcs = trans[0]
		var output_arcs = trans[1]
		var act = trans[2]
		var arg = trans[3]
		for input_arc in input_arcs:
			var new_arc = Arc.new()
			new_arc.position = position_array[input_arc[0]]
			new_arc.trans = new_trans
			new_arc.weight = input_arc[1]
			new_arc.input = true
			#input_arc_array.append(new_arc)
			new_trans.input_arcs.append(new_arc)
		for output_arc in output_arcs:
			var new_arc = Arc.new()
			new_arc.position = position_array[output_arc[0]]
			new_arc.trans = new_trans
			new_arc.weight = output_arc[1]
			new_arc.input = false
			new_trans.output_arcs.append(new_arc)
		new_trans.action = act
		new_trans.action_arg = arg
		new_trans.name = trans_names[i]
		new_trans.visual_pos = trans_positions[i]
		transition_array.append(new_trans)
	
	self.func_refs = func_refs
	self.agent = agent
	self.grid = grid
	

	
func update()-> bool:
	#Get pos info
	var position_look_up_table: Array = []
	for i in position_array.size():
		position_look_up_table.append(get_position_tokens(i))
	
	#determinar o numero de transições posiveis e selecionar uma aleatoriamente
	var possible_transitions: Array = []
	for i in transition_array.size():
		var possible: bool = true
		for arc in transition_array[i].input_arcs:
			if position_look_up_table[position_array.find(arc.position)] < arc.weight:
				possible = false
				break
		if possible:
			possible_transitions.append(i)
	#slecionar e disparar a transição
	if possible_transitions.size() > 0:
		var transition_to_fire = possible_transitions[randi() % possible_transitions.size()]
		fire_transition(transition_to_fire)
		return true
	return false
	
func fire_transition(transition_ind: int):
	for arc in transition_array[transition_ind].input_arcs:
		remove_tokens_from_position(position_array.find(arc.position), arc.weight)
	for arc in transition_array[transition_ind].output_arcs:
		add_tokens_to_position(position_array.find(arc.position), arc.weight)
	if  transition_array[transition_ind].action != -1:
		func_refs[transition_array[transition_ind].action].call_func(transition_array[transition_ind].action_arg)

func get_position_number() -> int:
	return position_array.size()
	
func get_transition_number() -> int:
	return transition_array.size()
	
	
func get_position_tokens(index: int) -> int:
	if index < get_position_number() and index >= 0:
		var pos = position_array[index]
		if pos.type == Position_type.PRIVATE:
			return pos.token_number
		elif pos.type == Position_type.PUBLIC and grid != null:
			var grid_pos = calc_pos(agent.position, Vector2(pos.public_pos[0],pos.public_pos[1]))
			return grid.position_grid[grid_pos.x][grid_pos.y]
		elif pos.type == Position_type.SHARED and grid != null and grid.shared_places.has(pos.shared_place_name):
			return grid.shared_places[pos.shared_place_name]
	return -1
	

func add_tokens_to_position(index: int, amount: int):
	if index < get_position_number() and index >= 0:
		var pos = position_array[index]
		if pos.type == Position_type.PRIVATE:
			pos.token_number += amount
		elif pos.type == Position_type.PUBLIC and grid != null:
			var grid_pos = calc_pos(agent.position, Vector2(pos.public_pos[0],pos.public_pos[1]))
			grid.position_grid[grid_pos.x][grid_pos.y] += amount
		elif pos.type == Position_type.SHARED and grid != null and grid.shared_places.has(pos.shared_place_name):
			grid.shared_places[pos.shared_place_name] += amount
		
	
func remove_tokens_from_position (index: int, amount: int):
	if index < get_position_number() and index >= 0:
		var pos = position_array[index]
		if pos.type == Position_type.PRIVATE:
			pos.token_number -= amount
		elif pos.type == Position_type.PUBLIC and grid != null:
			var grid_pos = calc_pos(agent.position, Vector2(pos.public_pos[0],pos.public_pos[1]))
			grid.position_grid[grid_pos.x][grid_pos.y] -= amount
		elif pos.type == Position_type.SHARED and grid != null and grid.shared_places.has(pos.shared_place_name):
			grid.shared_places[pos.shared_place_name] -= amount
		

func calc_pos(pos: Vector2, delta: Vector2):
	var new_pos = pos + delta
	var width = grid.width
	var heigth = grid.heigth
	if new_pos.x >= width:
		new_pos.x = 0
	elif new_pos.x < 0:
		new_pos.x = width-1
		
	if new_pos.y >= heigth:
		new_pos.y = 0
	elif new_pos.y < 0:
		new_pos.y = heigth-1
	return new_pos

func get_position(index: int):
	if index < get_position_number() and index >= 0:
		var pos = position_array[index]
		if not pos.is_public:
			return pos.token_number
		else: 
			return pos.public_pos
	return null
	
func get_transition(index: int) -> Array:
	if index < get_position_number() and index >= 0:
		var trans = transition_array[index]
		var return_array = [[],[]]
		for arc in trans.input_arcs:
			return_array[0].append([position_array.find(arc.position), arc.weight])
		for arc in trans.output_arcs:
			return_array[1].append([position_array.find(arc.position), arc.weight])
		return return_array
	return []
	
func get_position_array() -> Array:
	var return_array = []
	for pos in position_array:
		if not pos.is_public:
			return_array.append(pos.token_number)
		else:
			return_array.append(pos.public_pos)
	return return_array
	
func get_transition_array() -> Array:
	var return_array = []
	for trans in transition_array:
		var aux_array = [[],[]]
		for arc in trans.input_arcs:
			aux_array[0].append([position_array.find(arc.position), arc.weight])
		for arc in trans.output_arcs:
			aux_array[1].append([position_array.find(arc.position), arc.weight])
		return_array.append(aux_array)
	return return_array

func print_current_configuration():
	print("Current Configuration:")
	var conf = "\t"
	for i in position_array.size():
		conf = conf + "#" + str(i) + ":" + str(get_position_tokens(i)) + " "
	print(conf)
		
