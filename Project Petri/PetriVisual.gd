extends Node2D


signal petri_visual_closed()


var plGameAgent = preload("res://Scripts/GameAgent.gd")
var plPosition = load("res://Scripts/Position.tscn")
var plTransition = load("res://Scripts/Transition.tscn")
var plArc = load("res://Scripts/ArcVisual.tscn")
const Util = preload("res://Scripts/util.gd")

onready var pos_pos := $Pos_pos
onready var trans_pos := $Trans_pos
onready var petri_container: = $PetriContainer
onready var editor := $Editor
onready var name_input := $Editor/NameInput
onready var arc_pop := $ArcPopup
onready var arc_scroll := $"ArcPopup/ArcScroll"
onready var arc_from := $"ArcPopup/FromScroll"
onready var arc_to := $"ArcPopup/ToScroll"
onready var arc_weight_input := $"ArcPopup/WeightInput"
onready var create_arc_butt := $ArcPopup/CreateArcButt
onready var agent_color := $Editor/AgentColor
onready var agent_color_picker := $ColorPopup/ColorPicker
onready var color_pop := $ColorPopup

var agent: GameAgent = null
var new_agent: GameAgent = null

var vis_positions := []
var vis_transitions := []
var vis_arcs := []
var arcs := []

#scroll items
var from_items := []
var to_items := []

func create_petri(agent):
	
	vis_positions = []
	vis_transitions = []
	vis_arcs = []
	arcs = []
	
	self.agent = agent
	var agent_info = Util.generate_agent_info_from_agent(agent)
	new_agent = plGameAgent.new(agent_info, Vector2(agent.position.x,agent.position.y), agent.grid)
	
	var positions = agent.petri_brain.position_array
	var tansitions = agent.petri_brain.transition_array
	agent_color.color = agent.type_color
	
	#positions
	for i in positions.size():
		var new_pos = plPosition.instance()
		var c : Color
		if positions[i].type == PetriNet.Position_type.PRIVATE:
			c = Util.PUBLIC_POS_COLOR
		elif positions[i].type == PetriNet.Position_type.SHARED:
			c = Util.SHARED_POS_COLOR
		else:
			c = Util.PRIVATE_POS_COLOR
		new_pos.init(agent.petri_brain.position_array[i].name, agent.petri_brain.position_array[i].type, str(agent.petri_brain.position_array[i].token_number), str(agent.petri_brain.position_array[i].public_pos.x), str(agent.petri_brain.position_array[i].public_pos.y), agent.petri_brain.position_array[i].shared_place_name, i, false)
		#print(global_position + agent.petri_brain.position_array[i].visual_pos)
		new_pos.set_global_position(agent.petri_brain.position_array[i].visual_pos)
		new_pos.connect("pos_deleted", self, "handle_position_deletion")
		new_pos.connect("pos_saved", self, "handle_position_save")
		petri_container.add_child(new_pos)
		vis_positions.append(new_pos)
	
	#transitions
	for i in tansitions.size():
		var new_trans = plTransition.instance()
		new_trans.init(agent.petri_brain.transition_array[i].name, agent.petri_brain.transition_array[i].action, agent.petri_brain.transition_array[i].action_arg, agent.func_names, agent.func_tips, i, false)
		new_trans.set_global_position(agent.petri_brain.transition_array[i].visual_pos)
		new_trans.connect("trans_deleted", self, "handle_transition_deletion")
		new_trans.connect("trans_saved", self, "handle_transition_save")
		petri_container.add_child(new_trans)
		vis_transitions.append(new_trans)
		
		#arcs
		for arc in tansitions[i].input_arcs:
			var new_arc = plArc.instance()
			new_arc.init(vis_positions[positions.find(arc.position)], vis_transitions[tansitions.find(arc.trans)], true, arc.weight, global_position, Util.FROM_POS_TO_TRANS_ARC_COLOR)
			new_arc.connect("arc_deleted", self, "handle_arc_deletion")
			new_arc.connect("arc_saved", self, "handle_arc_save")
			petri_container.add_child(new_arc)
			arcs.append(arc)
			vis_arcs.append(new_arc)
		for arc in tansitions[i].output_arcs:
			var new_arc = plArc.instance()
			new_arc.init( vis_transitions[tansitions.find(arc.trans)], vis_positions[positions.find(arc.position)], false, arc.weight, global_position, Util.FROM_TRANS_TO_POS_ARC_COLOR)
			new_arc.connect("arc_deleted", self, "handle_arc_deletion")
			new_arc.connect("arc_saved", self, "handle_arc_save")
			petri_container.add_child(new_arc)
			arcs.append(arc)
			vis_arcs.append(new_arc)
		
	editor.visible = true
	name_input.text = agent.type_name

