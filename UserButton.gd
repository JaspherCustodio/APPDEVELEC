extends Node2D

var player_following = null

onready var button = $VoteButton


func _process(_delta: float) -> void:
	if player_following != null:
		global_position = player_following.global_position
	
