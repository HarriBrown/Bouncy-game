extends Area2D

const SPEED = 100.0
var direction = -1.0
var is_dead = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collision_shape_2d_2: CollisionShape2D = $CollisionShape2D2
@onready var timer: Timer = $Timer

func _ready() -> void:
	add_to_group("Enemy")
	animated_sprite_2d.play("Walk")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_dead:
		return
	position.x += direction * SPEED * delta

func _on_timer_timeout() -> void:
	if is_dead:
		return
	direction *= -1.0
	update_direction()

func update_direction() -> void:
	var facing_right = direction > 0
	animated_sprite_2d.flip_h = facing_right
	if collision_shape_2d:
		collision_shape_2d.position.x = -6.0 if facing_right else 6.0
	if collision_shape_2d_2:
		collision_shape_2d_2.position.x = -19.0 if facing_right else 19.0

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("Player") or body.name == "Player":
		var player = body
		# If the player is falling and their center is above the snail's mid-point, it's a stomp!
		if player.velocity.y > 0 and player.global_position.y < global_position.y + 10.0:
			stomp(player)
		else:
			var knock_dir = Vector2.RIGHT if player.global_position.x > global_position.x else Vector2.LEFT
			if player.has_method("take_damage"):
				player.take_damage(20, knock_dir)

func stomp(player: CharacterBody2D) -> void:
	is_dead = true
	if player.has_method("bounce_off_enemy"):
		player.bounce_off_enemy()
	
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if collision_shape_2d_2:
		collision_shape_2d_2.set_deferred("disabled", true)
	
	if animated_sprite_2d.sprite_frames.has_animation("Shell Top Hit"):
		animated_sprite_2d.play("Shell Top Hit")
	elif animated_sprite_2d.sprite_frames.has_animation("Hit"):
		animated_sprite_2d.play("Hit")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.tween_callback(queue_free)
