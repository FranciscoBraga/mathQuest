# MathProblem.gd

# Função final que pode gerar múltiplos tipos de problemas
func generate_problem(current_game_phase: int) -> Dictionary:
	var level = SettingsManager.difficulty_level
	# ... (toda a sua lógica para definir max_number e min_number baseada no nível e modo) ...
	var max_number = 99 # Exemplo
	var min_number = 1  # Exemplo
	
	# --- LÓGICA DE ESCOLHA DO TIPO DE PROBLEMA ---
	var problem_types = ["standard"]
	# Desbloqueia novos tipos de problema em fases mais avançadas
	if current_game_phase >= 5:
		problem_types.append("find_x")
	if current_game_phase >= 10:
		problem_types.append("greater_less")
		
	var chosen_problem_type = problem_types.pick_random()

	# Variáveis que vamos preencher
	var question: String
	var correct_answer: int
	
	match chosen_problem_type:
		"standard":
			# Lógica que já temos para A + B = ?
			# ... (copie a lógica de soma, sub, mult, div da nossa versão anterior aqui)
			var num1 = randi_range(min_number, max_number)
			var num2 = randi_range(min_number, max_number)
			correct_answer = num1 + num2
			question = "%d + %d = ?" % [num1, num2]

		"find_x":
			# Novo tipo de problema: Encontre o X
			var num1 = randi_range(min_number, max_number / 2)
			var result = randi_range(num1 + 1, max_number)
			correct_answer = result - num1
			question = "%d + X = %d" % [num1, result]
			
		"greater_less":
			# Novo tipo de problema: Qual é maior?
			var num1 = randi_range(min_number, 20)
			var num2 = randi_range(min_number, 20)
			var num3 = randi_range(min_number, 20)
			var num4 = randi_range(min_number, 20)
			
			var result1 = num1 * num2
			var result2 = num3 + num4
			
			question = "(%d × %d) ___ (%d + %d)" % [num1, num2, num3, num4]
			
			if result1 > result2: correct_answer = 1 # Usaremos 1 para ">"
			elif result1 < result2: correct_answer = 2 # 2 para "<"
			else: correct_answer = 3 # 3 para "="
	
	# --- GERAÇÃO DE RESPOSTAS INCORRETAS ---
	var wrong_answers = []
	if chosen_problem_type == "greater_less":
		# As respostas para este modo são sempre as mesmas
		var all_possible = [1, 2, 3]
		all_possible.erase(correct_answer)
		wrong_answers = all_possible
	else:
		# Usa a lógica de offset para os outros modos
		var offset_range = max(5, int(correct_answer * 0.2))
		while wrong_answers.size() < 3: # Aumentado para 3 opções erradas
			var offset = randi_range(-offset_range, offset_range)
			var new_wrong_answer = correct_answer + offset
			if offset != 0 and new_wrong_answer not in wrong_answers and new_wrong_answer >= 0:
				wrong_answers.append(new_wrong_answer)

	return {
		"question": question,
		"correct_answer": correct_answer,
		"wrong_answers": wrong_answers,
		"type": chosen_problem_type # Retorna o tipo para a UI saber como exibir
	}
