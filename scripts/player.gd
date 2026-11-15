extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var collect_sound: AudioStreamPlayer2D = $CollectSound

const SPEED = 300.0
const JUMP_VELOCITY = -850.0

var was_on_floor := true
var is_landing := false
var Bounce_factor = 0.4
var impact_velocity = 0

func _ready() -> void:
	# Force "Jumping down" to NOT loop, so animation_finished always triggers
	# even if Loop was left checked in SpriteFrames in the editor/git
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("Jumping down"):
		animated_sprite_2d.sprite_frames.set_animation_loop("Jumping down", false)

	if not animated_sprite_2d.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "Jumping down":
		is_landing = false


func _physics_process(delta: float) -> void:
	# Basic gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_landing = false
		jump_sound.play()
		

	# Movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	#Store what the velocity was before the impact, so that it can be dissapated
	impact_velocity = -velocity.y
	#Some reflection stuff, remove this because its useless, or let me improve on it - Harri
	var collision := move_and_collide(velocity * delta)
	if collision:
		var normal := collision.get_normal()
		# Bounce or slide your velocity using the normal
		velocity = velocity.bounce(normal)

	move_and_slide()

	var grounded = is_on_floor()

	# Animation logic
	if not grounded:
		is_landing = false
		if animated_sprite_2d.sprite_frames.has_animation("Jumping up"):
			animated_sprite_2d.play("Jumping up")
		elif animated_sprite_2d.animation == "Jumping down":
			# Fallback so it doesn't get stuck in landing animation mid-air
			animated_sprite_2d.play("Idle")

	elif not was_on_floor and grounded:
		# Just landed
		is_landing = true
		animated_sprite_2d.play("Jumping down")
		#Extra jump, never get a break NOT REALLY WORKING RN
		if velocity.y > -0.1*JUMP_VELOCITY:
			velocity.y = impact_velocity * Bounce_factor

	elif is_landing:
		# If the player starts moving, cancel landing immediately
		if direction != 0:
			is_landing = false
			if velocity.x < -1:
				animated_sprite_2d.play("Running left")
			elif velocity.x > 1:
				animated_sprite_2d.play("Running right")
		# Otherwise wait for the landing animation to finish
		pass

	elif velocity.x < -1:
		animated_sprite_2d.play("Running left")
	elif velocity.x > 1:
		animated_sprite_2d.play("Running right")
	else:
		animated_sprite_2d.play("Idle")

	was_on_floor = grounded
