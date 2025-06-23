# enemy.gd
extends CharacterBody2D

signal monster_clicked(monster_instance)

@export var damage = 10 # Dano que o inimigo causa
@export var attack_cooldown = 2.0 # Segundos de cooldown

# Nossa variável de estado. Começa como 'true' para que ele possa atacar assim que nascer.
var can_attack = true

@export var speed = 75.0
@export var answer_value = 0 

@onready var answer_label: Label = $AnswerLabel
@onready var click_area: Area2D = $ClickArea
# Referência ao nosso novo nó Timer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var player_node: Node2D

func _ready():
	player_node = get_tree().get_first_node_in_group("player")
	click_area.input_event.connect(_on_click_area_input_event)
	# Configura o tempo de espera do timer com base na nossa variável exportada
	attack_cooldown_timer.wait_time = attack_cooldown

func _physics_process(delta):
	if is_instance_valid(player_node):
		var direction = (player_node.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# A lógica de ataque agora só roda se o inimigo PUDER atacar
		if can_attack:
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				if collision.get_collider().is_in_group("player"):
					# --- A LÓGICA DE ATAQUE ACONTECE AQUI ---
					
					# 1. Causa o dano
					var player_collided = collision.get_collider()
					player_collided.take_damage(damage)
					
					# 2. Entra no estado de "RECARREGANDO"
					can_attack = false
					
					# 3. Inicia o cronômetro do cooldown
					attack_cooldown_timer.start()

					# 4. (Opcional, mas recomendado) Faz um pequeno recuo
					# para o inimigo não ficar "preso" no jogador.
					velocity = -direction * speed * 2 # Joga para trás com o dobro da velocidade
					move_and_slide() # Aplica o movimento de recuo
					
					print("Inimigo atacou! Entrando em cooldown...")
					break
					
# ESTA FUNÇÃO É CHAMADA QUANDO O TIMER TERMINA
func _on_attack_cooldown_timer_timeout():
	 # O tempo de recarga acabou. Volta para o estado "PODE ATACAR"
	can_attack = true
	print("Cooldown do inimigo terminou. Pronto para atacar!")
	
func set_answer(value: int):
	answer_value = value
	answer_label.text = str(answer_value)

func _on_click_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("monster_clicked", self)

func take_damage(amount: int):
	# Esta função é chamada quando o JOGADOR ataca o inimigo
	queue_free()

func apply_penalty_speed_boost():
	speed *= 1.5
	
# Adicione esta função em qualquer lugar do script
func stop_moving():
	# Esta função desliga completamente o _physics_process para este inimigo.
	# É a forma mais otimizada de pará-lo.
	set_physics_process(false)
