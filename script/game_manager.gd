# wave_manager.gd
extends Node

@export var enemy_scene: PackedScene
@export var spawn_radius = 500
@export var game_over_screen: Control

enum GameState { PLAYING, GAME_OVER }
var current_state = GameState.PLAYING

@export var player: CharacterBody2D
@export var question_label: Label
@export var monster_container: Node2D

var active_monsters = []
var correct_answer = 0

func _ready():
	player.died.connect(_on_player_died)
	game_over_screen.hide()
	
	# LINHA DE TESTE: O que o WaveManager pensa que é a posição do jogador?
	# Esta linha vai rodar ANTES de qualquer inimigo ser criado.
	if is_instance_valid(player):
		print("WaveManager no _ready: Posição do jogador é ", player.global_position)
	else:
		print("WaveManager no _ready: A REFERÊNCIA AO JOGADOR AINDA ESTÁ QUEBRADA!")

	call_deferred("start_wave", 5)

# --- FUNÇÃO CORRIGIDA ---
func start_wave(monster_count: int):
	# 1. Reseta o estado para garantir que a nova onda funcione
	current_state = GameState.PLAYING
	
	# 2. Limpa a lista de monstros ativos da onda anterior
	active_monsters.clear()
	
	# 3. Remove todos os nós de monstros antigos da cena
	for monster in monster_container.get_children():
		monster.queue_free()

	# 4. Gera os novos monstros (esta parte estava correta)
	for i in range(monster_count):
		var enemy_instance = enemy_scene.instantiate()
		
		# Verifica se o 'player' foi conectado no Inspetor antes de usar
		if is_instance_valid(player):
			enemy_instance.initialize(player)
		else:
			print("ERRO CRÍTICO: O 'Player' não foi arrastado para o WaveManager no Inspetor!")
			return

		var angle = i * (TAU / monster_count)
		var spawn_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
		enemy_instance.global_position = spawn_position
		
		enemy_instance.monster_clicked.connect(_on_monster_clicked)
		
		active_monsters.append(enemy_instance)
		monster_container.add_child(enemy_instance)
		
	new_math_round()
# --- FIM DA FUNÇÃO CORRIGIDA ---
	
func new_math_round():
	if current_state != GameState.PLAYING:
		return
	if active_monsters.is_empty():
		question_label.text = "ONDA CONCLUÍDA!"
		await get_tree().create_timer(3.0).timeout
		start_wave(6)
		return

	var problem = MathProblem.generate_problem(1)
	question_label.text = problem.question
	correct_answer = problem.correct_answer
	
	var answers_to_distribute = problem.wrong_answers
	
	while answers_to_distribute.size() < active_monsters.size() - 1:
		answers_to_distribute.append(correct_answer + randi_range(1, 5))

	active_monsters.shuffle()
	
	if not active_monsters.is_empty():
		active_monsters[0].set_answer(correct_answer)
		for i in range(1, active_monsters.size()):
			active_monsters[i].set_answer(answers_to_distribute[i-1])

func _on_monster_clicked(monster: CharacterBody2D):
	if current_state != GameState.PLAYING:
		return
	if monster.answer_value == correct_answer:
		player.perform_attack(monster)
		active_monsters.erase(monster)
		player.gain_power(20)
	else:
		monster.apply_penalty_speed_boost()
	
	new_math_round()

func _on_player_died():
	if current_state == GameState.GAME_OVER:
		return
	current_state = GameState.GAME_OVER
	game_over_screen.show()
	for monster in active_monsters:
		if is_instance_valid(monster):
			monster.stop_moving()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
