# player.gd
extends CharacterBody2D

# Definimos os possíveis estados do jogador
enum State { IDLE, MOVING, ATTACKING }
var current_state = State.IDLE # O jogador começa no estado "Parado"


# Vamos usar sinais para que outros nós saibam o que aconteceu com o jogador
signal health_changed(current_health)
signal died
signal power_changed(current_power)

@onready var animation_player = $AnimationPlayer
@export var projectile_scene: PackedScene
# Adicione uma referência para o nosso cérebro do jogo
@export var game_manager: Node


var health = 100
var max_health = 1000
var current_power = 0
var max_power = 100
var speed = 20


var last_direction = Vector2(0, 1)
var target_position: Vector2 # Nova variável para guardar o alvo do clique
# Substitua seu _physics_process inteiro por este:
# Substitua seu _physics_process inteiro por este:
func _physics_process(delta):
	# Usamos 'match' para tratar cada estado do jogador separadamente
	match current_state:
		State.IDLE:
			# No estado PARADO, garantimos que a velocidade seja zero
			# e atualizamos para a animação de parado.
			velocity = Vector2.ZERO
			update_animation(Vector2.ZERO)
		
		State.MOVING:
			# No estado MOVENDO, executamos toda a lógica de movimento point-and-click.
			var direction = global_position.direction_to(target_position)
			
			# Se estivermos perto o suficiente do alvo, mudamos para o estado IDLE.
			if global_position.distance_to(target_position) < 5:
				current_state = State.IDLE
			else:
				# Se não, calculamos a velocidade e atualizamos a animação de caminhada.
				velocity = direction * speed
				update_animation(direction)
		
		State.ATTACKING:
			# No estado ATACANDO, não fazemos NADA relacionado a movimento aqui.
			# A velocidade já foi zerada quando o ataque começou.
			# Apenas esperamos o sinal 'animation_finished' para mudar de estado.
			pass

	# A chamada move_and_slide() fica do lado de fora do match,
	# pois ela deve ser executada sempre para aplicar a 'velocity' atual
	# (seja ela zero, de movimento ou de um futuro efeito de recuo).
	move_and_slide()
	
func _input(event):
	# O jogador só pode receber ordens de movimento durante a EXPLORAÇÃO
	if game_manager.current_phase == game_manager.GamePhase.EXPLORATION:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# O jogador só pode se mover se não estiver atacando (regra antiga, ainda útil)
			if current_state != State.ATTACKING:
				target_position = get_global_mouse_position()
				current_state = State.MOVING

# Esta função será chamada por um inimigo ou projétil que o atingir
func take_damage(amount: int):
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("died")
		hide() # Apenas esconde o sprite do jogador
		get_node("CollisionShape2D").set_deferred("disabled", true) # Desativa a colisão de forma segura
		
func gain_power(amount: int):
	current_power = min(current_power + amount, max_power) # Garante que o poder não passe do máximo
	emit_signal("power_changed", current_power)

func perform_attack(target_monster: Node2D):
	# Não permite um novo ataque se já estiver atacando
	current_state = State.ATTACKING
	velocity = Vector2.ZERO # Garante que ele pare qualquer movimento residual
	
	# 1. Mude o estado para travar o movimento
	current_state = State.ATTACKING
	velocity = Vector2.ZERO # Garante que o jogador pare imediatamente
	
	# 2. Vira-se para o monstro e toca a animação de ataque
	last_direction = global_position.direction_to(target_monster.global_position)
	# (A lógica para escolher a animação correta já está na função abaixo)
	update_attack_animation()
	# 3. Cria e dispara o projétil
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.direction = global_position.direction_to(target_monster.global_position)
		projectile.global_position = global_position
		# Adiciona o projétil à cena principal para que ele não seja filho do jogador
		get_parent().add_child(projectile)
	
# Para organizar, vamos criar uma função só para a animação de ataque
func update_attack_animation():
	print("player direção X:",last_direction.x )
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			animation_player.play("attack_right")
			print("attack_right" )
		else:
			animation_player.play("attack_left")
			print("attack_left" )
	else:
		if last_direction.y > 0:
			animation_player.play("attack_down")
			print("attack_down" )
		else:
			animation_player.play("attack_up")
			print("attack_up" )
	
func update_animation(direction: Vector2):
	# Se o jogador não está se movendo, não atualiza a animação
	if direction.length() > 0:
		# Guarda a última direção para a animação de "parado"
		last_direction = direction

		# Toca a animação baseada na direção dominante
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animation_player.play("walk_right")
			else:
				animation_player.play("walk_left")
		else:
			if direction.y > 0:
				animation_player.play("walk_down")
			else:
				animation_player.play("walk_up")
	else:
		animation_player.play("idle")
		# Se parado, para na primeira imagem da última direção
		# (Você pode criar animações de "idle" aqui também)
		#animation_player.stop()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
# Se a animação que terminou foi uma de ataque, libera o jogador
	if anim_name.begins_with("attack_"):
		current_state = State.IDLE
