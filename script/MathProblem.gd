# MathProblem.gd
extends Node

# Gera um problema simples de adição.
# Dificuldade pode ser usada para aumentar os números.
func generate_problem(difficulty: int) -> Dictionary:
	var num1 = randi_range(1, 10 * difficulty)
	var num2 = randi_range(1, 10 * difficulty)
	var correct_answer = num1 + num2
	
	var question = "%d + %d" % [num1, num2]
	
	# Gera 3 respostas incorretas
	var wrong_answers = []
	while wrong_answers.size() < 3:
		var offset = randi_range(-5, 5)
		# Garante que o offset não seja zero e que a resposta não seja repetida
		if offset != 0 and (correct_answer + offset) not in wrong_answers:
			wrong_answers.append(correct_answer + offset)
			
	return {
		"question": question,
		"correct_answer": correct_answer,
		"wrong_answers": wrong_answers
	}