func destroy_petri():
	for child in petri_container.get_children():
		petri_container.remove_child(child)
		child.queue_free()

	vis_positions = []
	vis_transitions = []
	editor.visible = false


#Save agent into file and update the current one with the changes
func _on_SaveButt_pressed():
	#update agent with the info of new_agent
	#-name
	agent.type_name = name_input.text
	agent.type_color = agent_color.color
	#-petrybrain
	agent.petri_brain.position_array = new_agent.petri_brain.position_array
	agent.petri_brain.transition_array = new_agent.petri_brain.transition_array
	
#	for i in vis_positions.size():
#		agent.petri_brain.position_array[i].visual_pos = vis_positions[i].global_position - global_position
#		agent.petri_brain.position_array[i].token_number = int(vis_positions[i].tokens_label.text)
#		agent.petri_brain.position_array[i].name = vis_positions[i].name_label.text
#	for i in vis_transitions.size():
#		agent.petri_brain.transition_array[i].visual_pos = vis_transitions[i].global_position - global_position
#		agent.petri_brain.transition_array[i].name = vis_transitions[i].name_label.text
		
	#save agent
	Util.generate_file_from_agent_info(Util.generate_agent_info_from_agent(agent))
	emit_signal("petri_visual_closed")


func _on_ArcButton_pressed():
	arc_scroll.clear()
	arc_from.clear()
	from_items = []
	arc_to.clear()
	to_items = []
	arc_scroll.add_item("From Position to Transition")
	arc_scroll.add_item("From Transition to Position")
	add_things_to_scroll(vis_positions, arc_from, from_items)
	add_things_to_scroll(vis_transitions, arc_to, to_items)
	arc_pop.popup_centered()
	

func add_things_to_scroll(things, scroll, ref_array):
	for thing in things:
		if !thing.deleted:
			scroll.add_item(thing.name_label.text)
			ref_array.append(thing)
			

func _on_CreateArcButt_pressed():
	if(arc_weight_input.text.is_valid_integer() and arc_from.get_item_count()>0 and arc_to.get_item_count()>0):
		#pos to trans
		if arc_scroll.get_selected_id() == 0:
			#verificar se já existe um arco
			var arc_exists = false
			for va in vis_arcs:
				if va.is_from_pos and va.from == from_items[arc_from.get_selected_id()] and va.to == to_items[arc_to.get_selected_id()]:
					arc_exists = true
			if !arc_exists:
				var new_arc = plArc.instance()
				new_arc.init(from_items[arc_from.get_selected_id()], to_items[arc_to.get_selected_id()], true, int(arc_weight_input.text), global_position, Util.FROM_POS_TO_TRANS_ARC_COLOR)
				new_arc.connect("arc_deleted", self, "handle_arc_deletion")
				new_arc.connect("arc_saved", self, "handle_arc_save")
				petri_container.add_child(new_arc)
				vis_arcs.append(new_arc)
				
				#adicionar arc correspondente a new_agent
				var new_real_arc = PetriNet.Arc.new()
				#encontrar a posição e transição deste arco (os indices devem corresponder aos dos arrays das versões visuais)
				var arc_pos = new_agent.petri_brain.position_array[vis_positions.find(from_items[arc_from.get_selected_id()])]
				var arc_trans = new_agent.petri_brain.transition_array[vis_transitions.find(to_items[arc_to.get_selected_id()])]
				new_real_arc.position = arc_pos
				new_real_arc.trans = arc_trans
				new_real_arc.weight = int(arc_weight_input.text)
				new_real_arc.input = true
				#adicionar este arco à sua transição
				arc_trans.input_arcs.append(new_real_arc)
				
			
				
		#trans to pos
		else:
			#verificar se já existe um arco
			var arc_exists = false
			for va in vis_arcs:
				if !va.is_from_pos and va.from == from_items[arc_from.get_selected_id()] and va.to == to_items[arc_to.get_selected_id()]:
					arc_exists = true
			if !arc_exists:
				var new_arc = plArc.instance()
				new_arc.init(from_items[arc_from.get_selected_id()], to_items[arc_to.get_selected_id()], false, int(arc_weight_input.text), global_position, Util.FROM_TRANS_TO_POS_ARC_COLOR)
				new_arc.connect("arc_deleted", self, "handle_arc_deletion")
				new_arc.connect("arc_saved", self, "handle_arc_save")
				petri_container.add_child(new_arc)
				vis_arcs.append(new_arc)
				
				#adicionar arc correspondente a new_agent
				var new_real_arc = PetriNet.Arc.new()
				#encontrar a posição e transição deste arco (os indices devem corresponder aos dos arrays das versões visuais)
				var arc_pos = new_agent.petri_brain.position_array[vis_positions.find(to_items[arc_to.get_selected_id()])]
				var arc_trans = new_agent.petri_brain.transition_array[vis_transitions.find(from_items[arc_from.get_selected_id()])]
				new_real_arc.position = arc_pos
				new_real_arc.trans = arc_trans
				new_real_arc.weight = int(arc_weight_input.text)
				new_real_arc.input = false
				#adicionar este arco à sua transição
				arc_trans.output_arcs.append(new_real_arc)
				
				
		


