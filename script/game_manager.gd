# wave_manager.gd
extends Node

@export var enemy_scenes: Array[PackedScene]
@export var spawn_radius = 500
@export var game_over_screen: Panel
@export var exploration_answer_scene: PackedScene
@export var shop_button: Button
@export var shop_screen: Control
@export var hud: Control

enum GameState { PLAYING, GAME_OVER }
var current_state = GameState.PLAYING

var correct_streak = 0 # Combo de acertos seguidos

# Definimos os dois principais estados do nosso jogo
enum GamePhase { EXPLORATION, COMBAT }
var current_phase = GamePhase.EXPLORATION # O jogo começa na fase de exploração

@export var player: CharacterBody2D
@export var question_label: Label
@export var monster_container: Node2D
@onready var phase_timer: Timer = $PhaseTimer


var active_monsters = []
var correct_answer = 0

signal gold_changed(new_gold_amount) # Novo sinal

var gold = 0 # O jogador começa com 0 de ouro

# Variável para controlar o tamanho da grade
var current_phase_number = 1
# Dicionário que mapeia o início de uma faixa de fases ao seu tamanho de grade
var phase_answer_counts = {
	1: 4,  # Fases 1-6: Mostra 4 respostas (a cruz)
	7: 6,  # Fases 7-12: Mostra 6 respostas (cruz + 2 diagonais)
	13: 8, # Fases 13-18: Mostra 8 respostas (grade 3x3 completa)
	19: 12 # Fases 19-21: Mostra 12 respostas (em uma grade 5x5)
}
var phase_grid_data = {
	1: Vector2i(3, 3),  # Fases 1-6 terão grade 3x3
	7: Vector2i(5, 5),  # Fases 7-12 terão grade 5x5
	13: Vector2i(7, 7), # Fases 13-18 terão grade 7x7
	19: Vector2i(9, 9)  # Fases 19-21 terão grade 9x9
}

# Distância entre cada número no chão. Ajuste no Inspetor.
@export var answer_spawn_distance = 32.0


func _ready():
	player.died.connect(_on_player_died)
	# NOVA CONEXÃO: Ouve quando o jogador termina de se mover
	player.movement_finished.connect(_on_player_movement_finished)
	# Conecta os sinais dos novos botões
	shop_button.pressed.connect(_on_shop_button_pressed)
	# O caminho para o botão de fechar pode precisar de ajuste
	shop_screen.get_node("CloseShopButton").pressed.connect(_on_close_shop_button_pressed)
	game_over_screen.restart_game_requested.connect(_on_restart_button_pressed)
	game_over_screen.hide()
	
	# Conecta o sinal do nosso novo timer
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	
	# Inicia o jogo na primeira fase de exploração
	start_exploration_phase()

func start_exploration_phase():
	print("FASE DE EXPLORAÇÃO INICIOU!")
	current_phase = GamePhase.EXPLORATION
	shop_button.show() # Mostra o botão da loja na exploração

	# Garante que não há monstros na tela
	for monster in monster_container.get_children():
		monster.queue_free()
	active_monsters.clear()
	
	# AGORA, EM VEZ DE ESCONDER, NÓS MOSTRAMOS E GERAMOS O DESAFIO
	question_label.show()
	create_exploration_challenge()

	# Inicia o cronômetro para a próxima fase de combate
	phase_timer.start()
	
# Esta função cria o desafio de movimento que você descreveu
# wave_manager.gd
func create_exploration_challenge():
	# Limpa as respostas antigas do chão
	for answer_node in get_tree().get_nodes_in_group("exploration_answers"):
		answer_node.queue_free()

	# Gera um novo problema matemático
	var problem = MathProblem.generate_problem(current_phase_number) # Dificuldade aumenta com a fase
	question_label.text = problem.question
	correct_answer = problem.correct_answer
	
# --- LÓGICA DE PROGRESSÃO DE GRADE ---

	# 1. Determina o tamanho da grade e a contagem de respostas para a fase atual
	var grid_size = Vector2i(3, 3)
	var answer_count = 4 # Padrão
	
	for start_phase in phase_grid_data.keys():
		if current_phase_number >= start_phase:
			grid_size = phase_grid_data[start_phase]
	
	for start_phase in phase_answer_counts.keys():
		if current_phase_number >= start_phase:
			answer_count = phase_answer_counts[start_phase]

	# 2. Gera TODAS as posições possíveis para a grade atual
	var all_possible_positions = []
	var half_width = grid_size.x / 2
	var half_height = grid_size.y / 2
	
	for y in range(-half_height, half_height + 1):
		for x in range(-half_width, half_width + 1):
			if x == 0 and y == 0: continue
			all_possible_positions.append(Vector2(x, y))
	
	# 3. PRIORIZA as posições da cruz!
	# Esta função de ordenação customizada coloca as posições cardinais primeiro.
	all_possible_positions.sort_custom(func(a, b): return a.length_squared() < b.length_squared())

	# 4. SELECIONA apenas as posições que usaremos nesta fase
	# Ex: Se answer_count for 4, ele pegará as 4 primeiras posições da lista ordenada (a cruz!)
	var positions_to_use = all_possible_positions.slice(0, answer_count)
	positions_to_use.shuffle() # Embaralha só as posições que vamos usar

	# 5. Prepara e distribui as respostas
	var all_answers = problem.wrong_answers
	all_answers.append(correct_answer)
	all_answers.shuffle()

	var final_answer_count = min(all_answers.size(), positions_to_use.size())

	for i in range(final_answer_count):
		var answer_instance = exploration_answer_scene.instantiate()
		answer_instance.add_to_group("exploration_answers")
		
		var relative_pos = positions_to_use[i]
		var offset = relative_pos * answer_spawn_distance
		var spawn_position = player.global_position + offset

		answer_instance.setup(all_answers[i], spawn_position)
		answer_instance.choice_made.connect(_on_exploration_answer_chosen)
		add_child(answer_instance)
