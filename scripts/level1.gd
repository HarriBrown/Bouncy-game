extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	# Wait one frame so all children groups are registered
	await get_tree().process_frame
	var apples = get_tree().get_nodes_in_group("Apple")
	if hud and player:
		hud.init_hud(player, apples.size())
