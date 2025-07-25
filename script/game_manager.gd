# GameManager.gd (antigo wave_manager.gd)
extends Node

# --- EXPORTS: Conecte estes no Inspetor ---
@export var player: CharacterBody2D
@export var monster_container: Node2D
@export var enemy_scenes: Array[PackedScene] # Sua lista de inimigos
@export var portal_scene: PackedScene 

# UI Geral
@export var question_label: Label
@export var hud: Control # O container principal da UI com as barras e botões
@export var shop_button: Button
@export var config_button: Button

# Telas de UI
@export var game_over_screen: Panel
@export var shop_screen: Panel
@export var settings_screen: Panel

# --- LÓGICA DE AMEAÇA (NOVO SISTEMA) ---
var threat_level = 0.0 # Ameaça atual, de 0 em diante
@export var threat_rate = 0.5 # Pontos de ameaça ganhos por segundo
@export var spawn_base_cooldown = 4.0 # Tempo em segundos para spawnar um inimigo com ameaça zero

@onready var spawn_timer: Timer = $SpawnTimer

@export_category("Balanço da Fase")
# O número máximo de inimigos permitidos na tela ao mesmo tempo. Essencial para controle e performance.
@export var max_active_monsters: int = 20
# O tempo inicial em segundos entre o spawn de cada inimigo. Um número maior = mais fácil.
@export var initial_spawn_cooldown: float = 4.0
# Quão rápido a "barra de ameaça" invisível sobe. Um número maior = dificuldade aumenta mais rápido.
@export var threat_rate_per_second: float = 0.5
# Um multiplicador que define o quão mais rápido os inimigos aparecem conforme a ameaça aumenta.
@export var threat_scaling_factor: float = 0.05


# --- VARIÁVEIS DE ESTADO E JOGO ---
enum GameState { PLAYING, GAME_OVER, PAUSED } # Simplificado
var current_state = GameState.PLAYING

var active_monsters = []
var current_problem: Dictionary 
var correct_answer = 0

var current_phase_number = 1 # Controla o nível de dificuldade atual (1 a 21)
var is_combat_puzzle_active = false

@export var next_level_path: String = "res://levels/level_2.tscn"
var level_duration = 180.0 # 3 minutos em segundos
var level_timer = 0.0

func _ready():
	
	
	# Pega todos os nós que estão no grupo "interactables"
	var interactable_nodes = get_tree().get_nodes_in_group("interactables")
	for interactable in interactable_nodes:
		# Conecta o sinal de SUCESSO a uma função que dá a recompensa
		interactable.interaction_succeeded.connect(_on_interaction_succeeded)
		# Conecta o sinal de FALHA a uma função que aplica a penalidade
		interactable.interaction_failed.connect(_on_interaction_failed)
	# --- CONEXÕES DE SINAIS ---
	# Apenas conectamos tudo que precisa ser conectado no início.
	player.died.connect(_on_player_died)
	
	shop_button.pressed.connect(_on_shop_button_pressed)
	config_button.pressed.connect(_on_config_button_pressed)
	
	shop_screen.close_requested.connect(_on_close_shop_button_pressed)
	settings_screen.close_settings.connect(_on_close_button_settings)
	game_over_screen.restart_game_requested.connect(_on_restart_button_pressed)
	
	shop_screen.item_purchased.connect(_on_item_purchased)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Esconde as telas que não devem começar visíveis
	game_over_screen.hide()
	settings_screen.hide()
	shop_screen.hide()
	
	# A pergunta de combate só aparece quando um inimigo é clicado
	question_label.hide()
		# Garante que o timer inicial comece com o valor que definimos
	spawn_timer.wait_time = initial_spawn_cooldown

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
	
	level_timer += delta
	if level_timer >= level_duration:
		# Lógica para spawnar o Guardião da Fase
		# E para de contar o tempo
		set_process(false) # Exemplo de como parar o timer


func _on_spawn_timer_timeout():
	print("0 estado",current_state)
	if current_state != GameState.PLAYING:
		return
	print("10 inimigos",enemy_scenes.is_empty())
	
	# Se já atingimos o número máximo de inimigos na tela, simplesmente não cria um novo.
	if active_monsters.size() >= max_active_monsters:
		return # Para aqui, esperando o jogador limpar a tela um pouco.
	
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
			spawn_pos = Vector2(randf_range(0, screen_size.x), -10)
		1: # Baixo
			spawn_pos = Vector2(randf_range(0, screen_size.x), screen_size.y + 10)
		2: # Esquerda
			spawn_pos = Vector2(-10, randf_range(0, screen_size.y))
		3: # Direita
			spawn_pos = Vector2(screen_size.x + 10, randf_range(0, screen_size.y))

	# Converte a posição da tela para a posição do mundo
	var world_spawn_pos = player.global_position + (spawn_pos - screen_size / 2)

	# Inicializa e adiciona o inimigo
	enemy_instance.initialize(player)
	enemy_instance.global_position = world_spawn_pos
	enemy_instance.monster_clicked.connect(_on_monster_clicked)
	active_monsters.append(enemy_instance)
	monster_container.add_child(enemy_instance)
	
	
	if  not is_combat_puzzle_active:
		print("8 is_combat_puzzle_active",is_combat_puzzle_active)
		create_combat_challenge()

