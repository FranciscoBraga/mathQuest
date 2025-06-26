# enemy.gd
extends CharacterBody2D

signal monster_clicked(monster_instance)

@export var speed = 75.0
@export var answer_value = 0 

@onready var answer_label: Label = $AnswerLabel
@onready var click_area: Area2D = $ClickArea
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var player_node: Node2D
var can_attack = true

# _ready SÓ deve fazer conexões de sinais. Nenhuma outra lógica.
func _ready():
	click_area.input_event.connect(_on_click_area_input_event)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)

# Esta é a ÚNICA função que deve definir o player_node.
func initialize(target: Node2D):
	player_node = target

func _physics_process(delta):
	# A verificação 'is_instance_valid' é crucial.
	if is_instance_valid(player_node):
		var direction = (player_node.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if can_attack:
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				# Verifica se o corpo colidido é o mesmo que o nosso alvo
				if collision.get_collider() == player_node:
					var player_collided = collision.get_collider()
					player_collided.take_damage(10)
					can_attack = false
					attack_cooldown_timer.start()
					# Recuo opcional para não ficar preso
					velocity = -direction * speed * 2
					move_and_slide()
					break

func stop_moving():
	set_physics_process(false)

func _on_attack_cooldown_timer_timeout():
	can_attack = true

func set_answer(value: int):
	answer_value = value
	answer_label.text = str(answer_value)

func _on_click_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("monster_clicked", self)

func take_damage(amount: int):
	queue_free()

func apply_penalty_speed_boost():
	speed *= 1.5
