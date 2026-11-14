extends CharacterBody2D

@export var velocidad: float = 80.0

var direccion: int = 1
var atacando: bool = false
var puede_girar: bool = true
var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector_borde: RayCast2D = $DetectorBorde

func _ready() -> void:
	sprite.play("caminar")
	$Hitbox.body_entered.connect(_al_tocar)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta

	if not atacando:
		# Si choca con una pared O ve que ya no hay piso adelante, da la vuelta
		if puede_girar and (is_on_wall() or (is_on_floor() and not detector_borde.is_colliding())):
			voltear()

		velocity.x = direccion * velocidad
	else:
		velocity.x = 0

	move_and_slide()

func voltear() -> void:
	puede_girar = false
	direccion *= -1
	sprite.flip_h = direccion < 0
	detector_borde.position.x = abs(detector_borde.position.x) * direccion
	detector_borde.force_raycast_update()
	await get_tree().create_timer(0.15).timeout
	puede_girar = true

func _al_tocar(body: Node2D) -> void:
	if body.has_method("recibir_dano"):
		if body.velocity.y > 20.0:
			# Muere aplastada si la pisas desde arriba y rebotas
			$Hitbox.set_deferred("monitoring", false)
			set_physics_process(false)
			body.velocity.y = -340.0
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(sprite.scale.x * 1.4, sprite.scale.y * 0.2), 0.12)
			tween.parallel().tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 0.20)
			await tween.finished
			queue_free()
		else:
			# Te muerde si la tocas sin venir cayendo
			atacando = true
			sprite.flip_h = body.global_position.x < global_position.x
			sprite.play("ataque")
			body.recibir_dano(1)
			await sprite.animation_finished
			atacando = false
			sprite.play("caminar")
