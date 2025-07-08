# player.gd
extends CharacterBody2D

# Definimos os possíveis estados do jogador
enum State { IDLE, MOVING, ATTACKING, HURT }
var current_state = State.IDLE # O jogador começa no estado "Parado"


#sinais 
signal health_changed(current_health)
signal died
signal power_changed(current_power)
signal movement_finished

signal gold_changed(new_gold_amount)

@onready var animation_player = $AnimationPlayer
@export var projectile_scene: PackedScene
# Adicione uma referência para o nosso cérebro do jogo
@export var game_manager: Node


var health = 100
var max_health = 1000
var current_power = 0
var max_power = 100
var speed = 20
var gold = 0 # O jogador começa com 0 de ouro


var last_direction = Vector2(0, 1)
var target_position: Vector2 # Nova variável para guardar o alvo do clique
# Substitua seu _physics_process inteiro por este:
# Substitua seu _physics_process inteiro por este:
func _physics_process(delta):
	# Se o jogador estiver atacando ou tomando dano, não permite movimento.
	if current_state == State.ATTACKING or current_state == State.HURT:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Pega a direção do input do teclado
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Define a velocidade baseada na direção
	if direction.length() > 0:
		velocity = direction * speed
		current_state = State.MOVING
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE

	# Atualiza a animação e move o personagem
	update_animation(direction)
	move_and_slide()
	
# Adicione funções para as penalidades
func lose_power(amount: int):
	current_power = max(0, current_power - amount)
	emit_signal("power_changed", current_power)
	print("Poder perdido! Poder atual: ", current_power)
	
# O GameManager chama esta função para mover o jogador
func move_to_position(new_target: Vector2):
	# Só aceita o comando se não estiver atacando
	if current_state != State.ATTACKING:
		target_position = new_target
		current_state = State.MOVING

# Esta função será chamada por um inimigo ou projétil que o atingir
func take_damage(amount: int):
	if current_state == State.HURT: return # Evita tomar dano várias vezes seguidas

	health -= amount
	emit_signal("health_changed", health)
	
	# CHAMA A ANIMAÇÃO DE DANO AQUI!
	play_hit_animation()
	
	if health <= 0:
		emit_signal("died")
		hide()
		get_node("CollisionShape2D").set_deferred("disabled", true)
		
func gain_power(amount: int):
	current_power = min(current_power + amount, max_power) # Garante que o poder não passe do máximo
	emit_signal("power_changed", current_power)

#função para adicionar ouro
func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)

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
func play_hit_animation():
	print("take_hit")
	current_state = State.HURT # Trava o jogador no estado de "dano"
	animation_player.play("take_hit")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# Se a animação que terminou foi uma de ataque ou de tomar dano...
	if anim_name.begins_with("attack_") or anim_name == "take_hit":
		# ...libera o jogador, voltando ao estado IDLE.
		current_state = State.IDLE
		
