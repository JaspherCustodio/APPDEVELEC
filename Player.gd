extends KinematicBody2D

var vote = Global.vote setget set_vote
var can_vote = true
var max_votes = 3
var current_votes = 0

var username_text = load("res://UsernameText.tscn")
var vote_button = load("res://UserButton.tscn")

onready var voterlabel = $VoterResult

var button

var username setget username_set
var username_text_instance = null

var userbutton setget userbutton_set
var username_button_instance = null

puppet var puppet_vote = 0 setget puppet_vote_set
puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_username = "" setget puppet_username_set
puppet var puppet_userbutton setget puppet_userbutton_set

onready var tween = $Tween


func _ready():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	
	username_text_instance = Global.instance_node_at_location(username_text, PersistentNodes, global_position)
	username_text_instance.player_following = self
	
	username_button_instance = Global.instance_node_at_location(vote_button, PersistentNodes, global_position)
	username_button_instance.player_following = self
	

	button = username_button_instance.get_node("VoteButton")
	if button:
		button.connect("pressed", self, "_on_vote_button_pressed")
		print("CONNECTED")
	else:
		print("Vote button not found!")
	
	update_vote_mode(false)
#	update_vote_label()
	Global.alive_player.append(self)
	
	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = self

func _process(_delta: float) -> void:
	if username_text_instance != null:
		username_text_instance.name = "username" + name
	if username_button_instance != null:
		username_button_instance.name = "userbutton" + name
	
	if current_votes == max_votes:
		for player in PersistentNodes.get_children():
			if player.is_in_group("Button"):
				player.hide()

func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1, Tween.TRANS_LINEAR)
	tween.start()
#	rset_unreliable("puppet_position", global_position)  # Update less reliably for smoother transitions

func set_vote(new_value):
	vote = new_value
	
	if get_tree().has_network_peer():
		if is_network_master():
			rset("puppet_vote", vote)

func puppet_vote_set(new_value):
	puppet_vote = new_value
	
	if get_tree().has_network_peer():
		if not is_network_master():
			vote = puppet_vote

func username_set(new_value) -> void:
	username = new_value
	
	if get_tree().has_network_peer():
		if is_network_master() and username_text_instance != null:
			username_text_instance.text = username
			rset("puppet_username", username)

func puppet_username_set(new_value) -> void:
	puppet_username = new_value
	
	if get_tree().has_network_peer():
		if not is_network_master() and username_text_instance != null:
			username_text_instance.text = puppet_username

func userbutton_set(new_value) -> void:
	username = new_value
	
	if get_tree().has_network_peer():
		if is_network_master() and username_button_instance != null:
			rset("puppet_userbutton", userbutton)

func _network_peer_connected(id) -> void:
	rset_id(id, "puppet_username", username)
	rset_id(id, "puppet_userbutton", userbutton)

func _on_NetworkTickRate_timeout():
	if get_tree().has_network_peer() and is_network_master():
		rset_unreliable("puppet_position", global_position)

func puppet_userbutton_set(new_value) -> void:
	puppet_userbutton = new_value

sync func update_position(pos):
	global_position = pos
	puppet_position = pos

func update_vote_mode(vote_mode):
	if not vote_mode:
		username_button_instance.hide()
	else:
		username_button_instance.show()
	
	can_vote = vote_mode

sync func _register_vote(voted):
	vote += voted
	voterlabel.text = str(vote)
#	Global.alive_player.update_votes(self, vote)  # Example of a centralized update
	print("vote " + str(vote))
	print("curvote " + str(current_votes))
	print("vote sent for " + name)

func _on_vote_button_pressed():
	if current_votes < max_votes:
		current_votes += 1
		rpc("_register_vote", 1)
	else:
		print("Max votes reached for player:", "username" + name)

sync func destroy() -> void:
	username_text_instance.visible = false
	username_button_instance.visible = false
	visible = false
	Global.alive_player.erase(self)
	
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null

func _exit_tree() -> void:
	Global.alive_player.erase(self)
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null