func _on_ArcScroll_item_selected(index):
	arc_from.clear()
	from_items = []
	arc_to.clear()
	to_items = []
	#from position to transition
	if index == 0:
		add_things_to_scroll(vis_positions, arc_from, from_items)
		add_things_to_scroll(vis_transitions, arc_to, to_items)
	#from transition to position
	else:
		add_things_to_scroll(vis_transitions, arc_from, from_items)
		add_things_to_scroll(vis_positions, arc_to, to_items)
	

func handle_position_deletion(pos):
	#remover do array de referencias visuais
	var index = vis_positions.find(pos)
	
	var arcs_to_delete := []
	for arc in vis_arcs:
		if arc.to == pos or arc.from == pos:
			arcs_to_delete.append(arc)
	while !arcs_to_delete.empty():
		handle_arc_deletion(arcs_to_delete.pop_back())
		
	vis_positions.remove(index)
	pos.queue_free()
	
	#remover pos do array no new_agent
	new_agent.petri_brain.position_array.remove(index)
	
	
func handle_transition_deletion(trans):
	var index = vis_transitions.find(trans)
	
	var arcs_to_delete := []
	for arc in vis_arcs:
		if arc.to == trans or arc.from == trans:
			arcs_to_delete.append(arc)

	while !arcs_to_delete.empty():
		handle_arc_deletion(arcs_to_delete.pop_back())
		
	vis_transitions.remove(index)
	trans.queue_free()
	
	#remover trans do array no new_agent
	new_agent.petri_brain.transition_array.remove(index)
	
	
func handle_arc_deletion(arc):
	#eleminar do new_agent
	#encontrar a transição e posição do arc e remover no new_agent
	var trans: PetriNet.Transition
	var pos: PetriNet.Position
	#se é arco de input
	if arc.is_from_pos:
		trans = new_agent.petri_brain.transition_array[vis_transitions.find(arc.to)]
		pos = new_agent.petri_brain.position_array[vis_positions.find(arc.from)]
		#encontrar o arco correto dentro dos input arcs do trans
		for i in range(trans.input_arcs.size()):
			if trans.input_arcs[i].position == pos:
				trans.input_arcs.remove(i)
				break
	#se é de output
	else:
		trans = new_agent.petri_brain.transition_array[vis_transitions.find(arc.from)]
		pos = new_agent.petri_brain.position_array[vis_positions.find(arc.to)]
		#encontrar o arco correto dentro dos output arcs do trans
		for i in range(trans.output_arcs.size()):
			if trans.output_arcs[i].position == pos:
				trans.output_arcs.remove(i)
				break
	
	var index = vis_arcs.find(arc)
	vis_arcs.remove(index)
	arc.del()
	
	
