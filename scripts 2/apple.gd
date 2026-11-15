extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var collected: bool = false

func _ready() -> void:
	add_to_group("Apple")
	animated_sprite_2d.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body.is_in_group("Player") or body.name == "Player":
		collected = true
		if body.has_method("collect_apple"):
			body.collect_apple()
		collision_shape_2d.set_deferred("disabled", true)
		animated_sprite_2d.play("collected")
		await animated_sprite_2d.animation_finished
		queue_free()
