# GameManager.gd (antigo wave_manager.gd)
extends Node

# --- EXPORTS: Conecte estes no Inspetor ---
@export var player: CharacterBody2D
@export var monster_container: Node2D
@export var enemy_scenes: Array[PackedScene] # Sua lista de inimigos

# UI Geral
@export var question_label: Label
@export var hud: Control # O container principal da UI com as barras e botões
@export var shop_button: Button
@export var config_button: Button

# Telas de UI
@export var game_over_screen: Panel
@export var shop_screen: Panel
@export var settings_screen: Panel
@export var interaction_puzzle_ui: Panel

# --- LÓGICA DE AMEAÇA (NOVO SISTEMA) ---
var threat_level = 0.0 # Ameaça atual, de 0 em diante
@export var threat_rate = 0.5 # Pontos de ameaça ganhos por segundo
@export var spawn_base_cooldown = 4.0 # Tempo em segundos para spawnar um inimigo com ameaça zero

@onready var spawn_timer: Timer = $SpawnTimer

# --- VARIÁVEIS DE ESTADO E JOGO ---
enum GameState { PLAYING, GAME_OVER, PAUSED } # Simplificado
var current_state = GameState.PLAYING

var active_monsters = []
var correct_answer = 0

var current_phase_number = 1 # Controla o nível de dificuldade atual (1 a 21)


# Variáveis para o puzzle de interação
var current_interactable = null
var puzzles_to_solve = 0
var puzzles_solved = 0


func _ready():
	# --- CONEXÕES DE SINAIS ---
	# Apenas conectamos tudo que precisa ser conectado no início.
	player.died.connect(_on_player_died)
	
	shop_button.pressed.connect(_on_shop_button_pressed)
	config_button.pressed.connect(_on_config_button_pressed)
	
	shop_screen.close_requested.connect(_on_close_shop_button_pressed)
	settings_screen.close_settings.connect(_on_close_button_settings)
	game_over_screen.restart_game_requested.connect(_on_restart_button_pressed)
	
	interaction_puzzle_ui.answer_chosen.connect(_on_interaction_answer_chosen)
	
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Esconde as telas que não devem começar visíveis
	game_over_screen.hide()
	settings_screen.hide()
	shop_screen.hide()
	interaction_puzzle_ui.hide()
	
	# A pergunta de combate só aparece quando um inimigo é clicado
	question_label.hide()


func _process(delta: float) -> void:
	# O jogo só progride se estiver no estado PLAYING
	if current_state != GameState.PLAYING:
		return

	# --- ATUALIZAÇÃO CONTÍNUA DA AMEAÇA ---
	threat_level += threat_rate * delta
	
	# Ajusta dinamicamente a velocidade de spawn dos inimigos
	# Quanto maior a ameaça, menor o tempo de espera para o próximo inimigo
	var current_spawn_cooldown = max(0.5, spawn_base_cooldown - (threat_level * 0.05))
	spawn_timer.wait_time = current_spawn_cooldown


# Chamado pelo SpawnTimer para criar inimigos gradualmente
func _on_spawn_timer_timeout():
	if current_state != GameState.PLAYING:
		return

	if enemy_scenes.is_empty(): return
	
	# Pega um inimigo aleatório da lista
	var random_enemy_scene = enemy_scenes.pick_random()
	var enemy_instance = random_enemy_scene.instantiate()
	
	# Define uma posição aleatória nas bordas da tela (requer a câmera)
	var screen_size = get_viewport().get_visible_rect().size
	var spawn_edge = randi() % 4
	var spawn_pos = Vector2.ZERO
	
	match spawn_edge:
		0: # Cima
			spawn_pos = Vector2(randf_range(0, screen_size.x), -50)
		1: # Baixo
			spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 50)
		2: # Esquerda
			spawn_pos = Vector2(-50, randf_range(0, screen_size.y))
		3: # Direita
			spawn_pos = Vector2(screen_size.x + 50, randf_range(0, screen_size.y))

	# Converte a posição da tela para a posição do mundo
	var world_spawn_pos = player.global_position + (spawn_pos - screen_size / 2)

	# Inicializa e adiciona o inimigo
	enemy_instance.initialize(player)
	enemy_instance.global_position = world_spawn_pos
	enemy_instance.monster_clicked.connect(_on_monster_clicked)
	active_monsters.append(enemy_instance)
	monster_container.add_child(enemy_instance)


# A lógica de clicar no monstro agora mostra a pergunta
func _on_monster_clicked(monster: CharacterBody2D):
	if current_state != GameState.PLAYING:
		return

	# Gera um problema específico para este combate
	var problem = MathProblem.generate_problem(current_phase_number)
	question_label.text = problem.question
	question_label.show()
	correct_answer = problem.correct_answer # Guarda a resposta correta para este desafio

	# Lógica de ataque (exemplo: se a resposta for a do monstro, ataca)
	if monster.answer_value == correct_answer:
		player.perform_attack(monster)
		active_monsters.erase(monster)
		player.gain_power(20)
		question_label.hide() # Esconde a pergunta após o acerto
	else:
		monster.apply_penalty_speed_boost()
		question_label.hide() # Esconde a pergunta após o erro


# --- FUNÇÕES DE INTERAÇÃO E MENUS (A MAIORIA NÃO MUDA) ---

func start_interaction_puzzle(interactable_object):
	current_state = GameState.PAUSED
	current_interactable = interactable_object
	puzzles_to_solve = current_interactable.puzzle_steps
	puzzles_solved = 0
	ask_next_puzzle()

func ask_next_puzzle():
	var problem = MathProblem.generate_problem(current_phase_number)
	correct_answer = problem.correct_answer
	interaction_puzzle_ui.show_puzzle(problem)

func _on_interaction_answer_chosen(chosen_value):
	if chosen_value == correct_answer:
		puzzles_solved += 1
		if puzzles_solved >= puzzles_to_solve:
			current_interactable.on_interaction_success()
			end_interaction()
		else:
			ask_next_puzzle()
	else:
		end_interaction()

func end_interaction():
	interaction_puzzle_ui.hide()
	current_state = GameState.PLAYING
	current_interactable = null

func _on_shop_button_pressed():
	current_state = GameState.PAUSED
	shop_screen.show()
	get_tree().paused = true

func _on_close_shop_button_pressed():
	shop_screen.hide()
	get_tree().paused = false
	current_state = GameState.PLAYING

func _on_config_button_pressed():
	current_state = GameState.PAUSED
	settings_screen.show()
	get_tree().paused = true
	
func _on_close_button_settings():
	settings_screen.hide()
	get_tree().paused = false
	current_state = GameState.PLAYING

func _on_player_died():
	current_state = GameState.GAME_OVER
	game_over_screen.show()
	for monster in active_monsters:
		if is_instance_valid(monster):
			monster.stop_moving()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
