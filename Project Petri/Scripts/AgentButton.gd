extends Button

var parent
var agent

func init(agent, parent):
	self.agent = agent
	self.parent = parent
	text = agent.type_name
	

func _on_AgentButton_pressed():
	parent.agent_button_pressed(agent)
