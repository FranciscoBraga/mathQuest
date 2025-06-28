# wave_manager.gd
extends Node

@export var enemy_scenes: Array[PackedScene]
@export var spawn_radius = 500
@export var game_over_screen: Control

enum GameState { PLAYING, GAME_OVER }
var current_state = GameState.PLAYING

# Definimos os dois principais estados do nosso jogo
enum GamePhase { EXPLORATION, COMBAT }
var current_phase = GamePhase.EXPLORATION # O jogo começa na fase de exploração

@export var player: CharacterBody2D
@export var question_label: Label
@export var monster_container: Node2D
@onready var phase_timer: Timer = $PhaseTimer

var active_monsters = []
var correct_answer = 0


func _ready():
	player.died.connect(_on_player_died)
	game_over_screen.hide()
	
	# Conecta o sinal do nosso novo timer
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	
	# Inicia o jogo na primeira fase de exploração
	start_exploration_phase()

func start_exploration_phase():
	print("FASE DE EXPLORAÇÃO INICIOU!")
	current_phase = GamePhase.EXPLORATION
	
	# Garante que não há monstros ou perguntas na tela
	question_label.hide()
	for monster in monster_container.get_children():
		monster.queue_free()
	active_monsters.clear()

	# Inicia o cronômetro para a próxima fase de combate
	phase_timer.start()
	

# Dentro do seu script wave_manager.gd / game_manager.gd

func start_combat_phase():
	print("FASE DE COMBATE INICIOU!")
	current_phase = GamePhase.COMBAT
	
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
