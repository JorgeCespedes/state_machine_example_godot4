extends CharacterBody2D



@onready var sprite_idle: Sprite2D = $all_sprites/sprite_idle
@onready var sprite_move: Sprite2D = $all_sprites/sprite_move
@onready var sprite_jump: Sprite2D = $all_sprites/sprite_jump
@onready var sprite_fall: Sprite2D = $all_sprites/sprite_fall
@onready var sprite_attack_1: Sprite2D = $all_sprites/sprite_attack1
@onready var sprite_attack_2: Sprite2D = $all_sprites/sprite_attack2
@onready var sprite_attack_3: Sprite2D = $all_sprites/sprite_attack3
@onready var sprite_hit: Sprite2D = $all_sprites/sprite_hit
@onready var sprite_death: Sprite2D = $all_sprites/sprite_death
@onready var all_sprites = [sprite_idle, sprite_move, sprite_jump, sprite_fall, sprite_attack_1, sprite_attack_2, sprite_attack_3, sprite_hit, sprite_death]

@onready var col_attack_1: CollisionShape2D = $area_attack/col_attack1
@onready var col_attack_2: CollisionShape2D = $area_attack/col_attack2
@onready var col_attack_3: CollisionShape2D = $area_attack/col_attack3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
var state_machine

@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
@export var health: float = 100

var facing_right := true  # Por defecto mira a la derecha
var is_attacking: bool = false

func _ready() -> void:
	state_machine = animation_tree["parameters/playback"]
	animation_player.connect("animation_finished", Callable(self, "_on_animation_player_animation_finished"))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_attacking:
		handle_movement()
		handle_jump()
	
	handle_attack()
	
	move_and_slide()

# --- HANDLE MOVEMENT
func handle_movement():
	var move_direction = Input.get_axis("move_left", "move_right")
	if move_direction != 0:
		state_machine.travel("move")
		show_sprite(sprite_move)
		velocity.x = move_direction * speed
		flip_sprites(velocity.x > 0)
	else:  # Solo cambiar a idle si no está atacando
		state_machine.travel("idle")
		show_sprite(sprite_idle)
		velocity.x = 0

# --- HANDLE JUMP
func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	# Manejo del estado en el aire
	if not is_on_floor():
		if velocity.y < 0:
			# Estamos subiendo (salto)
			show_sprite(sprite_jump) 
			state_machine.travel("jump")
		else:
			# Estamos cayendo
			show_sprite(sprite_fall) 
			state_machine.travel("fall")

# --- HANDLE ATTACK
func handle_attack():
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		velocity.x = 0 # Opcional: detener movimiento durante el ataque
		
		# Generar un número aleatorio entre 0 y 2
		var random_index = randi() % 3
		match random_index:
			0:
				state_machine.travel("attack1")
				show_sprite(sprite_attack_1)
				animation_player.play("attack1")
			1:
				state_machine.travel("attack2")
				show_sprite(sprite_attack_2)
				animation_player.play("attack2")
			2:
				state_machine.travel("attack3")
				show_sprite(sprite_attack_3)
				animation_player.play("attack3")

# Función para voltear todos los sprites
func flip_sprites(face_right: bool):
	facing_right = face_right
	# Aplicar a todos los sprites relevantes
	for sprite in all_sprites:
		sprite.flip_h = !face_right
	# Posición del CollisionShape2D del ataque
	if face_right:
		col_attack_1.position = Vector2(36, 23)
		col_attack_2.position = Vector2(39, 26)
		col_attack_3.position = Vector2(36, 0)
	else:
		col_attack_1.position = Vector2(-36, 23)
		col_attack_2.position = Vector2(-39, 26)
		col_attack_3.position = Vector2(-36, 0)

# --- MOSTRAR SPRITE ACTIVO
func show_sprite(active_sprite: Sprite2D):
	for sprite in all_sprites:
		sprite.visible = (sprite == active_sprite)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack1" or anim_name == "attack2" or anim_name == "attack3" :
		is_attacking = false
		#state_machine.travel("idle")
