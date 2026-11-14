extends CharacterBody2D

@export var GRAVITY: float = 1000.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()
