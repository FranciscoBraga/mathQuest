# interaction_puzzle_ui.gd
extends Panel

signal answer_chosen(answer_value)

@onready var question_label: Label = $QuestionLabel
@onready var answer_buttons_container = $VBoxContainer

func show_puzzle(problem: Dictionary):
	question_label.text = problem.question
	
	var all_answers = problem.wrong_answers
	all_answers.append(problem.correct_answer)
	all_answers.shuffle()
	
	for i in range(answer_buttons_container.get_child_count()):
		var button = answer_buttons_container.get_child(i)
		if i < all_answers.size():
			button.text = str(all_answers[i])
			button.show()
			# Conecta o sinal do botão a uma função que emite nosso sinal personalizado
			if not button.is_connected("pressed", _on_button_pressed):
				button.pressed.connect(_on_button_pressed.bind(all_answers[i]))
		else:
			button.hide()
	
	show()

func _on_button_pressed(value):
	emit_signal("answer_chosen", value)

func hide_puzzle():
	hide()
