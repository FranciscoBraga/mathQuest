# wave_manager.gd
# Herda de Node porque é apenas um organizador, um cérebro. NÃO tem corpo.
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

#
#   NENHUMA FUNÇÃO _physics_process, velocity ou move_and_slide() AQUI!
#

func _ready():
	# Conecta o sinal de morte do jogador a uma função aqui no gerenciador
	player.died.connect(_on_player_died)
	
	# Esconde a tela de game over no início
	game_over_screen.hide()
	
	call_deferred("start_wave", 5)

func start_wave(monster_count: int):
	# ORDEM: Limpar o campo de batalha.
	if monster_container.get_children() != null:
		for monster in monster_container.get_children():
			monster.queue_free()
		active_monsters.clear()
	
	# ORDEM: Gerar 5 novos soldados.
	for i in range(monster_count):
		var enemy_instance = enemy_scene.instantiate()
		
		# ORDEM: Posicionar o soldado em seu ponto inicial.
		var angle = i * (TAU / monster_count)
		var spawn_position = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
		enemy_instance.global_position = spawn_position
		print(spawn_position)
		# ORDEM: Soldado, me avise quando você for clicado!
		enemy_instance.monster_clicked.connect(_on_monster_clicked)
		
		active_monsters.append(enemy_instance)
		monster_container.add_child(enemy_instance)
		
	# ORDEM: Começar a primeira rodada de desafios!
	new_math_round()
	
func new_math_round():
	if current_state != GameState.PLAYING:
		return
	 # Se não houver mais monstros, o jogador venceu a onda
	if active_monsters.is_empty():
		question_label.text = "ONDA CONCLUÍDA!"
		await get_tree().create_timer(3.0).timeout
		start_wave(6) # Próxima onda com mais inimigos
		return
 # Pega um novo problema do nosso singleton MathProblem (verifique se ele está no Autoload)
	var problem = MathProblem.generate_problem(1)
	question_label.text = problem.question
	correct_answer = problem.correct_answer
	
	var answers_to_distribute = problem.wrong_answers
	
	while answers_to_distribute.size() < active_monsters.size() - 1:
		answers_to_distribute.append(correct_answer + randi_range(1, 5))

	active_monsters.shuffle()
	
	active_monsters[0].set_answer(correct_answer)
	
	for i in range(1, active_monsters.size()):
		active_monsters[i].set_answer(answers_to_distribute[i-1])

func _on_monster_clicked(monster: CharacterBody2D):
	if current_state != GameState.PLAYING:
		return
	if monster.answer_value == correct_answer:
		player.perform_attack(monster)
		active_monsters.erase(monster)
		player.gain_power(20) # Dá 20 de poder por acerto, por exemplo

	else:
		print("Errado! Aplicando penalidade.")
		monster.apply_penalty_speed_boost()
	
	new_math_round()
# ... (o resto do código do wave_manager, como new_math_round e _on_monster_clicked, permanece o mesmo) ...
# ... pois eles são ordens e reações, não ações físicas.
func _on_player_died():
	# Se o jogo já acabou, não faz nada
	if current_state == GameState.GAME_OVER:
		return

	# 1. Muda o estado do jogo
	current_state = GameState.GAME_OVER
	print("O JOGO ACABOU!")

	# 2. Mostra a tela de Fim de Jogo
	game_over_screen.show()

	# 3. Manda TODOS os inimigos ativos pararem
	for monster in active_monsters:
		# Verifica se o monstro ainda é válido antes de chamar a função
		if is_instance_valid(monster):
			monster.stop_moving()
# Ela é chamada quando o botão de reiniciar é pressionado.
func _on_restart_button_pressed() -> void:
	# A mágica acontece aqui! Esta linha recarrega a cena atual.
	get_tree().reload_current_scene()
