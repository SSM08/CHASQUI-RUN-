extends CharacterBody2D

@export var velocidad: float = 240.0
@export var fuerza_salto: float = -430.0
@export var vida_maxima: int = 3

var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var vida_actual: int = vida_maxima
var invulnerable: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Aplicar gravedad cuando está en el aire
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. Salto con Espacio (solo si está pisando el suelo)
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# 3. Movimiento horizontal
	var direccion := Input.get_axis("mover_izq", "mover_der")
	if direccion != 0:
		velocity.x = direccion * velocidad
		sprite.flip_h = direccion < 0 # Voltea los fotogramas si va a la izquierda
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	# 4. Mover y chocar contra los bloques sólidos
	move_and_slide()

	# 5. Actualizar animación según el estado
	actualizar_animacion(direccion)

func actualizar_animacion(direccion: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	elif direccion != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

func recibir_dano(cantidad: int = 1) -> void:
	if invulnerable:
		return
	vida_actual -= cantidad
	print("Vida del Chasqui: ", vida_actual)
	
	if vida_actual <= 0:
		get_tree().reload_current_scene() # Reinicia el nivel si muere
		return
	
	# Breve invulnerabilidad con parpadeo para que no le bajen toda la vida de golpe
	invulnerable = true
	sprite.modulate.a = 0.5
	await get_tree().create_timer(1.0).timeout
	sprite.modulate.a = 1.0
	invulnerable = false