func create_combat_challenge():
	# Se não houver monstros, não há desafio.
	if active_monsters.is_empty():
		question_label.hide()
		is_combat_puzzle_active = false
		return
	
	# 1. Pede ao gerador um problema com o número exato de respostas erradas que precisamos
	# (uma a menos que o total de monstros vivos).
	var num_monsters = active_monsters.size()
	current_problem = MathProblem.generate_problem(current_phase_number, num_monsters - 1)
	
	# 2. Armazena a resposta correta em nossa variável de classe.
	correct_answer = current_problem.correct_answer
	
	# 3. Mostra a pergunta na tela.
	question_label.text = current_problem.question
	question_label.show()

	# 4. Prepara a lista COMPLETA de respostas para distribuir.
	var all_answers = current_problem.wrong_answers
	all_answers.append(correct_answer)
	all_answers.shuffle()
	
	# 5. Distribui CADA resposta para CADA monstro.
	for i in range(num_monsters):
		var monster = active_monsters[i]
		var answer_to_set = all_answers[i]
		monster.set_answer(answer_to_set)

	# Marca que um puzzle está ativo.
	is_combat_puzzle_active = true
# Chamado pelo SpawnTimer para criar inimigos gradualmente

# O Guardião, ao morrer, chama esta função
func on_guardian_defeated(guardian_position):
	# Garante que temos uma cena de portal configurada
	if not portal_scene:
		print("ERRO: Cena do portal não configurada no GameManager!")
		return

	# 1. Cria o portal usando a variável de export correta
	var portal = portal_scene.instantiate()
	portal.global_position = guardian_position
	
	# 2. Conecta o sinal do portal à nossa nova função
	portal.interaction_requested.connect(_on_portal_entered)
	
	# Adiciona o portal à cena
	add_child(portal)

# O portal, ao ser tocado, chama esta função
func on_portal_entered():
	# LÓGICA DE TRANSIÇÃO
	# Salva os dados importantes primeiro!
	SettingsManager.save_settings()
	# Muda para a próxima cena
	get_tree().change_scene_to_file(next_level_path)
	
# A lógica de clicar no monstro agora mostra a pergunta
func _on_monster_clicked(monster: CharacterBody2D):
	if not is_combat_puzzle_active: return
	if current_state != GameState.PLAYING: return

	# Agora a comparação com 'correct_answer' funciona, pois ela é uma
	# variável do GameManager e foi definida pelo último desafio criado.
	if monster.answer_value == correct_answer:
		# RESPOSTA CORRETA!
		active_monsters.erase(monster)
		player.perform_attack(monster)
		
		# Cria imediatamente o próximo desafio para os monstros que sobraram.
		create_combat_challenge()
	else:
		# RESPOSTA ERRADA!
		monster.apply_penalty_speed_boost()
		# Gera um novo desafio para dar ao jogador outra chance.
		create_combat_challenge()

func _on_shop_button_pressed():
	current_state = GameState.PAUSED
	shop_screen.show()
	get_tree().paused = true

func _on_close_shop_button_pressed():
	print("fechar  _on_close_shop_button_pressed")
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
	
func _on_interaction_succeeded(type, amount):
	if type == "ouro":
		player.add_gold(amount)

func _on_interaction_failed():
	player.lose_power(10)
	player.play_hit_animation()

func _on_item_purchased(item_data: ShopItemData):
	# Remove o ouro do jogador
	player.add_gold(-item_data.cost)
	
	# Aplica o bônus do atributo (a lógica exata pode variar)
	# Ex: player.speed += item_data.attribute_value
	print("Item '", item_data.item_name, "' foi adicionado ao inventário!")

	# Atualiza a loja para remover o item comprado (opcional)
	# shop_screen.remove_item(item_data)
	# Função chamada quando o jogador interage com o portal
func _on_portal_entered():
	print("Portal ativado! Transicionando para o próximo nível...")
	# Salva os dados do jogador antes de mudar de cena
	SettingsManager.save_settings() 
	# Muda para a cena definida na variável next_level_path
	get_tree().change_scene_to_file(next_level_path)
