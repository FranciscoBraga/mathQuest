# player.gd
extends CharacterBody2D

# Vamos usar sinais para que outros nós saibam o que aconteceu com o jogador
signal health_changed(current_health)
signal died
signal power_changed(current_power)

@onready var animation_player = $AnimationPlayer

var health = 100
var max_health = 1000
var current_power = 0
var max_power = 100

var last_direction = Vector2(0, 1)

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# CHAME A FUNÇÃO DE ANIMAÇÃO AQUI
	update_animation(direction)

	#velocity = direction * speed
	move_and_slide()
	
# Esta função será chamada por um inimigo ou projétil que o atingir
func take_damage(amount: int):
	health -= amount
	emit_signal("health_changed", health)
	print("Vida do jogador: ", health)
	print("SINAL 'health_changed' EMITIDO! Nova vida: ", health)
	if health <= 0:
		emit_signal("died")
		hide() # Apenas esconde o sprite do jogador
		get_node("CollisionShape2D").set_deferred("disabled", true) # Desativa a colisão de forma segura
		
func gain_power(amount: int):
	current_power = min(current_power + amount, max_power) # Garante que o poder não passe do máximo
	emit_signal("power_changed", current_power)
	print("Poder do jogador: ", current_power)

# Esta função será chamada pelo Maestro quando o jogador acertar um cálculo
func perform_attack(target_monster: Node2D):
	print("Atacando o monstro: ", target_monster.name)
	# AQUI VAI A LÓGICA DO ATAQUE
	# Exemplo 1: Dano instantâneo
	# TOCA A ANIMAÇÃO DE ATAQUE
	animation_player.play("attack")
	if target_monster.has_method("take_damage"):
		target_monster.take_damage(50) # Causa 50 de dano
		
	# Exemplo 2: Lançar um projétil (mais visual)
	# var projectile = ProjectileScene.instantiate()
	# projectile.target = target_monster
	# add_child(projectile)
	
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
		# Se parado, para na primeira imagem da última direção
		# (Você pode criar animações de "idle" aqui também)
		animation_player.stop()
