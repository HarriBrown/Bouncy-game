extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal apple_collected(count: int)
signal died

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var collect_sound: AudioStreamPlayer2D = $CollectSound

const SPEED = 300.0
const JUMP_VELOCITY = -850.0

var was_on_floor := true
var is_landing := false
var bounce_factor := 0.45

# Gameplay mechanics
@export var max_health: int = 100
var health: int = 100
var is_invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 1.0
var is_dead: bool = false
var apples_collected: int = 0

func _ready() -> void:
	add_to_group("Player")
	health = max_health
	
	# Force "Jumping down" to NOT loop, so animation_finished always triggers
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("Jumping down"):
		animated_sprite_2d.sprite_frames.set_animation_loop("Jumping down", false)

	if not animated_sprite_2d.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "Jumping down":
		is_landing = false

func bounce_off_enemy() -> void:
	velocity.y = JUMP_VELOCITY * 0.85
	is_landing = false
	jump_sound.play()

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_invincible:
		return
	
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		die()
	else:
		is_invincible = true
		invincibility_timer = INVINCIBILITY_DURATION
		death_sound.play()
		velocity = knockback_dir * 350.0 + Vector2(0, -350.0)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	death_sound.play()
	animated_sprite_2d.play("Dying")
	died.emit()
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func(): get_tree().reload_current_scene())

func collect_apple() -> void:
	apples_collected += 1
	collect_sound.play()
	apple_collected.emit(apples_collected)

func _physics_process(delta: float) -> void:
	if is_dead:
		# Apply gravity while dying so the corpse falls if in mid-air
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()
		return

	# Handle invincibility flashing
	if is_invincible:
		invincibility_timer -= delta
		modulate.a = 0.4 if fmod(invincibility_timer, 0.2) > 0.1 else 1.0
		if invincibility_timer <= 0.0:
			is_invincible = false
			modulate.a = 1.0

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_landing = false
		jump_sound.play()

	# Horizontal movement
	var direction := Input.get_axis("left", "right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Remember velocity right before collision resolution
	var prev_velocity = velocity

	move_and_slide()

	var grounded = is_on_floor()

	# Bouncing mechanic
	if not was_on_floor and grounded:
		# Just landed
		is_landing = true
		animated_sprite_2d.play("Jumping down")
		if prev_velocity.y > 150.0:
			velocity.y = -prev_velocity.y * bounce_factor
	elif is_on_wall() and abs(prev_velocity.x) > 180.0:
		# Bounce off walls
		velocity.x = -prev_velocity.x * bounce_factor

	# Animations
	if not grounded:
		is_landing = false
		if animated_sprite_2d.sprite_frames.has_animation("Jumping up"):
			animated_sprite_2d.play("Jumping up")
		elif animated_sprite_2d.animation == "Jumping down":
			animated_sprite_2d.play("Idle")
	elif is_landing:
		if direction != 0.0:
			is_landing = false
			if velocity.x < -1.0:
				animated_sprite_2d.play("Running left")
			elif velocity.x > 1.0:
				animated_sprite_2d.play("Running right")
	elif velocity.x < -1.0:
		animated_sprite_2d.play("Running left")
	elif velocity.x > 1.0:
		animated_sprite_2d.play("Running right")
	else:
		animated_sprite_2d.play("Idle")

	was_on_floor = grounded