func handle_position_save(pos):
	#encontrar a pos no new_agent
	var pos_to_update = new_agent.petri_brain.position_array[vis_positions.find(pos)]
	#nome, tokens, se é publico(?)
	pos_to_update.name = pos.name_label.text
	pos_to_update.type = pos.type
	pos_to_update.token_number = int(pos.token_text.text)
	pos_to_update.public_pos = Vector2(int(pos.x_text.text), int(pos.y_text.text))
	pos_to_update.shared_place_name = pos.shared_text.text
	#screen positon
	pos_to_update.visual_pos = pos.global_position - global_position
	
	

func handle_transition_save(trans):
	#encontrar a trans no new_agent
	var trans_to_update = new_agent.petri_brain.transition_array[vis_transitions.find(trans)]
	#nome
	trans_to_update.name = trans.name_label.text
	#action
	trans_to_update.action = trans.trans_act
	#action arg
	trans_to_update.action_arg = trans.trans_arg
	#screen positon
	trans_to_update.visual_pos = trans.global_position - global_position
	
	


func handle_arc_save(arc):
	#encontrar a transição e posição do arc e atualizar os seus dados no new_agent
	var trans: PetriNet.Transition
	var pos: PetriNet.Position
	var arc_to_update: PetriNet.Arc
	#se é arco de input
	if arc.is_from_pos:
		trans = new_agent.petri_brain.transition_array[vis_transitions.find(arc.to)]
		pos = new_agent.petri_brain.position_array[vis_positions.find(arc.from)]
		#encontrar o arco correto dentro dos input arcs do trans
		for i in range(trans.input_arcs.size()):
			if trans.input_arcs[i].position == pos:
				arc_to_update = trans.input_arcs[i]
				break
	#se é de output
	else:
		trans = new_agent.petri_brain.transition_array[vis_transitions.find(arc.from)]
		pos = new_agent.petri_brain.position_array[vis_positions.find(arc.to)]
		#encontrar o arco correto dentro dos output arcs do trans
		for i in range(trans.output_arcs.size()):
			if trans.output_arcs[i].position == pos:
				arc_to_update = trans.output_arcs[i]
				break
	
	#a unica coisa que atualizamos no arco de momento é o peso
	arc_to_update.weight = int(arc.weight_label.text)



func _on_PosButton_pressed():
	var new_pos = plPosition.instance()
	var pos_name: String = "P"+str(vis_positions.size())
	new_pos.init(pos_name, 0, str(0), 0, 0, "", vis_positions.size(), true)
	new_pos.connect("pos_deleted", self, "handle_position_deletion")
	new_pos.connect("pos_saved", self, "handle_position_save")
	petri_container.add_child(new_pos)
	vis_positions.append(new_pos)
	
	#adicionar pos correspondente a new_agent
	var new_real_pos = PetriNet.Position.new()
	new_real_pos.type = PetriNet.Position_type.PRIVATE
	new_real_pos.token_number = 0
	new_real_pos.name = pos_name
	new_real_pos.visual_pos = Vector2.ZERO
	new_agent.petri_brain.position_array.append(new_real_pos)
	


func _on_TransButton_pressed():
	var new_trans = plTransition.instance()
	new_trans.init("T"+str(vis_transitions.size()), -1, "", agent.func_names, agent.func_tips, vis_transitions.size(), true)
	new_trans.connect("trans_deleted", self, "handle_transition_deletion")
	new_trans.connect("trans_saved", self, "handle_transition_save")
	petri_container.add_child(new_trans)
	vis_transitions.append(new_trans)
	
	#adicionar trans correspondente a new_agent
	var new_real_trans = PetriNet.Transition.new()
	new_real_trans.name
	new_real_trans.action = -1
	new_real_trans.visual_pos = Vector2.ZERO
	new_agent.petri_brain.transition_array.append(new_real_trans)
	




#to solve a godot bug
func _on_ArcScroll_toggled(button_pressed):
	arc_from.visible = !arc_from.visible
	arc_to.visible = !arc_to.visible

#to solve a godot bug
func _on_FromScroll_toggled(button_pressed):
	arc_weight_input.visible = !arc_weight_input.visible
	create_arc_butt.visible = !create_arc_butt.visible


func _on_GoBackButton_pressed():
	emit_signal("petri_visual_closed")


func _on_ColorButton_pressed():
	agent_color_picker.color = agent.type_color
	color_pop.popup()


func _on_ColorSaveButton_pressed():
	agent_color.color = agent_color_picker.color
