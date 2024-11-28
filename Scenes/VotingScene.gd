extends Node2D

var current_spawn_location_instance_number = 1
var current_player_for_spawn_location_number = null


func _ready() -> void:
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	if get_tree().is_network_server():
		setup_players_position()

func setup_players_position() -> void:
	for player in PersistentNodes.get_children():
		if player.is_in_group("Player"):
			for spawn_location in $SpawnLocation.get_children():
				if int(spawn_location.name) == current_spawn_location_instance_number and current_player_for_spawn_location_number != player:
					player.rpc("update_position", spawn_location.global_position)
					current_spawn_location_instance_number += 1
					current_player_for_spawn_location_number = player

func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	
	if PersistentNodes.has_node(str(id)):
		PersistentNodes.get_node(str(id)).username_text_instance.queue_free()
		PersistentNodes.get_node(str(id)).queue_free()

#func update_vote_label():
#	vote_label.text = "Your Votes: %d/%d\n" % [current_votes, max_votes]
#	for player_id in player_votes.keys():
#		vote_label.text += "Player %s: %d votes\n" % [player_id, player_votes[player_id]]

#sync func end_voting():
#	for button in PersistentNodes.get_children():
#		button.disabled = true
#		var max_vote = 0
#		var player_to_destroy = null
#		for player in PersistentNodes.get_children():
#			if PersistentNodes.get_children()[player] > max_vote:
#				max_vote = PersistentNodes.get_children()[player]
#				player_to_destroy = player

#		if player_to_destroy:
#			print("%s has been destroyed!" % player_to_destroy)
#			if username_text_instance != null:
#				username_text_instance.visible = false
#
#			if get_tree().has_network_peer():
#				if get_tree().is_network_server():
#						rpc("destroy")
