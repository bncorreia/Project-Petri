extends Control

var plAgentButton = load("res://Scripts/AgentButton.tscn")
var plPosition = load("res://Scripts/Position.tscn")
var plTransition = load("res://Scripts/Transition.tscn")
var plArc = load("res://Scripts/ArcVisual.tscn")

onready var description := $Description
onready var cell_cords := $"Description/Cell Cords"
onready var number_of_tokens := $"Description/Number of Tokens"
onready var agent_butts := $"Description/Agent Buttons"
onready var petri_visual := $PetriVisual


var cords
var contents


func init(cords:Vector2, contents:Array):
	self.cords = cords
	self.contents = contents

func _ready():
	cell_cords.text = "Contents of Cell " + str(cords.y)+" "+str(cords.x)+":"
	number_of_tokens.text = str(contents[0]) + " Tokens"
	for agent in contents[1]:
		var new_butt = plAgentButton.instance()
		new_butt.init(agent, self)
		agent_butts.add_child(new_butt)

func agent_button_pressed(agent):
	petri_visual.destroy_petri()
	petri_visual.create_petri(agent)

func self_destruct():
	queue_free()

	
