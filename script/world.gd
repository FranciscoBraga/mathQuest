# world.gd
extends Node2D

# Pré-carrega a cena da nossa opção de resposta
@export var AnswerChoiceScene: PackedScene

# Referências aos nós da cena (arraste-os do painel de cena para o inspetor)
@onready var player = $player
@onready var question_label = $CanvasLayer/Control/QuestionLabel

var correct_answer: int
var target_position: Vector2

func _ready():
	# Começa o jogo criando o primeiro desafio de movimento
	create_movement_challenge()

func create_movement_challenge():
	# Pega um novo problema matemático do nosso singleton
	var problem = MathProblem.generate_problem(1) # Dificuldade 1 por enquanto
	
	question_label.text = problem.question
	correct_answer = problem.correct_answer
	
	# Combina a resposta certa com as erradas e embaralha
	var all_answers = problem.wrong_answers
	all_answers.append(correct_answer)
	all_answers.shuffle()
	
	# Cria as opções de resposta na tela, em volta do jogador
	for i in range(all_answers.size()):
		var answer_choice_instance = AnswerChoiceScene.instantiate()
		
		# Lógica para posicionar em círculo ao redor do jogador
		var angle = i * (PI * 2 / all_answers.size())
		var spawn_position = player.position + Vector2(cos(angle), sin(angle)) * 150 # 150 pixels de distância
		
		# Adiciona a instância como filha deste nó (o mundo)
		add_child(answer_choice_instance)
		
		# Configura a instância com o valor e a posição
		answer_choice_instance.setup(all_answers[i], spawn_position)
		
		# Conecta o sinal da instância a uma função aqui no "maestro"
		answer_choice_instance.choice_made.connect(_on_answer_choice_made)
		
	# Define a posição para onde o jogador deve ir se acertar
	# Por exemplo, vamos fazer ele andar 100 pixels para a direita
	target_position = player.position + Vector2(200, 0)

# Esta função é chamada quando QUALQUER opção de resposta é clicada
func _on_answer_choice_made(value_chosen: int):
	# Limpa as outras opções de resposta da tela
	for node in get_children():
		if node is Area2D:
			node.queue_free()

	if value_chosen == correct_answer:
		print("Resposta Correta!")
		player.move_to(target_position)
		# Após um tempinho, cria o próximo desafio
		await get_tree().create_timer(1.5).timeout
		create_movement_challenge()
	else:
		print("Resposta Errada!")
		# Lógica de erro: o jogador pode tremer, perder um pouco de vida, etc.
		await get_tree().create_timer(1.0).timeout
		create_movement_challenge() # Tenta de novo ou gera novo problema