# Dentro do seu script wave_manager.gd / game_manager.gd
func _on_exploration_answer_chosen(value_chosen, position_chosen):
	# Limpa TODOS os números da tela imediatamente após o clique
	for answer_node in get_tree().get_nodes_in_group("exploration_answers"):
		answer_node.queue_free()

	# Manda o jogador se mover, independentemente da resposta
	player.move_to_position(position_chosen)

	if value_chosen != correct_answer:
			print("Resposta errada! Penalidade aplicada.")
			player.lose_power(10)
			# CHAMA A ANIMAÇÃO DE DANO AQUI!
			player.play_hit_animation()
	if value_chosen == correct_answer:
		# RESPOSTA CORRETA: Aumenta o combo e calcula o ouro
		correct_streak += 1
		var gold_to_add = 0
		if correct_streak >= 7:
			gold_to_add = 4
		elif correct_streak >= 5:
			gold_to_add = 3
		elif correct_streak >= 3:
			gold_to_add = 2
		else:
			gold_to_add = 1
		
		print("Acerto! Combo: ", correct_streak, " | Ouro ganho: ", gold_to_add)
		player.add_gold(gold_to_add)

		# Manda o jogador se mover
		player.move_to_position(position_chosen)
	else:
		# RESPOSTA ERRADA: Zera o combo e aplica penalidade
		correct_streak = 0
		print("Resposta errada! Combo zerado. Penalidade aplicada.")
		player.lose_power(10)
		player.play_hit_animation()
		# Manda o jogador se mover mesmo errando
		player.move_to_position(position_chosen)
# NOVA FUNÇÃO: Chamada quando o jogador chega ao destino
func _on_player_movement_finished():
	# Só cria um novo desafio se ainda estivermos na fase de exploração
	if current_phase == GamePhase.EXPLORATION:
		print("Movimento concluído. Gerando novo desafio.")
		create_exploration_challenge()

func start_combat_phase():
	print("FASE DE COMBATE INICIOU!")
	current_phase = GamePhase.COMBAT
	shop_button.hide() # Esconde o botão da loja no combate
		# Limpa qualquer desafio de exploração que ainda esteja na tela
	for answer_node in get_tree().get_nodes_in_group("exploration_answers"):
		answer_node.queue_free()
	
	# Mostra a UI de perguntas, que pode ter sido escondida na fase de exploração
	question_label.show()
	
	# Define quantos monstros queremos nesta onda.
	# Você pode tornar este número dinâmico no futuro!
	var monster_count = 5
	
	# --- Verificações de Segurança ---
	# Garante que a lista de inimigos no Inspetor não está vazia.
	if enemy_scenes.is_empty():
		print("ERRO CRÍTICO: Nenhuma cena de inimigo foi adicionada à lista 'Enemy Scenes' no GameManager!")
		# Se não há inimigos, não podemos começar o combate. Voltamos à exploração.
		start_exploration_phase()
		return
	
	# Garante que a referência ao jogador é válida.
	if not is_instance_valid(player):
		print("ERRO CRÍTICO: O 'Player' não foi conectado ao GameManager no Inspetor!")
		return

	# --- Loop de Criação de Monstros ---
	# Gera a quantidade definida de monstros.
	for i in range(monster_count):
		# 1. Escolhe uma das cenas de inimigo ALEATORIAMENTE da nossa lista.
		var random_enemy_scene = enemy_scenes.pick_random()
		
		# 2. Cria uma nova instância daquela cena de inimigo.
		var enemy_instance = random_enemy_scene.instantiate()
		
		# 3. "Apresenta" o jogador ao novo inimigo para que ele saiba quem perseguir.
		enemy_instance.initialize(player)
		
		# 4. Calcula uma posição em círculo ao redor do jogador para o inimigo aparecer.
		var angle = i * (TAU / monster_count) # TAU é um atalho para 2 * PI na Godot 4
		var spawn_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
		enemy_instance.global_position = spawn_position
		
		# 5. Conecta o sinal de clique do inimigo à nossa função que lida com os cliques.
		enemy_instance.monster_clicked.connect(_on_monster_clicked)
		
		# 6. Adiciona o novo inimigo à nossa lista de monstros ativos para rastreamento.
		active_monsters.append(enemy_instance)
		
		# 7. Adiciona o inimigo à cena do jogo para que ele se torne visível e ativo.
		monster_container.add_child(enemy_instance)
		
	# Inicia a primeira rodada de perguntas matemáticas para a onda recém-criada.
	new_math_round()
	
# Esta função é chamada quando o tempo de exploração acaba
func _on_phase_timer_timeout():
	# Troca para a fase de combate
	start_combat_phase()

func new_math_round():
	if current_state != GameState.PLAYING:
		return
	if active_monsters.is_empty():
		question_label.text = "ONDA CONCLUÍDA!"
		await get_tree().create_timer(3.0).timeout
		# Volta para a fase de exploração!
		start_exploration_phase()
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
	print("_on_monster_clicked")
	if current_state != GameState.PLAYING:
		return
	if monster.answer_value == correct_answer:
		player.perform_attack(monster)
		active_monsters.erase(monster)
		player.gain_power(20)
		print("acertou")
	else:
		monster.apply_penalty_speed_boost()
		print("penalidade")
	
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
	
# Nova função para adicionar ouro
func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)
# Novas funções para abrir e fechar a loja
func _on_shop_button_pressed():
	shop_screen.show()
	get_tree().paused = true # PAUSA O JOGO!

func _on_close_shop_button_pressed():
	shop_screen.hide()
	get_tree().paused = false # DESPAUSA O JOGO!
