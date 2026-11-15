extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/HBoxContainer/HealthContainer/HealthBar
@onready var health_label: Label = $MarginContainer/HBoxContainer/HealthContainer/HealthLabel
@onready var apple_label: Label = $MarginContainer/HBoxContainer/AppleLabel
@onready var message_label: Label = $CenterContainer/MessageLabel

var total_apples: int = 0
var collected_apples: int = 0

func _ready() -> void:
	message_label.visible = false

func init_hud(player: Node, apples_count: int) -> void:
	total_apples = apples_count
	update_apples(0)
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(update_health)
		if player.has_signal("apple_collected"):
			player.apple_collected.connect(update_apples)
		if player.has_signal("died"):
			player.died.connect(_on_player_died)
		update_health(player.health, player.max_health)

func update_health(current: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current
	if health_label:
		health_label.text = "HP: %d/%d" % [current, max_val]

func update_apples(count: int) -> void:
	collected_apples = count
	if apple_label:
		apple_label.text = "Apples: %d / %d" % [count, total_apples]
	if total_apples > 0 and count >= total_apples:
		if message_label:
			message_label.text = "YOU WIN! ALL APPLES COLLECTED!\nPress R to Play Again"
			message_label.visible = true

func _on_player_died() -> void:
	if message_label:
		message_label.text = "GAME OVER\nRestarting..."
		message_label.visible = true
