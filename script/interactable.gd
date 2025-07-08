# interactable.gd
extends Area2D

# Sinais para comunicar o RESULTADO da interação para o GameManager
signal interaction_succeeded(reward_type, reward_amount)
signal interaction_failed

# --- Variáveis de Configuração (no Inspetor) ---
@export_enum("Fácil", "Médio", "Difícil") var difficulty = "Fácil"
@export_range(1, 5) var puzzle_steps = 1
@export var reward_type = "ouro"
@export var reward_amount = 20

# --- Referências e Estado Interno ---
@onready var puzzle_ui: Control = $PuzzleUI
@onready var question_label: Label = $PuzzleUI/QuestionLabel
@onready var answers_container: HBoxContainer = $PuzzleUI/AnswersContainer

var player_is_near = false
var has_been_unlocked = false
var correct_answer = 0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Conecta todos os botões de resposta a uma única função usando bind()
	for button in answers_container.get_children():
		# Nós "empacotamos" o próprio botão na conexão do sinal
		button.pressed.connect(_on_answer_button_pressed.bind(button))

func _process(delta: float) -> void:
# Nós só precisamos calcular a posição se a UI do puzzle estiver visível.
	if puzzle_ui.visible:
		# 1. Começamos na posição global do baú (self.global_position).
		# 2. Criamos um deslocamento (offset).
		#    - No eixo X: Subtraímos metade da LARGURA da UI para centralizá-la.
		#    - No eixo Y: Subtraímos um valor fixo (ex: 150) para posicioná-la ACIMA do baú.
		var ui_offset = Vector2(-puzzle_ui.size.x / 2, -15)
		
		# 3. Definimos a posição global da UI como a posição do baú + o nosso deslocamento.
		puzzle_ui.global_position = self.global_position + ui_offset

func _on_body_entered(body):
	if body.is_in_group("player") and not has_been_unlocked:
		player_is_near = true
		# Mostra o puzzle automaticamente ao tocar
		show_puzzle()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_is_near = false
		# Esconde o puzzle se o jogador se afastar sem resolver
		puzzle_ui.hide()

func show_puzzle():
	# Pede um novo problema ao nosso singleton
	var problem = MathProblem.generate_problem(1,2) # Pode usar a dificuldade aqui depois
	question_label.text = problem.question
	correct_answer = problem.correct_answer
	
	var all_answers = problem.wrong_answers
	all_answers.append(correct_answer)
	all_answers.shuffle()
	
	# Configura os botões com as respostas
	for i in range(answers_container.get_child_count()):
		var button = answers_container.get_child(i)
		if i < all_answers.size():
			var answer_value = all_answers[i]
			button.text = str(answer_value)
			button.set_meta("answer_value", answer_value) # Guarda o valor no botão
			button.show()
		else:
			button.hide()
			
	puzzle_ui.show()

func _on_answer_button_pressed(button_pressed: Button):
	var chosen_value = button_pressed.get_meta("answer_value")
	
	if chosen_value == correct_answer:
		# SUCESSO!
		print("Baú aberto!")
		has_been_unlocked = true
		puzzle_ui.hide()
		# Emite um sinal com a recompensa para o GameManager/Player pegar
		emit_signal("interaction_succeeded", reward_type, reward_amount)
		# Toca uma animação de "abrir"
		# $Sprite2D.play("open") # Exemplo
	else:
		# ERRO!
		print("Resposta errada!")
		puzzle_ui.hide()
		# Emite um sinal de falha para o Player sofrer a penalidade
		emit_signal("interaction_failed")
		
		# Opcional: o baú pode ficar "travado" por um tempo
		await get_tree().create_timer(5.0).timeout
		# E reaparecer o puzzle
		if player_is_near:
			show_puzzle()
